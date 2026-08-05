import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User profile data. Held in memory and persisted to SharedPreferences
/// so the dashboard / drawer header / profile page all see the same
/// values across launches.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.avatarPath,
  });

  final String name;
  final String email;
  final String? avatarPath;

  static const empty = UserProfile(
    name: 'Tahmid',
    email: 'tahmid@fitnessdiary.com',
  );

  UserProfile copyWith({String? name, String? email, String? avatarPath}) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

/// In-memory + SharedPreferences-backed profile store. Listeners get
/// notified when any field changes so the UI refreshes immediately.
class ProfileService extends ChangeNotifier {
  static const _kName = 'profile_name';
  static const _kEmail = 'profile_email';
  static const _kAvatar = 'profile_avatar';

  UserProfile _profile = UserProfile.empty;
  UserProfile get profile => _profile;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _profile = UserProfile(
      name: prefs.getString(_kName) ?? UserProfile.empty.name,
      email: prefs.getString(_kEmail) ?? UserProfile.empty.email,
      avatarPath: prefs.getString(_kAvatar),
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    _profile = _profile.copyWith(name: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name);
    notifyListeners();
  }

  Future<void> updateEmail(String email) async {
    _profile = _profile.copyWith(email: email);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email);
    notifyListeners();
  }

  Future<void> updateAvatar(String? path) async {
    _profile = _profile.copyWith(avatarPath: path);
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kAvatar);
    } else {
      await prefs.setString(_kAvatar, path);
    }
    notifyListeners();
  }

  Future<void> reset() async {
    _profile = UserProfile.empty;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kAvatar);
    notifyListeners();
  }
}
