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
