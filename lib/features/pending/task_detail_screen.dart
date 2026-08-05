import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../hub/hub_config.dart';
import '../../hub/models/task.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../../hub/task_repo.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';
import 'pending_screen.dart' show TaskStatusChip;

/// Görev detayı — dosya ancak bu ekran açılınca indirilir (B-031).
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskDetailProvider(summary));

    return Scaffold(
      appBar: AppBar(
        title: Text(task.valueOrNull?.title.isNotEmpty == true
            ? task.valueOrNull!.title
            : summary.title),
      ),
      body: switch (task) {
        AsyncData(:final value) => _TaskBody(task: value, summary: summary),
        AsyncError(:final error) => HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(taskDetailProvider(summary)),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TaskBody extends StatelessWidget {
  const _TaskBody({required this.task, required this.summary});

  final HubTask task;
  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (task.status.needsUser) ...[
          _WaitingBanner(task: task, summary: summary),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TaskStatusChip(status: task.status),
            _MetaChip(icon: Icons.label_outline, text: task.category),
            _MetaChip(icon: Icons.flag_outlined, text: task.priority),
            // Agent henüz ID atamadıysa görev hub'a yeni düşmüş demektir.
            if (!task.isPending)
              _MetaChip(icon: Icons.tag, text: task.id)
            else
              const _MetaChip(
                icon: Icons.schedule,
                text: 'agent henüz ele almadı',
              ),
            for (final tag in task.tags)
              _MetaChip(icon: Icons.sell_outlined, text: tag),
          ],
        ),
        if (task.hasResult) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 20, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.result,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
        AnnotatedDocument(
          data: task.body,
          sourcePath: task.path,
          padding: const EdgeInsets.only(top: 8),
        ),
      ],
    );
  }
}

/// `waiting/`teki görevin üstündeki şerit: ne beklendiğini söyler ve
/// "Yaptım" düğmesini taşır (sözleşme 1.4).
class _WaitingBanner extends ConsumerStatefulWidget {
  const _WaitingBanner({required this.task, required this.summary});

  final HubTask task;
  final TaskSummary summary;

  @override
  ConsumerState<_WaitingBanner> createState() => _WaitingBannerState();
}

class _WaitingBannerState extends ConsumerState<_WaitingBanner> {
  static const doneButtonKey = Key('waiting-done-button');
  static const answerButtonKey = Key('waiting-answer-button');
  static const answerNoteKey = Key('waiting-answer-note');
  static Key optionKey(int index) => Key('waiting-option-$index');

  bool _busy = false;
  String? _error;
  bool _reported = false;

  /// Seçenekli soruda işaretlenenler (sözleşme 1.12). `multi: false` ise
  /// içinde en fazla bir öğe bulunur.
  final _selected = <String>{};
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _toggle(String option) {
    setState(() {
      if (widget.task.multi) {
        _selected.contains(option)
            ? _selected.remove(option)
            : _selected.add(option);
      } else {
        // Tek seçimde ikinci dokunuş seçimi kaldırır: yanlış işaretlemeyi geri
        // almanın başka yolu yok, cevap da gönderilmemiş durumda.
        final wasSelected = _selected.contains(option);
        _selected
          ..clear()
          ..addAll(wasSelected ? const <String>[] : [option]);
      }
    });
  }

  /// Seçenekli soruya cevap (sözleşme 1.12).
  Future<void> _answer() async {
    if (_busy || _selected.isEmpty) return;
    // Seçim sırası listedeki sırayı izlesin; küme sırası dokunma sırasıdır ve
    // agent'ın okuduğu kayıtta rastgele görünürdü.
    final ordered =
        widget.task.options.where(_selected.contains).toList(growable: false);
    await _send(
      TaskDraft.waitingAnswer(
        widget.task,
        selected: ordered,
        note: _noteCtrl.text,
        author: ref.read(loginForRepoProvider(widget.summary.repoSlug)),
      ),
      'Cevap gönderildi.',
    );
  }

  Future<void> _report() async {
    if (_busy) return;
    await _send(
      TaskDraft.waitingDone(
        widget.task,
        author: ref.read(loginForRepoProvider(widget.summary.repoSlug)),
      ),
      'Agent\'a bildirildi.',
    );
  }

  Future<void> _send(TaskDraft base, String successMessage) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    // Bildirim, görevin **kendi** reposuna gider; aktif repo başkası olabilir
    // çünkü bekleyenler listesi çoklu repo (L-031).
    final slug = widget.summary.repoSlug;
    final draft = slug == null ? base : base.forRepo(slug);
    try {
      await ref.read(taskRepoForSlugProvider(slug)).send(draft);
      _finish(successMessage);
    } on HubNetworkError {
      // Ağ yokken bildirim kaybolmasın: normal görevlerle aynı kuyruk (B-032).
      await ref.read(outboxProvider.notifier).add(draft);
      _finish('Ağ yok — kuyruğa alındı.');
    } on HubError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish(String message) {
    ref.invalidate(pendingTasksProvider);
    if (!mounted) return;
    setState(() => _reported = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Şeridin metni. Sözleşme 1.15'te `for` alanı geldi: iş belirli bir kişiyi
  /// bekliyorsa bunu **söylemek** gerekiyor, yoksa herkes "herhalde diğeri
  /// bakar" diye geçer — ya da tersi, kimseyi beklemeyen bir işi herkes
  /// üstlenir. Düğmeler yine de kapatılmıyor: başkası adına cevaplamak meşru
  /// bir takım hareketi ve engellemek, bilgiyi elinde tutan kişiyi durdururdu.
  String _bannerText() {
    final mine = widget.task.waitsFor(
      ref.read(loginForRepoProvider(widget.summary.repoSlug)),
    );
    final who = widget.task.waitingFor;

    if (!mine && who != null) {
      return widget.task.isQuestion
          ? 'Bu soru $who kullanıcısını bekliyor. Cevabı sen de gönderebilirsin.'
          : 'Bu iş $who kullanıcısını bekliyor.';
    }
    return widget.task.isQuestion
        ? 'Agent bir cevap bekliyor. Seçimini işaretle; istersen açıklama da '
            'yazabilirsin.'
        : 'Bu iş seni bekliyor. Ne beklendiği aşağıdaki notlarda yazılı; '
            'yaptıktan sonra agent\'a haber ver.';
  }

  /// Seçenek listesi + isteğe bağlı açıklama + gönder (sözleşme 1.12).
  ///
  /// Cevaplandıktan sonra tümü kapanır: bir görev = bir soru. Konuşmanın
  /// devamı gerekiyorsa agent yeni bir `waiting/` görevi açar — aynı dosyaya
  /// ikinci cevap göndermek, agent'ın kuyruğunda hangisinin geçerli olduğu
  /// belirsiz iki kayıt bırakırdı.
  List<Widget> _answerSection(ThemeData theme, ColorScheme colors) {
    final options = widget.task.options;
    final locked = _busy || _reported;

    return [
      for (var i = 0; i < options.length; i++)
        _OptionTile(
          key: optionKey(i),
          label: options[i],
          selected: _selected.contains(options[i]),
          multi: widget.task.multi,
          enabled: !locked,
          onTap: () => _toggle(options[i]),
          colors: colors,
        ),
      if (widget.task.multi)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Birden çok seçebilirsin.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.onTertiaryContainer),
          ),
        ),
      const SizedBox(height: 12),
      TextField(
        key: answerNoteKey,
        controller: _noteCtrl,
        enabled: !locked,
        maxLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Açıklama (isteğe bağlı)',
          hintText: 'Listede olmayan bir durum varsa buraya yaz',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          key: answerButtonKey,
          onPressed: (locked || _selected.isEmpty) ? null : _answer,
          icon: Icon(_reported ? Icons.check : Icons.send),
          label: Text(_reported ? 'Cevaplandı' : 'Cevabı gönder'),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.task.isQuestion
                    ? Icons.help_outline
                    : Icons.pan_tool_outlined,
                size: 20,
                color: colors.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _bannerText(),
                  style: TextStyle(color: colors.onTertiaryContainer),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 12),
          // Sözleşme 1.12: seçenek varsa "Yaptım" **gösterilmez** — agent bir
          // soru sormuştur, cevabı "yaptım" değil seçimdir. Seçenek yoksa
          // davranış 1.11'deki gibi kalır (geriye uyumlu).
          if (widget.task.isQuestion)
            ..._answerSection(theme, colors)
          else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: doneButtonKey,
                // Bir kez bildirildikten sonra düğme kapanır: aynı iş için
                // ikinci bildirim, agent'ın kuyruğunda kopya demek olurdu.
                onPressed: (_busy || _reported) ? null : _report,
                icon: Icon(_reported ? Icons.check : Icons.done),
                label: Text(_reported ? 'Bildirildi' : 'Yaptım'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tek cevap seçeneği. Çoklu seçimde kutu, tekli seçimde daire — kullanıcı
/// dokunmadan önce kaç tane seçebileceğini görsün.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.multi,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final bool multi;
  final bool enabled;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final foreground = colors.onTertiaryContainer
        .withValues(alpha: enabled ? 1 : 0.5);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              switch ((multi, selected)) {
                (true, true) => Icons.check_box,
                (true, false) => Icons.check_box_outline_blank,
                (false, true) => Icons.radio_button_checked,
                (false, false) => Icons.radio_button_unchecked,
              },
              size: 20,
              color: foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
