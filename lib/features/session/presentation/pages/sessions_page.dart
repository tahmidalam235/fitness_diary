import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/daos/session_dao.dart';
import '../../../../core/di/injection.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';
import 'create_session_page.dart';
import 'session_details_page.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SessionBloc(getIt<SessionDao>())..add(const LoadSessions()),
      child: const _SessionsView(),
    );
  }
}

class _SessionsView extends StatelessWidget {
  const _SessionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(
            context,
            MaterialPageRoute(builder: (_) => const CreateSessionPage()),
          );

          if (!context.mounted || result == null) {
            return;
          }

          context.read<SessionBloc>().add(
            AddSession(
              name: result['name']!,
              description: result['description']!,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          if (state.sessions.isEmpty) {
            return const Center(child: Text('No Sessions'));
          }

          return ListView.builder(
            itemCount: state.sessions.length,
            itemBuilder: (context, index) {
              final session = state.sessions[index];

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailsPage(session: session),
                    ),
                  );
                },
                leading: const Icon(Icons.fitness_center),
                title: Text(session.name),
                subtitle: Text(session.description),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    context.read<SessionBloc>().add(DeleteSession(session.id));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
