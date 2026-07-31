import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Kullanıcının değiştirebildiği ayarlar (B-051).
class AppSettingsState {
  const AppSettingsState({required this.pollInterval});

  final Duration pollInterval;

  AppSettingsState copyWith({Duration? pollInterval}) =>
      AppSettingsState(pollInterval: pollInterval ?? this.pollInterval);
}

/// Ayarlar **eşzamanlı** bir varsayılanla başlar, disktekiler gelince
/// güncellenir. Böylece yoklama servisi açılışta "ayarlar yüklensin" diye
/// beklemez; kullanıcı bir değer değiştirmediyse zaten varsayılan geçerlidir.
class AppSettings extends Notifier<AppSettingsState> {
  static const pollIntervalKey = 'poll_interval_seconds';

  /// Ayarlarda sunulan aralıklar. Alt sınır 30 sn: ETag sayesinde istekler
  /// bedava olsa da daha sıkı yoklamanın pratik faydası yok, bataryası var.
  static const intervalChoices = [
    Duration(seconds: 30),
    Duration(seconds: 45),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  @override
  AppSettingsState build() {
    unawaited(_restore());
    return const AppSettingsState(pollInterval: Hub.defaultPollInterval);
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt(pollIntervalKey);
      if (seconds == null) return;

      final restored = Duration(seconds: seconds);
      if (!intervalChoices.contains(restored)) return;
      state = state.copyWith(pollInterval: restored);
    } catch (_) {
      // Ayarlar okunamazsa varsayılanla devam edilir; yoklama gibi temel bir
      // işlev, kayıtlı tercih okunamadı diye durmamalı.
    }
  }

  Future<void> setPollInterval(Duration interval) async {
    if (!intervalChoices.contains(interval)) return;
    state = state.copyWith(pollInterval: interval);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(pollIntervalKey, interval.inSeconds);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettings, AppSettingsState>(AppSettings.new);
