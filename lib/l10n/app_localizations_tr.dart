// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class LTr extends L {
  LTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Takip';

  @override
  String get langSystem => 'Sistem dili';

  @override
  String get langTurkish => 'Türkçe';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageHelp =>
      'Arayüz dili. Hub\'a yazılan görev ve notların dili değişmez — onların biçimi sözleşmeyle sabittir.';

  @override
  String get navPending => 'Bekleyenler';

  @override
  String get navBrowse => 'Tarayıcı';

  @override
  String get navAdd => 'Görev ekle';

  @override
  String get navSettings => 'Ayarlar';
}
