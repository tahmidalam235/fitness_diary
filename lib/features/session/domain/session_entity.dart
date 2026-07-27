class SessionEntity {
  const SessionEntity({this.id, required this.name, this.description = ''});

  final int? id;
  final String name;
  final String description;

  SessionEntity copyWith({int? id, String? name, String? description}) {
    return SessionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
