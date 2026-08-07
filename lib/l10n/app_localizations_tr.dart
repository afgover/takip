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

  @override
  String get navAddShort => 'Ekle';

  @override
  String get browseTitle => 'Hub Tarayıcı';

  @override
  String get catSecurity => 'Security';

  @override
  String get catDone => 'Tamamlananlar';

  @override
  String get catAnnotations => 'İşaretler';

  @override
  String get catSessions => 'Oturumlar';

  @override
  String get catArtifacts => 'Raporlar & Planlar';

  @override
  String get catKnowledge => 'Bilgi tabanı';

  @override
  String get catRoadmap => 'Yol haritası';

  @override
  String get catActivity => 'Aktivite';

  @override
  String get catContract => 'Sözleşme';

  @override
  String get catSourceAllRepos => 'tasks/ · notes/';

  @override
  String get catSourceCommits => 'commit geçmişi';

  @override
  String get sessionsEmptyTitle => 'Oturum kaydı yok';

  @override
  String get sessionsEmptySubtitle =>
      'Agent her çalışma oturumunu buraya yazar.';

  @override
  String get artifactsEmptyTitle => 'Henüz artifact yok';

  @override
  String get artifactsEmptySubtitle =>
      'Agent ürettiği rapor ve planları buraya kaydeder.';

  @override
  String get contractDocTitle => 'Format Sözleşmesi';
}
