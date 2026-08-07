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

  @override
  String get navAddShort => 'Add';

  @override
  String get browseTitle => 'Hub browser';

  @override
  String get catSecurity => 'Security';

  @override
  String get catDone => 'Completed';

  @override
  String get catAnnotations => 'Marks';

  @override
  String get catSessions => 'Sessions';

  @override
  String get catArtifacts => 'Reports & plans';

  @override
  String get catKnowledge => 'Knowledge base';

  @override
  String get catRoadmap => 'Roadmap';

  @override
  String get catActivity => 'Activity';

  @override
  String get catContract => 'Contract';

  @override
  String get catSourceAllRepos => 'tasks/ · notes/';

  @override
  String get catSourceCommits => 'commit history';

  @override
  String get sessionsEmptyTitle => 'No session records';

  @override
  String get sessionsEmptySubtitle =>
      'The agent writes every working session here.';

  @override
  String get artifactsEmptyTitle => 'No artifacts yet';

  @override
  String get artifactsEmptySubtitle =>
      'The agent saves the reports and plans it produces here.';

  @override
  String get contractDocTitle => 'Format contract';
}
