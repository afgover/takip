import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takip'**
  String get appTitle;

  /// No description provided for @langSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem dili'**
  String get langSystem;

  /// No description provided for @langTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get langTurkish;

  /// No description provided for @langEnglish.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @settingsLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHelp.
  ///
  /// In tr, this message translates to:
  /// **'Arayüz dili. Hub\'a yazılan görev ve notların dili değişmez — onların biçimi sözleşmeyle sabittir.'**
  String get settingsLanguageHelp;

  /// No description provided for @navPending.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyenler'**
  String get navPending;

  /// No description provided for @navBrowse.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcı'**
  String get navBrowse;

  /// No description provided for @navAdd.
  ///
  /// In tr, this message translates to:
  /// **'Görev ekle'**
  String get navAdd;

  /// No description provided for @navSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get navSettings;

  /// No description provided for @navAddShort.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get navAddShort;

  /// No description provided for @browseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hub Tarayıcı'**
  String get browseTitle;

  /// No description provided for @catSecurity.
  ///
  /// In tr, this message translates to:
  /// **'Security'**
  String get catSecurity;

  /// No description provided for @catDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananlar'**
  String get catDone;

  /// No description provided for @catAnnotations.
  ///
  /// In tr, this message translates to:
  /// **'İşaretler'**
  String get catAnnotations;

  /// No description provided for @catSessions.
  ///
  /// In tr, this message translates to:
  /// **'Oturumlar'**
  String get catSessions;

  /// No description provided for @catArtifacts.
  ///
  /// In tr, this message translates to:
  /// **'Raporlar & Planlar'**
  String get catArtifacts;

  /// No description provided for @catKnowledge.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi tabanı'**
  String get catKnowledge;

  /// No description provided for @catRoadmap.
  ///
  /// In tr, this message translates to:
  /// **'Yol haritası'**
  String get catRoadmap;

  /// No description provided for @catActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite'**
  String get catActivity;

  /// No description provided for @catContract.
  ///
  /// In tr, this message translates to:
  /// **'Sözleşme'**
  String get catContract;

  /// No description provided for @catSourceAllRepos.
  ///
  /// In tr, this message translates to:
  /// **'tasks/ · notes/'**
  String get catSourceAllRepos;

  /// No description provided for @catSourceCommits.
  ///
  /// In tr, this message translates to:
  /// **'commit geçmişi'**
  String get catSourceCommits;

  /// No description provided for @sessionsEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oturum kaydı yok'**
  String get sessionsEmptyTitle;

  /// No description provided for @sessionsEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Agent her çalışma oturumunu buraya yazar.'**
  String get sessionsEmptySubtitle;

  /// No description provided for @artifactsEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz artifact yok'**
  String get artifactsEmptyTitle;

  /// No description provided for @artifactsEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Agent ürettiği rapor ve planları buraya kaydeder.'**
  String get artifactsEmptySubtitle;

  /// No description provided for @contractDocTitle.
  ///
  /// In tr, this message translates to:
  /// **'Format Sözleşmesi'**
  String get contractDocTitle;

  /// No description provided for @doneEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan görev yok'**
  String get doneEmptyTitle;

  /// No description provided for @doneEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Agent bir görevi bitirince burada arşivlenir.'**
  String get doneEmptySubtitle;

  /// No description provided for @pendingEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen görev yok'**
  String get pendingEmptyTitle;

  /// No description provided for @pendingEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Eklediğin görevler agent ele alana kadar burada görünür.'**
  String get pendingEmptySubtitle;

  /// No description provided for @pendingFilterEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Filtreye uyan görev yok'**
  String get pendingFilterEmptyTitle;

  /// No description provided for @pendingFilterEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} görev var ama hiçbiri seçtiğin filtreye uymuyor.'**
  String pendingFilterEmptySubtitle(int count);

  /// No description provided for @outboxQueuedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı gelince gönderilecek'**
  String get outboxQueuedSubtitle;

  /// No description provided for @outboxQueuedBadge.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilecek'**
  String get outboxQueuedBadge;

  /// No description provided for @onboardingIntro.
  ///
  /// In tr, this message translates to:
  /// **'Hub reposuna bağlan. Yalnızca bu repoya scope\'lanmış bir fine-grained token kullan.'**
  String get onboardingIntro;

  /// No description provided for @repoFieldInvalid.
  ///
  /// In tr, this message translates to:
  /// **'owner/ad biçiminde girin'**
  String get repoFieldInvalid;

  /// No description provided for @show.
  ///
  /// In tr, this message translates to:
  /// **'Göster'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In tr, this message translates to:
  /// **'Gizle'**
  String get hide;

  /// No description provided for @connect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get connect;

  /// No description provided for @tokenHelpTitle.
  ///
  /// In tr, this message translates to:
  /// **'Token nasıl alınır?'**
  String get tokenHelpTitle;

  /// No description provided for @tokenHelpStored.
  ///
  /// In tr, this message translates to:
  /// **'Token yalnızca bu cihazın güvenli deposunda saklanır.'**
  String get tokenHelpStored;

  /// No description provided for @tokenRequired.
  ///
  /// In tr, this message translates to:
  /// **'Token gerekli'**
  String get tokenRequired;

  /// No description provided for @repoFieldLabel.
  ///
  /// In tr, this message translates to:
  /// **'Repo (owner/ad)'**
  String get repoFieldLabel;

  /// No description provided for @tokenFieldLabel.
  ///
  /// In tr, this message translates to:
  /// **'Fine-grained token'**
  String get tokenFieldLabel;

  /// No description provided for @roadmapTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yol Haritası'**
  String get roadmapTitle;

  /// No description provided for @knowledgeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi Tabanı'**
  String get knowledgeTitle;

  /// No description provided for @annotationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşaretler'**
  String get annotationsTitle;

  /// No description provided for @statusQueued.
  ///
  /// In tr, this message translates to:
  /// **'{count} görev gönderilmeyi bekliyor'**
  String statusQueued(int count);

  /// No description provided for @docMalformedFrontmatter.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosyanın başlık bloğu okunamadı; içerik ham hâliyle gösteriliyor.'**
  String get docMalformedFrontmatter;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @connectAnyway.
  ///
  /// In tr, this message translates to:
  /// **'Yine de bağlan'**
  String get connectAnyway;

  /// No description provided for @manageRepos.
  ///
  /// In tr, this message translates to:
  /// **'Repoları yönet'**
  String get manageRepos;

  /// No description provided for @queuedTasks.
  ///
  /// In tr, this message translates to:
  /// **'{count} görev kuyrukta'**
  String queuedTasks(int count);

  /// No description provided for @queuedTasksWithSlug.
  ///
  /// In tr, this message translates to:
  /// **'{slug} · {count} görev kuyrukta'**
  String queuedTasksWithSlug(String slug, int count);

  /// No description provided for @markYellow.
  ///
  /// In tr, this message translates to:
  /// **'Sarı işaretle'**
  String get markYellow;

  /// No description provided for @markRed.
  ///
  /// In tr, this message translates to:
  /// **'Kırmızı çizgi'**
  String get markRed;

  /// No description provided for @markBookmark.
  ///
  /// In tr, this message translates to:
  /// **'Yer imi'**
  String get markBookmark;

  /// No description provided for @addNote.
  ///
  /// In tr, this message translates to:
  /// **'Not ekle'**
  String get addNote;

  /// No description provided for @createTask.
  ///
  /// In tr, this message translates to:
  /// **'Görev oluştur'**
  String get createTask;

  /// No description provided for @copy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// No description provided for @knowledgeEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'{label} boş'**
  String knowledgeEmptyTitle(String label);

  /// No description provided for @knowledgeEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Agent yeni kayıt ekledikçe burada görünür.'**
  String get knowledgeEmptySubtitle;

  /// No description provided for @knowledgeSuperseded.
  ///
  /// In tr, this message translates to:
  /// **'geçersiz kayıt'**
  String get knowledgeSuperseded;

  /// No description provided for @annotationsEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz işaret yok'**
  String get annotationsEmptyTitle;

  /// No description provided for @annotationsEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir belgede metin seçip yer imi koyabilir, işaretleyebilir ya da not düşebilirsin. Hepsi burada toplanır.'**
  String get annotationsEmptySubtitle;

  /// No description provided for @activityHubOnly.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız hub kayıtlarını göster'**
  String get activityHubOnly;

  /// No description provided for @activityShowCode.
  ///
  /// In tr, this message translates to:
  /// **'Kod commit\'lerini de göster'**
  String get activityShowCode;

  /// No description provided for @activityEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Akış boş'**
  String get activityEmptyTitle;

  /// No description provided for @activityEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hub\'a kayıt düştükçe burada görünür.'**
  String get activityEmptySubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @secConnection.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı'**
  String get secConnection;

  /// No description provided for @secPolling.
  ///
  /// In tr, this message translates to:
  /// **'Yoklama'**
  String get secPolling;

  /// No description provided for @secOffline.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı'**
  String get secOffline;

  /// No description provided for @secData.
  ///
  /// In tr, this message translates to:
  /// **'Veri'**
  String get secData;

  /// No description provided for @repos.
  ///
  /// In tr, this message translates to:
  /// **'Repolar'**
  String get repos;

  /// No description provided for @reposSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} · {count} repo kayıtlı'**
  String reposSubtitle(String name, int count);

  /// No description provided for @pollIntervalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol aralığı'**
  String get pollIntervalTitle;

  /// No description provided for @pollIntervalHelp.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklik yokken kontroller GitHub istek limitinden düşmez, bu yüzden sık yoklamanın maliyeti yalnız batarya.'**
  String get pollIntervalHelp;

  /// No description provided for @backup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme'**
  String get backup;

  /// No description provided for @backupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıları parolayla şifreli tek metne çevir / geri yükle'**
  String get backupSubtitle;

  /// No description provided for @downloadNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi indir'**
  String get downloadNow;

  /// No description provided for @offlineHelp.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıdaki her şey cihaza indirilir ve hub değiştikçe kendiliğinden güncellenir; ağ yokken de açılır. Yalnızca değişen dosyalar indirilir.'**
  String get offlineHelp;

  /// No description provided for @trySendNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi dene'**
  String get trySendNow;

  /// No description provided for @clearCache.
  ///
  /// In tr, this message translates to:
  /// **'Önbelleği temizle'**
  String get clearCache;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Cihazdaki kopya dahil, her şey yeniden iner'**
  String get clearCacheSubtitle;

  /// No description provided for @resetConnection.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı sıfırla'**
  String get resetConnection;

  /// No description provided for @resetAllConnections.
  ///
  /// In tr, this message translates to:
  /// **'Tüm bağlantıları sıfırla'**
  String get resetAllConnections;

  /// No description provided for @resetScopeOne.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı silinir, onboarding\'e dönülür'**
  String get resetScopeOne;

  /// No description provided for @resetScopeAll.
  ///
  /// In tr, this message translates to:
  /// **'{count} bağlantının tamamı cihazdan silinir'**
  String resetScopeAll(int count);

  /// No description provided for @resetConfirmOne.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı sıfırlansın mı?'**
  String get resetConfirmOne;

  /// No description provided for @resetConfirmAll.
  ///
  /// In tr, this message translates to:
  /// **'Bütün bağlantılar sıfırlansın mı?'**
  String get resetConfirmAll;

  /// No description provided for @resetBody.
  ///
  /// In tr, this message translates to:
  /// **'{scope} ve onboarding ekranına dönersin.'**
  String resetBody(String scope);

  /// No description provided for @resetBodyQueued.
  ///
  /// In tr, this message translates to:
  /// **'{scope}. Kuyrukta bekleyen {count} görev gönderilemeden kalır.'**
  String resetBodyQueued(String scope, int count);

  /// No description provided for @reset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get reset;

  /// No description provided for @syncChecking.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklik aranıyor…'**
  String get syncChecking;

  /// No description provided for @syncNever.
  ///
  /// In tr, this message translates to:
  /// **'Henüz indirilmedi'**
  String get syncNever;

  /// No description provided for @syncFailed.
  ///
  /// In tr, this message translates to:
  /// **'İndirilemedi — {reason}'**
  String syncFailed(String reason);

  /// No description provided for @syncJustNow.
  ///
  /// In tr, this message translates to:
  /// **'{base} · az önce güncellendi'**
  String syncJustNow(String base);

  /// No description provided for @syncMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{base} · {n} dakika önce'**
  String syncMinutes(String base, int n);

  /// No description provided for @syncHours.
  ///
  /// In tr, this message translates to:
  /// **'{base} · {n} saat önce'**
  String syncHours(String base, int n);

  /// No description provided for @syncDays.
  ///
  /// In tr, this message translates to:
  /// **'{base} · {n} gün önce'**
  String syncDays(String base, int n);

  /// No description provided for @watchNever.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kontrol edilmedi'**
  String get watchNever;

  /// No description provided for @watchJustNow.
  ///
  /// In tr, this message translates to:
  /// **'Az önce kontrol edildi'**
  String get watchJustNow;

  /// No description provided for @watchMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{n} dakika önce kontrol edildi'**
  String watchMinutes(int n);

  /// No description provided for @watchHours.
  ///
  /// In tr, this message translates to:
  /// **'{n} saat önce kontrol edildi'**
  String watchHours(int n);

  /// No description provided for @cacheCleared.
  ///
  /// In tr, this message translates to:
  /// **'Temizlendi, yeniden indiriliyor.'**
  String get cacheCleared;

  /// No description provided for @resetSubtitleOne.
  ///
  /// In tr, this message translates to:
  /// **'Token silinir, onboarding\'e dönülür'**
  String get resetSubtitleOne;

  /// No description provided for @resetSubtitleAll.
  ///
  /// In tr, this message translates to:
  /// **'{count} reponun token\'ı silinir, onboarding\'e dönülür'**
  String resetSubtitleAll(int count);

  /// No description provided for @statusTitle.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get statusTitle;

  /// No description provided for @offlineCopyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cihazdaki kopya'**
  String get offlineCopyTitle;

  /// No description provided for @syncDownloading.
  ///
  /// In tr, this message translates to:
  /// **'{done}/{total} belge indiriliyor…'**
  String syncDownloading(int done, int total);

  /// No description provided for @syncDocsDownloaded.
  ///
  /// In tr, this message translates to:
  /// **'{count} belge indirildi'**
  String syncDocsDownloaded(int count);

  /// No description provided for @intervalSeconds.
  ///
  /// In tr, this message translates to:
  /// **'{n} saniye'**
  String intervalSeconds(int n);

  /// No description provided for @intervalMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{n} dakika'**
  String intervalMinutes(int n);

  /// No description provided for @connectionSettings.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı ayarları'**
  String get connectionSettings;

  /// No description provided for @errNoConnectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı yok'**
  String get errNoConnectionTitle;

  /// No description provided for @errNoConnectionBody.
  ///
  /// In tr, this message translates to:
  /// **'İnternete bağlanılamadı. Eklediğin görevler kuyrukta bekler ve bağlantı gelince kendiliğinden gönderilir.'**
  String get errNoConnectionBody;

  /// No description provided for @errAuthBody.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar\'dan token\'ı yenileyebilirsin; izinler Contents: Read and write ve Metadata: Read olmalı.'**
  String get errAuthBody;

  /// No description provided for @errRateTitle.
  ///
  /// In tr, this message translates to:
  /// **'İstek limiti doldu'**
  String get errRateTitle;

  /// No description provided for @errRateBody.
  ///
  /// In tr, this message translates to:
  /// **'GitHub istek limiti doldu; bir süre sonra kendiliğinden açılır.'**
  String get errRateBody;

  /// No description provided for @errNotFoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bulunamadı'**
  String get errNotFoundTitle;

  /// No description provided for @errGenericTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir sorun çıktı'**
  String get errGenericTitle;

  /// No description provided for @addTaskTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görev Ekle'**
  String get addTaskTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get fieldTitle;

  /// No description provided for @titleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlık gerekli'**
  String get titleRequired;

  /// No description provided for @titleNeedsLetter.
  ///
  /// In tr, this message translates to:
  /// **'Başlık harf ya da rakam içermeli'**
  String get titleNeedsLetter;

  /// No description provided for @fieldDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get fieldDescription;

  /// No description provided for @fieldPriority.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get fieldPriority;

  /// No description provided for @newCategoryName.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kategori adı'**
  String get newCategoryName;

  /// No description provided for @categoryRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kategori adı gerekli'**
  String get categoryRequired;

  /// No description provided for @sendToInbox.
  ///
  /// In tr, this message translates to:
  /// **'Inbox\'a Gönder'**
  String get sendToInbox;

  /// No description provided for @taskQueuedOffline.
  ///
  /// In tr, this message translates to:
  /// **'Ağ yok — görev kuyruğa alındı, bağlantı gelince gönderilecek.'**
  String get taskQueuedOffline;

  /// No description provided for @securityEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik kaydı yok'**
  String get securityEmptyTitle;

  /// No description provided for @securityEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Agent tarama, önlem ve bulguları buraya yazar (sözleşme §12).'**
  String get securityEmptySubtitle;

  /// No description provided for @securityOpenCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} açık kayıt'**
  String securityOpenCount(int count);

  /// No description provided for @securityFilterEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu türde kayıt yok'**
  String get securityFilterEmptyTitle;

  /// No description provided for @securityFilterEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Filtreyi kaldırıp tümünü görebilirsin.'**
  String get securityFilterEmptySubtitle;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// No description provided for @securityOpen.
  ///
  /// In tr, this message translates to:
  /// **'açık'**
  String get securityOpen;

  /// No description provided for @secKindMeasure.
  ///
  /// In tr, this message translates to:
  /// **'Önlem'**
  String get secKindMeasure;

  /// No description provided for @secKindOpen.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get secKindOpen;

  /// No description provided for @secKindTodo.
  ///
  /// In tr, this message translates to:
  /// **'Yapılacak'**
  String get secKindTodo;

  /// No description provided for @secKindScan.
  ///
  /// In tr, this message translates to:
  /// **'Tarama'**
  String get secKindScan;

  /// No description provided for @kind.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get kind;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get remove;

  /// No description provided for @reposHelp.
  ///
  /// In tr, this message translates to:
  /// **'Her repo kendi token\'ıyla saklanır. Bir token yalnızca kendi reposunu kapsamalı — tek token\'ı bütün repolara yetkilendirmek, telefonu kaybettiğinde kaybın büyümesi demektir.'**
  String get reposHelp;

  /// No description provided for @removeRepoTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} kaldırılsın mı?'**
  String removeRepoTitle(String name);

  /// No description provided for @removeRepoBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu reponun token\'ı cihazdan silinir.'**
  String get removeRepoBody;

  /// No description provided for @removeRepoQueued.
  ///
  /// In tr, this message translates to:
  /// **'Kuyrukta bu repoya ait {count} görev var; repo kaldırılırsa gönderilemezler.'**
  String removeRepoQueued(int count);

  /// No description provided for @removeRepoLast.
  ///
  /// In tr, this message translates to:
  /// **'Bu son repo — kaldırırsan onboarding ekranına dönersin.'**
  String get removeRepoLast;

  /// No description provided for @repoRemoved.
  ///
  /// In tr, this message translates to:
  /// **'{name} kaldırıldı.'**
  String repoRemoved(String name);

  /// No description provided for @identityMissing.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik yok — Düzenle\'den yazabilirsin'**
  String get identityMissing;

  /// No description provided for @contractUnreadable.
  ///
  /// In tr, this message translates to:
  /// **'Sözleşme sürümü okunamadı'**
  String get contractUnreadable;

  /// No description provided for @contractStale.
  ///
  /// In tr, this message translates to:
  /// **'Sözleşme {version} — ana kopya {master}, agent güncellemeli'**
  String contractStale(String version, String master);

  /// No description provided for @contractCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Sözleşme {version}'**
  String contractCurrent(String version);

  /// No description provided for @connectionUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı güncellendi.'**
  String get connectionUpdated;

  /// No description provided for @repoAdded.
  ///
  /// In tr, this message translates to:
  /// **'Repo eklendi.'**
  String get repoAdded;

  /// No description provided for @connectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı'**
  String get connectionTitle;

  /// No description provided for @addRepo.
  ///
  /// In tr, this message translates to:
  /// **'Repo ekle'**
  String get addRepo;

  /// No description provided for @repoLocked.
  ///
  /// In tr, this message translates to:
  /// **'Repo değiştirilemez — yeni repo eklemek için \"Repo ekle\".'**
  String get repoLocked;

  /// No description provided for @labelOptional.
  ///
  /// In tr, this message translates to:
  /// **'Ad (isteğe bağlı)'**
  String get labelOptional;

  /// No description provided for @labelHelp.
  ///
  /// In tr, this message translates to:
  /// **'Repo seçicide görünür; boşsa owner/ad gösterilir.'**
  String get labelHelp;

  /// No description provided for @identityLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik (GitHub kullanıcı adı)'**
  String get identityLabel;

  /// No description provided for @identityHelp.
  ///
  /// In tr, this message translates to:
  /// **'Açtığın görev ve notlara `author` olarak yazılır. Boş bırakırsan token\'dan okunmaya çalışılır.'**
  String get identityHelp;

  /// No description provided for @tokenDifferent.
  ///
  /// In tr, this message translates to:
  /// **'Farklı token kullan (isteğe bağlı)'**
  String get tokenDifferent;

  /// No description provided for @tokenKeepIfEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Yeni token (boş bırakılırsa değişmez)'**
  String get tokenKeepIfEmpty;

  /// No description provided for @verifyAndSave.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula ve kaydet'**
  String get verifyAndSave;

  /// No description provided for @reuseTokenHelp.
  ///
  /// In tr, this message translates to:
  /// **'Aynı token birden çok repoyu kapsıyorsa yeniden kullan.'**
  String get reuseTokenHelp;

  /// No description provided for @enterNewToken.
  ///
  /// In tr, this message translates to:
  /// **'Yeni token gireceğim'**
  String get enterNewToken;

  /// No description provided for @useTokenOf.
  ///
  /// In tr, this message translates to:
  /// **'{name} token\'ını kullan'**
  String useTokenOf(String name);

  /// No description provided for @token.
  ///
  /// In tr, this message translates to:
  /// **'Token'**
  String get token;

  /// No description provided for @tokenRequiredShort.
  ///
  /// In tr, this message translates to:
  /// **'Token gerekli.'**
  String get tokenRequiredShort;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'tr':
      return LTr();
  }

  throw FlutterError(
      'L.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
