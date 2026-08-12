/// Functional result type used across domain and data layers.
///
/// `Either<L, R>` represents a value of either [Left] (a [Failure]) or
/// [Right] (a success payload). Use [fold] to consume both sides.
sealed class Either<L, R> {
  const Either();

  /// Returns true when this is a [Right] value.
  bool get isRight => this is Right<L, R>;

  /// Returns true when this is a [Left] value.
  bool get isLeft => this is Left<L, R>;

  /// Pattern-match over both cases.
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    final self = this;
    if (self is Right<L, R>) {
      return onRight(self.value);
    }
    return onLeft((self as Left<L, R>).value);
  }

  /// Map the success value, leaving failures untouched.
  Either<L, T> map<T>(T Function(R right) mapper) {
    final self = this;
    if (self is Right<L, R>) {
      return Right<L, T>(mapper(self.value));
    }
    return Left<L, T>((self as Left<L, R>).value);
  }

  /// Map the failure value, leaving successes untouched.
  Either<T, R> mapLeft<T>(T Function(L left) mapper) {
    final self = this;
    if (self is Left<L, R>) {
      return Left<T, R>(mapper(self.value));
    }
    return Right<T, R>((self as Right<L, R>).value);
  }

  /// Monadic bind on the success side.
  Either<L, T> bind<T>(Either<L, T> Function(R right) mapper) {
    final self = this;
    if (self is Right<L, R>) {
      return mapper(self.value);
    }
    return Left<L, T>((self as Left<L, R>).value);
  }

  /// Returns the success value or a fallback when this is a [Left].
  R getOrElse(R Function(L left) fallback) {
    final self = this;
    if (self is Right<L, R>) {
      return self.value;
    }
    return fallback((self as Left<L, R>).value);
  }
}

/// Failure side of [Either].
final class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Left<L, R> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Left($value)';
}

/// Success side of [Either].
final class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Right<L, R> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Right($value)';
}
