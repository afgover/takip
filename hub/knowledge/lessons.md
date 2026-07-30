# Çıkarılan Dersler (lessons)

Yapılan hatalar ve öğrenilenler; tekrarlanmaması için tek tek kayıt altında.
Biçim: `SYSTEM.md` §5.

---

## L-001 — Altyapı işletmek ürünün önüne geçebilir
- **Tarih:** 2026-07-30
- **Kaynak:** İlk taskr deneyimi (Expo + özel backend)
- **Açıklama:** Auth, offline senkron, deploy ve güvenlik yamaları; görev
  yönetimi ürününün kendisinden daha fazla emek tüketti. Yönetilen bir omurga
  (GitHub) üzerine kurulmak bu yükü sıfıra yaklaştırır. Yeni bileşen eklerken
  ölçüt: "Bunu biz mi işletmek zorundayız?"

## L-002 — Paylaşılan tek dosya, eşzamanlı yazmada çakışır
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 tasarımı (K-004)
- **Açıklama:** Tüm görevleri tek `todos.json`'da tutmak iki yazarın sürekli
  çakışmasına yol açar. Kayıt-başına-dosya modelinde ekleme hiçbir zaman
  çakışmaz; güncellemede de çakışma tek göreve izole kalır.

## L-003 — Kritik parametreleri işleme başlamadan teyit et
- **Tarih:** 2026-07-30
- **Kaynak:** S-2026-07-30-duzeltme-ve-dongu-testi
- **Açıklama:** Hub, kullanıcının kastettiği `taskr_takip` yerine yanlışlıkla
  `takip` reposuna kuruldu; iki benzer adlı repo varken isim teyit edilmeden
  taşıma yapıldı ve iş iki kez yapıldı. Kural: repo adı, hedef branch gibi geri
  alması maliyetli parametrelerde belirsizlik varsa önce listele/teyit et,
  sonra uygula.

## L-004 — Görev döngüsünün Contents API yolu ayrıca test edilmeli
- **Tarih:** 2026-07-30
- **Kaynak:** B-016 testi
- **Açıklama:** T-001 döngüsü (inbox → active → done) git ile işletildi ve
  sözleşme sorunsuz çalıştı; ancak uygulamanın kullanacağı yol Contents API'dir
  (taşıma = DELETE + PUT, SHA zorunlu). Bu yol Faz 3'te (B-034) uçtan uca ayrıca
  test edilecek.

## L-005 — Contents API'de "boş dizin" diye bir şey yok
- **Tarih:** 2026-07-30
- **Kaynak:** B-023
- **Açıklama:** Git boş dizin tutmaz; bir klasörün son dosyası silinince klasör
  de yok olur. Contents API bu durumda 404 döner — yani "içi boşalmış dizin" ile
  "hiç var olmayan dizin" ayırt edilemez. Dizin listelemede 404'ü hata olarak
  göstermek yanlış olur (kullanıcı boş inbox'ta hata ekranı görür); `listDir`
  404'ü **boş liste**ye çevirir. Tek dosya okumada 404 gerçek hatadır, olduğu
  gibi bırakılır.

## L-006 — Doğrulanmamış kod sessizce birikir
- **Tarih:** 2026-07-30
- **Kaynak:** B-023 (iskeletin ilk derlenmesi)
- **Açıklama:** B-021 iskeleti SDK'sız ortamda yazıldığı için hiç derlenmemişti.
  İlk `flutter analyze` çalıştırıldığında iskelette 2 gerçek derleme hatası
  çıktı (`DropdownButtonFormField.initialValue` — o sürümde alan adı `value`).
  Hata küçüktü ama kod yazıldığı anda değil, haftalar sonra görülecekti. Kural:
  SDK gerektiren iş yapılıyorsa SDK ortama kurulur ve **her oturumda** analiz +
  test çalıştırılır; "sonra doğrularız" borcu faiziyle geri döner.
