import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/common/hub_watcher_scope.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell.dart';
import 'hub/hub_config.dart';
import 'hub/hub_language.dart';
import 'l10n/app_localizations.dart';

class TakipApp extends ConsumerWidget {
  const TakipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(hubConfigProvider);
    // Dil **aktif hub'ın** özelliği (sözleşme 1.19), cihazın tercihi değil.
    // Hub yokken (onboarding) ve okunamadığında null → sistem dili.
    final language = ref.watch(activeHubLanguageProvider).valueOrNull;

    return MaterialApp(
      title: 'Takip',
      locale: language == null ? null : Locale(language.code),
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
