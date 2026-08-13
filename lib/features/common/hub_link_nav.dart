import 'package:flutter/material.dart';

import '../../hub/hub_link.dart';
import '../../l10n/app_localizations.dart';
import '../browse/document_screen.dart';

/// Belgedeki bir bağlantıya dokunulunca hedefi açar (sözleşme 1.25 §15).
///
/// Hub'ın kayıtları birbirine ID'yle atıf yapıyor; bu atıflar bağlantı olarak
/// yazıldığında telefonda da tıklanabilir olmalı — yoksa kural yalnız GitHub'da
/// okuyan için işe yarar ve uygulamada ölü metin kalır.
///
/// Hub dışı bağlantı **açılmaz, söylenir**: sessizce hiçbir şey yapmayan bir
/// dokunuş, kullanıcıya uygulamanın donduğunu düşündürür.
void openHubLink(
  BuildContext context, {
  required String? href,
  required String fromPath,
  String? repoSlug,
}) {
  final link = resolveHubLink(href, fromPath: fromPath);
  if (link == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L.of(context).linkOutsideHub)),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DocumentScreen(
        path: link.path,
        title: link.path.split('/').last,
        anchor: link.anchor,
        repoSlug: repoSlug,
      ),
    ),
  );
}
