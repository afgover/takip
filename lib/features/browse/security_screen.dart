import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../hub/browse_repo.dart';
import '../../hub/models/hub_doc.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';

/// Güvenlik logu (sözleşme 1.10 §12): taramalar, alınan önlemler, bilinen
/// açıklar ve yapılacak güvenlik işleri.
///
/// Tek bir canlı dosyadan (`hub/SECURITY.md`) okunuyor ve kayıtlar
/// `knowledge/` ile aynı biçimde ayrıştırılıyor. Ayrı bir dosya biçimi
/// uydurmak, aynı "ID'li canlı liste" fikrinin iki yerde ayrışmasına yol
/// açardı.
///
/// **Açık kayıtlar üstte.** Bu ekranın işi bir arşivi güzel göstermek değil,
/// kapanmamış güvenlik işini görünür kılmak; kronolojik sıralama kapanmış on
/// kaydın altına bir açığı gömerdi.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  SecurityKind? _filter;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(securityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: switch (entries) {
        AsyncData(:final value) when value.isEmpty => const HubEmptyView(
            icon: Icons.shield_outlined,
            title: 'Güvenlik kaydı yok',
            subtitle: 'Agent tarama, önlem ve bulguları buraya yazar '
                '(sözleşme §12).',
          ),
        AsyncData(:final value) => _List(
            entries: _ordered(value),
            filter: _filter,
            onFilter: (kind) => setState(() => _filter = kind),
          ),
        AsyncError(:final error) => HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(securityProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  /// Açık kayıtlar önce; her grupta dosyadaki sıra korunur.
  static List<KnowledgeEntry> _ordered(List<KnowledgeEntry> entries) {
    final open = <KnowledgeEntry>[];
    final closed = <KnowledgeEntry>[];
    for (final entry in entries) {
      (isSecurityOpen(entry) ? open : closed).add(entry);
    }
    return [...open, ...closed];
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.entries,
    required this.filter,
    required this.onFilter,
  });

  final List<KnowledgeEntry> entries;
  final SecurityKind? filter;
  final void Function(SecurityKind?) onFilter;

  @override
  Widget build(BuildContext context) {
    final shown = filter == null
        ? entries
        : entries.where((e) => securityKindOf(e) == filter).toList();
    final openCount = entries.where(isSecurityOpen).length;

    return Column(
      children: [
        _Filters(entries: entries, selected: filter, onChanged: onFilter),
        if (openCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    size: 16, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 6),
                Text(
                  '$openCount açık kayıt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: shown.isEmpty
              ? const HubEmptyView(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'Bu türde kayıt yok',
                  subtitle: 'Filtreyi kaldırıp tümünü görebilirsin.',
                )
              : ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _SecurityTile(entry: shown[i]),
                ),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.entries,
    required this.selected,
    required this.onChanged,
  });

  final List<KnowledgeEntry> entries;
  final SecurityKind? selected;
  final void Function(SecurityKind?) onChanged;

  @override
  Widget build(BuildContext context) {
    // Yalnız dosyada gerçekten geçen türler gösteriliyor; boş bir filtre
    // kullanıcıya "burada bir şey var" diye yanlış bilgi verirdi.
    final present = <SecurityKind>[
      for (final kind in SecurityKind.values)
        if (entries.any((e) => securityKindOf(e) == kind)) kind,
    ];
    if (present.length < 2) return const SizedBox(height: 8);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              key: const Key('security-filter-all'),
              label: const Text('Tümü'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final kind in present)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                key: Key('security-filter-${kind.name}'),
                avatar: Icon(kind.icon, size: 16),
                label: Text(kind.label),
                selected: selected == kind,
                onSelected: (_) => onChanged(kind),
              ),
            ),
        ],
      ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({required this.entry});

  final KnowledgeEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final kind = securityKindOf(entry);
    final open = isSecurityOpen(entry);

    return ExpansionTile(
      leading: Icon(
        kind?.icon ?? Icons.shield_outlined,
        color: open ? theme.colorScheme.error : muted,
      ),
      title: Text(
        entry.title,
        style: entry.isInvalidated
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: muted,
              )
            : null,
      ),
      subtitle: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Tag(entry.id, color: theme.colorScheme.primary),
          if (kind != null) _Tag(kind.label, color: muted),
          // Kapalı kayıtta rozet yok: ekranın taşıdığı bilgi "hangileri
          // kapanmadı"; her satıra rozet koymak onu görünmez kılardı.
          if (open) _Tag('açık', color: theme.colorScheme.error),
          if (entry.date != null) _Tag(entry.date!, color: muted),
        ],
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AnnotatedDocument(
            data: entry.body,
            sourcePath: Hub.securityFile,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Güvenlik kaydının türü (sözleşme §12 `Tür` alanı).
enum SecurityKind {
  tarama('Tarama', Icons.search),
  onlem('Önlem', Icons.verified_user_outlined),
  acik('Açık', Icons.report_gmailerrorred_outlined),
  yapilacak('Yapılacak', Icons.build_outlined);

  const SecurityKind(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Kayıt gövdesindeki `- **Tür:**` satırını okur. Dosyada Türkçe karaktersiz
/// yazılıyor (dosya adı kuralıyla aynı gerekçe), ekranda okunabilir hâli
/// gösteriliyor.
SecurityKind? securityKindOf(KnowledgeEntry entry) {
  final raw = entry.field('Tür')?.toLowerCase();
  if (raw == null) return null;
  for (final kind in SecurityKind.values) {
    if (raw == kind.name) return kind;
  }
  return null;
}

/// Kapanmamış kayıt mı? `Durum` alanı yoksa kapalı sayılır: alanı olmayan
/// eski kayıtlar yüzünden ekranı yanlış yere "açık" uyarısıyla doldurmamak
/// için. Geçersizleşen kayıt (R-004) hiçbir zaman açık sayılmaz.
bool isSecurityOpen(KnowledgeEntry entry) {
  if (entry.isInvalidated) return false;
  return entry.field('Durum')?.toLowerCase() == 'acik';
}
