import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../hub/all_tasks.dart';
import '../../hub/hub_config.dart';
import '../../hub/hub_language.dart';
import '../../hub/hub_watcher.dart';
import '../../hub/models/task.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/models/task_event.dart';
import '../../hub/outbox.dart';
import '../../hub/task_repo.dart';
import '../../l10n/app_localizations.dart';

/// Yorum ve atama (sözleşme 1.37). İkisi de inbox'a **olay dosyası** yazar;
/// app hedef görevin dosyasına dokunmaz (R-001). İşlenmemiş olaylar burada
/// hedefin üstüne bindirilir, yani ajan çalışmasa da herkes görür.

/// Olayı görevin **kendi** reposuna gönderir; ağ yoksa kuyruğa alır.
/// Gönderildiyse true, kuyruğa alındıysa false. Diğer hatalar çağırana gider.
Future<bool> sendEvent(WidgetRef ref, TaskSummary summary, TaskDraft base) async {
  final slug = summary.repoSlug;
  final draft = slug == null ? base : base.forRepo(slug);
  try {
    await ref.read(taskRepoForSlugProvider(slug)).send(draft);
    unawaited(ref.read(hubWatcherProvider.notifier).checkAfterWrite());
    return true;
  } on HubNetworkError {
    await ref.read(outboxProvider.notifier).add(draft);
    return false;
  }
}

/// Kuyrukta bekleyen, bu görevi hedefleyen olay taslakları.
List<TaskEvent> _queuedEvents(WidgetRef ref, TaskSummary summary) {
  final drafts = ref.watch(outboxProvider).valueOrNull ?? const <TaskDraft>[];
  return [
    for (final d in drafts)
      if (d.repoSlug == summary.repoSlug)
        if (TaskEvent.parse(d.fileName, d.content) case final e?
            when e.target == summary.fileName)
          e,
  ];
}

/// GitHub kullanıcı adı kuralı: harf, rakam, tek tire; en çok 39.
final _login = RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$');

/// "Sorumlu: @ad" ve Üstlen / Ata eylemleri.
class TaskOwnerRow extends ConsumerStatefulWidget {
  const TaskOwnerRow({super.key, required this.task, required this.summary});

  final HubTask task;
  final TaskSummary summary;

  static const takeOverKey = Key('task-take-over');
  static const assignKey = Key('task-assign');

  @override
  ConsumerState<TaskOwnerRow> createState() => _TaskOwnerRowState();
}

class _TaskOwnerRowState extends ConsumerState<TaskOwnerRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final me = ref.watch(loginForRepoProvider(widget.summary.repoSlug));
    final events = [
      ...ref.watch(taskEventsProvider(widget.summary)).valueOrNull ?? const [],
      ..._queuedEvents(ref, widget.summary),
    ].where((e) => e.kind == TaskEventKind.assign && (e.assignee ?? '').isNotEmpty)
        .toList()
      ..sort((a, b) => a.created.compareTo(b.created));

    final pending = events.isEmpty ? null : events.last.assignee;
    final owner = pending ??
        (widget.task.status == TaskStatus.active ? widget.task.assignee : null);
    final done = widget.task.status == TaskStatus.done;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.assignment_ind_outlined,
            size: 18, color: Theme.of(context).colorScheme.outline),
        Text(owner == null ? l.detailNoOwner : l.detailOwner(owner)),
        if (pending != null)
          Text('· ${l.detailOwnerPending}',
              style: Theme.of(context).textTheme.labelSmall),
        if (!done && me != null && owner != me)
          TextButton(
            key: TaskOwnerRow.takeOverKey,
            onPressed: _busy ? null : () => _assign(me),
            child: Text(l.detailTakeOver),
          ),
        if (!done)
          TextButton(
            key: TaskOwnerRow.assignKey,
            onPressed: _busy ? null : _pickAndAssign,
            child: Text(l.detailAssign),
          ),
      ],
    );
  }

  /// Hubda geçen kişiler: öneri olarak sunulur, serbest yazım da serbest.
  Set<String> _knownPeople(String? me) {
    final tasks =
        ref.read(activeRepoPendingTasksProvider).valueOrNull ?? const [];
    return {
      if (me != null) me,
      for (final t in tasks) ...[
        if (t.author != null) t.author!,
        if (t.assignee != null) t.assignee!,
        if (t.waitingFor != null) t.waitingFor!,
      ],
    };
  }

  Future<void> _pickAndAssign() async {
    final me = ref.read(loginForRepoProvider(widget.summary.repoSlug));
    final people = _knownPeople(me).toList()..sort();
    final who = await showDialog<String>(
      context: context,
      builder: (_) => _AssignDialog(people: people),
    );
    if (who != null) await _assign(who);
  }

  Future<void> _assign(String who) async {
    final l = L.of(context);
    setState(() => _busy = true);
    try {
      final lang = ref
              .read(languageForRepoProvider(widget.summary.repoSlug))
              .valueOrNull ??
          HubLanguage.tr;
      final me = ref.read(loginForRepoProvider(widget.summary.repoSlug));
      final sent = await sendEvent(
        ref,
        widget.summary,
        TaskDraft.assign(widget.task, assignee: who, lang: lang, author: me),
      );
      _snack(sent ? l.detailAssignSent(who) : l.detailQueued);
    } on HubError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// "Kime verilsin?" penceresi. Metin denetleyicisi pencerenin kendi ömrüne
/// bağlı: pencere kapanma animasyonu boyunca da çiziliyor, denetleyiciyi
/// çağıran silerse kapanırken "disposed" hatası verir.
class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.people});

  final List<String> people;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim().replaceFirst(RegExp('^@'), '');
    if (!_login.hasMatch(v)) {
      setState(() => _error = L.of(context).detailAssignInvalid);
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AlertDialog(
      title: Text(l.detailAssignTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: l.detailAssignHint,
                prefixText: '@',
                errorText: _error,
              ),
            ),
            if (widget.people.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final p in widget.people)
                    ActionChip(
                      label: Text('@$p'),
                      onPressed: () => Navigator.of(context).pop(p),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l.detailAssign.replaceAll('…', '')),
        ),
      ],
    );
  }
}

/// Yorum akışı: işlenmiş (`## Yorumlar`), işlenmeyi bekleyen (inbox'taki
/// olay) ve gönderilmeyi bekleyen (kuyruk) yorumlar, zaman sırasıyla; altta
/// yazma kutusu.
class TaskThread extends ConsumerStatefulWidget {
  const TaskThread({super.key, required this.task, required this.summary});

  final HubTask task;
  final TaskSummary summary;

  static const inputKey = Key('task-comment-input');
  static const sendKey = Key('task-comment-send');

  @override
  ConsumerState<TaskThread> createState() => _TaskThreadState();
}

class _TaskThreadState extends ConsumerState<TaskThread> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final events =
        ref.watch(taskEventsProvider(widget.summary)).valueOrNull ?? const [];
    final queued = _queuedEvents(ref, widget.summary);
    final comments = <(TaskComment, String?)>[
      for (final c in parseComments(widget.task.body)) (c, null),
      for (final e in events.where((e) => e.kind == TaskEventKind.comment))
        (TaskComment.fromEvent(e), l.detailCommentPending),
      for (final e in queued.where((e) => e.kind == TaskEventKind.comment))
        (TaskComment.fromEvent(e), l.detailCommentQueued),
    ]..sort((a, b) {
        final x = a.$1.at, y = b.$1.at;
        if (x == null || y == null) return 0;
        return x.compareTo(y);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Text(l.detailCommentsTitle(comments.length),
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (comments.isEmpty)
          Text(l.detailNoComments,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        for (final (c, note) in comments)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (c.author != null) '@${c.author}',
                    if (c.at != null) _when(context, c.at!),
                    if (note != null) note,
                  ].join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: note == null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(c.text),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: TaskThread.inputKey,
                controller: _ctrl,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l.detailCommentHint),
                onChanged: (_) => setState(() {}),
              ),
            ),
            IconButton(
              key: TaskThread.sendKey,
              tooltip: l.detailCommentSend,
              onPressed:
                  _busy || _ctrl.text.trim().isEmpty ? null : _send,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }

  String _when(BuildContext context, DateTime utc) {
    final local = utc.toLocal();
    final m = MaterialLocalizations.of(context);
    return '${m.formatShortMonthDay(local)} '
        '${m.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
  }

  Future<void> _send() async {
    final l = L.of(context);
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      final lang = ref
              .read(languageForRepoProvider(widget.summary.repoSlug))
              .valueOrNull ??
          HubLanguage.tr;
      final me = ref.read(loginForRepoProvider(widget.summary.repoSlug));
      final sent = await sendEvent(
        ref,
        widget.summary,
        TaskDraft.comment(widget.task, text: text, lang: lang, author: me),
      );
      _ctrl.clear();
      _snack(sent ? l.detailCommentSent : l.detailQueued);
    } on HubError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
