import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/utils.dart';
import '../../hub/categories.dart';
import '../../hub/hub_config.dart';
import '../../hub/hub_connections.dart';
import '../../hub/hub_language.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../../hub/task_repo.dart';
import '../../l10n/app_localizations.dart';

/// Görev ekleme: hedef repo, başlık, açıklama, öncelik, kategori →
/// `tasks/inbox/` (B-030).
///
/// Kategoriler (K-010): varsayılanlar + daha önce görülenler + serbest giriş.
///
/// **Hedef repo görünür ve seçilebilir.** Önceden görev, o an aktif olan
/// bağlantıya yazılıyordu ve ekranda bunu söyleyen hiçbir şey yoktu; hedef,
/// başka bir ekranın (repo şeridi) durumundan türüyordu. Sonuç, bütün
/// görevlerin farkına varılmadan tek bir hub'ın kuyruğunda toplanmasıydı —
/// yazılan yer ile kastedilen yer ayrıldığında bunu kimse fark etmiyor,
/// yalnız o projenin agent'ı yabancı işler görüyor.
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  static const titleFieldKey = Key('add-task-title');
  static const descriptionFieldKey = Key('add-task-description');
  static const categoryFieldKey = Key('add-task-category');
  static const newCategoryFieldKey = Key('add-task-new-category');
  static const targetRepoFieldKey = Key('add-task-target-repo');
  static const submitKey = Key('add-task-submit');

  /// Kategori listesindeki "yeni kategori" seçeneği.
  static const newCategoryValue = '__yeni__';

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _newCategoryCtrl = TextEditingController();

  String _priority = 'normal';
  String _category = Hub.defaultCategories.first;
  bool _busy = false;
  String? _error;

  /// Kullanıcının **açıkça** seçtiği hedef repo; null ise aktif repo izlenir.
  ///
  /// Null bırakmak bilinçli: kullanıcı üstteki şeritten repo değiştirdiğinde
  /// hedef de onunla gelir. Bir kez seçim yapıldıysa seçim korunur — "bu işi
  /// şu projeye açıyorum" niyeti, aktif reponun değişmesiyle bozulmamalı.
  String? _targetSlug;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  bool get _isNewCategory => _category == AddTaskScreen.newCategoryValue;

  String get _effectiveCategory =>
      _isNewCategory ? _newCategoryCtrl.text.trim() : _category;

  /// Görevin gideceği bağlantı: seçilmişse o, değilse aktif olan.
  ///
  /// Kaynak `hubConnectionsProvider`: `hubConfigProvider` ondan **asenkron**
  /// türediği için repo değiştikten hemen sonra bayat kalabiliyor ve hedefi
  /// bayat bir sağlayıcıya sormanın bedeli, görevin yanlış projeye düşmesi
  /// (L-019, L-031, L-045 aynı hattın üç durağı).
  HubConfig? _resolveTarget() {
    final connections =
        ref.read(hubConnectionsProvider).valueOrNull ?? const HubConnectionsState();
    final chosen = _targetSlug;
    return (chosen == null ? null : connections.bySlug(chosen)) ??
        connections.active;
  }

  Future<void> _submit() async {
    final l = L.of(context);
    if (_busy || !_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final category = _effectiveCategory;
    final slug = _resolveTarget()?.slug;
    final draft = TaskDraft.create(
      title: _titleCtrl.text,
      description: _descCtrl.text,
      priority: _priority,
      category: category,
      // Kimlik ve dil **hedef reponun** bağlantısından okunuyor: A reposuna
      // yazılan kayda B bağlantısının sahibini yazmak (sözleşme 1.15) ya da
      // İngilizce bir hub'a Türkçe gövde göndermek aynı hatanın iki yüzü.
      author: ref.read(loginForRepoProvider(slug)),
      // Görev de hedef hub'ını **kendisi** söylüyor (B-139): yanlış hub'a
      // düşerse ancak bu satırla teşhis edilir — bildirimlerdeki gerekçenin
      // aynısı (sözleşme 1.24, L-045).
      repoSlug: slug,
      lang: ref.read(languageForRepoProvider(slug)).valueOrNull ??
          HubLanguage.tr,
    );
    // Taslak **daha üretilirken** damgalanıyor. Damgayı kuyruğa girerken
    // basmak (T-003) ağ hatasında hedefi "kuyruğa alındığı andaki aktif repo"
    // yapıyordu; kullanıcının ekranda gördüğü hedef ise seçtiği repoydu.
    final stamped = slug == null ? draft : draft.forRepo(slug);

    try {
      await ref.read(taskRepoForSlugProvider(slug)).send(stamped);
      await _finishSuccessfully(category, l.addSent);
    } on HubNetworkError {
      // Ağ yokken görev kaybolmaz: kuyruğa alınır, bağlantı gelince gider.
      // Damgalı taslağın damgası korunuyor (L-045).
      await ref.read(outboxProvider.notifier).add(stamped);
      await _finishSuccessfully(category, l.addQueued);
    } on HubError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = l.addUnexpected('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Gönderildi ya da kuyruğa alındı — ikisinde de form temizlenir, çünkü
  /// kullanıcının yazdığı iş kaybolmamıştır.
  Future<void> _finishSuccessfully(String category, String message) async {
    await ref.read(taskCategoriesProvider.notifier).remember(category);
    ref.invalidate(pendingTasksProvider);

    if (!mounted) return;
    _titleCtrl.clear();
    _descCtrl.clear();
    _newCategoryCtrl.clear();
    setState(() => _category = category);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final categories =
        ref.watch(taskCategoriesProvider).valueOrNull ?? Hub.defaultCategories;
    final connections =
        ref.watch(hubConnectionsProvider).valueOrNull ?? const HubConnectionsState();
    final target = (_targetSlug == null
            ? null
            : connections.bySlug(_targetSlug!)) ??
        connections.active;

    return Scaffold(
      appBar: AppBar(title: Text(l.addTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hedef, form alanlarının **üstünde**: "nereye yazıyorum" sorusu
            // "ne yazıyorum"dan önce gelir. Tek bağlantı varken alan hiç
            // çizilmiyor — seçeneksiz bir seçici, karar veriliyormuş izlenimi
            // verir; o durumda hedefi zaten üstteki repo şeridi söylüyor.
            if (connections.length > 1) ...[
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l.addFieldTargetRepo,
                  border: const OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  // `DropdownButtonFormField` değil: değeri dışarıdan
                  // (seçim yoksa aktif repodan) sürülen bir alan, kendi
                  // içinde durum tutmamalı. `FormField` seçimi kendi
                  // sakladığı için, kullanıcı üstteki şeritten repo
                  // değiştirdiğinde alan eski adı göstermeye devam eder ve
                  // gösterilen hedef ile yazılan hedef ayrışırdı.
                  child: DropdownButton<String>(
                    key: AddTaskScreen.targetRepoFieldKey,
                    value: target?.slug,
                    isExpanded: true,
                    items: [
                      for (final c in connections.connections)
                        DropdownMenuItem(
                          value: c.slug,
                          child: Text(c.displayName),
                        ),
                    ],
                    onChanged:
                        _busy ? null : (v) => setState(() => _targetSlug = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              key: AddTaskScreen.titleFieldKey,
              controller: _titleCtrl,
              enabled: !_busy,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.addFieldTitle,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return l.addTitleRequired;
                // Dosya adı slug'dan üretiliyor; hiç harf/rakam yoksa
                // sözleşmeye uygun ad çıkmaz.
                if (slugIsEmpty(value)) return l.addTitleNeedsAlnum;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: AddTaskScreen.descriptionFieldKey,
              controller: _descCtrl,
              enabled: !_busy,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.addFieldDescription,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: InputDecoration(
                labelText: l.addFieldPriority,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final p in Hub.priorities)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: _busy ? null : (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: AddTaskScreen.categoryFieldKey,
              initialValue: _category,
              decoration: InputDecoration(
                labelText: l.addFieldCategory,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c, child: Text(c)),
                DropdownMenuItem(
                  value: AddTaskScreen.newCategoryValue,
                  child: Text(l.addNewCategory),
                ),
              ],
              onChanged: _busy ? null : (v) => setState(() => _category = v!),
            ),
            if (_isNewCategory) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: AddTaskScreen.newCategoryFieldKey,
                controller: _newCategoryCtrl,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: l.addNewCategoryName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => _isNewCategory && (v ?? '').trim().isEmpty
                    ? l.addCategoryRequired
                    : null,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              _InlineError(message: _error!),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: AddTaskScreen.submitKey,
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(l.addSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

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
