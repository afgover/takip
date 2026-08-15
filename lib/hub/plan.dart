import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'browse_repo.dart';
import 'hub_language.dart';

/// Görev ağacı (`hub/PLAN.md`, sözleşme 1.25 §14).
///
/// Ayrıştırıcı `KnowledgeEntry` deseninden ayrı duruyor çünkü buradaki kayıt
/// bir gövde metni değil **ağaç**: adımların birbirine göre derinliği bilginin
/// kendisi ve markdown olarak çizilince o derinlik ekranda filtrelenemez hâle
/// gelirdi.
class Plan {
  const Plan({
    required this.id,
    required this.title,
    required this.fields,
    required this.steps,
  });

  final String id;
  final String title;

  /// Gövdedeki `- **Ad:** değer` satırları. Alan adları hub diline göre değişir
  /// (`Durum`/`Status`), bu yüzden ham hâlleriyle saklanıp okurken her iki dil
  /// de deneniyor — `SECURITY.md` ayrıştırıcısıyla aynı gerekçe.
  final Map<String, String> fields;

  final List<PlanStep> steps;

  String? field(String name) => fields[name.toLowerCase()];

  PlanStatus get status {
    for (final name in HubLanguage.allStatusFields) {
      final raw = field(name)?.toLowerCase();
      if (raw == null) continue;
      for (final value in PlanStatus.values) {
        if (value.fileValues.contains(raw)) return value;
      }
    }
    // Alanı olmayan bir plan açık sayılır: ağacın işi kapanmamış işi görünür
    // kılmak, eksik alan yüzünden bir planı sessizce arşive itmek değil.
    return PlanStatus.acik;
  }

  /// Plan iş bittikten sonra kayıttan **türetildi** mi (sözleşme 1.26 §14)?
  ///
  /// Ekranda ayrı gösteriliyor çünkü ikisi aynı şey değil: önceden yazılmış bir
  /// plan işin nasıl yürütüleceğine dair bir **karar**, türetilmiş bir plan ise
  /// nasıl yürüdüğüne dair bir **kayıt**. İkincisini birincisi gibi göstermek,
  /// hub'ın kendi geçmişini olduğundan planlı gösterirdi.
  ///
  /// Alan yoksa `false`: 1.26 öncesi yazılmış planların hepsi önceden yazılmıştı
  /// (R-008 — yeni alan eski kayıtları bozmaz).
  bool get reconstructed {
    for (final name in _derivedFields) {
      final raw = field(name)?.toLowerCase();
      if (raw == null) continue;
      return raw == 'true' || raw == 'evet' || raw == 'yes';
    }
    return false;
  }

  int get doneCount => steps.where((s) => s.state == PlanStepState.done).length;

  /// İptal edilen adım paydadan düşer: "6/8" derken iki adımın bilerek
  /// yapılmadığını saymak, ilerlemeyi olduğundan az gösterirdi.
  int get plannedCount =>
      steps.where((s) => s.state != PlanStepState.cancelled).length;
}

/// `Türetilmiş:` / `Derived:` — alan adları hub diline göre değişiyor, ikisi de
/// deneniyor (`Durum`/`Status` ile aynı gerekçe).
const _derivedFields = ['türetilmiş', 'turetilmis', 'derived'];

/// Ağacın bir adımı. Derinlik girintiden gelir (iki boşluk = bir seviye).
class PlanStep {
  const PlanStep({
    required this.id,
    required this.title,
    required this.depth,
    required this.state,
    this.note,
  });

  /// `P-001.2.1` — yoksa boş dize (numarasız yazılmış bir satır da gösterilir).
  final String id;
  final String title;
  final int depth;
  final PlanStepState state;

  /// Satırın `·` ayracından sonraki kısmı: tamamlanma tarihi ya da iptal
  /// gerekçesi. Ham markdown olarak duruyor, çizimi ekranın işi.
  final String? note;
}

enum PlanStepState { open, done, cancelled }

enum PlanStatus {
  acik(['acik', 'open']),
  tamamlandi(['tamamlandi', 'completed', 'done']),
  iptal(['iptal', 'cancelled', 'canceled']);

  const PlanStatus(this.fileValues);

  /// Dosyada bu durumu gösterebilecek değerler — **bütün diller**
  /// ([HubLanguage.allRequestHeadings] ile aynı gerekçe: okurken geniş olmak
  /// bedava, dar olmak kaydı okunamaz kılıyor).
  final List<String> fileValues;
}

/// `PLAN.md`'yi planlara ayırır.
///
/// Dosyanın başındaki açıklama metni (ilk `## ` başlığından öncesi) atlanır;
/// sözleşmenin şemasında oraya serbest metin yazılabiliyor.
List<Plan> parsePlans(String source) {
  final plans = <Plan>[];
  final lines = source.split('\n');

  String? id;
  var title = '';
  var fields = <String, String>{};
  var steps = <PlanStep>[];

  void flush() {
    final current = id;
    if (current == null) return;
    plans.add(Plan(id: current, title: title, fields: fields, steps: steps));
    fields = <String, String>{};
    steps = <PlanStep>[];
  }

  for (final line in lines) {
    final heading = _planHeading.firstMatch(line);
    if (heading != null) {
      flush();
      id = heading.group(1)!;
      title = heading.group(2)?.trim() ?? '';
      continue;
    }
    if (id == null) continue;

    final field = _field.firstMatch(line);
    if (field != null) {
      fields[field.group(1)!.trim().toLowerCase()] = field.group(2)!.trim();
      continue;
    }

    final step = _parseStep(line);
    if (step != null) {
      steps.add(step);
      continue;
    }

    // Adım satırının devamı (sarılmış satır) öncekine eklenir: sözleşme
    // örneklerinde uzun adımlar girintili olarak bölünüyor ve bölünen parça
    // ayrı bir adım gibi görünürse ağaç bozulur.
    if (steps.isNotEmpty && line.trim().isNotEmpty && line.startsWith(' ')) {
      final last = steps.removeLast();
      steps.add(PlanStep(
        id: last.id,
        title: '${last.title} ${line.trim()}',
        depth: last.depth,
        state: last.state,
        note: last.note,
      ));
    }
  }
  flush();
  return plans;
}

/// `## P-001 — başlık`
final _planHeading = RegExp(r'^##\s+(P-\d+)\s*[—-]?\s*(.*)$');

/// `- **Durum:** acik`
final _field = RegExp(r'^\s*-\s+\*\*([^:*]+):?\*\*:?\s*(.*)$');

/// `- [x] P-001.1 — başlık · not`
final _stepLine = RegExp(r'^(\s*)-\s+\[( |x|X)\]\s+(.*)$');

/// `P-001.2` ile başlayan gövde.
final _stepId = RegExp(r'^(P-\d+(?:\.\d+)*)\s*[—-]?\s*(.*)$');

PlanStep? _parseStep(String line) {
  final match = _stepLine.firstMatch(line);
  if (match == null) return null;

  final indent = match.group(1)!.length;
  final checked = match.group(2)!.toLowerCase() == 'x';
  var body = match.group(3)!.trim();

  // İptal: kutu boş **ve** başlık üstü çizili (R-004 — iptal edilen adım
  // silinmez). Ayrı bir kutu işareti (`- [-]`) uydurulmadı: markdown'da
  // standart değil, GitHub'da da uygulamada da ham metin olarak görünürdü.
  final struck = _struck.firstMatch(body);
  final cancelled = !checked && struck != null;
  if (struck != null) {
    body = '${struck.group(1)!}${struck.group(2)!}'.trim();
  }

  String? note;
  final separator = body.indexOf('·');
  if (separator >= 0) {
    note = body.substring(separator + 1).trim();
    body = body.substring(0, separator).trim();
  }

  final withId = _stepId.firstMatch(body);
  return PlanStep(
    id: withId?.group(1) ?? '',
    title: (withId?.group(2) ?? body).trim(),
    depth: indent ~/ 2,
    state: cancelled
        ? PlanStepState.cancelled
        : checked
            ? PlanStepState.done
            : PlanStepState.open,
    note: note?.isEmpty ?? true ? null : note,
  );
}

/// `~~üstü çizili~~` — çizgi başlıkta, not dışarıda kalabilir.
final _struck = RegExp(r'^~~(.*?)~~(.*)$');

/// Görev ağacı. **Dosya yoksa boş liste** döner (sözleşme §14/6): `PLAN.md`
/// opsiyoneldir ve olmaması hata değil, henüz çok adımlı bir plan yazılmamış
/// olması demektir. Hata olarak gösterilseydi her hub'da kırmızı bir ekran
/// çıkardı.
/// Tazelenme sinyali `docContentProvider`'dan geliyor: tarayıcının bütün
/// belgeleri zaten oradan okunuyor, ayrı bir okuma yolu açmak aynı dosyanın iki
/// farklı tazelik kuralına bağlanması demek olurdu.
final planProvider = FutureProvider.autoDispose<List<Plan>>((ref) async {
  try {
    return parsePlans(await ref.watch(docContentProvider(Hub.planFile).future));
  } on Object {
    return const [];
  }
});
