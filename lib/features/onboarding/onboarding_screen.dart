import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../hub/hub_access.dart';
import '../../hub/hub_config.dart';

/// Hub bağlantı kurulumu: repo (owner/ad) + fine-grained token.
///
/// Token kaydedilmeden önce doğrulanır (B-022): yanlış token ya da yanlış repo
/// ile kurulumu "başarılı" sayıp kullanıcıyı boş listelerle baş başa bırakmak
/// yerine, hata daha ilk ekranda ve sebebiyle birlikte gösterilir.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const repoFieldKey = Key('onboarding-repo-field');
  static const tokenFieldKey = Key('onboarding-token-field');
  static const submitButtonKey = Key('onboarding-submit');
  static const errorKey = Key('onboarding-error');

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repoCtrl = TextEditingController(text: Hub.defaultRepo);
  final _tokenCtrl = TextEditingController();

  bool _busy = false;
  bool _showToken = false;
  String? _error;

  @override
  void dispose() {
    _repoCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;

    final parsed = HubConfig.parseRepo(_repoCtrl.text)!;
    final candidate = HubConfig(
      owner: parsed.owner,
      repo: parsed.repo,
      token: _tokenCtrl.text.trim(),
    );

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(hubAccessVerifierProvider)(candidate);
      // Yalnızca doğrulama geçtiyse diske yazılır.
      await ref.read(hubConfigProvider.notifier).save(candidate);
      // Kayıt sonrası app.dart otomatik olarak kabuğa geçer; burada
      // gezinme yapılmaz.
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Takip',
                      style: theme.textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hub reposuna bağlan. Yalnızca bu repoya scope\'lanmış '
                      'bir fine-grained token kullan.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: OnboardingScreen.repoFieldKey,
                      controller: _repoCtrl,
                      enabled: !_busy,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Repo (owner/ad)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      validator: (v) => HubConfig.parseRepo(v ?? '') == null
                          ? 'owner/ad biçiminde girin'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: OnboardingScreen.tokenFieldKey,
                      controller: _tokenCtrl,
                      enabled: !_busy,
                      obscureText: !_showToken,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Fine-grained token',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.key_outlined),
                        suffixIcon: IconButton(
                          tooltip: _showToken ? 'Gizle' : 'Göster',
                          icon: Icon(_showToken
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _showToken = !_showToken),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Token gerekli'
                          : null,
                      onFieldSubmitted: (_) => _connect(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBox(key: OnboardingScreen.errorKey, message: _error!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: OnboardingScreen.submitButtonKey,
                      onPressed: _busy ? null : _connect,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Bağlan'),
                    ),
                    const SizedBox(height: 16),
                    const _TokenHelp(),
                  ],
                ),
              ),
            ),
          ),
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
          Icon(Icons.error_outline, color: colors.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Token'ı nasıl üreteceğini hatırlatan açılır bölüm — izinler R-005'teki
/// kapsamla birebir aynı.
class _TokenHelp extends StatelessWidget {
  const _TokenHelp();

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Token nasıl alınır?'),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'GitHub → Settings → Developer settings → '
            'Personal access tokens → Fine-grained tokens → Generate new token\n\n'
            '• Repository access: Only select repositories → ${Hub.defaultRepo}\n'
            '• Permissions: Contents → Read and write, Metadata → Read\n\n'
            'Token yalnızca bu cihazın güvenli deposunda saklanır.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
