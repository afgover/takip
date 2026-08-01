import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/connections_backup.dart';
import '../../hub/hub_connections.dart';

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
    final pass = _exportPassCtrl.text;
    if (pass.length < 6) {
      _say('Parola en az 6 karakter olmalı.', error: true);
      return;
    }

    final connections =
        ref.read(hubConnectionsProvider).valueOrNull?.connections ?? const [];
    if (connections.isEmpty) {
      _say('Yedeklenecek bağlantı yok.', error: true);
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
      _say('${connections.length} bağlantı yedeklendi.');
    } catch (e) {
      _say('Yedek alınamadı: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final text = _importTextCtrl.text.trim();
    if (text.isEmpty) {
      _say('Yedek metnini yapıştır.', error: true);
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
      _say('${restored.length} bağlantı geri yüklendi.');
    } on BackupError catch (e) {
      _say(e.message, error: true);
    } catch (e) {
      _say('Geri yüklenemedi: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count =
        ref.watch(hubConnectionsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Yedekleme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dışa aktar', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Kayıtlı $count bağlantı tek bir metne çevrilir. Metin '
            'token\'larını taşıdığı için belirlediğin parolayla şifrelenir — '
            'parolasız işe yaramaz.',
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
            decoration: const InputDecoration(
              labelText: 'Yedek parolası',
              helperText: 'Bunu unutursan yedek işe yaramaz.',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: BackupScreen.exportButtonKey,
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.ios_share),
            label: const Text('Yedek oluştur'),
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
                _say('Panoya kopyalandı. Parola yöneticine yapıştır.');
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Panoya kopyala'),
            ),
            const SizedBox(height: 4),
            Text(
              'Bunu parola yöneticine kaydet. Panoda bırakma — pano geçmişi '
              'tutan uygulamalar okuyabilir.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const Divider(height: 40),
          Text('Geri yükle', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Yedekteki repolar listeye eklenir. Zaten kayıtlı bir repo gelirse '
            'token\'ı tazelenir; mevcut bağlantıların silinmez.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            key: BackupScreen.importTextKey,
            controller: _importTextCtrl,
            enabled: !_busy,
            maxLines: 4,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Yedek metni',
              border: OutlineInputBorder(),
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
            decoration: const InputDecoration(
              labelText: 'Yedek parolası',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: BackupScreen.importButtonKey,
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('Geri yükle'),
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
