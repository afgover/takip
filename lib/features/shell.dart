import 'package:flutter/material.dart';

import 'add_task/add_task_screen.dart';
import 'browse/browse_screen.dart';
import 'common/hub_status_banner.dart';
import 'common/repo_switcher.dart';
import 'pending/pending_screen.dart';
import 'settings/settings_screen.dart';

/// Alt gezinmeli ana kabuk: Bekleyenler · Ekle · Tarayıcı · Ayarlar.
///
/// Repo şeridi (T-003) ve durum şeridi (B-050) sekmelerin üstünde, yani hangi
/// ekranda olursa olsun görünür. Sıra bilinçli: "hangi repodayım" sorusu
/// "bağlantı iyi mi" sorusundan önce gelir — ikincisinin cevabı birincisine
/// bağlıdır.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static const settingsTabIndex = 3;

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
      body: Column(
        children: [
          const RepoSwitcher(),
          HubStatusBanner(
            onOpenSettings: () =>
                setState(() => _index = AppShell.settingsTabIndex),
          ),
          Expanded(child: _screens[_index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.pending_actions), label: 'Bekleyenler'),
          NavigationDestination(icon: Icon(Icons.add_task), label: 'Ekle'),
          NavigationDestination(
              icon: Icon(Icons.folder_open), label: 'Tarayıcı'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
