import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/annotations.dart';
import '../../hub/hub_config.dart';
import '../../hub/models/task.dart';
import 'hub_markdown.dart';
import 'selection_record.dart';

/// Hub belgelerini **seçilebilir ve işaretlenebilir** olarak çizer.
///
/// İki şeyi birlikte yapar:
/// - Belgeye bağlı kayıtların alıntılarını metinde işaretler (sarı/kırmızı).
/// - Metin seçilince menüyü **tamamen değiştirir**: sarı işaretle, kırmızı
///   çiz, görev oluştur, kopyala. Sistemin varsayılan öğeleri (arama, çeviri,
///   asistanlar) eklenmez — cihazda o liste bir düzine öğeye çıkıp asıl
///   eylemleri taşma menüsünün dibine düşürüyordu.
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

  static const highlightLabel = 'Sarı işaretle';
  static const underlineLabel = 'Kırmızı çizgi';
  static const commentLabel = 'Yorum ekle';
  static const taskLabel = 'Görev oluştur';
  static const copyLabel = 'Kopyala';

  @override
  ConsumerState<AnnotatedDocument> createState() => _AnnotatedDocumentState();
}

class _AnnotatedDocumentState extends ConsumerState<AnnotatedDocument> {
  String? _selected;

  /// Menüden tek dokunuşla işaretleme: sayfa açılmadan kayıt oluşur.
  ///
  /// Sarı = `yorum` ("buraya bak"), kırmızı = `duzeltme` ("burası yanlış").
  /// Not girmek isteyen "Görev oluştur"u kullanır; buradaki iki eylemin
  /// amacı okurken akışı bölmemek.
  void _quickMark(
    SelectableRegionState state,
    String selection, {
    required RecordKind kind,
    required TaskMark mark,
  }) {
    state.hideToolbar();
    _create(SelectionRequest(kind: kind, mark: mark), selection);
  }

  /// Kaydı **bu ekran** oluşturur; sayfa/kutu yalnız seçimi döndürür.
  /// Sebebi: onların `ref`'i kapandığı anda ölüyor ve işaret hiç eklenmiyordu
  /// (L-025).
  void _create(SelectionRequest request, String selection) {
    createSelectionRecord(
      ref: ref,
      context: context,
      quote: selection,
      sourcePath: widget.sourcePath,
      kind: request.kind,
      mark: request.mark,
      note: request.note,
      priority: request.priority,
      section: sectionOf(widget.data, selection),
      repoSlug: ref.read(hubConfigProvider).value?.slug,
    );
  }

  Future<void> _openSheet(String selection) async {
    final request = await openSelectionRecord(
      context,
      quote: selection,
      sourcePath: widget.sourcePath,
    );
    if (request != null && mounted) _create(request, selection);
  }

  Future<void> _openComment(String selection) async {
    final request = await openCommentBox(context, quote: selection);
    if (request != null && mounted) _create(request, selection);
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
        return _SelectionMenu(
          anchors: state.contextMenuAnchors,
          actions: [
            (
              AnnotatedDocument.highlightLabel,
              Icons.brush_outlined,
              () => _quickMark(state, selection,
                  kind: RecordKind.yorum, mark: TaskMark.highlight),
            ),
            (
              AnnotatedDocument.underlineLabel,
              Icons.format_underlined,
              () => _quickMark(state, selection,
                  kind: RecordKind.duzeltme, mark: TaskMark.underline),
            ),
            (
              AnnotatedDocument.commentLabel,
              Icons.chat_bubble_outline,
              () {
                state.hideToolbar();
                _openComment(selection);
              },
            ),
            (
              AnnotatedDocument.taskLabel,
              Icons.add_task,
              () {
                state.hideToolbar();
                _openSheet(selection);
              },
            ),
            (
              AnnotatedDocument.copyLabel,
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
  final List<(String, IconData, VoidCallback)> actions;

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
              for (final (label, icon, onTap) in actions)
                InkWell(
                  key: Key('selection-menu-$label'),
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
