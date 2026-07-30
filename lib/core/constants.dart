/// Hub sözleşmesi (taskr_takip/SYSTEM.md) sabitleri.
abstract final class Hub {
  static const inboxDir = 'tasks/inbox';
  static const activeDir = 'tasks/active';
  static const doneDir = 'tasks/done';
  static const sessionsDir = 'sessions';
  static const artifactsDir = 'artifacts';
  static const knowledgeDir = 'knowledge';
  static const backlogFile = 'BACKLOG.md';
  static const evolutionFile = 'EVOLUTION.md';

  /// K-010: varsayılan kategoriler; kullanıcı serbest değer ekleyebilir.
  static const defaultCategories = [
    'gorev',
    'arastirma',
    'gelistirme',
    'hata',
    'fikir',
  ];

  static const priorities = ['low', 'normal', 'high', 'urgent'];

  /// Foreground polling aralığı (B-024). Ayarlardan değiştirilebilir.
  static const defaultPollInterval = Duration(seconds: 45);
}
