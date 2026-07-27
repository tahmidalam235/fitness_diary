import 'package:flutter/material.dart';

import '../../domain/session_entity.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    this.onTap,
    this.onDelete,
  });

  final SessionEntity session;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            session.name.isEmpty ? '?' : session.name[0].toUpperCase(),
          ),
        ),
        title: Text(session.name),
        subtitle: Text(
          session.description.isEmpty ? 'No description' : session.description,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
