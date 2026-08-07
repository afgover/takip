import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/common/hub_watcher_scope.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell.dart';
import 'hub/hub_config.dart';
import 'hub/settings.dart';
import 'l10n/app_localizations.dart';

class TakipApp extends ConsumerWidget {
  const TakipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(hubConfigProvider);
    // null = sistem dilini izle (cihaz Türkçe değilse İngilizce'ye düşer).
    final localeCode = ref.watch(
      appSettingsProvider.select((s) => s.localeCode),
    );

    return MaterialApp(
      title: 'Takip',
      locale: localeCode == null ? null : Locale(localeCode),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: switch (config) {
        // Yoklama yalnız bağlantı kurulduktan sonra başlar.
        AsyncData(:final value) => value == null
            ? const OnboardingScreen()
            : const HubWatcherScope(child: AppShell()),
        AsyncError() => const OnboardingScreen(),
        _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
      },
    );
  }
}
