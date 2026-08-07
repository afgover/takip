// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class LTr extends L {
  LTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Takip';

  @override
  String get langSystem => 'Sistem dili';

  @override
  String get langTurkish => 'Türkçe';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageHelp =>
      'Arayüz dili. Hub\'a yazılan görev ve notların dili değişmez — onların biçimi sözleşmeyle sabittir.';

  @override
  String get navPending => 'Bekleyenler';

  @override
  String get navBrowse => 'Tarayıcı';

  @override
  String get navAdd => 'Görev ekle';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navAddShort => 'Ekle';

  @override
  String get browseTitle => 'Hub Tarayıcı';

  @override
  String get catSecurity => 'Security';

  @override
  String get catDone => 'Tamamlananlar';

  @override
  String get catAnnotations => 'İşaretler';

  @override
  String get catSessions => 'Oturumlar';

  @override
  String get catArtifacts => 'Raporlar & Planlar';

  @override
  String get catKnowledge => 'Bilgi tabanı';

  @override
  String get catRoadmap => 'Yol haritası';

  @override
  String get catActivity => 'Aktivite';

  @override
  String get catContract => 'Sözleşme';

  @override
  String get catSourceAllRepos => 'tasks/ · notes/';

  @override
  String get catSourceCommits => 'commit geçmişi';

  @override
  String get sessionsEmptyTitle => 'Oturum kaydı yok';

  @override
  String get sessionsEmptySubtitle =>
      'Agent her çalışma oturumunu buraya yazar.';

  @override
  String get artifactsEmptyTitle => 'Henüz artifact yok';

  @override
  String get artifactsEmptySubtitle =>
      'Agent ürettiği rapor ve planları buraya kaydeder.';

  @override
  String get contractDocTitle => 'Format Sözleşmesi';

  @override
  String get doneEmptyTitle => 'Tamamlanan görev yok';

  @override
  String get doneEmptySubtitle =>
      'Agent bir görevi bitirince burada arşivlenir.';

  @override
  String get pendingEmptyTitle => 'Bekleyen görev yok';

  @override
  String get pendingEmptySubtitle =>
      'Eklediğin görevler agent ele alana kadar burada görünür.';

  @override
  String get pendingFilterEmptyTitle => 'Filtreye uyan görev yok';

  @override
  String pendingFilterEmptySubtitle(int count) {
    return '$count görev var ama hiçbiri seçtiğin filtreye uymuyor.';
  }

  @override
  String get outboxQueuedSubtitle => 'Bağlantı gelince gönderilecek';

  @override
  String get outboxQueuedBadge => 'Gönderilecek';

  @override
  String get onboardingIntro =>
      'Hub reposuna bağlan. Yalnızca bu repoya scope\'lanmış bir fine-grained token kullan.';

  @override
  String get repoFieldInvalid => 'owner/ad biçiminde girin';

  @override
  String get show => 'Göster';

  @override
  String get hide => 'Gizle';

  @override
  String get connect => 'Bağlan';

  @override
  String get tokenHelpTitle => 'Token nasıl alınır?';

  @override
  String get tokenHelpStored =>
      'Token yalnızca bu cihazın güvenli deposunda saklanır.';

  @override
  String get tokenRequired => 'Token gerekli';

  @override
  String get repoFieldLabel => 'Repo (owner/ad)';

  @override
  String get tokenFieldLabel => 'Fine-grained token';

  @override
  String get roadmapTitle => 'Yol Haritası';

  @override
  String get knowledgeTitle => 'Bilgi Tabanı';

  @override
  String get annotationsTitle => 'İşaretler';

  @override
  String statusQueued(int count) {
    return '$count görev gönderilmeyi bekliyor';
  }

  @override
  String get docMalformedFrontmatter =>
      'Bu dosyanın başlık bloğu okunamadı; içerik ham hâliyle gösteriliyor.';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get connectAnyway => 'Yine de bağlan';

  @override
  String get manageRepos => 'Repoları yönet';

  @override
  String queuedTasks(int count) {
    return '$count görev kuyrukta';
  }

  @override
  String queuedTasksWithSlug(String slug, int count) {
    return '$slug · $count görev kuyrukta';
  }

  @override
  String get markYellow => 'Sarı işaretle';

  @override
  String get markRed => 'Kırmızı çizgi';

  @override
  String get markBookmark => 'Yer imi';

  @override
  String get addNote => 'Not ekle';

  @override
  String get createTask => 'Görev oluştur';

  @override
  String get copy => 'Kopyala';

  @override
  String knowledgeEmptyTitle(String label) {
    return '$label boş';
  }

  @override
  String get knowledgeEmptySubtitle =>
      'Agent yeni kayıt ekledikçe burada görünür.';

  @override
  String get knowledgeSuperseded => 'geçersiz kayıt';

  @override
  String get annotationsEmptyTitle => 'Henüz işaret yok';

  @override
  String get annotationsEmptySubtitle =>
      'Bir belgede metin seçip yer imi koyabilir, işaretleyebilir ya da not düşebilirsin. Hepsi burada toplanır.';

  @override
  String get activityHubOnly => 'Yalnız hub kayıtlarını göster';

  @override
  String get activityShowCode => 'Kod commit\'lerini de göster';

  @override
  String get activityEmptyTitle => 'Akış boş';

  @override
  String get activityEmptySubtitle => 'Hub\'a kayıt düştükçe burada görünür.';
}
