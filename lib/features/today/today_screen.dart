import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../merkez/merkez_api.dart';
import '../../merkez/merkez_providers.dart';

String _errorText(L l, Object error) {
  if (error is! MerkezError) return l.todayErrorServer;
  final message = error.serverMessage;
  return switch (error.kind) {
    MerkezErrorKind.unauthorized => l.todayErrorPassword,
    MerkezErrorKind.rateLimited => l.todayErrorRateLimit,
    MerkezErrorKind.network => l.todayErrorNetwork,
    MerkezErrorKind.server => l.todayErrorServer,
    MerkezErrorKind.conflict ||
    MerkezErrorKind.rejected =>
      message ?? l.todayErrorServer,
  };
}

/// Tüm hub'ların bekleyen kararları tek listede (Merkez `/today`).
///
/// Hub'lara yine yalnız sunucu yazar: uygulama cevabı Merkez'e gönderir, Merkez
/// `tasks/inbox`'a dosya ekler. Bağlı değilken diğer sekmeler eskisi gibi çalışır.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(merkezTokenProvider);
    return token.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _LoginForm(),
      data: (value) => value == null ? const _LoginForm() : const _TodayList(),
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = L.of(context);
    if (_password.text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(merkezTokenProvider.notifier).login(_password.text);
      _password.clear();
    } catch (e) {
      if (mounted) setState(() => _error = _errorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l.todayLoginTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l.todayLoginHint),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: l.todayPassword,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l.todayLoginButton),
        ),
      ],
    );
  }
}

class _TodayList extends ConsumerWidget {
  const _TodayList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final today = ref.watch(merkezTodayProvider);
    // Yenilerken eski liste ekranda kalır: açık bir kartın altından kaymasın.
    final data = today.valueOrNull;
    if (data == null) {
      if (today.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorText(l, today.error!), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(merkezTodayProvider),
                  child: Text(l.todayRetry),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final active = data.hubs.where((h) => h.isActive && h.waiting.isNotEmpty);
    final parked =
        data.hubs.where((h) => h.status == 'beklemede' && h.waiting.isNotEmpty);

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(merkezCommandsProvider);
        return ref.refresh(merkezTodayProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Text(
            l.todaySummary(data.totals.pendingDecisions, data.totals.withOptions),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (data.totals.awaitingAgent > 0)
            Text(l.todayAwaitingCount(data.totals.awaitingAgent)),
          if (data.failedHubs.isNotEmpty)
            Text(
              l.todayStaleHubs(data.failedHubs.join(', ')),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const _CommandsSection(),
          if (active.isEmpty && parked.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(l.todayEmpty, textAlign: TextAlign.center),
            ),
          for (final hub in active) _HubSection(hub: hub),
          if (parked.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l.todayParked(data.totals.parked)),
              children: [for (final hub in parked) _HubSection(hub: hub)],
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(merkezTokenProvider.notifier).logout(),
            child: Text(l.todayLogout),
          ),
        ],
      ),
    );
  }
}

/// Mac mini'de iş başlatan kapalı katalog (ör. harcamaları çıkar).
///
/// Sonuç anlık gelmez: iş kuyruğa düşer, çalıştırıcı alınca başlar. Bu yüzden
/// başarı mesajı "başladı" değil "kuyruğa alındı" der.
class _CommandsSection extends ConsumerWidget {
  const _CommandsSection();

  String? _statusText(L l, String? status) => switch (status) {
        'queued' => l.todayCommandQueued,
        'running' => l.todayCommandRunning,
        'done' => l.todayCommandDone,
        'failed' => l.todayCommandFailed,
        _ => null,
      };

  Future<void> _run(BuildContext context, WidgetRef ref, MerkezCommand command,
      String title) async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(l.todayCommandConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.todayCommandCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.todayCommandRun),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = ref.read(merkezTokenProvider).valueOrNull;
    if (token == null) return;
    try {
      await ref.read(merkezApiProvider).runCommand(token, command.name);
      messenger.showSnackBar(SnackBar(content: Text(l.todayCommandQueuedNote)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_errorText(l, e))));
    }
    ref.invalidate(merkezCommandsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    final commands = ref.watch(merkezCommandsProvider).valueOrNull ?? const [];
    if (commands.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final command in commands)
            Builder(builder: (context) {
              final title = english ? command.titleEn : command.titleTr;
              final status = _statusText(l, command.lastStatus);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title),
                subtitle: status == null ? null : Text(status),
                trailing: FilledButton.tonal(
                  onPressed: command.isActive
                      ? null
                      : () => _run(context, ref, command, title),
                  child: Text(l.todayCommandRun),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _HubSection extends StatelessWidget {
  const _HubSection({required this.hub});

  final TodayHub hub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(
            '${hub.project} (${hub.waiting.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final task in hub.waiting) _TaskCard(hub: hub, task: task),
      ],
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.hub, required this.task});

  final TodayHub hub;
  final TodayTask task;

  Future<void> _answer(BuildContext context, String? option) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AnswerSheet(hub: hub, task: task, option: option),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(L.of(context).todayAnswerSent)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final colors = Theme.of(context).colorScheme;
    final canAnswer = task.taskId != null && !task.awaitingAgent;
    final high = task.priority == 'urgent' || task.priority == 'high';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${task.taskId == null ? '' : '${task.taskId} · '}${task.title}',
              style: high ? const TextStyle(fontWeight: FontWeight.w600) : null,
            ),
            if (task.due != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.overdue
                      ? l.todayOverdue(task.due!)
                      : l.todayDue(task.due!),
                  style: task.overdue ? TextStyle(color: colors.error) : null,
                ),
              ),
            if (task.awaitingAgent)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.todayAwaitingAgent,
                  style: TextStyle(color: colors.primary),
                ),
              ),
            if (canAnswer) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final option in task.options)
                    OutlinedButton(
                      onPressed: () => _answer(context, option),
                      child: Text(option),
                    ),
                  TextButton(
                    onPressed: () => _answer(context, null),
                    child: Text(l.todayWriteAnswer),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cevap geri alınamaz: gönderim tek dokunuşla değil, bu sayfadaki onayla olur.
class _AnswerSheet extends ConsumerStatefulWidget {
  const _AnswerSheet({required this.hub, required this.task, this.option});

  final TodayHub hub;
  final TodayTask task;
  final String? option;

  @override
  ConsumerState<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends ConsumerState<_AnswerSheet> {
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = L.of(context);
    final token = ref.read(merkezTokenProvider).valueOrNull;
    if (token == null || _busy) return;
    if (widget.option == null && _note.text.trim().isEmpty) {
      setState(() => _error = l.todayAnswerEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(merkezApiProvider).answer(
            token,
            hub: widget.hub.slug,
            taskId: widget.task.taskId!,
            option: widget.option,
            text: _note.text,
          );
      ref.invalidate(merkezTodayProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // Çift cevapta liste bayattır: kart "ajan bekleniyor"a dönsün.
      if (e is MerkezError && e.kind == MerkezErrorKind.conflict) {
        ref.invalidate(merkezTodayProvider);
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _errorText(l, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.task.title, style: Theme.of(context).textTheme.titleSmall),
          if (widget.option != null) ...[
            const SizedBox(height: 8),
            Text(l.todayChoice(widget.option!)),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: 2000,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: widget.option == null
                  ? l.todayAnswerText
                  : l.todayAnswerNote,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: colors.error)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: Text(l.todaySend),
          ),
        ],
      ),
    );
  }
}
