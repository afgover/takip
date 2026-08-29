// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get langTurkish => 'Türkçe';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get navPending => 'Pending';

  @override
  String get navBrowse => 'Browser';

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
  String get catPlan => 'Task tree';

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
  String outboxStuckTitle(int count) {
    return '$count tasks cannot be sent';
  }

  @override
  String outboxStuckSubtitle(String repos) {
    return 'Target repository is not connected: $repos. Add it back and they will go on their own.';
  }

  @override
  String get outboxStuckDiscard => 'Delete';

  @override
  String outboxStuckConfirmTitle(int count) {
    return 'Delete $count tasks?';
  }

  @override
  String get outboxStuckConfirmBody =>
      'These tasks were never sent. Deleting them cannot be undone.';

  @override
  String get outboxStuckDiscarded =>
      'Tasks that could not be sent were deleted.';

  @override
  String get outboxQueuedBadge => 'Queued';

  @override
  String get pendingReportedBadge => 'Told';

  @override
  String get pendingReportedSubtitle =>
      'Stays in the list until the agent handles it';

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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get secConnection => 'Connection';

  @override
  String get secPolling => 'Polling';

  @override
  String get secOffline => 'Offline';

  @override
  String get secData => 'Data';

  @override
  String get repos => 'Repositories';

  @override
  String reposSubtitle(String name, int count) {
    return '$name · $count repositories';
  }

  @override
  String get tokenScopeTitle => 'Token scope';

  @override
  String get tokenScopeSubtitle => 'Measure how many repos the token can see';

  @override
  String get tokenScopeMeasuring => 'Measuring…';

  @override
  String get tokenScopeUnknown =>
      'Could not measure. Network or permission issue; the result is unknown.';

  @override
  String tokenScopeOk(int visible, int needed) {
    return 'Sees $visible repos, needs $needed. No excess access visible.';
  }

  @override
  String tokenScopeExcessFound(int visible, int needed) {
    return 'Sees $visible repos, needs $needed. Tap for details.';
  }

  @override
  String get close => 'Close';

  @override
  String get pollIntervalTitle => 'Check interval';

  @override
  String get pollIntervalHelp =>
      'When nothing changed, checks do not count against the GitHub rate limit, so frequent polling only costs battery.';

  @override
  String get backup => 'Backup';

  @override
  String get backupSubtitle =>
      'Turn connections into one password-encrypted text / restore them';

  @override
  String get downloadNow => 'Download now';

  @override
  String get offlineHelp =>
      'Everything in the browser is downloaded to the device and updates itself as the hub changes; it opens without a network too. Only changed files are downloaded.';

  @override
  String get trySendNow => 'Try now';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearCacheSubtitle =>
      'Everything re-downloads, including the on-device copy';

  @override
  String get resetConnection => 'Reset connection';

  @override
  String get resetAllConnections => 'Reset all connections';

  @override
  String get resetScopeOne =>
      'The connection is deleted and you return to onboarding';

  @override
  String resetScopeAll(int count) {
    return 'All $count connections are deleted from the device';
  }

  @override
  String get resetConfirmOne => 'Reset the connection?';

  @override
  String get resetConfirmAll => 'Reset all connections?';

  @override
  String resetBody(String scope) {
    return '$scope and you return to the onboarding screen.';
  }

  @override
  String resetBodyQueued(String scope, int count) {
    return '$scope. $count queued tasks will remain unsent.';
  }

  @override
  String get reset => 'Reset';

  @override
  String get syncChecking => 'Looking for changes…';

  @override
  String get syncNever => 'Not downloaded yet';

  @override
  String syncFailed(String reason) {
    return 'Download failed — $reason';
  }

  @override
  String syncJustNow(String base) {
    return '$base · updated just now';
  }

  @override
  String syncMinutes(String base, int n) {
    return '$base · $n minutes ago';
  }

  @override
  String syncHours(String base, int n) {
    return '$base · $n hours ago';
  }

  @override
  String syncDays(String base, int n) {
    return '$base · $n days ago';
  }

  @override
  String get watchNever => 'Not checked yet';

  @override
  String get watchJustNow => 'Checked just now';

  @override
  String watchMinutes(int n) {
    return 'Checked $n minutes ago';
  }

  @override
  String watchHours(int n) {
    return 'Checked $n hours ago';
  }

  @override
  String get cacheCleared => 'Cleared, downloading again.';

  @override
  String get resetSubtitleOne =>
      'The token is deleted and you return to onboarding';

  @override
  String resetSubtitleAll(int count) {
    return 'Tokens for $count repositories are deleted and you return to onboarding';
  }

  @override
  String get statusTitle => 'Status';

  @override
  String get offlineCopyTitle => 'On-device copy';

  @override
  String syncDownloading(int done, int total) {
    return 'Downloading $done/$total documents…';
  }

  @override
  String syncDocsDownloaded(int count) {
    return '$count documents downloaded';
  }

  @override
  String intervalSeconds(int n) {
    return '$n seconds';
  }

  @override
  String intervalMinutes(int n) {
    return '$n minutes';
  }

  @override
  String errAuthBody(String message) {
    return '$message\nYou can renew the token in Settings; permissions must be Contents: Read and write and Metadata: Read.';
  }

  @override
  String get errRateTitle => 'Request limit reached';

  @override
  String get errRateBody =>
      'GitHub\'s request limit is used up; it clears on its own after a while.';

  @override
  String get errNotFoundTitle => 'Not found';

  @override
  String get errGenericTitle => 'Something went wrong';

  @override
  String get all => 'All';

  @override
  String get secKindMeasure => 'Measure';

  @override
  String get secKindTodo => 'To do';

  @override
  String get secKindDecision => 'Decision';

  @override
  String get secKindScan => 'Scan';

  @override
  String get kind => 'Kind';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get reposHelp =>
      'Each repository is stored with its own token. A token should cover only its own repository — authorising one token for every repository means a bigger loss if you lose the phone.';

  @override
  String removeRepoTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeRepoBody =>
      'This repository’s token is deleted from the device.';

  @override
  String removeRepoQueued(int count) {
    return 'There are $count queued tasks for this repository; they cannot be sent if it is removed.';
  }

  @override
  String get removeRepoLast =>
      'This is the last repository — removing it returns you to onboarding.';

  @override
  String repoRemoved(String name) {
    return '$name removed.';
  }

  @override
  String get identityMissing => 'No identity — you can set it under Edit';

  @override
  String get contractUnreadable => 'Contract version could not be read';

  @override
  String contractStale(String version, String master) {
    return 'Contract $version — master is $master, the agent should update';
  }

  @override
  String contractCurrent(String version) {
    return 'Contract $version';
  }

  @override
  String get connectionUpdated => 'Connection updated.';

  @override
  String get repoAdded => 'Repository added.';

  @override
  String get connectionTitle => 'Connection';

  @override
  String get addRepo => 'Add repository';

  @override
  String get repoLocked =>
      'The repository cannot be changed — use “Add repository” instead.';

  @override
  String get labelOptional => 'Name (optional)';

  @override
  String get labelHelp =>
      'Shown in the repository switcher; owner/name is used when empty.';

  @override
  String get identityLabel => 'Identity (GitHub username)';

  @override
  String get identityHelp =>
      'Written as `author` on tasks and notes you create. If left empty it is read from the token.';

  @override
  String get tokenDifferent => 'Use a different token (optional)';

  @override
  String get tokenKeepIfEmpty => 'New token (unchanged if left empty)';

  @override
  String get verifyAndSave => 'Verify and save';

  @override
  String get reuseTokenHelp =>
      'Reuse the same token if it covers more than one repository.';

  @override
  String get enterNewToken => 'I will enter a new token';

  @override
  String useTokenOf(String name) {
    return 'Use $name’s token';
  }

  @override
  String get token => 'Token';

  @override
  String get tokenRequiredShort => 'Token required.';

  @override
  String get languageFromHub =>
      'Hub language — declared in `SYSTEM.md`. The interface, the contract and new records follow it; changing it is the agent’s job.';

  @override
  String get errSettingsButton => 'Connection settings';

  @override
  String get errRetry => 'Try again';

  @override
  String get errNetworkTitle => 'No connection';

  @override
  String get errNetworkBody =>
      'Could not reach the internet. Tasks you add wait in the queue and are sent on their own once you are back online.';

  @override
  String get errAuthTitle => 'Token was rejected';

  @override
  String errRateBodyIn(String left) {
    return 'GitHub\'s request limit is used up. Retrying in $left.';
  }

  @override
  String get errUnexpectedTitle => 'Unexpected error';

  @override
  String get errLeftSoon => 'a moment';

  @override
  String errLeftMinutes(int count) {
    return '$count minutes';
  }

  @override
  String errLeftHours(int count) {
    return '$count hours';
  }

  @override
  String get addTitle => 'Add Task';

  @override
  String get addFieldTitle => 'Title';

  @override
  String get addTitleRequired => 'Title is required';

  @override
  String get addTitleNeedsAlnum => 'Title must contain a letter or a digit';

  @override
  String get addFieldDescription => 'Description';

  @override
  String get addFieldPriority => 'Priority';

  @override
  String get addFieldCategory => 'Category';

  @override
  String get addFieldTargetRepo => 'Target repo';

  @override
  String get addNewCategory => 'New category…';

  @override
  String get addNewCategoryName => 'New category name';

  @override
  String get addCategoryRequired => 'Category name is required';

  @override
  String get addSubmit => 'Send to Hub';

  @override
  String get addSent => 'Task sent to the hub.';

  @override
  String get addQueued =>
      'No connection — the task is queued and will be sent once you are back online.';

  @override
  String addUnexpected(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupExportHeading => 'Export';

  @override
  String backupExportIntro(int count) {
    return 'Your $count saved connections are turned into a single piece of text. Because that text carries your tokens, it is encrypted with a passphrase you choose — without it the text is useless.';
  }

  @override
  String get backupPassLabel => 'Backup passphrase';

  @override
  String get backupPassHelp => 'If you forget this, the backup is useless.';

  @override
  String get backupExportButton => 'Create backup';

  @override
  String get backupCopyButton => 'Copy to clipboard';

  @override
  String get backupCopied => 'Copied. Paste it into your password manager.';

  @override
  String get backupCopyWarning =>
      'Save this in your password manager. Do not leave it on the clipboard — apps that keep clipboard history can read it.';

  @override
  String get backupRestoreHeading => 'Restore';

  @override
  String get backupRestoreIntro =>
      'Repositories in the backup are added to your list. If one is already saved, its token is refreshed; your existing connections are not removed.';

  @override
  String get backupTextLabel => 'Backup text';

  @override
  String get backupRestoreButton => 'Restore';

  @override
  String get backupPassTooShort =>
      'The passphrase must be at least 6 characters.';

  @override
  String get backupNothingToExport => 'There are no connections to back up.';

  @override
  String backupExported(int count) {
    return '$count connections backed up.';
  }

  @override
  String backupExportFailed(String error) {
    return 'Could not create the backup: $error';
  }

  @override
  String get backupPasteFirst => 'Paste the backup text.';

  @override
  String backupRestored(int count) {
    return '$count connections restored.';
  }

  @override
  String backupImportFailed(String error) {
    return 'Could not restore: $error';
  }

  @override
  String get detailNotHandledYet => 'agent has not picked this up yet';

  @override
  String get detailAnswerSent => 'Answer sent.';

  @override
  String get detailReported => 'The agent has been told.';

  @override
  String get detailQueued => 'No connection — queued.';

  @override
  String detailUnexpected(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String waitingForOtherQuestion(String who) {
    return 'This question is waiting on $who. You can answer it too.';
  }

  @override
  String waitingForOther(String who) {
    return 'This work is waiting on $who.';
  }

  @override
  String get waitingQuestion =>
      'The agent is waiting for an answer. Mark your choice; you can add a note if you like.';

  @override
  String get waitingWork =>
      'This work is waiting on you. What is expected is written in the notes below; tell the agent once it is done.';

  @override
  String get detailMultiHint => 'You can pick more than one.';

  @override
  String get detailNoteLabel => 'Note (optional)';

  @override
  String get detailNoteHint => 'Write here if none of the options fit';

  @override
  String get detailAnswered => 'Answered';

  @override
  String get detailSendAnswer => 'Send answer';

  @override
  String get detailReportedShort => 'Told';

  @override
  String get detailDidIt => 'Done';

  @override
  String get secEmptyTitle => 'No security records';

  @override
  String get secEmptySubtitle =>
      'The agent writes scans, measures and findings here (contract §12).';

  @override
  String secOpenCount(int count) {
    return '$count open records';
  }

  @override
  String get planEmptyTitle => 'The task tree is empty';

  @override
  String get planEmptySubtitle =>
      'When the agent writes a multi-step plan, its steps appear here (contract §14).';

  @override
  String get planFilterAll => 'All';

  @override
  String get planFilterEmptyTitle => 'No plans in this state';

  @override
  String get planFilterEmptySubtitle => 'Clear the filter to see all of them.';

  @override
  String get planStatusOpen => 'Open';

  @override
  String get planStatusCompleted => 'Completed';

  @override
  String get planStatusCancelled => 'Cancelled';

  @override
  String get planDerived => 'derived';

  @override
  String planProgress(int done, int total) {
    return '$done/$total steps';
  }

  @override
  String get linkOutsideHub =>
      'This link points outside the hub; the app only opens hub documents.';

  @override
  String get secFilterEmptyTitle => 'No records of this kind';

  @override
  String get secFilterEmptySubtitle => 'Clear the filter to see everything.';

  @override
  String get secFilterAll => 'All';

  @override
  String get secOpenBadge => 'open';

  @override
  String get secKindHole => 'Hole';

  @override
  String get kindTask => 'Task';

  @override
  String get kindComment => 'Comment';

  @override
  String get kindFix => 'Fix';

  @override
  String get kindDiscussion => 'Discussion';

  @override
  String get selTitle => 'Record from selection';

  @override
  String get selMark => 'Mark';

  @override
  String get selNote => 'Note';

  @override
  String get selNoteHelp =>
      'Leave it empty and it stays a mark or note — it does not enter the work queue';

  @override
  String get selHintFix => 'What is wrong, and what should it say?';

  @override
  String get selHintDiscussion =>
      'What is the problem, what do you want to discuss?';

  @override
  String get selHintComment => 'What should be kept as a note?';

  @override
  String get selHintTask => 'What should be done?';

  @override
  String get selPriority => 'Priority';

  @override
  String get selAddAsMark => 'Add as a mark';

  @override
  String selCreateKind(String kind) {
    return 'Create $kind';
  }

  @override
  String get selQueuedRecord => 'No connection — the record is queued.';

  @override
  String get selQueuedNote => 'No connection — the note is queued.';

  @override
  String selUnexpected(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get noteBoxTitle => 'Add a note';

  @override
  String get noteBoxHint => 'A note to yourself — the agent gets no work';

  @override
  String get noteBoxCancel => 'Cancel';

  @override
  String get noteBoxAdd => 'Add';

  @override
  String get annDeleteNote => 'Delete note';

  @override
  String get annDeleteMark => 'Delete mark';

  @override
  String get annNoteDeleted => 'Note deleted.';

  @override
  String get annMarkDeleted => 'Mark deleted.';

  @override
  String get annAlreadyHandled =>
      'The agent has picked this up; the mark stays in the hub.';

  @override
  String get selMarkYellow => 'Yellow';

  @override
  String get selMarkRed => 'Red';

  @override
  String get selMarkGreen => 'Green';

  @override
  String get selMarkBlue => 'Blue';

  @override
  String get pendingTitle => 'Pending';

  @override
  String get pendingRefresh => 'Refresh';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get sortWaitingFirst => 'Waiting first';

  @override
  String get sortByDate => 'By date';

  @override
  String get sortByPriority => 'By priority';

  @override
  String get sortAscending => 'ascending';

  @override
  String get sortDescending => 'descending';

  @override
  String get detailDoneNoteLabel => 'Anything to add? (optional)';

  @override
  String get detailDoneNoteHint =>
      'How you did it, something that came up, anything the agent should know';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterPriority => 'Priority';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterNone => '(no options)';

  @override
  String get queuedDraftsTitle => 'Queued drafts';

  @override
  String get queuedDraftEdit => 'Edit';

  @override
  String get queuedDraftDelete => 'Delete';

  @override
  String get queuedDraftDeleteConfirm =>
      'Delete this draft? It has not been sent; deleting it writes nothing anywhere.';

  @override
  String get queuedDraftDeleted => 'Draft deleted';

  @override
  String get queuedDraftSaved =>
      'Draft updated; it will be sent in this form once a connection returns';

  @override
  String get queuedDraftEditTitle => 'Edit draft';

  @override
  String get queuedTasksTapHint => 'Tap to view, edit or delete';
}
