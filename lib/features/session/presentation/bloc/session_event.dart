import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

abstract class SessionEvent {
  const SessionEvent();
}

class LoadSessions extends SessionEvent {
  const LoadSessions();
}

class AddSession extends SessionEvent {
  const AddSession({required this.name, required this.description});

  final String name;
  final String description;

  SessionsCompanion toCompanion() {
    return SessionsCompanion.insert(
      name: name,
      description: Value(description),
    );
  }
}

class DeleteSession extends SessionEvent {
  const DeleteSession(this.id);

  final int id;
}
