/// Hub sözleşmesi (hub/SYSTEM.md) sabitleri.
/// K-012: takip projesi hub'ını kendi reposunda `hub/` klasöründe barındırır;
/// tüm sözleşme yolları bu önekle kullanılır.
abstract final class Hub {
  static const basePath = 'hub';
  static const inboxDir = '$basePath/tasks/inbox';
  static const activeDir = '$basePath/tasks/active';
  static const doneDir = '$basePath/tasks/done';
  static const sessionsDir = '$basePath/sessions';
  static const artifactsDir = '$basePath/artifacts';
  static const knowledgeDir = '$basePath/knowledge';
  static const backlogFile = '$basePath/BACKLOG.md';
  static const evolutionFile = '$basePath/EVOLUTION.md';

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
