import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/hub_config.dart';

/// Hub bağlantı kurulumu: repo (owner/ad) + fine-grained token.
/// TODO(B-022): kaydetmeden önce tek GET ile token/repo doğrulaması ve
/// anlaşılır hata mesajları.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repoCtrl = TextEditingController(text: 'afgover/takip');
  final _tokenCtrl = TextEditingController();

  @override
  void dispose() {
    _repoCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final parts = _repoCtrl.text.trim().split('/');
    await ref.read(hubConfigProvider.notifier).save(
          HubConfig(owner: parts[0], repo: parts[1], token: _tokenCtrl.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Takip',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Hub reposuna bağlan: yalnızca bu repoya scope\'lanmış '
                  'fine-grained token kullan (Contents: R&W, Metadata: R).',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _repoCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Repo (owner/ad)', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || !v.contains('/')) ? 'owner/ad biçiminde girin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tokenCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Fine-grained token', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Token gerekli' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _save, child: const Text('Bağlan')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
