/// Unit is a void-equivalent marker used as the success type for use cases
/// that have no meaningful return value (e.g. delete operations).
final class Unit {
  const Unit._();

  /// Singleton instance.
  static const Unit instance = Unit._();

  @override
  String toString() => 'Unit';
}
