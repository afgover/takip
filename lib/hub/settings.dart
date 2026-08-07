import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Kullanıcının değiştirebildiği ayarlar (B-051).
class AppSettingsState {
  const AppSettingsState({required this.pollInterval, this.localeCode});

  final Duration pollInterval;

  /// Arayüz dili: `tr`, `en` ya da **null = sistem dili** (sözleşme 1.18).
  ///
  /// Yalnız arayüzü etkiler. Hub'a **yazılan** görev ve notların dili buna
  /// bağlı değildir: gövde başlıkları (`## İstek`, `## Notlar`) sözleşmeyle
  /// sabit ve ayrıştırıcı onları arıyor — dile göre değişselerdi mevcut bütün
  /// kayıtlar okunamaz hâle gelirdi.
  final String? localeCode;

  AppSettingsState copyWith({
    Duration? pollInterval,
    String? localeCode,
    bool clearLocale = false,
  }) =>
      AppSettingsState(
        pollInterval: pollInterval ?? this.pollInterval,
        localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      );
}

/// Ayarlar **eşzamanlı** bir varsayılanla başlar, disktekiler gelince
/// güncellenir. Böylece yoklama servisi açılışta "ayarlar yüklensin" diye
/// beklemez; kullanıcı bir değer değiştirmediyse zaten varsayılan geçerlidir.
class AppSettings extends Notifier<AppSettingsState> {
  static const pollIntervalKey = 'poll_interval_seconds';
  static const localeKey = 'locale_code';

  /// Desteklenen arayüz dilleri.
  static const supportedLocales = ['tr', 'en'];

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
      final code = prefs.getString(localeKey);
      if (code != null && supportedLocales.contains(code)) {
        state = state.copyWith(localeCode: code);
      }

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

  /// Arayüz dilini değiştirir. [code] null ise sistem dili kullanılır.
  Future<void> setLocale(String? code) async {
    if (code != null && !supportedLocales.contains(code)) return;
    state = state.copyWith(localeCode: code, clearLocale: code == null);

    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(localeKey);
    } else {
      await prefs.setString(localeKey, code);
    }
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettings, AppSettingsState>(AppSettings.new);
