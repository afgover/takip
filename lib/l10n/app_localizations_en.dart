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

  @override
  String get roadmapTitle => 'Roadmap';

  @override
  String get knowledgeTitle => 'Knowledge base';

  @override
  String get annotationsTitle => 'Marks';

  @override
  String statusQueued(int count) {
    return '$count tasks waiting to be sent';
  }

  @override
  String get docMalformedFrontmatter =>
      'This file’s header block could not be read; the content is shown raw.';

  @override
  String get cancel => 'Cancel';

  @override
  String get connectAnyway => 'Connect anyway';

  @override
  String get manageRepos => 'Manage repositories';

  @override
  String queuedTasks(int count) {
    return '$count tasks queued';
  }

  @override
  String queuedTasksWithSlug(String slug, int count) {
    return '$slug · $count tasks queued';
  }

  @override
  String get markYellow => 'Highlight yellow';

  @override
  String get markRed => 'Underline red';

  @override
  String get markBookmark => 'Bookmark';

  @override
  String get addNote => 'Add note';

  @override
  String get createTask => 'Create task';

  @override
  String get copy => 'Copy';

  @override
  String knowledgeEmptyTitle(String label) {
    return '$label is empty';
  }

  @override
  String get knowledgeEmptySubtitle =>
      'New records appear here as the agent adds them.';

  @override
  String get knowledgeSuperseded => 'superseded record';

  @override
  String get annotationsEmptyTitle => 'No marks yet';

  @override
  String get annotationsEmptySubtitle =>
      'Select text in any document to bookmark, highlight or add a note. They all gather here.';

  @override
  String get activityHubOnly => 'Show hub records only';

  @override
  String get activityShowCode => 'Show code commits too';

  @override
  String get activityEmptyTitle => 'The feed is empty';

  @override
  String get activityEmptySubtitle =>
      'Records appear here as they land in the hub.';
}
