import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/annotations.dart';
import '../../hub/models/task.dart';
import '../common/hub_error_view.dart';
import 'document_screen.dart';

/// Bütün repolardaki işaretler tek listede (sözleşme 1.12).
///
/// Yer iminin varlık sebebi bu ekran: "burayı sonra bulayım" ancak sonradan
/// bulunabiliyorsa bir işe yarar. Yalnız yer imleri değil **her** işaret
/// burada — kullanıcı bir yeri neyle işaretlediğini hatırlamak zorunda
/// kalmasın; renge göre süzebilir.
class AnnotationsScreen extends ConsumerStatefulWidget {
  const AnnotationsScreen({super.key});

  static const listKey = Key('annotations-list');
  static Key filterKey(TaskMark? mark) =>
      Key('annotations-filter-${mark?.name ?? 'all'}');

  @override
  ConsumerState<AnnotationsScreen> createState() => _AnnotationsScreenState();
}

class _AnnotationsScreenState extends ConsumerState<AnnotationsScreen> {
  TaskMark? _filter;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(allAnnotationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('İşaretler')),
      body: switch (entries) {
        AsyncData(:final value) => _List(
            entries: value,
            filter: _filter,
            onFilter: (mark) => setState(() => _filter = mark),
          ),
        AsyncError(:final error) => HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(allAnnotationsProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.entries,
    required this.filter,
    required this.onFilter,
  });

  final List<AnnotationEntry> entries;
  final TaskMark? filter;
  final ValueChanged<TaskMark?> onFilter;

  @override
  Widget build(BuildContext context) {
    // Süzgeç seçenekleri listede **gerçekten geçen** renklerden türüyor:
    // hiç yer imi yokken "Yer imi" süzgecini göstermek, boş sonuç veren bir
    // düğme sunmak olurdu (B-068'deki kural).
    final present = {for (final e in entries) e.annotation.mark};
    final shown = filter == null
        ? entries
        : entries.where((e) => e.annotation.mark == filter).toList();

    if (entries.isEmpty) {
      return const _Empty();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                key: AnnotationsScreen.filterKey(null),
                label: Text('Hepsi (${entries.length})'),
                selected: filter == null,
                onSelected: (_) => onFilter(null),
              ),
              for (final mark in TaskMark.values)
                if (present.contains(mark))
                  ChoiceChip(
                    key: AnnotationsScreen.filterKey(mark),
                    label: Text(mark.label),
                    selected: filter == mark,
                    onSelected: (_) => onFilter(filter == mark ? null : mark),
                  ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: AnnotationsScreen.listKey,
            padding: const EdgeInsets.all(12),
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _AnnotationCard(entry: shown[index]),
          ),
        ),
      ],
    );
  }
}

class _AnnotationCard extends StatelessWidget {
  const _AnnotationCard({required this.entry});

  final AnnotationEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final annotation = entry.annotation;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Kayıt kendi reposunun belgesini açar; liste çok kaynaklı olduğu için
        // aktif repoya bakmak "bulunamadı" demek olurdu (L-031).
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DocumentScreen(
              path: annotation.sourcePath,
              repoSlug: annotation.repoSlug,
              title: _fileNameOf(annotation.sourcePath),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: markColor(annotation.mark),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.repoLabel,
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(annotation.category, style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                annotation.quote,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (annotation.note != null) ...[
                const SizedBox(height: 6),
                Text(
                  annotation.note!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                annotation.sourcePath,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fileNameOf(String path) => path.split('/').last;
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 48),
            const SizedBox(height: 12),
            Text('Henüz işaret yok', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Bir belgede metin seçip yer imi koyabilir, işaretleyebilir ya '
              'da not düşebilirsin. Hepsi burada toplanır.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Listedeki renk noktası — belgedeki işaret renkleriyle aynı olmalı, yoksa
/// kullanıcı listede gördüğü rengi belgede aramak zorunda kalır.
Color markColor(TaskMark mark) => switch (mark) {
      TaskMark.highlight => const Color(0xFFFFE082),
      TaskMark.underline => const Color(0xFFE57373),
      TaskMark.comment => const Color(0xFFA5D6A7),
      TaskMark.bookmark => const Color(0xFF90CAF9),
    };
