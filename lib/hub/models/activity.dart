/// Commit mesajının hangi tür kayda ait olduğu (SYSTEM.md §8).
enum ActivityKind {
  task('Görev'),
  session('Oturum'),
  artifact('Rapor'),
  backlog('Backlog'),
  evolution('Evrim'),
  knowledge('Bilgi'),
  system('Sözleşme'),

  /// Kullanıcının kendi notu (`notes/`, sözleşme 1.9). Ayrı tür: akışta
  /// "agent şunu yaptı" ile "kullanıcı kendine not aldı" karışmamalı.
  note('Not'),

  /// Güvenlik logu kaydı (`SECURITY.md`, sözleşme 1.10).
  security('Güvenlik'),

  /// §8 önekine uymayan commit. K-012'den beri kod ve hub aynı repoda
  /// olduğu için akışta uygulama commit'leri de görünür; ayırt edilebilsin
  /// diye ayrı tür.
  code('Kod');

  const ActivityKind(this.label);

  final String label;

  bool get isHubRecord => this != ActivityKind.code;
}

/// Aktivite akışındaki tek satır (B-045).
///
/// Commit mesajları sözleşmede makine tarafından okunabilir olacak şekilde
/// tanımlı (`task(T-001): active → done`); bu sınıf onları insan diline
/// çevirir ("Agent T-001'i tamamladı").
class ActivityEntry {
  const ActivityEntry({
    required this.kind,
    required this.text,
    required this.sha,
    this.subject,
    this.date,
  });

  factory ActivityEntry.fromCommit({
    required String message,
    required String sha,
    DateTime? date,
  }) {
    final firstLine = message.split('\n').first.trim();
    final match = _prefix.firstMatch(firstLine);

    if (match == null) {
      return ActivityEntry(
        kind: ActivityKind.code,
        text: firstLine,
        sha: sha,
        date: date,
      );
    }

    final kind = _kinds[match.group(1)!];
    if (kind == null) {
      // `feat(B-023): …` gibi kod commit'i. Öneki atmıyoruz: backlog
      // referansı ("hangi madde") bilginin kendisi.
      return ActivityEntry(
        kind: ActivityKind.code,
        text: firstLine,
        sha: sha,
        date: date,
      );
    }

    final subject = match.group(2); // parantez içi: T-001, S-…, A-…
    final rest = match.group(3)!.trim();

    return ActivityEntry(
      kind: kind,
      text: _humanize(kind, subject, rest),
      subject: subject,
      sha: sha,
      date: date,
    );
  }

  final ActivityKind kind;

  /// Ekranda gösterilen cümle.
  final String text;

  /// Varsa kaydın ID'si (`T-001`, `S-2026-…`).
  final String? subject;

  final String sha;
  final DateTime? date;

  static final _prefix = RegExp(r'^(\w+)(?:\(([^)]*)\))?:\s*(.*)$');

  static const _kinds = {
    'task': ActivityKind.task,
    'session': ActivityKind.session,
    'artifact': ActivityKind.artifact,
    'backlog': ActivityKind.backlog,
    'evolution': ActivityKind.evolution,
    'knowledge': ActivityKind.knowledge,
    'system': ActivityKind.system,
    'note': ActivityKind.note,
    'security': ActivityKind.security,
  };

  /// Sözleşmedeki kalıpları gündelik Türkçeye çevirir. Tanımadığı bir kalıpta
  /// mesajı olduğu gibi bırakır — uydurmaktansa ham hâli daha dürüst.
  static String _humanize(ActivityKind kind, String? subject, String rest) {
    final id = subject ?? '';

    switch (kind) {
      case ActivityKind.task:
        if (rest.contains('active → done')) return '$id tamamlandı';
        if (rest.contains('inbox → active')) return '$id ele alındı';
        if (rest.contains("inbox'a eklendi")) {
          return rest.contains('app')
              ? 'Yeni görev eklendi (uygulamadan)'
              : 'Yeni görev eklendi';
        }
        if (rest.contains('not eklendi')) return '$id için not eklendi';
        return id.isEmpty ? rest : '$id: $rest';

      case ActivityKind.session:
        if (rest.contains('açıldı')) return 'Oturum açıldı';
        if (rest.contains('kapandı')) return 'Oturum kapandı';
        return 'Oturum kaydı güncellendi';

      case ActivityKind.artifact:
        return rest.isEmpty ? 'Rapor eklendi' : rest;

      case ActivityKind.backlog:
      case ActivityKind.evolution:
      case ActivityKind.knowledge:
      case ActivityKind.system:
      case ActivityKind.note:
      case ActivityKind.security:
      case ActivityKind.code:
        return rest;
    }
  }
}
