import 'package:flutter/material.dart';

import '../../hub/token_scope.dart';
import '../../l10n/app_localizations.dart';

/// Kapsamı geniş bir token bulunduğunda gösterilen onay kutusu (B-092).
///
/// **Neden engellemiyor:** token çalışıyor. Reddetmek, elinde klasik token
/// olan kullanıcıya uygulamayı tümden kapatırdı — güvenlik kontrolünün
/// kullanıcıyı işini yapamaz hâle getirmesi, kontrolün kapatılmasıyla
/// sonuçlanır. Bunun yerine uyarı, kullanıcının hâlâ token alanının başında
/// olduğu anda gösterilir: "Vazgeç" formda kalır, dar bir token yapıştırmak
/// tek hareket uzaktadır.
///
/// `true` = kullanıcı yine de devam etmek istiyor.
Future<bool> confirmWideTokenScope(
  BuildContext context,
  TokenScopeWarning warning,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: tokenScopeDialogKey,
      icon: const Icon(Icons.gpp_maybe_outlined),
      title: Text(warning.title),
      content: SingleChildScrollView(child: Text(warning.body)),
      actions: [
        TextButton(
          key: tokenScopeCancelKey,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(L.of(context).cancel),
        ),
        FilledButton(
          key: tokenScopeContinueKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(L.of(context).connectAnyway),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

const tokenScopeDialogKey = Key('token-scope-dialog');
const tokenScopeCancelKey = Key('token-scope-cancel');
const tokenScopeContinueKey = Key('token-scope-continue');
