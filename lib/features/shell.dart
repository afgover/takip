import 'package:flutter/material.dart';

import 'add_task/add_task_screen.dart';
import 'browse/browse_screen.dart';
import 'pending/pending_screen.dart';
import 'settings/settings_screen.dart';

/// Alt gezinmeli ana kabuk: Bekleyenler · Ekle · Tarayıcı · Ayarlar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    PendingScreen(),
    AddTaskScreen(),
    BrowseScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.pending_actions), label: 'Bekleyenler'),
          NavigationDestination(icon: Icon(Icons.add_task), label: 'Ekle'),
          NavigationDestination(icon: Icon(Icons.folder_open), label: 'Tarayıcı'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
