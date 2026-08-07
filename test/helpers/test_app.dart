import 'package:flutter/material.dart';
import 'package:takip/l10n/app_localizations.dart';

/// Testlerde ekran saran `MaterialApp` — **delegelerle birlikte**.
///
/// Neden ortak bir yardımcı: ekranlar `L.of(context)` kullanmaya başladıkça,
/// delegesi olmayan her test "null check operator used on a null value" ile
/// kırılıyor. Hata mesajı çeviriyle ilgisiz göründüğü için her seferinde
/// yeniden teşhis gerekiyor. Daha kötüsü, delege listesini test başına
/// kopyalamak test ortamını uygulamadan **ayırır**: uygulamada olan bir dil
/// ayarı testte olmayabilir ve fark sessizce büyür.
///
/// Tek kaynak: `L.localizationsDelegates` — uygulamanın kendisi de aynısını
/// kullanıyor (`lib/app.dart`).
///
/// **Dil varsayılan olarak Türkçe'ye sabit.** Test ortamının platform dili
/// `en_US` ve desteklenen diller arasında İngilizce de var; sabitlenmezse
/// ekranlar İngilizce çizilir ve Türkçe metin arayan onlarca test, çeviriyle
/// ilgisi yokmuş gibi görünen bir sebeple kırılır. Sabitlemek ayrıca testi
/// koşulduğu makinenin diline bağımlı olmaktan çıkarıyor.
/// İngilizce'yi sınayan test `locale: Locale('en')` verir.
MaterialApp testApp(
  Widget home, {
  Locale locale = const Locale('tr'),
  ThemeData? theme,
}) =>
    MaterialApp(
      locale: locale,
      theme: theme,
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: home,
    );

/// Widget ağacı olmadan çeviriye ulaşmak.
///
/// `describeHubError` gibi saf fonksiyonlar `L`'yi parametre alıyor; testin de
/// dili **açıkça** vermesi gerekiyor. Varsayılan Türkçe — `testApp` ile aynı
/// gerekçe: sabitlenmezse test koşulduğu makinenin diline bağlı olur.
Future<L> testL([Locale locale = const Locale('tr')]) =>
    L.delegate.load(locale);
