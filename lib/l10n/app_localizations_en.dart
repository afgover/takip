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

  @override
  String get doneEmptyTitle => 'No completed tasks';

  @override
  String get doneEmptySubtitle =>
      'When the agent finishes a task it is archived here.';

  @override
  String get pendingEmptyTitle => 'No pending tasks';

  @override
  String get pendingEmptySubtitle =>
      'Tasks you add appear here until the agent picks them up.';

  @override
  String get pendingFilterEmptyTitle => 'No tasks match the filter';

  @override
  String pendingFilterEmptySubtitle(int count) {
    return 'There are $count tasks but none match your filter.';
  }

  @override
  String get outboxQueuedSubtitle => 'Will be sent when back online';

  @override
  String get outboxQueuedBadge => 'Queued';

  @override
  String get onboardingIntro =>
      'Connect to your hub repository. Use a fine-grained token scoped to this repository only.';

  @override
  String get repoFieldInvalid => 'Enter it as owner/name';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get connect => 'Connect';

  @override
  String get tokenHelpTitle => 'How do I get a token?';

  @override
  String get tokenHelpStored =>
      'The token is stored only in this device’s secure storage.';

  @override
  String get tokenRequired => 'Token required';

  @override
  String get repoFieldLabel => 'Repository (owner/name)';

  @override
  String get tokenFieldLabel => 'Fine-grained token';
}
