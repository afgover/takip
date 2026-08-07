import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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
    final l = L.of(context);

    return Scaffold(
      // Gövde `AppBar`sız başlıyor: en üstteki şerit, korunmazsa durum
      // çubuğunun (saat, pil) altına girip okunmaz hâle geliyor. Alt taraf
      // hariç tutuldu — orayı `bottomNavigationBar` zaten kendi hallediyor.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const RepoSwitcher(),
            HubStatusBanner(
              onOpenSettings: () =>
                  setState(() => _index = AppShell.settingsTabIndex),
            ),
            Expanded(child: _screens[_index]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.pending_actions), label: l.navPending),
          NavigationDestination(
              icon: const Icon(Icons.add_task), label: l.navAddShort),
          NavigationDestination(
              icon: const Icon(Icons.folder_open), label: l.navBrowse),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: l.navSettings),
        ],
      ),
    );
  }
}
