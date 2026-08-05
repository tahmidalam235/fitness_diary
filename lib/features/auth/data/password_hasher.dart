import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 password hasher.
///
/// Implemented inline because the current `crypto` package (3.x)
/// dropped the top-level `pbkdf2_hmac_sha256` function and only ships
/// the HMAC primitive. The algorithm itself is small enough to be
/// worth owning — RFC 2898, ~40 lines.
///
/// Parameters:
///   * 16-byte random salt (per-user, stored alongside the hash)
///   * 120,000 iterations — OWASP 2023 recommendation for SHA-256
///   * 32-byte derived key length
///
/// Verification uses a constant-time compare so an attacker can't
/// mount a timing oracle against the hashed output.
class PasswordHasher {
  PasswordHasher._();

  static const int _saltBytes = 16;
  static const int _iterations = 120000;
  static const int _dkLen = 32;

  /// Hashes [password] and returns the salt + hash + iteration count
  /// to persist alongside the user row.
  static HashedPassword hash(String password) {
    final rng = Random.secure();
    final salt = Uint8List(_saltBytes);
    for (var i = 0; i < _saltBytes; i++) {
      salt[i] = rng.nextInt(256);
    }
    final bytes = _pbkdf2(
      password: utf8.encode(password),
      salt: salt,
      iterations: _iterations,
      dkLen: _dkLen,
    );
    return HashedPassword(
      hashB64: base64.encode(bytes),
      saltB64: base64.encode(salt),
      iterations: _iterations,
    );
  }

  /// Verifies [password] against the stored [hashed] values.
  /// Returns true on match, false on mismatch. The compare is
  /// constant-time over the base64 strings so we don't leak the
  /// position of the first mismatched byte.
  static bool verify({
    required String password,
    required HashedPassword hashed,
  }) {
    final salt = base64.decode(hashed.saltB64);
    final bytes = _pbkdf2(
      password: utf8.encode(password),
      salt: salt,
      iterations: hashed.iterations,
      dkLen: _dkLen,
    );
    final candidate = base64.encode(bytes);
    return _constantTimeEquals(candidate, hashed.hashB64);
  }

  /// Reference PBKDF2 implementation per RFC 2898 §5.2:
  ///   DK = T1 || T2 || ... || TdkLen/hLen
  ///   Ti = F(P, S, c, i)
  ///   F(P, S, c, i) = U1 ^ U2 ^ ... ^ Uc
  ///   U1 = HMAC(P, S || INT(i))
  ///   Un = HMAC(P, U{n-1})
  static Uint8List _pbkdf2({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int dkLen,
  }) {
    final hmac = Hmac(sha256, password);
    final hLen = 32; // SHA-256 output length
    final blocks = (dkLen + hLen - 1) ~/ hLen;
    final out = Uint8List(blocks * hLen);

    for (var blockIndex = 1; blockIndex <= blocks; blockIndex++) {
      // U1 = HMAC(P, S || INT(blockIndex))
      final first = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..setRange(salt.length, salt.length + 4, _int32be(blockIndex));
      var u = Uint8List.fromList(hmac.convert(first).bytes);
      final t = Uint8List.fromList(u);

      // U2..Uc and folded XOR.
      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < hLen; j++) {
          t[j] ^= u[j];
        }
      }

      out.setRange((blockIndex - 1) * hLen, blockIndex * hLen, t);
    }

    return Uint8List.sublistView(out, 0, dkLen);
  }

  /// 32-bit big-endian integer as 4 bytes — the block counter for
  /// PBKDF2.
  static List<int> _int32be(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  /// Constant-time string compare. Both strings must be the same
  /// length; we XOR each code unit and OR the results, returning
  /// true only when the running accumulator is zero.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// Salted + stretched password output, ready to be written to the
/// `users` row.
class HashedPassword {
  const HashedPassword({
    required this.hashB64,
    required this.saltB64,
    required this.iterations,
  });

  final String hashB64;
  final String saltB64;
  final int iterations;
}