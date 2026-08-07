import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/annotations.dart';
import '../../hub/hub_config.dart';
import '../../hub/models/task.dart';
import 'hub_markdown.dart';
import 'selection_record.dart';
import '../../l10n/app_localizations.dart';

/// Hub belgelerini **seçilebilir ve işaretlenebilir** olarak çizer.
///
/// İki şeyi birlikte yapar:
/// - Belgeye bağlı kayıtların alıntılarını metinde işaretler (sarı/kırmızı).
/// - Metin seçilince menüyü **tamamen değiştirir**: sarı işaretle, kırmızı
///   çiz, not ekle, görev oluştur, kopyala. Sistemin varsayılan öğeleri (arama,
///   çeviri, asistanlar) eklenmez — cihazda o liste bir düzine öğeye çıkıp asıl
///   eylemleri taşma menüsünün dibine düşürüyordu.
///
/// Yalnız **notlu görev** agent'ın iş kuyruğuna (`tasks/inbox/`) girer. Notsuz
/// işaret/çizgi ve "Not ekle" — hepsi kullanıcının kendisi içindir ve `notes/`a
/// yazılır (sözleşme 1.9): işaret belgede kalır, Bekleyen görevler'i doldurmaz.
/// Boş seçimlerin iş kuyruğunu doldurması buradan kesildi.
///
/// Oturumlar, raporlar, bilgi tabanı, yol haritası ve görev detayı — hepsi
/// bunu kullanır, böylece davranış her yerde aynıdır.
class AnnotatedDocument extends ConsumerStatefulWidget {
  const AnnotatedDocument({
    super.key,
    required this.data,
    required this.sourcePath,
    this.padding = EdgeInsets.zero,
    this.onTapLink,
  });

  final String data;

  /// Belgenin hub içindeki yolu — oluşturulan kaydın `source` alanı olur ve
  /// işaretler bununla bulunur.
  final String sourcePath;

  final EdgeInsets padding;
  final void Function(String text, String? href, String title)? onTapLink;

  /// Menü öğeleri metinle değil **anahtarla** bulunuyor (sözleşme 1.18).
  /// Etiket artık dile göre değişiyor; metni kimlik olarak kullanmak testleri
  /// ve menüyü seçili dile bağımlı kılardı.
  static const highlightKey = Key('selection-highlight');
  static const underlineKey = Key('selection-underline');

  /// Yer imi (v1.12) — tek dokunuş, hiçbir koşulda göreve dönüşmez.
  static const bookmarkKey = Key('selection-bookmark');
  static const noteKey = Key('selection-note');
  static const taskKey = Key('selection-task');
  static const copyKey = Key('selection-copy');

  @override
  ConsumerState<AnnotatedDocument> createState() => _AnnotatedDocumentState();
}

/// Diyalog açılmadan önce toplanan, widget yaşam döngüsünden bağımsız bağlam.
typedef _Captured = ({
  ProviderContainer container,
  ScaffoldMessengerState messenger,
  String? section,
  String? repoSlug,
});

class _AnnotatedDocumentState extends ConsumerState<AnnotatedDocument> {
  String? _selected;

  /// Menüden tek dokunuşla işaretleme: sayfa açılmadan kayıt oluşur.
  ///
  /// Sarı ("buraya bak") ve kırmızı ("burası yanlış") işaretler **notsuz**tur;
  /// bu yüzden `notes/`a düşerler (agent'ın iş kuyruğuna değil) — okurken hızlı
  /// bir görsel iz, akışı bölmeden. Agent'a iş çıkarmak isteyen "Görev
  /// oluştur"la bir not yazar; not, seçimi göreve dönüştürür.
  void _quickMark(
    SelectableRegionState state,
    String selection, {
    required RecordKind kind,
    required TaskMark mark,
  }) {
    final captured = _capture(selection);
    state.hideToolbar();
    _create(SelectionRequest(kind: kind, mark: mark), selection, captured);
  }

  /// Diyalog/sayfa açmadan **önce** yaşam döngüsünden bağımsız olan her şeyi
  /// topla: kullanıcı yazarken bu ekran yeniden kurulabilir ve `context`/`ref`
  /// geçersizleşebilir (L-029).
  _Captured _capture(String selection) => (
        container: ProviderScope.containerOf(context, listen: false),
        messenger: ScaffoldMessenger.of(context),
        section: sectionOf(widget.data, selection),
        repoSlug: ref.read(hubConfigProvider).value?.slug,
      );

  /// Kaydı **bu ekran** oluşturur; sayfa/kutu yalnız seçimi döndürür.
  /// Sebebi: onların `ref`'i kapandığı anda ölüyor ve işaret hiç eklenmiyordu
  /// (L-025).
  ///
  /// Yakalanan değerler **zorunlu** — "yoksa `ref`'ten oku" gibi bir yedek yol
  /// bırakılmadı. Öyle bir yedek, yakalanan değer meşru olarak null olduğunda
  /// (bağlı repo yokken `repoSlug`) sessizce devreye girip ölmüş bir `ref`e
  /// uzanıyordu; hata da kullanıcıya "eklendi" dedikten sonra çıkıyordu.
  void _create(
    SelectionRequest request,
    String selection,
    _Captured captured,
  ) {
    // Notsuz seçim iş kuyruğuna GİRMEZ: `notes/`a not olarak yazılır — işaret
    // (sarı/kırmızı) belgede kalır ama Bekleyen görevler'i doldurmaz. Not
    // yazılmışsa "sen şunu yap" niyetidir → görev (`tasks/inbox/`). Bu ayrım
    // hem hızlı işaretleri hem sayfayı kapsar; ikisi de buradan geçiyor.
    // Yer imi bu kuralın **üstünde** (sözleşme 1.12): notlu olsa bile göreve
    // dönüşmez. "Burayı sonra bulayım" demek agent'a iş vermek değildir; yer
    // imine düşülen not da kullanıcının kendine bıraktığı işarettir.
    if (!request.mark.canBecomeTask || request.note.trim().isEmpty) {
      createNote(
        container: captured.container,
        messenger: captured.messenger,
        quote: selection,
        sourcePath: widget.sourcePath,
        // Notsuz yolda zaten boş; yer iminde dolu olabilir ve kaybolmamalı.
        note: request.note,
        mark: request.mark,
        section: captured.section,
        repoSlug: captured.repoSlug,
      );
      return;
    }
    createSelectionRecord(
      container: captured.container,
      messenger: captured.messenger,
      quote: selection,
      sourcePath: widget.sourcePath,
      kind: request.kind,
      mark: request.mark,
      note: request.note,
      priority: request.priority,
      section: captured.section,
      repoSlug: captured.repoSlug,
    );
  }

  Future<void> _openSheet(String selection) async {
    final captured = _capture(selection);
    final request = await openSelectionRecord(
      context,
      quote: selection,
      sourcePath: widget.sourcePath,
    );
    if (request == null) return;
    _create(request, selection, captured);
  }

  /// Kendine not (sözleşme 1.9 §11) — görev değil, bu yüzden görev yolundan
  /// değil `createNote`'tan geçiyor ve Bekleyenler'de görünmüyor.
  Future<void> _openNote(String selection) async {
    final captured = _capture(selection);
    final note = await openNoteBox(context, quote: selection);
    if (note == null) return;
    createNote(
      container: captured.container,
      messenger: captured.messenger,
      quote: selection,
      sourcePath: widget.sourcePath,
      note: note,
      section: captured.section,
      repoSlug: captured.repoSlug,
    );
  }

  @override
  Widget build(BuildContext context) {
    // İşaretler kayıtlardan türüyor; okunamazsa belge yine çizilir, yalnız
    // işaretsiz kalır — kayıt katmanının sorunu belgeyi gizlememeli.
    final stored =
        ref.watch(annotationsForProvider(widget.sourcePath)).valueOrNull ??
            const <Annotation>[];
    // Az önce oluşturulanlar senkron yetişene kadar buradan gelir.
    final fresh =
        ref.watch(freshAnnotationsProvider)[widget.sourcePath] ?? const [];
    final annotations = [...stored, ...fresh];

    return SelectionArea(
      onSelectionChanged: (content) => _selected = content?.plainText,
      contextMenuBuilder: (context, state) {
        final selection = _selected?.trim() ?? '';
        if (selection.isEmpty) return const SizedBox.shrink();

        // Menü **tamamen** bu uygulamanın ve **taşma yok**: beş eylem alt
        // alta, hepsi tek bakışta. Varsayılan araç çubuğu yatay olduğu için
        // sığmayanları üç noktaya gizliyordu; cihazda asıl eylemler o
        // menünün dibine düşüyordu (L-027). Dikey liste bunu ortadan
        // kaldırıyor — ekran genişliğine bağımlı değil.
        final l = L.of(context);
        return _SelectionMenu(
          anchors: state.contextMenuAnchors,
          actions: [
            (
              AnnotatedDocument.highlightKey,
              l.markYellow,
              Icons.brush_outlined,
              () => _quickMark(state, selection,
                  kind: RecordKind.yorum, mark: TaskMark.highlight),
            ),
            (
              AnnotatedDocument.underlineKey,
              l.markRed,
              Icons.format_underlined,
              () => _quickMark(state, selection,
                  kind: RecordKind.duzeltme, mark: TaskMark.underline),
            ),
            (
              AnnotatedDocument.bookmarkKey,
              l.markBookmark,
              Icons.bookmark_outline,
              () => _quickMark(state, selection,
                  kind: RecordKind.yorum, mark: TaskMark.bookmark),
            ),
            (
              AnnotatedDocument.noteKey,
              l.addNote,
              Icons.sticky_note_2_outlined,
              () {
                state.hideToolbar();
                _openNote(selection);
              },
            ),
            (
              AnnotatedDocument.taskKey,
              l.createTask,
              Icons.add_task,
              () {
                state.hideToolbar();
                _openSheet(selection);
              },
            ),
            (
              AnnotatedDocument.copyKey,
              l.copy,
              Icons.copy_all_outlined,
              () {
                state.hideToolbar();
                Clipboard.setData(ClipboardData(text: selection));
              },
            ),
          ],
        );
      },
      child: HubMarkdown(
        widget.data,
        onTapAnnotation: (annotation) {
          final captured = _capture('');
          openAnnotationCard(
            context,
            annotation: annotation,
            container: captured.container,
            messenger: captured.messenger,
          );
        },
        // Seçim dıştaki `SelectionArea` tarafından yönetiliyor; markdown'ın
        // kendi seçimi açık kalsaydı iki seçim katmanı çakışırdı.
        selectable: false,
        padding: widget.padding,
        annotations: annotations,
        onTapLink: widget.onTapLink,
      ),
    );
  }
}

/// Seçim menüsü: beş eylem **alt alta**, taşma menüsü yok.
///
/// Konumlandırma `TextSelectionToolbarLayoutDelegate` ile yapılıyor —
/// seçimin üstünde yer varsa üstte, yoksa altında çizilir; ekran dışına
/// taşmaz.
class _SelectionMenu extends StatelessWidget {
  const _SelectionMenu({required this.anchors, required this.actions});

  final TextSelectionToolbarAnchors anchors;
  final List<(Key, String, IconData, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anchorBelow = anchors.secondaryAnchor ?? anchors.primaryAnchor;

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchorBelow,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (key, label, icon, onTap) in actions)
                InkWell(
                  key: key,
                  onTap: onTap,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(label, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
