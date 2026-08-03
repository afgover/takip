import 'dart:async';

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

/// Kullanıcının seçimden ne üretmek istediği. Sayfa/kutu bunu döndürür;
/// kaydı çağıran ekran oluşturur.
class SelectionRequest {
  const SelectionRequest({
    required this.kind,
    required this.mark,
    this.note = '',
    this.priority = 'normal',
  });

  final RecordKind kind;
  final TaskMark mark;
  final String note;
  final String priority;
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

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  /// Sayfa kaydı **kendisi oluşturmuyor**, kullanıcının seçimini geri
  /// döndürüyor.
  ///
  /// Kayıt oluşturmak sayfanın `ref`'iyle yapılırsa, sayfa kapandığı anda o
  /// `ref` ölüyor ve işaret hiç eklenmiyordu — "yorum eklendi" deyip ekranda
  /// hiçbir şey görünmemesinin sebebi buydu (L-025). Kaydı, sayfayı açan ve
  /// ondan uzun yaşayan ekran oluşturur.
  void _submit() {
    Navigator.of(context).pop(
      SelectionRequest(
        kind: _kind,
        mark: _mark,
        note: _noteCtrl.text,
        priority: _priority,
      ),
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
                    onChanged: (v) => setState(() => _priority = v ?? 'normal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: SelectionRecordSheet.submitKey,
                onPressed: _submit,
                icon: Icon(_kind.icon),
                label: Text('${_kind.label} oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçimden kayıt üretir: **işaret hemen görünür**, gönderim arka planda.
///
/// Beklemeli yapılırsa (gönder → sonra çiz) kullanıcı sarıya bastıktan sonra
/// ağ turu kadar boş ekrana bakıyor; bu, okurken not almanın akışını bozuyor
/// (L-026). İşaret önce yerel katmana yazılıyor, gönderim arkada sürüyor.
/// Kalıcı bir hata olursa işaret geri alınıyor — yalancı bir iz bırakmaktansa
/// kaybolması dürüst.
void createSelectionRecord({
  required WidgetRef ref,
  required BuildContext context,
  required String quote,
  required String sourcePath,
  required RecordKind kind,
  required TaskMark mark,
  String note = '',
  String priority = 'normal',
  String? section,
  String? repoSlug,
}) {
  final normalized = collapseWhitespace(quote);
  final messenger = ScaffoldMessenger.of(context);

  final annotation = Annotation(
    quote: normalized,
    mark: mark,
    title: normalized,
    category: kind.category,
    path: '',
  );
  ref.read(freshAnnotationsProvider.notifier).add(sourcePath, annotation);

  final draft = TaskDraft.fromSelection(
    quote: normalized,
    sourcePath: sourcePath,
    kind: kind.category,
    mark: mark,
    note: note,
    priority: priority,
    section: section,
    repoSlug: repoSlug,
  );

  unawaited(() async {
    try {
      await ref.read(taskRepoProvider).send(draft);
    } on HubNetworkError {
      // Ağ yok: kuyruğa alınır, işaret kalır — kayıt kaybolmadı (B-032).
      await ref.read(outboxProvider.notifier).add(draft);
      messenger.showSnackBar(
        const SnackBar(content: Text('Ağ yok — kayıt kuyruğa alındı.')),
      );
    } on HubError catch (e) {
      ref.read(freshAnnotationsProvider.notifier).remove(sourcePath, annotation);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ref.read(freshAnnotationsProvider.notifier).remove(sourcePath, annotation);
      messenger.showSnackBar(
        SnackBar(content: Text('Beklenmeyen hata: $e')),
      );
    }
    ref.invalidate(allPendingTasksProvider);
  }());
}

/// Seçilen metinden kayıt oluşturma sayfasını açar; kullanıcının seçimini
/// döndürür (vazgeçilirse null). Kaydı çağıran ekran oluşturur.
Future<SelectionRequest?> openSelectionRecord(
  BuildContext context, {
  required String quote,
  required String sourcePath,
}) {
  return showModalBottomSheet<SelectionRequest>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SelectionRecordSheet(
      quote: collapseWhitespace(quote),
      sourcePath: sourcePath,
    ),
  );
}

/// Seçime hızlıca yorum yazma kutusu; yazılan notu döndürür.
///
/// Tam sayfadan (tür, işaret, öncelik) daha hafif: okurken bir not düşmek
/// isteyen kullanıcıyı beş alanla karşılamamak için ayrı tutuldu.
Future<SelectionRequest?> openCommentBox(
  BuildContext context, {
  required String quote,
}) {
  final controller = TextEditingController();
  final normalized = collapseWhitespace(quote);

  return showDialog<SelectionRequest>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Yorum ekle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              normalized,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(dialogContext).textTheme.bodySmall,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: commentSubmitKey,
          onPressed: () => Navigator.of(dialogContext).pop(
            SelectionRequest(
              kind: RecordKind.yorum,
              mark: TaskMark.highlight,
              note: controller.text,
            ),
          ),
          child: const Text('Ekle'),
        ),
      ],
    ),
  );
}

const commentFieldKey = Key('selection-comment-field');
const commentSubmitKey = Key('selection-comment-submit');
