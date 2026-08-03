# SECURITY.md — Güvenlik Logu

Bu projede güvenliğe dair yapılan taramalar, alınan önlemler, bilinen açıklar
ve yapılması gereken işler. Biçim ve kurallar: `SYSTEM.md` §12.

**Sır yazılmaz.** Kayıtlar neyin korunduğunu anlatır, korunan şeyin kendisini
değil. Token, parola veya anahtar bu dosyada hiçbir koşulda yer almaz.

---

## SEC-001 — Token yalnızca cihazın güvenli deposunda tutulur
- **Tarih:** 2026-07-30
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** R-005, Aşama 0 tasarım oturumu
- **Açıklama:** GitHub token'ı `flutter_secure_storage` üzerinden saklanır
  (Android'de Keystore destekli). Token dosyaya, commit'e, log'a ve hata
  mesajına yazılmaz; kaynak kodda ya da hub'da hiçbir kopyası yoktur.
  Kullanıcı token'ı doğrudan cihaza girer — geliştirme sohbetine, ekran
  görüntüsüne veya repoya hiç girmez.

## SEC-002 — Token dışa yalnızca parolayla şifreli yedek olarak çıkar
- **Tarih:** 2026-08-01
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** R-006, K-019, S-2026-08-01-token-kaliciligi
- **Açıklama:** Bağlantı yedeği PBKDF2-HMAC-SHA256 (150.000 tur) ile türetilen
  anahtarla AES-GCM kullanılarak şifrelenir. Düz metin token dışa aktarımı
  **yok** — kullanıcı istese de eklenmez, çünkü yedek metni panoya, e-postaya
  ve yedeklenen dosya sistemine düşen bir şeydir.
  Doğrulaması `test/hub/connections_backup_test.dart`: yedek metninde token
  düz hâliyle geçmiyor.

## SEC-003 — App'in yazma alanı yapısal olarak kapalı
- **Tarih:** 2026-08-03
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** R-001, K-029
- **Açıklama:** Uygulama hub'da yalnızca `tasks/inbox/` ve `notes/` altına
  yazabilir. Kural runtime kontrolüne bırakılmamıştır: yazma kapısı yol değil
  **dosya adı** alır ve klasörü kapalı bir enum'dan (`HubFolder`) seçer, yani
  üçüncü bir klasöre yazmak tip düzeyinde imkânsızdır. Silme de aynı kapıdan
  geçer. Bir hata ya da bozuk girdi yüzünden agent'ın dosyalarının üzerine
  yazılması bu yüzden mümkün değil.
  Doğrulaması `test/hub/write_permission_test.dart`.

## SEC-004 — Token isteğin gittiği repoya göre seçilir
- **Tarih:** 2026-08-02
- **Tür:** onlem
- **Durum:** kapali
- **Kaynak:** L-019, T-003
- **Açıklama:** Çoklu repo desteğinde adres ile token farklı zamanlarda
  okunuyordu; repo değiştirildiği anda A reposunun adresine B reposunun
  token'ı gidebiliyordu. Artık token, isteğin **yolundan** çıkarılan
  `owner/repo` ile eşleşen bağlantıdan seçilir. Bir projenin token'ının başka
  bir projeye gönderilmesi böylece yapısal olarak engellendi.

## SEC-005 — Bağımlılık taraması yapılmadı
- **Tarih:** 2026-08-03
- **Tür:** yapilacak
- **Durum:** acik
- **Kaynak:** S-2026-08-03-sifirdan-cozum
- **Açıklama:** Projede `dart pub outdated` / bilinen zafiyet taraması hiç
  koşulmadı. Doğrudan bağımlılıklar az ve tanınmış paketler (dio, riverpod,
  flutter_secure_storage, cryptography, flutter_markdown) ama bu bir denetim
  yerine geçmez. Yapılacak: sürüm ve zafiyet taraması koşulup bulguları
  `tarama` kaydı olarak buraya yazmak.

## SEC-006 — Token izin kapsamı daraltılmadı doğrulanmadı
- **Tarih:** 2026-08-03
- **Tür:** yapilacak
- **Durum:** acik
- **Kaynak:** R-005
- **Açıklama:** Token'ın fine-grained ve yalnız ilgili repolara scope'lu
  olması **kullanıcının elinde**; uygulama bunu doğrulamıyor. Token geniş
  kapsamlıysa uygulama bunu fark etmez. Yapılacak: onboarding'de token'ın
  kapsamını `/user` ve repo erişimiyle sınayıp gereğinden geniş kapsamda
  kullanıcıyı uyarmak.

## SEC-007 — Hub içeriği cihazda şifresiz duruyor
- **Tarih:** 2026-08-03
- **Tür:** acik
- **Durum:** acik
- **Kaynak:** B-057 çevrimdışı kopya
- **Açıklama:** Çevrimdışı kopya (`shared_preferences`) hub'ın markdown
  içeriğini düz metin tutuyor. Token orada değil (SEC-001), ama proje
  içeriği cihaz ele geçerse okunabilir. Risk kabul edilmiş durumda: içerik
  zaten GitHub'da duruyor ve depolama uygulama korumalı alanında. Kararın
  değişmesi gereken durum: hub'a gizli sayılacak içerik girmesi.
