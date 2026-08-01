---
id: S-2026-08-01-cevrimdisi-tarayici
date: 2026-08-01
status: closed
topics: [cevrimdisi, senkron, tarayici, b057]
artifacts: []
tasks_touched: []
---

# Oturum: Tarayıcının çevrimdışı çalışması ve otomatik senkron

## Özet
Kullanıcı dört şey istedi; ölçüldüğünde **ikisinin zaten var olduğu** çıktı:
çevrimdışı görev ekleme (B-032, ağ hatasında kuyruğa alma) ve bağlantı gelince
senkron (başarılı yoklama "çevrimiçiyiz" sayılıp kuyruğu boşaltıyor). Eksik
olan, tarayıcı içeriğinin **hiç açılmamış belgeler dahil** çevrimdışı
çalışması ve kendiliğinden güncellenmesiydi.

Önceki durum kısmi çevrimdışıydı: ETag önbelleği (B-046) yalnız açılmış
belgeleri tutuyordu, yani çevrimdışı okunabilen şey kullanıcının daha önce
gördüğü şeydi.

Yapılan (B-057, takip@1161e2b): hub'ın tamamı (`hub/**.md`) cihaza iniyor ve
hub değiştikçe kendiliğinden güncelleniyor. Senkron **ağaç farkına** dayanıyor
(SK-010): Git ağacı her dosyanın blob SHA'sını tek istekte veriyor, SHA
değişmemişse dosya indirilmiyor. Hub 38 dosya / 150 KB olduğu için ilk
indirme de önemsiz.

`flutter analyze` temiz, **247 test** (10 yeni). Cihaza kuruldu, crash yok;
Ayarlar → Çevrimdışı bölümü telefon kilitlendiği için gözle doğrulanamadı.

## Kayıt

### Kullanıcı
> tarayici kismindakiler offline da kullanilsin,oto matik indirsin,
> guncellesin, offline gorev ekleme de olsun, baglanti saglaninca sync yapsin

### Agent
İstek dörde ayrıldı ve her biri koda bakılarak durumu tespit edildi — hepsini
yeniden yazmak yerine gerçekten eksik olanı bulmak için:

| İstek | Durum |
|---|---|
| Çevrimdışı görev ekleme | zaten var (B-032) |
| Bağlantı gelince senkron | zaten var (B-024 + B-032) |
| Tarayıcı çevrimdışı | kısmen — yalnız açılmış belgeler (B-046) |
| Otomatik indirme/güncelleme | yok |

**Tasarım:** yeni katmanın ETag önbelleğinden farkı *niyet*. Önbellek gidilen
yolu ucuzlatır; çevrimdışı kopya ise hub'ın kasıtlı olarak indirilmiş
kopyasıdır. Aynı yerde tutulsalardı hangi kaydın niçin orada olduğu
belirsizleşirdi — ayrı tutuldular.

Senkron ağaç farkına dayanıyor: ağaç tek istekte bütün blob SHA'larını veriyor
(K-014), SHA değişmemişse indirme yok. İlk senkrondan sonra maliyet = 1 ağaç
isteği + değişen dosya sayısı. Ağaç ETag'li olduğu için değişiklik yokken
limitten de düşmüyor.

Üç ayrıntı bilinçli:
- **Ağaç en sona yazılıyor.** İndirme yarıda kalırsa yerel ağaç eski kalır ve
  bir sonraki senkron eksikleri yeniden dener; önce yazılsaydı sistem "her şey
  güncel" sanırdı.
- **Uzaktan silinen dosya yerel kopyadan düşürülüyor**, yoksa kullanıcı artık
  var olmayan bir belgeyi listede görmeye devam ederdi.
- **Kopya repo başına ayrı.** Ayrılmasaydı A reposunun belgeleri B'ye
  geçildiğinde de listede görünürdü — kullanıcının gördüğü içerik ile
  bulunduğu repo birbirini tutmazdı. Test bunu ayrıca doğruluyor.

Ağ yokken senkron elde olan kopyayı bozmuyor; bu beklenen durum olduğu için
hata gürültüsü de üretmiyor. Önbellek temizleme artık yerel kopyayı da siliyor
— yalnız ETag silinseydi tarayıcı eski kopyayı göstermeye devam eder ve
"temizledim ama değişmedi" denirdi.

**Kapsam dışı bırakılan, bilinçli:** görev listeleri (Bekleyenler/
Tamamlananlar) bu kopyadan okumuyor; hâlâ ETag önbelleğiyle çalışıyorlar, yani
çevrimdışı yalnız daha önce görülen hâli gösteriyorlar. Kullanıcı tarayıcıyı
sormuştu; görev listeleri için ayrı madde açılabilir (B-057 notunda yazılı).

Kurulum sırasında ayarlar ekranı yine uzadığı için bir test kırıldı — L-015'in
tarif ettiği tembel liste sorunu, `scrollUntilVisible` ile çözüldü.
