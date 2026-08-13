# Kurallar (rules)

Projede uyulacak kalıcı kurallar. Kayıtlar silinmez; geçersizleşen kural üstü
çizilir ve nedeni yazılır. Biçim: `SYSTEM.md` §5.

---

## R-001 — App'in yazma alanı kapalı: tasks/inbox/ ve notes/
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 tasarım oturumu
- **Açıklama:** ~~Kullanıcı uygulaması hub'da yalnızca `tasks/inbox/`'a dosya
  yazar.~~ Taşıma, düzenleme ve diğer tüm klasörlere yazma agent'ın işidir. Bu,
  izin modelini basit ve öngörülebilir tutar.
  **Genişletme (2026-08-03, sözleşme 1.9, K-029):** yazma alanı ikiye çıktı —
  `tasks/inbox/` (agent'ın iş kuyruğu) ve `notes/` (kullanıcının kendi
  notları). Gerekçe: kullanıcının kendine aldığı not tek yazma alanı yüzünden
  görev olmak zorunda kalıyordu ve agent'ın iş kuyruğunda görünüyordu.
  Kuralın **özü değişmedi**: alan hâlâ kapalı bir küme ve yapısal olarak
  kilitli — app yol değil dosya adı verir, klasörü `HubFolder` enum'undan
  seçer, üçüncü bir klasöre yazması tip düzeyinde imkânsızdır. Silme de aynı
  kapıdan geçer.

## ~~R-002 — Uygulama token'ı yalnızca hub'a scope'lanır~~
- **Tarih:** 2026-07-30 (geçersiz: 2026-07-30, K-012 — bkz. R-005)
- **Kaynak:** Aşama 0, K-002
- **Açıklama:** ~~Token asla kod repolarına erişemez.~~ `takip` özel durumunda
  hub, uygulama reposunun içinde yaşadığı için token bu repoya scope'lanır;
  ayrıntı R-005'te. Diğer projeler için ilke geçerliliğini korur.

## R-003 — Hub'a push'lanmamış kayıt, yapılmamış kayıttır
- **Tarih:** 2026-07-30
- **Kaynak:** AGENT_PROTOCOL.md
- **Açıklama:** Agent'ın ürettiği hiçbir çıktı, hub'a commit'lenip push'lanmadan
  tamamlanmış sayılmaz.

## R-004 — Silme yok, üstü çizme var
- **Tarih:** 2026-07-30
- **Kaynak:** SYSTEM.md
- **Açıklama:** Oturum, artifact, done-görev ve knowledge kayıtları silinmez.
  Geçersizleşen kayıt üstü çizilerek işaretlenir ve gerekçesi eklenir.

## R-005 — Token `takip`e scope'lanır; app'in yazma alanı hub/tasks/inbox/
- **Tarih:** 2026-07-30
- **Kaynak:** K-012
- **Açıklama:** `takip` kendi hub'ını barındırdığı için uygulama token'ı
  "Only select repositories → takip" ile üretilir (`Contents: R&W`,
  `Metadata: R`). Kod ve veri aynı repoda olduğundan token teknik olarak koda
  da yazabilir — bilinçli tercih (K-012); app davranış olarak yalnızca
  `hub/tasks/inbox/`'a yazar (R-001, yol öneki `hub/`). Diğer projelerde ayrı
  `<proje>_takip` repo modeli ve eski scope kuralı geçerlidir.

## R-006 — Token cihaz dışına yalnızca parolayla şifreli yedek olarak çıkar
- **Tarih:** 2026-08-01
- **Kaynak:** S-2026-08-01-token-kaliciligi
- **Açıklama:** R-005 token'ın hiçbir dosyaya ve commit'e yazılmamasını
  söylüyor. Yedekleme özelliği bunun **tek istisnası**dır ve koşulları
  bağlayıcıdır: (1) dışa aktarılan metin PBKDF2 + AES-GCM ile, kullanıcının
  belirlediği parolayla şifrelenir — düz metin dışa aktarma eklenmez;
  (2) yedek hiçbir yere kendiliğinden yazılmaz (dosya yok, ağ yok), yalnız
  ekranda gösterilir ve kullanıcı isterse panoya alır; (3) ekranda, metnin
  token taşıdığı ve parola yöneticisine konması gerektiği açıkça söylenir.
  Gerekçe: çok repolu kurulumda veri kaybı sonrası token'ları tek tek yeniden
  girmek sistemi kullanılamaz kılıyordu; ama kolaylık, token'ı korumasız bir
  dizeye çevirmeyi haklı çıkarmaz.

## R-007 — Yer imi hiçbir koşulda görev olmaz
- **Tarih:** 2026-08-04
- **Kaynak:** Sözleşme 1.12 §4, T-008
- **Açıklama:** `mark: bookmark` taşıyan kayıt her zaman `notes/`a yazılır,
  not yazılmış olsa bile. Diğer işaretlerde ayrımı notun varlığı yapar
  (notsuz → `notes/`, notlu → `tasks/inbox/`, B-099); yer iminde niyet zaten
  adındadır: "burayı sonra bulayım". Bir yer imine düşülen not da kullanıcının
  kendine bıraktığı işarettir, agent'a verilmiş bir iş değil.
  Kural kodda tek yerde duruyor (`TaskMark.canBecomeTask`) ve karar noktası
  `AnnotatedDocument._create`'tir — R-001'in yazma alanı kısıtı değişmedi,
  yalnız hangi alana gidileceği bu kuralla belirleniyor.

## R-008 — Sözleşme public: kırıcı değişiklik artık serbest değil
- **Tarih:** 2026-08-13
- **Kaynak:** B-097, T-011, S-2026-08-13-durum-ozeti
- **Açıklama:** `afgover/takip` 2026-08-13'te public oldu ve §10 zinciri
  ölçülerek doğrulandı: başka hub'ların agent'ları
  `raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.md`'yi çekip kendi
  kopyalarını buna göre güncelliyor. Bugüne kadar sözleşme bir günde
  1.8 → 1.11, sonra 1.11 → 1.17 gidebiliyordu; bunu mümkün kılan şey
  kimsenin bağlı olmamasıydı ve **o şart bitti**.
  Bundan sonra sözleşme değişikliği için: (1) mevcut kayıtları geçersiz kılan
  bir değişiklik yapılmaz — yeni alan **isteğe bağlı** eklenir, eski biçim
  okunmaya devam eder; (2) zorunlu hâle gelmesi gereken bir alan varsa önce
  isteğe bağlı olarak girer, geçiş `SYSTEM.md` §13'e **geçici madde** olarak
  yazılır (kalkma koşuluyla birlikte); (3) sürüm numarası her değişiklikte
  artar — uzaktaki hub'ın tek karşılaştırma ölçütü o.
  Gerekçe teknik değil sosyal: ana kopyayı çeken agent, çektiği şeyin kendi
  hub'ını bozmayacağına güveniyor. Bu güven kırıldığında bozulan tek şey bir
  dosya değil, §10 zincirinin kendisi olur — bir kez kötü güncelleme yiyen
  hub'ın sahibi kontrolü kapatır.
