import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/annotations.dart';
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
  static const underlineLabel = 'Kırmızı çiz';
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
    createSelectionRecord(
      ref: ref,
      context: context,
      quote: selection,
      sourcePath: widget.sourcePath,
      kind: kind.category,
      mark: mark,
      successLabel: kind.label,
    );
  }

  @override
  Widget build(BuildContext context) {
    // İşaretler kayıtlardan türüyor; okunamazsa belge yine çizilir, yalnız
    // işaretsiz kalır — kayıt katmanının sorunu belgeyi gizlememeli.
    final annotations =
        ref.watch(annotationsForProvider(widget.sourcePath)).valueOrNull ??
            const [];

    return SelectionArea(
      onSelectionChanged: (content) => _selected = content?.plainText,
      contextMenuBuilder: (context, state) {
        final selection = _selected?.trim() ?? '';
        // Menü **tamamen** bu uygulamanın: sistemin varsayılan öğeleri
        // (tarayıcılarda arama, çeviri, parola yöneticisi, yapay zekâ
        // asistanları…) hiç eklenmiyor. Cihazda denendiğinde o liste bir düzine
        // öğeye çıkıyor ve buradaki asıl eylemler taşma menüsünün dibine
        // düşüyordu. Belge okurken metin seçmenin sebebi işaretlemek ya da iş
        // açmaktır; menü bunu söylemeli.
        if (selection.isEmpty) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: state.contextMenuAnchors,
            buttonItems: const [],
          );
        }

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
              label: AnnotatedDocument.highlightLabel,
              onPressed: () => _quickMark(
                state,
                selection,
                kind: RecordKind.yorum,
                mark: TaskMark.highlight,
              ),
            ),
            ContextMenuButtonItem(
              label: AnnotatedDocument.underlineLabel,
              onPressed: () => _quickMark(
                state,
                selection,
                kind: RecordKind.duzeltme,
                mark: TaskMark.underline,
              ),
            ),
            ContextMenuButtonItem(
              label: AnnotatedDocument.taskLabel,
              onPressed: () {
                state.hideToolbar();
                openSelectionRecord(
                  context,
                  quote: selection,
                  sourcePath: widget.sourcePath,
                );
              },
            ),
            ContextMenuButtonItem(
              label: AnnotatedDocument.copyLabel,
              onPressed: () {
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
