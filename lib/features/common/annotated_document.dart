import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/annotations.dart';
import 'hub_markdown.dart';
import 'selection_record.dart';

/// Hub belgelerini **seçilebilir ve işaretlenebilir** olarak çizer.
///
/// İki şeyi birlikte yapar:
/// - Belgeye bağlı kayıtların alıntılarını metinde işaretler (sarı/kırmızı).
/// - Metin seçilince menüye "Kayıt oluştur" ekler; seçimden görev, yorum,
///   düzeltme veya tartışma üretilir (sözleşme 1.5).
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

  static const menuLabel = 'Kayıt oluştur';

  @override
  ConsumerState<AnnotatedDocument> createState() => _AnnotatedDocumentState();
}

class _AnnotatedDocumentState extends ConsumerState<AnnotatedDocument> {
  String? _selected;

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
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            // **En başta**: Android seçim menüsü cihazdaki uygulamalarla
            // (tarayıcılar, çevirmenler, parola yöneticileri) doluyor ve sona
            // eklenen öğe taşma menüsünün dibine düşüyor. Bu ekranda seçim
            // yapmanın asıl sebebi kayıt oluşturmak; görünür yerde olmalı.
            if (selection.isNotEmpty)
              ContextMenuButtonItem(
                label: AnnotatedDocument.menuLabel,
                onPressed: () {
                  state.hideToolbar();
                  openSelectionRecord(
                    context,
                    quote: selection,
                    sourcePath: widget.sourcePath,
                  );
                },
              ),
            ...state.contextMenuButtonItems,
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
