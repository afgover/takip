import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../hub/plan.dart';
import '../../l10n/app_localizations.dart';
import '../common/annotated_document.dart';
import '../common/hub_error_view.dart';
import '../common/hub_link_nav.dart';

/// Görev ağacı (sözleşme 1.25 §14): çok adımlı işlerin adımları ve durumu.
///
/// Ekranın işi arşivi güzel göstermek değil, **yarım kalanı** görünür kılmak —
/// `SecurityScreen` ile aynı gerekçe. Bu yüzden açık planlar üstte ve
/// varsayılan filtre "açık": tamamlanmış on planın altına gömülen bir adım,
/// müdahale edilmesi gereken tek şey olabilir.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  PlanStatus? _filter = PlanStatus.acik;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final plans = ref.watch(planProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.catPlan)),
      body: switch (plans) {
        // Dosya yoksa da boş liste gelir (sözleşme §14/6) — hata değil, henüz
        // çok adımlı plan yazılmamış demek.
        AsyncData(:final value) when value.isEmpty => HubEmptyView(
            icon: Icons.account_tree_outlined,
            title: l.planEmptyTitle,
            subtitle: l.planEmptySubtitle,
          ),
        AsyncData(:final value) => _List(
            plans: _ordered(value),
            filter: _filter,
            onFilter: (status) => setState(() => _filter = status),
          ),
        AsyncError(:final error) => HubErrorView(
            error: error,
            onRetry: () => ref.invalidate(planProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  /// Açık planlar önce; her grupta dosyadaki sıra korunur (sözleşme yeni planı
  /// en üste yazdırıyor, yani dosya sırası zaten yeniden eskiye).
  static List<Plan> _ordered(List<Plan> plans) {
    final open = <Plan>[];
    final rest = <Plan>[];
    for (final plan in plans) {
      (plan.status == PlanStatus.acik ? open : rest).add(plan);
    }
    return [...open, ...rest];
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.plans,
    required this.filter,
    required this.onFilter,
  });

  final List<Plan> plans;
  final PlanStatus? filter;
  final void Function(PlanStatus?) onFilter;

  @override
  Widget build(BuildContext context) {
    final shown =
        filter == null ? plans : plans.where((p) => p.status == filter).toList();

    return Column(
      children: [
        _Filters(plans: plans, selected: filter, onChanged: onFilter),
        const Divider(height: 1),
        Expanded(
          child: shown.isEmpty
              ? HubEmptyView(
                  icon: Icons.filter_alt_off_outlined,
                  title: L.of(context).planFilterEmptyTitle,
                  subtitle: L.of(context).planFilterEmptySubtitle,
                )
              : ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _PlanTile(plan: shown[i]),
                ),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.plans,
    required this.selected,
    required this.onChanged,
  });

  final List<Plan> plans;
  final PlanStatus? selected;
  final void Function(PlanStatus?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // Yalnız dosyada gerçekten geçen durumlar (SecurityScreen ile aynı kural:
    // boş bir filtre "burada bir şey var" diye yanlış bilgi verir).
    final present = <PlanStatus>[
      for (final status in PlanStatus.values)
        if (plans.any((p) => p.status == status)) status,
    ];

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              key: const Key('plan-filter-all'),
              label: Text(l.planFilterAll),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final status in present)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                key: Key('plan-filter-${status.name}'),
                label: Text(status.labelIn(l)),
                selected: selected == status,
                onSelected: (_) => onChanged(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final open = plan.status == PlanStatus.acik;

    return ExpansionTile(
      key: Key('plan-${plan.id}'),
      // Açık plan kendiliğinden açılır: ağacın tek işi yarım kalanı
      // göstermekse, onu görmek için bir dokunuş daha istemek ters.
      initiallyExpanded: open,
      leading: Icon(
        open ? Icons.account_tree : Icons.check_circle_outline,
        color: open ? theme.colorScheme.primary : muted,
      ),
      title: Text(plan.title),
      subtitle: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Tag(plan.id, color: theme.colorScheme.primary),
          _Tag(plan.status.labelIn(l), color: open ? theme.colorScheme.primary : muted),
          // Türetilmiş plan ayrı işaretleniyor: önceden yazılmış bir plan
          // karardır, türetilmiş olan kayıttır (sözleşme 1.26 §14).
          if (plan.reconstructed) _Tag(l.planDerived, color: muted),
          if (plan.plannedCount > 0)
            _Tag(
              l.planProgress(plan.doneCount, plan.plannedCount),
              color: muted,
            ),
        ],
      ),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
      children: [
        for (final step in plan.steps) _StepRow(step: step),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final PlanStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final cancelled = step.state == PlanStepState.cancelled;

    final (icon, color) = switch (step.state) {
      PlanStepState.done => (Icons.check_box, theme.colorScheme.primary),
      PlanStepState.open => (Icons.check_box_outline_blank, muted),
      PlanStepState.cancelled => (Icons.disabled_by_default_outlined, muted),
    };

    return Padding(
      // Girinti ağacın kendisi: derinlik bilginin bir parçası, düz bir liste
      // alt adımı ana adımdan ayırt edilemez kılardı.
      padding: EdgeInsets.fromLTRB(8.0 + step.depth * 20, 4, 0, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    if (step.id.isNotEmpty)
                      TextSpan(
                        text: '${step.id} ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    TextSpan(text: step.title),
                  ]),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                    color: cancelled ? muted : null,
                  ),
                ),
                if (step.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AnnotatedDocument(
                      data: step.note!,
                      sourcePath: Hub.planFile,
                      onTapLink: (_, href, __) => openHubLink(
                        context,
                        href: href,
                        fromPath: Hub.planFile,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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

extension _PlanStatusLabel on PlanStatus {
  /// Etiket arayüzden gelir, dosyadaki **değer** çevrilmez — `SecurityKind` ile
  /// aynı ayrım (değer kayıtta durur, etiket okuyanın dilinde).
  String labelIn(L l) => switch (this) {
        PlanStatus.acik => l.planStatusOpen,
        PlanStatus.tamamlandi => l.planStatusCompleted,
        PlanStatus.iptal => l.planStatusCancelled,
      };
}
