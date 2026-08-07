# takip

***Türkçe** · [English](README.en.md)*

Projelerini bir AI agent ile yürütürken **ne konuşulduğunun, ne kararlaştırıldığının
ve ne yapıldığının** kaybolmadığı bir çalışma biçimi. İki parçadan oluşur:

- **Sözleşme** (`hub/SYSTEM.md`) — agent'ın her çalışmasını hangi dosyaya, hangi
  biçimde yazacağını tanımlar. Oturum kayıtları, görevler, kararlar, çıkarılan
  dersler, güvenlik logu.
- **Uygulama** (`lib/`) — bu kayıtları telefondan okuduğun ve agent'a oradan
  görev attığın Flutter istemcisi.

Aradaki taşıyıcı **GitHub'ın kendisi**. Backend yok, sunucu yok, hesap yok:
uygulama doğrudan `api.github.com` ile konuşur, veri senin reponda durur.

## Neden

Bir agent'la uzun süre çalışınca sohbet kapanır ve onunla birlikte "bunu neden
böyle yapmıştık" da gider. Notlar dağılır, yarım kalan işler unutulur, agent bir
sonraki oturumda geçmişi bilmez.

Buradaki cevap basit: **hub'a yansımayan iş, yapılmamış sayılır.** Agent her
oturumu, her kararı ve her görevi repoya yazar; sen telefondan okursun, oradan
görev açarsın, işaretlersin, not alırsın.

## Nasıl çalışır

```
    telefon (Flutter)                GitHub                     agent
  ┌───────────────────┐        ┌──────────────────┐      ┌─────────────────┐
  │ görev aç          │──PUT──▶│  <proje>_takip   │◀────▶│ oku, işi yap,   │
  │ oku / işaretle    │◀─GET───│    hub/          │      │ kaydet, push'la │
  │ not al            │        │                  │      │                 │
  └───────────────────┘        └──────────────────┘      └─────────────────┘
```

Görevin **durumu klasördür**: `tasks/inbox → active → waiting → done`. `waiting/`
özeldir — agent orada senden bir şey bekler ve bu telefonda görünür, sohbette
kaybolmaz.

Uygulama hub'da yalnız iki yere yazabilir: `tasks/inbox/` (agent'ın iş kuyruğu)
ve `notes/` (senin kendi notların). Kural runtime kontrolüne bırakılmamıştır —
yazma kapısı yol değil dosya adı alır ve klasörü kapalı bir kümeden seçer.

## Repo yapısı

Bu repo kendi kendini barındırır: uygulama kodu ve takip projesinin kendi hub'ı
aynı yerdedir.

| Konum | Rol |
|---|---|
| `lib/` | Uygulama kodu |
| `hub/SYSTEM.md` | Format sözleşmesi — **ana kopya**, diğer projeler buradan günceller |
| `hub/AGENT_PROTOCOL.md` | Agent'ın kayıt prosedürü |
| `hub/artifacts/reference/agent-kurulum-talimati.md` | Yeni bir projeye kurulum talimatı (TR — **ana kopya**) |
| `hub/artifacts/reference/setup-instruction.en.md` | Aynı talimatın İngilizcesi |
| `hub/` (gerisi) | Bu projenin kendi hafızası: oturumlar, görevler, backlog, dersler |
| `tool/install.sh` | Cihaza yerinde kurulum (veriyi silmez) |

Her proje **kendi** takip reposunda izlenir: `<proje>_takip`, hub içeriği o
reponun `hub/` klasöründe.

## Kendi projende kullanmak

1. GitHub'da private bir `<proje>_takip` reposu aç.
2. Token'ın o repoyu kapsasın (fine-grained, Contents: Read and write).
3. Agent'a [`agent-kurulum-talimati.md`](hub/artifacts/reference/agent-kurulum-talimati.md)
   dosyasını olduğu gibi ver. Gerisini o kurar — sıfırdan bir proje için de,
   geçmişi olan bir proje için de (geçmişi kanıta dayalı toplayıp
   `reconstructed: true` ile kaydeder).
4. Uygulamada repoyu ekle.

Ayrıntı: [`proje-ekleme.md`](hub/artifacts/reference/proje-ekleme.md).

## Çalıştırma

```bash
flutter pub get
flutter test
flutter run
```

Cihaza kurulum için `flutter install` yerine:

```bash
bash tool/install.sh
```

Bu betik yalnız `adb install -r` kullanır, hiçbir koşulda paketi kaldırmaz —
`flutter install` başarısız olunca kaldırıp yeniden kuruyor ve cihazdaki
token'ı siliyordu.

## Durum ve sınırlar

Sürüm 0.1.0. Günlük kullanımda ama **tek kullanıcılık varsayımlarla** yazıldı:

- **Android**; iOS hiç denenmedi.
- Arayüz Türkçe ve İngilizce. Dil **hub'ın özelliğidir**, kurulumda seçilir
  (`SYSTEM.md` → `Hub dili`); sözleşme, arayüz ve yeni kayıtlar onu izler.
  Sözleşmenin kendisi şimdilik yalnız Türkçe — İngilizce varyantı `B-116`.
- Kimlik doğrulama **kişisel erişim token'ı** ile. Token yalnız cihazın güvenli
  deposunda durur, hiçbir dosyaya/commit'e/log'a yazılmaz. Uygulama klasik
  (`ghp_`) bir token verildiğinde uyarır ama **fine-grained bir token'ın "All
  repositories" ile üretilip üretilmediğini göremez** (`SEC-012`, açık kayıt).
  Genel dağıtım için doğru cevap GitHub App / OAuth'tur ve backlog'da `B-061`
  olarak durur.
- Cihazdaki çevrimdışı kopya şifresiz (`SEC-007`, bilinçli kabul edilmiş risk).

Güvenlik geçmişinin tamamı: [`hub/SECURITY.md`](hub/SECURITY.md) — alınan
önlemler, bilinen açıklar ve yapılacaklar tek yerde.

## Sözleşme sürümü

Şu an **1.20**. Her hub kendi kopyasını taşır ve agent her oturum açılışında ana
kopyayla karşılaştırıp geriden geliyorsa günceller (`SYSTEM.md` §10). Sürüm eşit
ama içerik farklıysa (ayrışma) üzerine yazılmaz — bu, yalnız numaraya bakan bir
kontrolün göremediği ve gerçekten yaşanmış bir durumdur.

## Geliştirme

Katmanlar tek yönlü: `lib/github/` (saf GitHub REST) → `lib/hub/` (sözleşme
katmanı) → `lib/features/` (ekranlar). `github/` sözleşmeyi bilmez, `hub/` UI'yi
bilmez.

Koddaki `TODO(B-0xx)` işaretleri `hub/BACKLOG.md` maddelerine karşılık gelir.
Çıkarılan dersler `hub/knowledge/lessons.md`'de `L-0xx` olarak numaralıdır ve
kod yorumlarından bu numaralara atıf yapılır — bir satırın neden öyle yazıldığı
oradan okunabilir.

## Lisans

MIT — bkz. [LICENSE](LICENSE).
