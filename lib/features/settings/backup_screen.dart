import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/connections_backup.dart';
import '../../hub/hub_connections.dart';
import '../../l10n/app_localizations.dart';

/// Bağlantıların parolayla şifreli yedeği: dışa aktar / geri yükle.
///
/// Cihaz verisi kaybolduğunda (fabrika ayarları, "verileri temizle", yeni
/// telefon, kurulumun paketi kaldırması → L-014) bütün repoların token'ını
/// tek tek yeniden girmek yerine tek yapıştırma yeter.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  static const exportPassKey = Key('backup-export-pass');
  static const exportButtonKey = Key('backup-export-button');
  static const exportResultKey = Key('backup-export-result');
  static const importTextKey = Key('backup-import-text');
  static const importPassKey = Key('backup-import-pass');
  static const importButtonKey = Key('backup-import-button');
  static const messageKey = Key('backup-message');

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _exportPassCtrl = TextEditingController();
  final _importTextCtrl = TextEditingController();
  final _importPassCtrl = TextEditingController();

  String? _exported;
  String? _message;
  bool _isError = false;
  bool _busy = false;

  @override
  void dispose() {
    _exportPassCtrl.dispose();
    _importTextCtrl.dispose();
    _importPassCtrl.dispose();
    super.dispose();
  }

  void _say(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isError = error;
    });
  }

  Future<void> _export() async {
    final l = L.of(context);
    final pass = _exportPassCtrl.text;
    if (pass.length < 6) {
      _say(l.backupPassTooShort, error: true);
      return;
    }

    final connections =
        ref.read(hubConnectionsProvider).valueOrNull?.connections ?? const [];
    if (connections.isEmpty) {
      _say(l.backupNothingToExport, error: true);
      return;
    }

    setState(() {
      _busy = true;
      _exported = null;
      _message = null;
    });
    try {
      final backup =
          await ConnectionsBackup.export(connections, passphrase: pass);
      if (!mounted) return;
      setState(() => _exported = backup);
      _say(l.backupExported(connections.length));
    } catch (e) {
      _say(l.backupExportFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final l = L.of(context);
    final text = _importTextCtrl.text.trim();
    if (text.isEmpty) {
      _say(l.backupPasteFirst, error: true);
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final restored = await ConnectionsBackup.import(
        text,
        passphrase: _importPassCtrl.text,
      );

      // Var olan bağlantılar korunur; aynı repo gelirse token'ı tazelenir
      // (upsert). Geri yükleme, elde çalışan bir kurulumu silmemeli.
      final notifier = ref.read(hubConnectionsProvider.notifier);
      for (final connection in restored) {
        await notifier.upsertAndActivate(connection);
      }

      if (!mounted) return;
      _importTextCtrl.clear();
      _importPassCtrl.clear();
      _say(l.backupRestored(restored.length));
    } on BackupError catch (e) {
      _say(e.message, error: true);
    } catch (e) {
      _say(l.backupImportFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final count =
        ref.watch(hubConnectionsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.backupExportHeading, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l.backupExportIntro(count),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            key: BackupScreen.exportPassKey,
            controller: _exportPassCtrl,
            enabled: !_busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l.backupPassLabel,
              helperText: l.backupPassHelp,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: BackupScreen.exportButtonKey,
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.ios_share),
            label: Text(l.backupExportButton),
          ),
          if (_exported != null) ...[
            const SizedBox(height: 12),
            Container(
              key: BackupScreen.exportResultKey,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _exported!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _exported!));
                _say(l.backupCopied);
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: Text(l.backupCopyButton),
            ),
            const SizedBox(height: 4),
            Text(l.backupCopyWarning, style: theme.textTheme.bodySmall),
          ],
          const Divider(height: 40),
          Text(l.backupRestoreHeading, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l.backupRestoreIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            key: BackupScreen.importTextKey,
            controller: _importTextCtrl,
            enabled: !_busy,
            maxLines: 4,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l.backupTextLabel,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: BackupScreen.importPassKey,
            controller: _importPassCtrl,
            enabled: !_busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l.backupPassLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: BackupScreen.importButtonKey,
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.settings_backup_restore),
            label: Text(l.backupRestoreButton),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Container(
              key: BackupScreen.messageKey,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message!,
                style: TextStyle(
                  color: _isError
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
