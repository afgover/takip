import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../hub/hub_access.dart';
import '../../hub/hub_config.dart';
import '../../hub/hub_watcher.dart';

/// Ekran ne yapıyor: yeni repo mu ekliyor, var olanı mı düzenliyor (T-003).
enum ConnectionMode { add, edit }

/// Bağlantı ekleme / değiştirme: repo, ad ve token (B-051, T-003).
///
/// Onboarding'le aynı kural: yeni bilgiler **doğrulanmadan kaydedilmez**
/// (B-022). Çalışan bir kurulumu bozup kullanıcıyı boş listelerle bırakmak,
/// hiç değiştirmemekten kötü.
class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({
    super.key,
    this.mode = ConnectionMode.edit,
    this.initial,
  });

  /// Düzenlenecek bağlantı. Verilmezse aktif bağlantı düzenlenir.
  final HubConfig? initial;
  final ConnectionMode mode;

  static const repoFieldKey = Key('connection-repo-field');
  static const labelFieldKey = Key('connection-label-field');
  static const tokenFieldKey = Key('connection-token-field');
  static const submitKey = Key('connection-submit');
  static const errorKey = Key('connection-error');

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _repoCtrl;
  late final TextEditingController _labelCtrl;
  final _tokenCtrl = TextEditingController();

  bool _busy = false;
  bool _showToken = false;
  String? _error;

  bool get _isAdd => widget.mode == ConnectionMode.add;

  /// Düzenlenen bağlantı; ekleme kipinde null.
  HubConfig? get _target =>
      _isAdd ? null : (widget.initial ?? ref.read(hubConfigProvider).value);

  @override
  void initState() {
    super.initState();
    final target = _target;
    _repoCtrl = TextEditingController(text: _isAdd ? '' : (target?.slug ?? ''));
    _labelCtrl = TextEditingController(text: target?.label ?? '');
  }

  @override
  void dispose() {
    _repoCtrl.dispose();
    _labelCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    final current = _target;
    final parsed = HubConfig.parseRepo(_repoCtrl.text)!;
    final typedToken = _tokenCtrl.text.trim();
    final typedLabel = _labelCtrl.text.trim();

    // Düzenlemede token alanı boş bırakılırsa mevcut token korunur; eklemede
    // token zorunludur (doğrulayacak bir şey olmalı).
    final candidate = HubConfig(
      owner: parsed.owner,
      repo: parsed.repo,
      token: typedToken.isEmpty ? (current?.token ?? '') : typedToken,
      label: typedLabel.isEmpty ? null : typedLabel,
    );

    if (candidate.token.isEmpty) {
      setState(() => _error = 'Token gerekli.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(hubAccessVerifierProvider)(candidate);
      await ref.read(hubConfigProvider.notifier).save(candidate);
      // Token düzeldiyse yoklama durmuş olabilir; yeniden başlat.
      ref.read(hubWatcherProvider.notifier).start();
      unawaited(ref.read(hubWatcherProvider.notifier).checkNow());

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAdd ? 'Repo eklendi.' : 'Bağlantı güncellendi.'),
        ),
      );
    } on HubError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran, yapılandırma henüz yüklenirken açılmış olabilir; geldiğinde repo
    // alanını doldur (kullanıcı yazmaya başlamadıysa).
    ref.listen<AsyncValue<HubConfig?>>(hubConfigProvider, (previous, next) {
      if (_isAdd || widget.initial != null) return;
      final config = next.value;
      if (config != null && _repoCtrl.text.trim().isEmpty) {
        _repoCtrl.text = config.slug;
      }
    });

    // Var olan bir bağlantının reposu değiştirilemez: değiştirilseydi kayıt
    // "başka bir repo" olurdu ve eski bağlantı listede öksüz kalırdı. Repo
    // değiştirmek isteyen ekler, sonra eskisini kaldırır.
    final repoLocked = !_isAdd && _target != null;

    return Scaffold(
      appBar: AppBar(title: Text(_isAdd ? 'Repo ekle' : 'Bağlantı')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: ConnectionScreen.repoFieldKey,
              controller: _repoCtrl,
              enabled: !_busy && !repoLocked,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Repo (owner/ad)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.folder_outlined),
                helperText: repoLocked
                    ? 'Repo değiştirilemez — yeni repo eklemek için "Repo ekle".'
                    : null,
              ),
              validator: (v) => HubConfig.parseRepo(v ?? '') == null
                  ? 'owner/ad biçiminde girin'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ConnectionScreen.labelFieldKey,
              controller: _labelCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Ad (isteğe bağlı)',
                helperText: 'Repo seçicide görünür; boşsa owner/ad gösterilir.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ConnectionScreen.tokenFieldKey,
              controller: _tokenCtrl,
              enabled: !_busy,
              obscureText: !_showToken,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: _isAdd
                    ? 'Fine-grained token'
                    : 'Yeni token (boş bırakılırsa değişmez)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_showToken
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showToken = !_showToken),
                ),
              ),
              validator: (v) => _isAdd && (v == null || v.trim().isEmpty)
                  ? 'Token gerekli'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorBox(key: ConnectionScreen.errorKey, message: _error!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: ConnectionScreen.submitKey,
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Doğrula ve kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: colors.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
