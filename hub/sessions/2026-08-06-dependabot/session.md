---
id: S-2026-08-06-dependabot
date: 2026-08-06
status: closed
reconstructed: false
topics: [guvenlik, dependabot]
artifacts: []
tasks_touched: [T-009]
---

# Oturum: Dependabot açıldı (T-009)

## Özet
B-102'nin **sürekli izleme ayağı** devreye girdi: kullanıcı repoda dependency
graph, Dependabot alerts ve security updates'i açtı. Artık `pubspec.lock`'a
karşı yeni bir danışmanlık çıktığında haber geliyor ve açık bulunan paket için
otomatik PR açılıyor.

Katmanlı taramanın (K-035) ikisi de yerinde:
- **sürekli** → Dependabot (bilinen zafiyet)
- **30 günde bir** → `tool/scan.sh` (sır, Android yapılandırması, sürüm
  güncelliği — otomatik gözcüsü olmayan parçalar)

**Doğrulama sınırı kayda geçti:** ayarın açık olduğu agent tarafından
ölçülmedi. Bu makinede `gh` kurulu değil ve agent'ta token yok, yani kayıt
kullanıcının bildirimine dayanıyor. Bunu yazmak önemliydi — bugünün geri
kalanında (L-035, L-038, L-039) tekrar tekrar çıkan şey, doğrulanmamış bir
iddianın kayda "ölçülmüş" gibi girmesinin nasıl bir güvence yanılsaması
ürettiğiydi.

T-006 (token genişliği ölçümü) hâlâ açık: o da kullanıcının token'ını
gerektiriyor ve token agent'a geçmemeli (SEC-001).

## Kayıt

### Kullanıcı
> sirada ne var

### Agent
Kuyruk durumu çıkarıldı: inbox ve active boş, agent'ın tek başına
ilerletebileceği madde kalmamış. Açık olanlar ya kullanıcıya bağlı (T-006,
T-009, T-010; B-097, B-098, B-103) ya da 2. plandaki Faz 6 işleri.

Öneri verildi: sıradaki en değerli iş kod yazmak değil, **B-052** — birkaç gün
normal kullanım. Gerekçe kanıta dayalı: son iki günün düzeltmeleri (B-099,
B-106, B-107) planlarken değil **kullanırken** çıktı.

### Kullanıcı
> ikisini. birden hallet

### Agent
İkisinin de agent tarafından yapılamayacağı, ama **farklı sebeplerle**,
açıklandı: T-006 yapısal olarak imkânsız (token agent'a geçmemeli — görevin
tasarım gereği), T-009 ise mümkün ama kullanıcının hesabında güvenlik ayarı
değiştirmek demek, o yüzden önce soruldu. T-006 için token'ı ekrana ve kabuk
geçmişine düşürmeyen bir komut verildi (`read -rsp`).

### Kullanıcı
> hepsi enabled

### Agent
T-009 `done`'a taşındı, SEC-011 ve B-102 güncellendi. Doğrulamanın kullanıcı
bildirimine dayandığı açıkça kayda yazıldı (`gh` yok, token yok).
