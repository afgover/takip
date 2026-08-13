// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class LTr extends L {
  LTr([String locale = 'tr']) : super(locale);

  @override
  String get langTurkish => 'Türkçe';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get navPending => 'Bekleyenler';

  @override
  String get navBrowse => 'Tarayıcı';

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
  String get catPlan => 'Görev ağacı';

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

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get secConnection => 'Bağlantı';

  @override
  String get secPolling => 'Yoklama';

  @override
  String get secOffline => 'Çevrimdışı';

  @override
  String get secData => 'Veri';

  @override
  String get repos => 'Repolar';

  @override
  String reposSubtitle(String name, int count) {
    return '$name · $count repo kayıtlı';
  }

  @override
  String get pollIntervalTitle => 'Kontrol aralığı';

  @override
  String get pollIntervalHelp =>
      'Değişiklik yokken kontroller GitHub istek limitinden düşmez, bu yüzden sık yoklamanın maliyeti yalnız batarya.';

  @override
  String get backup => 'Yedekleme';

  @override
  String get backupSubtitle =>
      'Bağlantıları parolayla şifreli tek metne çevir / geri yükle';

  @override
  String get downloadNow => 'Şimdi indir';

  @override
  String get offlineHelp =>
      'Tarayıcıdaki her şey cihaza indirilir ve hub değiştikçe kendiliğinden güncellenir; ağ yokken de açılır. Yalnızca değişen dosyalar indirilir.';

  @override
  String get trySendNow => 'Şimdi dene';

  @override
  String get clearCache => 'Önbelleği temizle';

  @override
  String get clearCacheSubtitle =>
      'Cihazdaki kopya dahil, her şey yeniden iner';

  @override
  String get resetConnection => 'Bağlantıyı sıfırla';

  @override
  String get resetAllConnections => 'Tüm bağlantıları sıfırla';

  @override
  String get resetScopeOne => 'Bağlantı silinir, onboarding\'e dönülür';

  @override
  String resetScopeAll(int count) {
    return '$count bağlantının tamamı cihazdan silinir';
  }

  @override
  String get resetConfirmOne => 'Bağlantı sıfırlansın mı?';

  @override
  String get resetConfirmAll => 'Bütün bağlantılar sıfırlansın mı?';

  @override
  String resetBody(String scope) {
    return '$scope ve onboarding ekranına dönersin.';
  }

  @override
  String resetBodyQueued(String scope, int count) {
    return '$scope. Kuyrukta bekleyen $count görev gönderilemeden kalır.';
  }

  @override
  String get reset => 'Sıfırla';

  @override
  String get syncChecking => 'Değişiklik aranıyor…';

  @override
  String get syncNever => 'Henüz indirilmedi';

  @override
  String syncFailed(String reason) {
    return 'İndirilemedi — $reason';
  }

  @override
  String syncJustNow(String base) {
    return '$base · az önce güncellendi';
  }

  @override
  String syncMinutes(String base, int n) {
    return '$base · $n dakika önce';
  }

  @override
  String syncHours(String base, int n) {
    return '$base · $n saat önce';
  }

  @override
  String syncDays(String base, int n) {
    return '$base · $n gün önce';
  }

  @override
  String get watchNever => 'Henüz kontrol edilmedi';

  @override
  String get watchJustNow => 'Az önce kontrol edildi';

  @override
  String watchMinutes(int n) {
    return '$n dakika önce kontrol edildi';
  }

  @override
  String watchHours(int n) {
    return '$n saat önce kontrol edildi';
  }

  @override
  String get cacheCleared => 'Temizlendi, yeniden indiriliyor.';

  @override
  String get resetSubtitleOne => 'Token silinir, onboarding\'e dönülür';

  @override
  String resetSubtitleAll(int count) {
    return '$count reponun token\'ı silinir, onboarding\'e dönülür';
  }

  @override
  String get statusTitle => 'Durum';

  @override
  String get offlineCopyTitle => 'Cihazdaki kopya';

  @override
  String syncDownloading(int done, int total) {
    return '$done/$total belge indiriliyor…';
  }

  @override
  String syncDocsDownloaded(int count) {
    return '$count belge indirildi';
  }

  @override
  String intervalSeconds(int n) {
    return '$n saniye';
  }

  @override
  String intervalMinutes(int n) {
    return '$n dakika';
  }

  @override
  String errAuthBody(String message) {
    return '$message\nAyarlardan token\'ı yenileyebilirsin; izinler Contents: Read and write ve Metadata: Read olmalı.';
  }

  @override
  String get errRateTitle => 'İstek limiti doldu';

  @override
  String get errRateBody =>
      'GitHub istek limiti doldu; bir süre sonra kendiliğinden açılır.';

  @override
  String get errNotFoundTitle => 'Bulunamadı';

  @override
  String get errGenericTitle => 'Bir sorun çıktı';

  @override
  String get all => 'Tümü';

  @override
  String get secKindMeasure => 'Önlem';

  @override
  String get secKindTodo => 'Yapılacak';

  @override
  String get secKindScan => 'Tarama';

  @override
  String get kind => 'Tür';

  @override
  String get edit => 'Düzenle';

  @override
  String get remove => 'Kaldır';

  @override
  String get reposHelp =>
      'Her repo kendi token\'ıyla saklanır. Bir token yalnızca kendi reposunu kapsamalı — tek token\'ı bütün repolara yetkilendirmek, telefonu kaybettiğinde kaybın büyümesi demektir.';

  @override
  String removeRepoTitle(String name) {
    return '$name kaldırılsın mı?';
  }

  @override
  String get removeRepoBody => 'Bu reponun token\'ı cihazdan silinir.';

  @override
  String removeRepoQueued(int count) {
    return 'Kuyrukta bu repoya ait $count görev var; repo kaldırılırsa gönderilemezler.';
  }

  @override
  String get removeRepoLast =>
      'Bu son repo — kaldırırsan onboarding ekranına dönersin.';

  @override
  String repoRemoved(String name) {
    return '$name kaldırıldı.';
  }

  @override
  String get identityMissing => 'Kimlik yok — Düzenle\'den yazabilirsin';

  @override
  String get contractUnreadable => 'Sözleşme sürümü okunamadı';

  @override
  String contractStale(String version, String master) {
    return 'Sözleşme $version — ana kopya $master, agent güncellemeli';
  }

  @override
  String contractCurrent(String version) {
    return 'Sözleşme $version';
  }

  @override
  String get connectionUpdated => 'Bağlantı güncellendi.';

  @override
  String get repoAdded => 'Repo eklendi.';

  @override
  String get connectionTitle => 'Bağlantı';

  @override
  String get addRepo => 'Repo ekle';

  @override
  String get repoLocked =>
      'Repo değiştirilemez — yeni repo eklemek için \"Repo ekle\".';

  @override
  String get labelOptional => 'Ad (isteğe bağlı)';

  @override
  String get labelHelp => 'Repo seçicide görünür; boşsa owner/ad gösterilir.';

  @override
  String get identityLabel => 'Kimlik (GitHub kullanıcı adı)';

  @override
  String get identityHelp =>
      'Açtığın görev ve notlara `author` olarak yazılır. Boş bırakırsan token\'dan okunmaya çalışılır.';

  @override
  String get tokenDifferent => 'Farklı token kullan (isteğe bağlı)';

  @override
  String get tokenKeepIfEmpty => 'Yeni token (boş bırakılırsa değişmez)';

  @override
  String get verifyAndSave => 'Doğrula ve kaydet';

  @override
  String get reuseTokenHelp =>
      'Aynı token birden çok repoyu kapsıyorsa yeniden kullan.';

  @override
  String get enterNewToken => 'Yeni token gireceğim';

  @override
  String useTokenOf(String name) {
    return '$name token\'ını kullan';
  }

  @override
  String get token => 'Token';

  @override
  String get tokenRequiredShort => 'Token gerekli.';

  @override
  String get languageFromHub =>
      'Hub dili — `SYSTEM.md` içinde yazılı. Arayüz, sözleşme ve yeni kayıtlar bunu izler; değiştirmek agent\'ın işidir.';

  @override
  String get errSettingsButton => 'Bağlantı ayarları';

  @override
  String get errRetry => 'Yeniden dene';

  @override
  String get errNetworkTitle => 'Bağlantı yok';

  @override
  String get errNetworkBody =>
      'İnternete bağlanılamadı. Eklediğin görevler kuyrukta bekler ve bağlantı gelince kendiliğinden gönderilir.';

  @override
  String get errAuthTitle => 'Token kabul edilmedi';

  @override
  String errRateBodyIn(String left) {
    return 'GitHub istek limiti doldu. $left sonra yeniden denenecek.';
  }

  @override
  String get errUnexpectedTitle => 'Beklenmeyen hata';

  @override
  String get errLeftSoon => 'Birazdan';

  @override
  String errLeftMinutes(int count) {
    return '$count dakika';
  }

  @override
  String errLeftHours(int count) {
    return '$count saat';
  }

  @override
  String get addTitle => 'Görev Ekle';

  @override
  String get addFieldTitle => 'Başlık';

  @override
  String get addTitleRequired => 'Başlık gerekli';

  @override
  String get addTitleNeedsAlnum => 'Başlık harf ya da rakam içermeli';

  @override
  String get addFieldDescription => 'Açıklama';

  @override
  String get addFieldPriority => 'Öncelik';

  @override
  String get addFieldCategory => 'Kategori';

  @override
  String get addNewCategory => 'Yeni kategori…';

  @override
  String get addNewCategoryName => 'Yeni kategori adı';

  @override
  String get addCategoryRequired => 'Kategori adı gerekli';

  @override
  String get addSubmit => 'Hub\'a Gönder';

  @override
  String get addSent => 'Görev hub\'a gönderildi.';

  @override
  String get addQueued =>
      'Ağ yok — görev kuyruğa alındı, bağlantı gelince gönderilecek.';

  @override
  String addUnexpected(String error) {
    return 'Beklenmeyen hata: $error';
  }

  @override
  String get backupTitle => 'Yedekleme';

  @override
  String get backupExportHeading => 'Dışa aktar';

  @override
  String backupExportIntro(int count) {
    return 'Kayıtlı $count bağlantı tek bir metne çevrilir. Metin token\'larını taşıdığı için belirlediğin parolayla şifrelenir — parolasız işe yaramaz.';
  }

  @override
  String get backupPassLabel => 'Yedek parolası';

  @override
  String get backupPassHelp => 'Bunu unutursan yedek işe yaramaz.';

  @override
  String get backupExportButton => 'Yedek oluştur';

  @override
  String get backupCopyButton => 'Panoya kopyala';

  @override
  String get backupCopied => 'Panoya kopyalandı. Parola yöneticine yapıştır.';

  @override
  String get backupCopyWarning =>
      'Bunu parola yöneticine kaydet. Panoda bırakma — pano geçmişi tutan uygulamalar okuyabilir.';

  @override
  String get backupRestoreHeading => 'Geri yükle';

  @override
  String get backupRestoreIntro =>
      'Yedekteki repolar listeye eklenir. Zaten kayıtlı bir repo gelirse token\'ı tazelenir; mevcut bağlantıların silinmez.';

  @override
  String get backupTextLabel => 'Yedek metni';

  @override
  String get backupRestoreButton => 'Geri yükle';

  @override
  String get backupPassTooShort => 'Parola en az 6 karakter olmalı.';

  @override
  String get backupNothingToExport => 'Yedeklenecek bağlantı yok.';

  @override
  String backupExported(int count) {
    return '$count bağlantı yedeklendi.';
  }

  @override
  String backupExportFailed(String error) {
    return 'Yedek alınamadı: $error';
  }

  @override
  String get backupPasteFirst => 'Yedek metnini yapıştır.';

  @override
  String backupRestored(int count) {
    return '$count bağlantı geri yüklendi.';
  }

  @override
  String backupImportFailed(String error) {
    return 'Geri yüklenemedi: $error';
  }

  @override
  String get detailNotHandledYet => 'agent henüz ele almadı';

  @override
  String get detailAnswerSent => 'Cevap gönderildi.';

  @override
  String get detailReported => 'Agent\'a bildirildi.';

  @override
  String get detailQueued => 'Ağ yok — kuyruğa alındı.';

  @override
  String detailUnexpected(String error) {
    return 'Beklenmeyen hata: $error';
  }

  @override
  String waitingForOtherQuestion(String who) {
    return 'Bu soru $who kullanıcısını bekliyor. Cevabı sen de gönderebilirsin.';
  }

  @override
  String waitingForOther(String who) {
    return 'Bu iş $who kullanıcısını bekliyor.';
  }

  @override
  String get waitingQuestion =>
      'Agent bir cevap bekliyor. Seçimini işaretle; istersen açıklama da yazabilirsin.';

  @override
  String get waitingWork =>
      'Bu iş seni bekliyor. Ne beklendiği aşağıdaki notlarda yazılı; yaptıktan sonra agent\'a haber ver.';

  @override
  String get detailMultiHint => 'Birden çok seçebilirsin.';

  @override
  String get detailNoteLabel => 'Açıklama (isteğe bağlı)';

  @override
  String get detailNoteHint => 'Listede olmayan bir durum varsa buraya yaz';

  @override
  String get detailAnswered => 'Cevaplandı';

  @override
  String get detailSendAnswer => 'Cevabı gönder';

  @override
  String get detailReportedShort => 'Bildirildi';

  @override
  String get detailDidIt => 'Yaptım';

  @override
  String get secEmptyTitle => 'Güvenlik kaydı yok';

  @override
  String get secEmptySubtitle =>
      'Agent tarama, önlem ve bulguları buraya yazar (sözleşme §12).';

  @override
  String secOpenCount(int count) {
    return '$count açık kayıt';
  }

  @override
  String get planEmptyTitle => 'Görev ağacı boş';

  @override
  String get planEmptySubtitle =>
      'Agent çok adımlı bir plan yazdığında adımları burada görünür (sözleşme §14).';

  @override
  String get planFilterAll => 'Tümü';

  @override
  String get planFilterEmptyTitle => 'Bu durumda plan yok';

  @override
  String get planFilterEmptySubtitle =>
      'Filtreyi kaldırıp tümünü görebilirsin.';

  @override
  String get planStatusOpen => 'Açık';

  @override
  String get planStatusCompleted => 'Tamamlandı';

  @override
  String get planStatusCancelled => 'İptal';

  @override
  String planProgress(int done, int total) {
    return '$done/$total adım';
  }

  @override
  String get linkOutsideHub =>
      'Bu bağlantı hub dışına gidiyor; uygulama yalnız hub belgelerini açar.';

  @override
  String get secFilterEmptyTitle => 'Bu türde kayıt yok';

  @override
  String get secFilterEmptySubtitle => 'Filtreyi kaldırıp tümünü görebilirsin.';

  @override
  String get secFilterAll => 'Tümü';

  @override
  String get secOpenBadge => 'açık';

  @override
  String get secKindHole => 'Açık';

  @override
  String get kindTask => 'Görev';

  @override
  String get kindComment => 'Yorum';

  @override
  String get kindFix => 'Düzeltme';

  @override
  String get kindDiscussion => 'Tartışma';

  @override
  String get selTitle => 'Seçimden kayıt';

  @override
  String get selMark => 'İşaret';

  @override
  String get selNote => 'Not';

  @override
  String get selNoteHelp =>
      'Boş bırakırsan iş kuyruğuna girmez — işaret/not olarak kalır';

  @override
  String get selHintFix => 'Nesi yanlış, ne olmalı?';

  @override
  String get selHintDiscussion => 'Sorun ne, neyi tartışmak istiyorsun?';

  @override
  String get selHintComment => 'Not olarak ne kalsın?';

  @override
  String get selHintTask => 'Ne yapılsın?';

  @override
  String get selPriority => 'Öncelik';

  @override
  String get selAddAsMark => 'İşaret olarak ekle';

  @override
  String selCreateKind(String kind) {
    return '$kind oluştur';
  }

  @override
  String get selQueuedRecord => 'Ağ yok — kayıt kuyruğa alındı.';

  @override
  String get selQueuedNote => 'Ağ yok — not kuyruğa alındı.';

  @override
  String selUnexpected(String error) {
    return 'Beklenmeyen hata: $error';
  }

  @override
  String get noteBoxTitle => 'Not ekle';

  @override
  String get noteBoxHint => 'Kendine not — agent\'a iş düşmez';

  @override
  String get noteBoxCancel => 'Vazgeç';

  @override
  String get noteBoxAdd => 'Ekle';

  @override
  String get annDeleteNote => 'Notu sil';

  @override
  String get annDeleteMark => 'İşareti sil';

  @override
  String get annNoteDeleted => 'Not silindi.';

  @override
  String get annMarkDeleted => 'İşaret silindi.';

  @override
  String get annAlreadyHandled =>
      'Agent bu kaydı ele almış; işaret hub\'da duruyor.';

  @override
  String get selMarkYellow => 'Sarı';

  @override
  String get selMarkRed => 'Kırmızı';

  @override
  String get selMarkGreen => 'Yeşil';

  @override
  String get selMarkBlue => 'Mavi';

  @override
  String get pendingTitle => 'Bekleyenler';

  @override
  String get pendingRefresh => 'Yenile';

  @override
  String get sortTooltip => 'Sıralama';

  @override
  String get sortWaitingFirst => 'Bekleyenler önce';

  @override
  String get sortByDate => 'Tarihe göre';

  @override
  String get sortByPriority => 'Önceliğe göre';

  @override
  String get sortAscending => 'artan';

  @override
  String get sortDescending => 'azalan';

  @override
  String get detailDoneNoteLabel =>
      'Eklemek istediğin bir şey var mı? (isteğe bağlı)';

  @override
  String get detailDoneNoteHint =>
      'Nasıl yaptığın, çıkan bir aksaklık, agent’ın bilmesi gereken bir şey';

  @override
  String get filterRepo => 'Repo';

  @override
  String get filterCategory => 'Kategori';

  @override
  String get filterPriority => 'Öncelik';

  @override
  String get filterReset => 'Sıfırla';

  @override
  String get filterNone => '(seçenek yok)';
}
