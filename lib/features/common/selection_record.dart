import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/utils.dart';
import '../../hub/all_tasks.dart';
import '../../hub/annotations.dart';
import '../../hub/hub_config.dart';
import '../../hub/hub_language.dart';
import '../../hub/models/task.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../../hub/task_repo.dart';
import '../../l10n/app_localizations.dart';

/// Seçilen metinden oluşturulabilecek kayıt türleri (sözleşme 1.5).
///
/// Hepsi aynı şeye dönüşür — `tasks/inbox/`'a bir görev — ama `category`
/// alanı ne olduğunu söyler. Agent bunu okuyup nasıl ele alacağını bilir:
/// `duzeltme` belgeyi düzeltmeyi, `tartisma` cevap vermeyi gerektirir.
enum RecordKind {
  gorev('gorev', Icons.add_task, TaskMark.highlight),
  yorum('yorum', Icons.chat_bubble_outline, TaskMark.comment),
  duzeltme('duzeltme', Icons.edit_outlined, TaskMark.underline),
  tartisma('tartisma', Icons.forum_outlined, TaskMark.highlight);

  const RecordKind(this.category, this.icon, this.defaultMark);

  /// Kayda **yazılan** değer (sözleşme §4 kategorileri) — çevrilmez, yoksa
  /// aynı hub'da iki dilde kategori birikirdi.
  final String category;
  final IconData icon;

  /// Ekranda görünen ad. Kategoriden ayrı: biri dosyada duruyor, diğeri
  /// okuyanın dilinde.
  String labelIn(L l) => switch (this) {
        gorev => l.kindTask,
        yorum => l.kindComment,
        duzeltme => l.kindFix,
        tartisma => l.kindDiscussion,
      };

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
    final l = L.of(context);
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
            Text(l.selTitle, style: theme.textTheme.titleMedium),
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
                    label: Text(kind.labelIn(l)),
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
                Text(l.selMark, style: theme.textTheme.labelLarge),
                const SizedBox(width: 12),
                for (final mark in TaskMark.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: SelectionRecordSheet.markKey(mark),
                      label: Text(switch (mark) {
                        TaskMark.highlight => l.selMarkYellow,
                        TaskMark.underline => l.selMarkRed,
                        TaskMark.comment => l.selMarkGreen,
                        TaskMark.bookmark => l.selMarkBlue,
                      }),
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
              // Boş/dolu geçişinde buton etiketi değişsin diye yeniden çiz.
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l.selNote,
                helperText: l.selNoteHelp,
                helperMaxLines: 2,
                hintText: switch (_kind) {
                  RecordKind.duzeltme => l.selHintFix,
                  RecordKind.tartisma => l.selHintDiscussion,
                  RecordKind.yorum => l.selHintComment,
                  RecordKind.gorev => l.selHintTask,
                },
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(l.selPriority, style: theme.textTheme.labelLarge),
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
              // Not boşsa görev değil işaret üretilir (notes/'a). Buton bunu
              // açıkça söylesin ki "Görev oluştur"a basıp not almak şaşırtmasın.
              child: FilledButton.icon(
                key: SelectionRecordSheet.submitKey,
                onPressed: _submit,
                icon: Icon(_noteCtrl.text.trim().isEmpty
                    ? Icons.brush_outlined
                    : _kind.icon),
                label: Text(_noteCtrl.text.trim().isEmpty
                    ? l.selAddAsMark
                    : l.selCreateKind(_kind.labelIn(l))),
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
/// `WidgetRef` değil `ProviderContainer` alıyor. Sebebi somut: kullanıcı yorum
/// kutusunda yazarken arkada bir yoklama belgeyi tazeliyor, ekran widget'ı
/// disposed oluyor ve onun `ref`'iyle yapılan iş sessizce düşüyordu — "yorum
/// eklendi" deyip hiçbir şey olmamasının sebebi buydu (L-029). Container ve
/// messenger widget yaşam döngüsüne bağlı değil.
///
/// Beklemeli yapılırsa (gönder → sonra çiz) kullanıcı sarıya bastıktan sonra
/// ağ turu kadar boş ekrana bakıyor; bu, okurken not almanın akışını bozuyor
/// (L-026). İşaret önce yerel katmana yazılıyor, gönderim arkada sürüyor.
/// Kalıcı bir hata olursa işaret geri alınıyor — yalancı bir iz bırakmaktansa
/// kaybolması dürüst.

/// [l] parametre olarak geçiyor: bu fonksiyonlar widget değil ve `messenger`
/// dışında bir bağlamları yok. Çağıranın dili vermesi, gizlice global bir dile
/// bağlanmaktan iyi (aynı gerekçe: `describeHubError`).
void createSelectionRecord({
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
  required L l,
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

  final draftForPath = TaskDraft.fromSelection(
    quote: normalized,
    sourcePath: sourcePath,
    kind: kind.category,
    mark: mark,
    note: note,
    priority: priority,
    section: section,
    repoSlug: repoSlug,
    author: container.read(loginForRepoProvider(repoSlug)),
    lang: container.read(languageForRepoProvider(repoSlug)).valueOrNull ??
        HubLanguage.tr,
  );
  // Yol baştan biliniyor: kullanıcı işareti hemen silmek isterse hangi dosyayı
  // kaldıracağımızı senkronu beklemeden bilmeliyiz.
  final annotation = Annotation(
    quote: normalized,
    mark: mark,
    title: normalized,
    category: kind.category,
    path: '${Hub.inboxDir}/${draftForPath.fileName}',
    sourcePath: sourcePath,
    repoSlug: repoSlug,
    note: note.trim().isEmpty ? null : note.trim(),
  );
  container.read(freshAnnotationsProvider.notifier).add(sourcePath, annotation);

  final draft = draftForPath;

  unawaited(() async {
    try {
      await container.read(taskRepoForSlugProvider(repoSlug)).send(draft);
    } on HubNetworkError {
      // Ağ yok: kuyruğa alınır, işaret kalır — kayıt kaybolmadı (B-032).
      await container.read(outboxProvider.notifier).add(draft);
      messenger.showSnackBar(
        SnackBar(content: Text(l.selQueuedRecord)),
      );
    } on HubError catch (e) {
      container.read(freshAnnotationsProvider.notifier).remove(sourcePath, annotation);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      container.read(freshAnnotationsProvider.notifier).remove(sourcePath, annotation);
      messenger.showSnackBar(
        SnackBar(content: Text(l.selUnexpected('$e'))),
      );
    }
    container.invalidate(allPendingTasksProvider);
  }());
}

/// Seçimden **not** üretir (sözleşme 1.9 §11).
///
/// [createSelectionRecord]'dan ayrı bir fonksiyon, çünkü not bir görev değil:
/// `notes/`a gidiyor, önceliği/kategorisi/durumu yok ve bekleyen işlerde
/// görünmüyor. Aynı fonksiyona bayrak eklemek, ikisinin ayrı şeyler olduğunu
/// gizlerdi — kullanıcının şikâyeti tam olarak buydu: kendine aldığı not
/// agent'ın iş kuyruğunda çıkıyordu.
///
/// İşaretin hemen görünmesi ve gönderimin arkada sürmesi görevlerdekiyle aynı
/// (L-026); gerekçesi de aynı: okurken not almanın akışı bölünmemeli.
void createNote({
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
  required L l,
  required String quote,
  required String sourcePath,
  String note = '',
  TaskMark mark = TaskMark.comment,
  String? section,
  String? repoSlug,
}) {
  final normalized = collapseWhitespace(quote);

  final draft = TaskDraft.note(
    quote: normalized,
    sourcePath: sourcePath,
    note: note,
    mark: mark,
    section: section,
    repoSlug: repoSlug,
    // Kimlik, yazılacak reponun bağlantısından gelir (L-019'un aynı gerekçesi).
    author: container.read(loginForRepoProvider(repoSlug)),
    lang: container.read(languageForRepoProvider(repoSlug)).valueOrNull ??
        HubLanguage.tr,
  );
  final annotation = Annotation(
    quote: normalized,
    mark: mark,
    title: draft.title,
    category: 'not',
    path: '${Hub.notesDir}/${draft.fileName}',
    sourcePath: sourcePath,
    repoSlug: repoSlug,
    note: note.trim().isEmpty ? null : note.trim(),
  );
  container.read(freshAnnotationsProvider.notifier).add(sourcePath, annotation);

  unawaited(() async {
    try {
      await container.read(taskRepoForSlugProvider(repoSlug)).sendNote(draft);
    } on HubNetworkError {
      await container.read(outboxProvider.notifier).add(draft);
      messenger.showSnackBar(
        SnackBar(content: Text(l.selQueuedNote)),
      );
    } on HubError catch (e) {
      container
          .read(freshAnnotationsProvider.notifier)
          .remove(sourcePath, annotation);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      container
          .read(freshAnnotationsProvider.notifier)
          .remove(sourcePath, annotation);
      messenger.showSnackBar(SnackBar(content: Text(l.selUnexpected('$e'))));
    }
    // Bekleyenler'i tazelemeye gerek yok: not oraya hiç girmiyor.
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

/// Seçime hızlıca **kendine not** yazma kutusu; yazılan notu döndürür.
///
/// Tam sayfadan (tür, işaret, öncelik) daha hafif: okurken bir not düşmek
/// isteyen kullanıcıyı beş alanla karşılamamak için ayrı tutuldu. Ürettiği şey
/// görev değil, not (§11) — agent'ın iş kuyruğuna girmez.
Future<String?> openNoteBox(
  BuildContext context, {
  required String quote,
}) {
  final controller = TextEditingController();
  final normalized = collapseWhitespace(quote);

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(L.of(dialogContext).noteBoxTitle),
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
            key: noteFieldKey,
            controller: controller,
            autofocus: true,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: L.of(dialogContext).noteBoxHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(L.of(dialogContext).noteBoxCancel),
        ),
        FilledButton(
          key: noteSubmitKey,
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: Text(L.of(dialogContext).noteBoxAdd),
        ),
      ],
    ),
  );
}

const noteFieldKey = Key('selection-note-box-field');
const noteSubmitKey = Key('selection-note-box-submit');

/// İşarete dokununca açılan kayıt kartı: ne olduğunu gösterir, silmeyi sunar.
///
/// Silme yalnız `inbox/`ta duran kayıtlar için mümkün (sözleşme 1.7). Agent
/// kaydı `active/`e almışsa dosya orada değildir; o zaman kullanıcıya
/// "agent ele almış" denir ve dokunulmaz — ele alınmış bir işi sessizce yok
/// etmek agent'ın çalışmasını çöpe atardı.
Future<bool> openAnnotationCard(
  BuildContext context, {
  required Annotation annotation,
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
}) async {
  final l = L.of(context);
  final deleted = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    switch (annotation.mark) {
                      TaskMark.highlight => Icons.brush_outlined,
                      TaskMark.comment => Icons.sticky_note_2_outlined,
                      TaskMark.underline => Icons.format_underlined,
                      TaskMark.bookmark => Icons.bookmark_outline,
                    },
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(annotation.category, style: theme.textTheme.titleSmall),
                  // Kimlik yalnız **görevlerde** anlamlı: notlar kişisel, orada
                  // yazan hep "ben" olurdu (sözleşme 1.16).
                  if (annotation.author != null &&
                      annotation.category != 'not') ...[
                    const Spacer(),
                    Icon(Icons.person_outline,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(annotation.author!,
                        style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Alıntı **bağlam**: kullanıcı zaten belgede görüyor, o yüzden
              // küçük ve solgun.
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
                child: Text(annotation.quote,
                    style: theme.textTheme.bodySmall, maxLines: 6,
                    overflow: TextOverflow.ellipsis),
              ),
              // Kartın asıl taşıdığı şey: kullanıcının o alıntı hakkında
              // yazdığı metin. Bu olmadan kart, kullanıcının zaten gördüğü
              // alıntıyı tekrar ediyordu.
              if (annotation.note != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  key: annotationNoteKey,
                  annotation.note!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: annotationDeleteKey,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(isNotePath(annotation.path)
                      ? L.of(sheetContext).annDeleteNote
                      : L.of(sheetContext).annDeleteMark),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (deleted != true) return false;

  // Yerel katmandan hemen kalksın: silme ağ turunu beklerken işaret ekranda
  // durursa kullanıcı "silinmedi" sanır.
  container.read(freshAnnotationsProvider.notifier).remove(
        annotation.sourcePath,
        annotation,
      );

  final fileName = annotation.path.split('/').last;
  final folder =
      isNotePath(annotation.path) ? HubFolder.notes : HubFolder.inbox;
  var message = folder == HubFolder.notes ? l.annNoteDeleted : l.annMarkDeleted;
  try {
    final removed = await container
        .read(taskRepoForSlugProvider(annotation.repoSlug))
        .deleteFrom(folder, fileName);
    if (!removed) {
      message = l.annAlreadyHandled;
    }
  } on HubError catch (e) {
    message = e.message;
  }

  container.invalidate(allPendingTasksProvider);
  messenger.showSnackBar(SnackBar(content: Text(message)));
  return true;
}

const annotationDeleteKey = Key('annotation-delete');
const annotationNoteKey = Key('annotation-note');
