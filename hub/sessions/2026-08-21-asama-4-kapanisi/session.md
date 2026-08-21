---
id: S-2026-08-21-asama-4-kapanisi
date: 2026-08-21
status: closed
reconstructed: false
author: afgover
topics: [evrim, asama, yon, karar]
artifacts: []
tasks_touched: [T-017]
---

# Oturum: Aşama 4 kapanışı ve sıradaki aşamanın hedefi

## Özet

Altı gündür `waiting/`te duran bir **yön kararı** kapandı: Aşama 4 bitti,
Aşama 5 açıldı ve ilk iki koşulu aynı gün karşılandı.

**Karar verilmeden önce verisi tazelendi.** [T-017](../../tasks/done/2026-08-15-asama-4-kapanisi.md)'nin
notları 15 Ağustos tarihliydi. Aradaki fark önemliydi: üç madde doğup kapandı
ve biri ([B-135](../../BACKLOG.md#B-135)) **uygulamanın kendi inbox'ından**
geldi — yani Aşama 4'ün mekanizması, hedefinin karşılandığı ilan edildikten
altı gün sonra da iş üretiyordu. Aşamanın kapanma gerekçesi bu yüzden
"kullanım bitti" değil: **kullanım artık aşama değil, zemin**.

**Aşama 5'in kapanma koşulu uydurulmadı, ölçüldü.** Önce zemin tarandı —
bağımlılık tazeliği, kodda kalan işaretçiler, test kapsamı, tarama süresi.
Çıkan üç ölçülebilir koşul yazıldı; test kapsamı bilerek **dışarıda bırakıldı**
(604 test, doğrudan testi olmayan tek dosya var — aşama hedefi olacak boşluk
değil). Kullanımdan gelen sürtünme de koşula konmadı: o aşamanın sürekli işi,
bitiş çizgisi değil. Bitiş çizgisi olsaydı aşama hiç kapanmazdı — B-052'yi 15
gün açık tutan hatanın aynısı ([L-049](../../knowledge/lessons.md#L-049)).

**İki koşul aynı gün karşılandı.** 15 paket yükseldi, `flutter_lints` 6'ya
çıktı ve yeni kural hiçbir yeri kırmadı; `intl` yükseltilemedi ama gerekçesi
**ölçülerek** yazıldı (SDK'nın `flutter_localizations`'ı tam eşitlikle
sabitliyor, kaynakta doğrulandı). Ölü işaretçi silinmedi, **doğrusuyla
değiştirildi** — boş bırakmak "burada bir şey yok" derdi, oysa asıl bilgi
katman ayrımıydı.

**Aşamanın kısa olacağı görünüyor ve şişirilmedi.** Geriye yalnız tarama
koşulu kaldı (~3 Eylül). Ölçülmüş borç gerçekten küçüktü; uydurma maddelerle
uzatmak, kapanma koşulu yazmanın amacını bozardı.

**Ölçüm:** `flutter analyze` temiz, **604 test**, sözleşme 1.26 ana kopyayla
farksız.

## Kayıt

### Kullanıcı
> evet t017yi de yapalım

### Agent — kararın verisi tazelendi

[T-017](../../tasks/waiting/2026-08-15-asama-4-kapanisi.md)'nin notları
2026-08-15 tarihli; karar altı gün sonra veriliyor. Aradaki fark ölçüldü
(aşağıda), sonra karar kullanıcıya soruldu.

**Ölçülen fark (15 → 21 Ağustos):** üç madde doğup kapandı (B-133, B-134,
B-135); açık backlog değişmedi (aynı 8 madde, hiçbirinin tetikleyicisi
oluşmadı); test 575 → 604. Aşama 5 adayı olarak güvenlik artığı da bakıldı ve
elendi: tek açık kayıt [SEC-007](../../SECURITY.md#SEC-007) ve o bir **kabul
edilmiş risk**, iş değil — üstelik repo public olduğundan içerik zaten açık.

### Kullanıcı
> (karar) Aşama 4'ü kapat — Aşama 5: bakım ve sağlamlaştırma

### Agent — zemin ölçüldü, kapanma koşulu yazıldı

Seçeneğin kendi şartı kapanma koşulunu birlikte yazmaktı. Uydurmamak için önce
ölçüldü: bağımlılık tazeliği (`flutter pub outdated`), koddaki işaretçiler,
test kapsamı, `tarama` kaydının yaşı. Üç koşul buradan çıktı; ayrıntı
[EVOLUTION.md → Aşama 5](../../EVOLUTION.md)'te.

### Kullanıcı
> (karar) Minor şimdi, major gerekçeli ertelensin

### Agent — B-136 ve B-137 aynı gün kapandı

`flutter pub upgrade` 15 paketi yükseltti; `flutter_lints` 6'ya çıkarıldı ve
**yeni lint kuralı hiçbir yeri kırmadı** — susturma gerekmedi. `intl` tek
istisna ve gerekçesi ölçüldü: SDK'nın `flutter_localizations` paketi
`intl: 0.20.2` diye **tam eşitlikle** sabitliyor (kısıt kaynakta doğrulandı),
yani bu depoda yapılacak bir şey yok; tetikleyici SDK yükseltmesi.

Major geçişler [B-138](../../BACKLOG.md#B-138)'e ayrıldı ve **üç tetikleyicisi
yazıldı** (güvenlik danışmanlığı / yalnız yeni major'da olan bir yetenek /
SDK'nın mevcut sürümü kırması). Gerekçesi ve çıkışı yazılı bir erteleme,
sessiz borç değildir.

`commits_api.dart`'taki `TODO(B-045)` — B-045 2026-07-30'da kapanmıştı —
silinmek yerine doğrusuyla değiştirildi: ayrıştırma `activity.dart`'ta, bu
sınıf ham veriyi taşıyor. Kodda başka `TODO`/`FIXME` kalmadı (ölçüldü).

**Ölçüm:** `flutter analyze` temiz, **604 test**.
