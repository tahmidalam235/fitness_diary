import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.fitness_center_rounded, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'Fitness Diary',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            _tile(
              context,
              icon: Icons.today_rounded,
              title: 'Today',
              route: '/today',
            ),
            _tile(
              context,
              icon: Icons.view_week_rounded,
              title: 'Sessions',
              route: '/sessions',
            ),
            _tile(
              context,
              icon: Icons.fitness_center_rounded,
              title: 'Workout Library',
              route: '/workouts',
            ),
            _tile(
              context,
              icon: Icons.calendar_month_rounded,
              title: 'Calendar',
              route: '/calendar',
            ),
            _tile(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'Dashboard',
              route: '/dashboard',
            ),
            _tile(
              context,
              icon: Icons.settings_rounded,
              title: 'Settings',
              route: '/settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
