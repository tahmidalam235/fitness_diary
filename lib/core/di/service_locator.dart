import 'package:get_it/get_it.dart';

/// Global service-locator instance.
///
/// Defined here (not in `injection.dart`) so registration extensions
/// can reference it without creating a circular import.
final GetIt getIt = GetIt.instance;
