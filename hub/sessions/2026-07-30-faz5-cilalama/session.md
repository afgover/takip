---
id: S-2026-07-30-faz5-cilalama
date: 2026-07-30
status: closed
topics: [gelistirme, flutter, ux]
artifacts: []
tasks_touched: []
---

# Oturum: Faz 5 — hata UX'i ve ayarlar (B-050, B-051)

## Özet
B-050 ve B-051 tamamlandı. 184 test, `flutter analyze` temiz. Faz 5'in kalan
maddeleri (B-052 bir haftalık kullanım, B-053 geri bildirim turu) kullanıcıya
bağlı olduğu için açık.

**Önce bir hata düzeltildi.** B-046 ağ yokken GET'leri önbellekten döndürüyor.
Ama yoklamanın sorduğu soru "hub değişti mi" ve eski sürümü geri okumak bunu
yanıtlamıyor: yoklama çevrimdışıyken "her şey yolunda" sanıyordu, kullanıcı
bağlantısının koptuğunu hiç öğrenemezdi. `headSha()` artık önbellekten gelen
yanıtı cevap saymıyor, ağ hatası veriyor. İçerik ekranları önbellekten
beslenmeye devam ediyor — ihtiyaç farklı, davranış da farklı olmalı.

**B-050.** Hata sunumu tek yerde toplandı (`describeHubError`): her tip için
kısa başlık, ne olduğu ve **yapılabilecek bir şey**. Token hatasında ayarlara
giden düğme ve gereken izinler yazılı; rate limit'te kalan süre söyleniyor; ağ
hatasında görevlerin kuyrukta beklediği hatırlatılıyor. Ayrıca her ekranın
üstünde duran bir durum şeridi eklendi: kullanıcı "Görev Ekle" ekranındayken
token'ın geçersiz olduğunu bilmeli, yoksa yazdığı görev sessizce kuyruğa
düşer. Şerit hata yokken de kuyrukta bekleyen görev varsa görünüyor.

**B-051.** Yoklama aralığı (30 sn…5 dk) ayarlanabiliyor, diske yazılıyor ve
çalışan zamanlayıcıya anında uygulanıyor — değişiklik bir sonraki açılışa
kalmıyor. Ayarlar eşzamanlı varsayılanla başlayıp diskteki değeri sonradan
alıyor; böylece yoklama açılışta "ayarlar yüklensin" diye beklemiyor, ayar
okunamazsa da varsayılanla çalışmaya devam ediyor.

Bağlantı düzenleme ekranı B-022'nin kuralını sürdürüyor: yeni bilgiler
doğrulanmadan kaydedilmiyor. Çalışan bir kurulumu bozup kullanıcıyı boş
listelerle bırakmak, hiç değiştirmemekten kötü. Token alanı boş bırakılırsa
yalnız repo değişiyor. Sıfırlama onay istiyor ve kuyrukta bekleyen görev
varsa bunu söylüyor.

Testler bir kırılganlık daha gösterdi: bağlantı ekranı, yapılandırma henüz
yüklenirken açılırsa repo alanı boş kalıyordu (gerçek akışta kabuk zaten
yüklenmiş halde açıyor, ama varsayım kırılgandı). Yapılandırma geldiğinde
alan dolduruluyor.

## Kayıt

### Kullanıcı
> faz 5 devam

### Agent
B-050 ve B-051 uygulandı; B-046'nın yoklamayla etkileşiminden doğan hata
düzeltildi. B-052 kullanıcının bir haftalık kullanımı, B-053 ona bağlı —
ikisi de bu oturumda ele alınamaz.
