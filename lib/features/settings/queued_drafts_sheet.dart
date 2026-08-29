import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/models/task_draft.dart';
import '../../hub/outbox.dart';
import '../../l10n/app_localizations.dart';

/// Kuyruktaki taslakların listesi — düzenleme ve silme (T-021).
///
/// Kuyruk şimdiye dek yalnız *sayı* olarak görünüyordu; çevrimdışı eklenen
/// görev gönderilene kadar dokunulamaz bir kara kutuydu. Kullanıcının
/// şikâyeti birebir buydu: "eklenen görev (offline'da) değiştirilip
/// silinemiyor". Silme onaylıdır ve taslağın *hiçbir yere yazılmadığını*
/// açıkça söyler — kuyruktan silmek, hub'dan silmek değildir.
class QueuedDraftsSheet extends ConsumerWidget {
  const QueuedDraftsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const QueuedDraftsSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final drafts = ref.watch(outboxProvider).valueOrNull ?? const <TaskDraft>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.queuedDraftsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in drafts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(d.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: d.repoSlug == null
                          ? null
                          : Text(d.repoSlug!,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l.queuedDraftEdit,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edit(context, ref, d),
                          ),
                          IconButton(
                            tooltip: l.queuedDraftDelete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(context, ref, d),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, TaskDraft d) async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.queuedDraftDelete),
        content: Text(l.queuedDraftDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.queuedDraftDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(outboxProvider.notifier).remove(d.fileName);
    messenger.showSnackBar(SnackBar(content: Text(l.queuedDraftDeleted)));
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, TaskDraft d) async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<({String title, String description})>(
      context: context,
      builder: (_) => _EditDraftDialog(draft: d),
    );
    if (result == null) return;
    await ref
        .read(outboxProvider.notifier)
        .replace(d.fileName,
            d.edited(title: result.title, description: result.description));
    messenger.showSnackBar(SnackBar(content: Text(l.queuedDraftSaved)));
  }
}

/// Düzenleme diyaloğu kendi denetleyicilerine sahip: `showDialog` dönüşünde
/// dışarıdan `dispose` etmek, kapanış animasyonu denetleyiciyi hâlâ
/// kullanırken çöp bırakıyordu — testin yakaladığı kusur tam buydu.
class _EditDraftDialog extends StatefulWidget {
  const _EditDraftDialog({required this.draft});

  final TaskDraft draft;

  @override
  State<_EditDraftDialog> createState() => _EditDraftDialogState();
}

class _EditDraftDialogState extends State<_EditDraftDialog> {
  late final _titleCtrl = TextEditingController(text: widget.draft.title);
  late final _descCtrl =
      TextEditingController(text: widget.draft.descriptionFromContent);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AlertDialog(
      title: Text(l.queuedDraftEditTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: l.addFieldTitle),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(labelText: l.addFieldDescription),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return; // başlıksız görev sözleşmede yok
            Navigator.pop(
                context, (title: title, description: _descCtrl.text));
          },
          child: Text(l.queuedDraftEdit),
        ),
      ],
    );
  }
}
