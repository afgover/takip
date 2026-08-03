import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/utils.dart';
import '../../hub/all_tasks.dart';
import '../../hub/annotations.dart';
import '../../hub/models/task.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../../hub/task_repo.dart';

/// Seçilen metinden oluşturulabilecek kayıt türleri (sözleşme 1.5).
///
/// Hepsi aynı şeye dönüşür — `tasks/inbox/`'a bir görev — ama `category`
/// alanı ne olduğunu söyler. Agent bunu okuyup nasıl ele alacağını bilir:
/// `duzeltme` belgeyi düzeltmeyi, `tartisma` cevap vermeyi gerektirir.
enum RecordKind {
  gorev('Görev', 'gorev', Icons.add_task, TaskMark.highlight),
  yorum('Yorum', 'yorum', Icons.chat_bubble_outline, TaskMark.highlight),
  duzeltme('Düzeltme', 'duzeltme', Icons.edit_outlined, TaskMark.underline),
  tartisma('Tartışma', 'tartisma', Icons.forum_outlined, TaskMark.highlight);

  const RecordKind(this.label, this.category, this.icon, this.defaultMark);

  final String label;
  final String category;
  final IconData icon;

  /// Düzeltme kırmızı altı çizili başlar — "burası yanlış" demenin görsel
  /// karşılığı; diğerleri sarı işaret.
  final TaskMark defaultMark;
}

/// Seçilen metinden kayıt oluşturma sayfası.
class SelectionRecordSheet extends ConsumerStatefulWidget {
  const SelectionRecordSheet({
    super.key,
    required this.quote,
    required this.sourcePath,
  });

  /// Kullanıcının seçtiği metin — kaydın `quote` alanı.
  final String quote;

  /// Metnin okunduğu belgenin hub içindeki yolu — kaydın `source` alanı.
  final String sourcePath;

  static const noteFieldKey = Key('selection-note-field');
  static const submitKey = Key('selection-submit');
  static Key kindKey(RecordKind kind) => Key('selection-kind-${kind.name}');
  static Key markKey(TaskMark mark) => Key('selection-mark-${mark.name}');

  @override
  ConsumerState<SelectionRecordSheet> createState() =>
      _SelectionRecordSheetState();
}

class _SelectionRecordSheetState extends ConsumerState<SelectionRecordSheet> {
  final _noteCtrl = TextEditingController();
  RecordKind _kind = RecordKind.gorev;
  late TaskMark _mark = _kind.defaultMark;
  String _priority = 'normal';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    // Sayfayı önce kapat: kayıt yolu ortak (`createSelectionRecord`) ve
    // sonucu snackbar'la bildiriyor; sayfa açık kalsaydı bildirim onun
    // altında kalırdı.
    final navigator = Navigator.of(context);
    final quote = widget.quote;
    final sourcePath = widget.sourcePath;
    final kind = _kind;
    final note = _noteCtrl.text;
    final priority = _priority;
    final mark = _mark;
    navigator.pop();

    await createSelectionRecord(
      ref: ref,
      context: navigator.context,
      quote: quote,
      sourcePath: sourcePath,
      kind: kind.category,
      mark: mark,
      note: note,
      priority: priority,
      successLabel: kind.label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seçimden kayıt', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 3),
                ),
              ),
              child: Text(
                widget.quote,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final kind in RecordKind.values)
                  ChoiceChip(
                    key: SelectionRecordSheet.kindKey(kind),
                    avatar: Icon(kind.icon, size: 16),
                    label: Text(kind.label),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() {
                      _kind = kind;
                      _mark = kind.defaultMark;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('İşaret', style: theme.textTheme.labelLarge),
                const SizedBox(width: 12),
                for (final mark in TaskMark.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: SelectionRecordSheet.markKey(mark),
                      label: Text(mark == TaskMark.highlight ? 'Sarı' : 'Kırmızı'),
                      selected: _mark == mark,
                      onSelected: (_) => setState(() => _mark = mark),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: SelectionRecordSheet.noteFieldKey,
              controller: _noteCtrl,
              enabled: !_busy,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                hintText: switch (_kind) {
                  RecordKind.duzeltme => 'Nesi yanlış, ne olmalı?',
                  RecordKind.tartisma => 'Sorun ne, neyi tartışmak istiyorsun?',
                  RecordKind.yorum => 'Not olarak ne kalsın?',
                  RecordKind.gorev => 'Ne yapılsın?',
                },
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Öncelik', style: theme.textTheme.labelLarge),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    isDense: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      for (final p in ['low', 'normal', 'high', 'urgent'])
                        DropdownMenuItem(value: p, child: Text(p)),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _priority = v ?? 'normal'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: SelectionRecordSheet.submitKey,
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_kind.icon),
                label: Text('${_kind.label} oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçimden kayıt üretip hub'a gönderir; sonucu kullanıcıya bildirir.
///
/// Hem hızlı işaretleme (menüden tek dokunuş) hem de ayrıntılı sayfa bunu
/// kullanır — yazma yolu tek olsun diye. Ağ yoksa kayıt kuyruğa alınır
/// (B-032), yani seçim hiçbir durumda kaybolmaz.
Future<void> createSelectionRecord({
  required WidgetRef ref,
  required BuildContext context,
  required String quote,
  required String sourcePath,
  required String kind,
  required TaskMark mark,
  String note = '',
  String priority = 'normal',
  String? successLabel,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final draft = TaskDraft.fromSelection(
    quote: collapseWhitespace(quote),
    sourcePath: sourcePath,
    kind: kind,
    mark: mark,
    note: note,
    priority: priority,
  );

  // Alıntı tek yerde normalleştiriliyor: hızlı işaretleme ile sayfadan
  // oluşturma aynı metni yazsın diye.
  final normalized = collapseWhitespace(quote);

  String message;
  var created = false;
  try {
    await ref.read(taskRepoProvider).send(draft);
    created = true;
    message = '${successLabel ?? 'Kayıt'} eklendi.';
  } on HubNetworkError {
    await ref.read(outboxProvider.notifier).add(draft);
    // Kuyruğa girse de işaret hemen görünmeli: kayıt kaybolmadı.
    created = true;
    message = 'Ağ yok — ${(successLabel ?? 'kayıt').toLowerCase()} kuyruğa alındı.';
  } on HubError catch (e) {
    message = e.message;
  } catch (e) {
    message = 'Beklenmeyen hata: $e';
  }

  if (created) {
    ref.read(freshAnnotationsProvider.notifier).add(
          sourcePath,
          Annotation(
            quote: normalized,
            mark: mark,
            title: normalized,
            category: kind,
            path: '',
          ),
        );
  }

  ref.invalidate(allPendingTasksProvider);
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// Seçilen metinden kayıt oluşturma sayfasını açar.
Future<void> openSelectionRecord(
  BuildContext context, {
  required String quote,
  required String sourcePath,
}) {
  final trimmed = collapseWhitespace(quote);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SelectionRecordSheet(
      quote: trimmed,
      sourcePath: sourcePath,
    ),
  );
}

/// Seçime hızlıca yorum yazma kutusu.
///
/// Tam sayfadan (tür, işaret, öncelik) daha hafif: okurken bir not düşmek
/// isteyen kullanıcıyı beş alanla karşılamamak için ayrı tutuldu. Kayıt yine
/// aynı yoldan gider — `yorum` kategorisi, sarı işaret.
Future<void> openCommentBox(
  BuildContext context, {
  required String quote,
  required String sourcePath,
}) {
  final controller = TextEditingController();
  final normalized = collapseWhitespace(quote);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Yorum ekle'),
      content: Consumer(
        builder: (context, ref, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                normalized,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: commentFieldKey,
              controller: controller,
              autofocus: true,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Not olarak ne kalsın?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Vazgeç'),
        ),
        Consumer(
          builder: (context, ref, _) => FilledButton(
            key: commentSubmitKey,
            onPressed: () {
              final note = controller.text;
              final navigator = Navigator.of(dialogContext);
              navigator.pop();
              createSelectionRecord(
                ref: ref,
                context: navigator.context,
                quote: normalized,
                sourcePath: sourcePath,
                kind: RecordKind.yorum.category,
                mark: TaskMark.highlight,
                note: note,
                successLabel: RecordKind.yorum.label,
              );
            },
            child: const Text('Ekle'),
          ),
        ),
      ],
    ),
  );
}

const commentFieldKey = Key('selection-comment-field');
const commentSubmitKey = Key('selection-comment-submit');
