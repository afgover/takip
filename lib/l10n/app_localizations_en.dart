// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Takip';

  @override
  String get langSystem => 'System language';

  @override
  String get langTurkish => 'Türkçe';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageHelp =>
      'Interface language. The language of tasks and notes written to the hub does not change — their format is fixed by the contract.';

  @override
  String get navPending => 'Pending';

  @override
  String get navBrowse => 'Browser';

  @override
  String get navAdd => 'Add task';

  @override
  String get navSettings => 'Settings';
}
