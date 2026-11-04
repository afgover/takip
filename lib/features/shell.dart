import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../merkez/merkez_providers.dart';

import 'add_task/add_task_screen.dart';
import 'browse/browse_screen.dart';
import 'common/hub_status_banner.dart';
import 'common/repo_switcher.dart';
import 'pending/pending_screen.dart';
import 'settings/settings_screen.dart';
import 'share/shared_text.dart';
import 'today/today_screen.dart';

/// Alt gezinmeli ana kabuk: Bugün · Bekleyenler · Ekle · Tarayıcı · Ayarlar.
///
/// Repo şeridi (T-003) ve durum şeridi (B-050) sekmelerin üstünde, yani hangi
/// ekranda olursa olsun görünür. Sıra bilinçli: "hangi repodayım" sorusu
/// "bağlantı iyi mi" sorusundan önce gelir — ikincisinin cevabı birincisine
/// bağlıdır.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  static const todayTabIndex = 0;
  static const pendingTabIndex = 1;
  static const addTabIndex = 2;
  static const settingsTabIndex = 4;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Merkez'e bağlı olmayan kullanıcının ana ekranı değişmez.
  int _index = AppShell.pendingTabIndex;
  bool _openedToday = false;

  static const _screens = [
    TodayScreen(),
    PendingScreen(),
    AddTaskScreen(),
    BrowseScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // Açılışta bir kez: oturum varsa ana ekran Bugün. Sonraki girişlerde
    // kullanıcının seçili sekmesi elinden alınmaz.
    ref.listen<AsyncValue<String?>>(merkezTokenProvider, (_, next) {
      if (_openedToday || !next.hasValue) return;
      _openedToday = true;
      if (next.value != null) setState(() => _index = AppShell.todayTabIndex);
    });
    // Paylaş menüsünden metin geldi (P-031): formu gösteren sekmeye geç.
    ref.listen<SharedText?>(sharedTextProvider, (previous, next) {
      if (next != null && next.seq != previous?.seq) {
        setState(() => _index = AppShell.addTabIndex);
      }
    });

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
            // IndexedStack: tüm sekmeler canlı kalır — `_screens[_index]`
            // seçileni yeniden kurup ötekileri YOK EDİYORDU ve ekleme
            // ekranındaki yazı, kullanıcı başka sekmeye bakıp dönünce
            // kayboluyordu (T-022). Bedeli ekranların bellekte durması;
            // hepsi hafif, kabul edildi.
            Expanded(child: IndexedStack(index: _index, children: _screens)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.today), label: l.navToday),
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
