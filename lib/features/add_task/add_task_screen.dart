import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/utils.dart';
import '../../hub/categories.dart';
import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../../hub/task_repo.dart';

/// Görev ekleme: başlık, açıklama, öncelik, kategori → `tasks/inbox/` (B-030).
///
/// Kategoriler (K-010): varsayılanlar + daha önce görülenler + serbest giriş.
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  static const titleFieldKey = Key('add-task-title');
  static const descriptionFieldKey = Key('add-task-description');
  static const categoryFieldKey = Key('add-task-category');
  static const newCategoryFieldKey = Key('add-task-new-category');
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

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final category = _effectiveCategory;
    final draft = TaskDraft.create(
      title: _titleCtrl.text,
      description: _descCtrl.text,
      priority: _priority,
      category: category,
    );

    try {
      await ref.read(taskRepoProvider).send(draft);
      await _finishSuccessfully(category, 'Görev hub\'a gönderildi.');
    } on HubNetworkError {
      // Ağ yokken görev kaybolmaz: kuyruğa alınır, bağlantı gelince gider.
      await ref.read(outboxProvider.notifier).add(draft);
      await _finishSuccessfully(
        category,
        'Ağ yok — görev kuyruğa alındı, bağlantı gelince gönderilecek.',
      );
    } on HubError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Beklenmeyen hata: $e');
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
    final categories =
        ref.watch(taskCategoriesProvider).valueOrNull ?? Hub.defaultCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Görev Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: AddTaskScreen.titleFieldKey,
              controller: _titleCtrl,
              enabled: !_busy,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Başlık gerekli';
                // Dosya adı slug'dan üretiliyor; hiç harf/rakam yoksa
                // sözleşmeye uygun ad çıkmaz.
                if (slugIsEmpty(value)) return 'Başlık harf ya da rakam içermeli';
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
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Öncelik',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c, child: Text(c)),
                const DropdownMenuItem(
                  value: AddTaskScreen.newCategoryValue,
                  child: Text('Yeni kategori…'),
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
                decoration: const InputDecoration(
                  labelText: 'Yeni kategori adı',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _isNewCategory && (v ?? '').trim().isEmpty
                    ? 'Kategori adı gerekli'
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
              label: const Text('Hub\'a Gönder'),
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
