/// Hub sözleşmesi (hub/SYSTEM.md) sabitleri.
/// K-012: takip projesi hub'ını kendi reposunda `hub/` klasöründe barındırır;
/// tüm sözleşme yolları bu önekle kullanılır.
abstract final class Hub {
  static const basePath = 'hub';
  static const inboxDir = '$basePath/tasks/inbox';
  static const activeDir = '$basePath/tasks/active';

  /// Agent'ın kullanıcıdan somut bir şey beklediği görevler (sözleşme 1.4).
  static const waitingDir = '$basePath/tasks/waiting';
  static const doneDir = '$basePath/tasks/done';
  static const sessionsDir = '$basePath/sessions';
  static const artifactsDir = '$basePath/artifacts';
  static const knowledgeDir = '$basePath/knowledge';
  static const backlogFile = '$basePath/BACKLOG.md';
  static const evolutionFile = '$basePath/EVOLUTION.md';

  /// Onboarding'de öneri olarak gelen repo (K-012: kod ve hub aynı repoda).
  static const defaultRepo = 'afgover/takip';

  /// K-010: varsayılan kategoriler; kullanıcı serbest değer ekleyebilir.
  static const defaultCategories = [
    'gorev',
    'arastirma',
    'gelistirme',
    'hata',
    'fikir',
    // v1.5: belgeden seçilerek üretilen kayıtların türleri.
    'yorum',
    'duzeltme',
    'tartisma',
  ];

  /// Sözleşmenin bu uygulamanın bildiği sürümü. Bağlantıların `hub/SYSTEM.md`
  /// sürümü bununla karşılaştırılır (§10).
  static const contractVersion = '1.8';
  static const systemFile = '$basePath/SYSTEM.md';

  static const priorities = ['low', 'normal', 'high', 'urgent'];

  /// Foreground polling aralığı (B-024). Ayarlardan değiştirilebilir.
  static const defaultPollInterval = Duration(seconds: 45);
}
