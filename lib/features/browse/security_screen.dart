import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../hub/browse_repo.dart';
import '../../hub/hub_language.dart';
import '../../hub/models/hub_doc.dart';
import '../../l10n/app_localizations.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';
import '../common/hub_link_nav.dart';

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
    final l = L.of(context);
    final entries = ref.watch(securityProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.catSecurity)),
      body: switch (entries) {
        AsyncData(:final value) when value.isEmpty => HubEmptyView(
            icon: Icons.shield_outlined,
            title: l.secEmptyTitle,
            subtitle: l.secEmptySubtitle,
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
                  L.of(context).secOpenCount(openCount),
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
              ? HubEmptyView(
                  icon: Icons.filter_alt_off_outlined,
                  title: L.of(context).secFilterEmptyTitle,
                  subtitle: L.of(context).secFilterEmptySubtitle,
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
              label: Text(L.of(context).secFilterAll),
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
                label: Text(kind.labelIn(L.of(context))),
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
          if (kind != null) _Tag(kind.labelIn(L.of(context)), color: muted),
          // Kapalı kayıtta rozet yok: ekranın taşıdığı bilgi "hangileri
          // kapanmadı"; her satıra rozet koymak onu görünmez kılardı.
          if (open) _Tag(L.of(context).secOpenBadge, color: theme.colorScheme.error),
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
            onTapLink: (_, href, __) => openHubLink(
              context,
              href: href,
              fromPath: Hub.securityFile,
            ),
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

/// Güvenlik kaydının türü (sözleşme §12 `Tür` / `Type` alanı).
///
/// Enum adları dosyada geçen **değerler**; etiket arayüzden gelir. İkisi ayrı
/// çünkü değer kayıtta duruyor ve dil değiştirdiğinde geçmiş kayıtlar aynen
/// kalıyor — etiketse okuyanın diline göre değişmeli.
enum SecurityKind {
  tarama(Icons.search, ['tarama', 'scan']),
  onlem(Icons.verified_user_outlined, ['onlem', 'measure']),
  acik(Icons.report_gmailerrorred_outlined, ['acik', 'hole']),
  yapilacak(Icons.build_outlined, ['yapilacak', 'todo']),

  /// Sonuçları kabul edilmiş güvenlik kararı (v1.25). Ne tarama, ne önlem, ne
  /// açık: repoyu public yapmak gibi, geri alınamayan ve sonuçları bilerek
  /// üstlenilen bir seçim. Dördünden birine sıkıştırmak kaydı yanlış
  /// etiketler — SEC-013 tam bu yüzden tanınmıyordu.
  karar(Icons.gavel_outlined, ['karar', 'decision']);

  const SecurityKind(this.icon, this.fileValues);

  final IconData icon;

  /// Dosyada bu türü gösterebilecek değerler — **bütün diller**.
  /// [HubLanguage.allRequestHeadings] ile aynı gerekçe: okurken geniş olmak
  /// bedava, dar olmak kaydı okunamaz kılıyor.
  final List<String> fileValues;

  String labelIn(L l) => switch (this) {
        tarama => l.secKindScan,
        onlem => l.secKindMeasure,
        acik => l.secKindHole,
        yapilacak => l.secKindTodo,
        karar => l.secKindDecision,
      };
}

/// Kayıt gövdesindeki `- **Tür:**` (ya da İngilizce hub'da `- **Type:**`)
/// satırını okur. Dosyada Türkçe karaktersiz yazılıyor — dosya adı kuralıyla
/// aynı gerekçe.
SecurityKind? securityKindOf(KnowledgeEntry entry) {
  final raw = _fieldInAnyLanguage(entry, HubLanguage.allTypeFields);
  if (raw == null) return null;
  for (final kind in SecurityKind.values) {
    if (kind.fileValues.contains(raw)) return kind;
  }
  return null;
}

/// Kapanmamış kayıt mı? `Durum` alanı yoksa kapalı sayılır: alanı olmayan
/// eski kayıtlar yüzünden ekranı yanlış yere "açık" uyarısıyla doldurmamak
/// için. Geçersizleşen kayıt (R-004) hiçbir zaman açık sayılmaz.
bool isSecurityOpen(KnowledgeEntry entry) {
  if (entry.isInvalidated) return false;
  final raw = _fieldInAnyLanguage(entry, HubLanguage.allStatusFields);
  return raw != null && HubLanguage.allOpenValues.contains(raw);
}

/// Alan adı hub diline göre değişiyor; ilk bulunan kazanır.
String? _fieldInAnyLanguage(KnowledgeEntry entry, List<String> names) {
  for (final name in names) {
    final value = entry.field(name);
    if (value != null) return value.toLowerCase();
  }
  return null;
}
