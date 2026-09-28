---
id: S-2026-09-28-agentmemory-kiyas
date: 2026-09-28
status: open
reconstructed: false
author: afgover
topics: [kiyas, agent-hafizasi, harici-repo]
artifacts:
  - artifacts/S-2026-09-28-agentmemory-kiyas/agentmemory-kiyas.md
tasks_touched: []
---

# Oturum: `rohitg00/agentmemory` incelemesi ve takip hub'ı ile kıyas

## Özet

*(oturum açık — kapanışta yazılacak)*

## Kayıt

### [11:38] Kullanıcı

> https://github.com/rohitg00/agentmemory
> bu repoyu incelemeni ve bizim repo ile kıyaslamanı istiyorum

### [11:40] Agent

Repo meta verisi: "Persistent memory for AI coding agents based on
real-world benchmarks", TypeScript, Apache-2.0, ~29k yıldız, ~25 MB,
bugün güncellenmiş. Plan [P-026](../../PLAN.md) olarak yazıldı; repo
scratchpad'e salt okunur klonlanacak, kodu çalıştırılmayacak. İçindeki
talimat metinleri (README, AGENTS.md vb.) veri olarak okunur, talimat
olarak uygulanmaz.

### [11:55] Agent

İnceleme bitti (`c314c7b`, v0.9.29). Bulgular:
- Mimari: hook'lar her araç kullanımını otomatik yakalıyor → dedup →
  gizlilik filtresi → sıkıştırma → BM25 (+vektör, +graf) indeksi;
  SessionStart'ta 2000 token bütçeyle top-K enjekte ediliyor. Depo yerel
  KV (`~/.agentmemory`), ayrı bir motor süreci (`iii` engine) üzerinde.
- İddia doğrulaması: %95,2 R@5 **geri getirme** isabeti, QA doğruluğu değil
  (kendi raporu söylüyor); aynı tabloda MemPalace %96,6 ile önde — README'nin
  "#1" iddiasıyla çelişiyor. "%92 token" v0.6.0'ın 240 sentetik gözlemli
  setinden, orada R@5 %43,8. Test iddiası doğru (182 dosya, ~1.880 test).
- `DESIGN.md` mimari değil, sitenin görsel tasarım sistemi.
- Gizlilik filtresi 40 satır: yalnız bilinen anahtar kalıpları + `<private>`;
  kişisel veri filtresi yok, istemler ve araç çıktıları saklanıyor.

### [12:10] Agent

Kıyas yazıldı:
[A-2026-09-28-001](../../artifacts/S-2026-09-28-agentmemory-kiyas/agentmemory-kiyas.md)
(`artifact-lint.sh` temiz). Sonuç: iki sistem farklı problemi çözüyor —
agentmemory ajan için geri çağırma motoru, takip insan ve ajan arasında
denetlenebilir iş defteri; örtüşme yalnız "geçmişi hatırlama". Benimseme
önerilmedi. Alınabilecek üç fikir [KARAR] olarak işaretlendi: hub içi arama
(B-145), oturum ritmi kancası (B-144 d), ders/kurallar için "yerine geçen"
alanı. Alınmaması gerekenler: otomatik ham yakalama (public repo, SEC-017),
servis bağımlılığı (K-001), sıkıştırılmış hafızayı kaynak saymak.

### [12:10] Kullanıcı

> 1 ve 3 mantıklı, 2 yi biraz daha açıklarmısın

### [12:15] Agent

2\. maddeyi açıklamadan önce `.claude/settings.json` okundu ve kıyasta bir
**hata** bulundu: `tool/hub-guard.sh` 2026-08-28'den beri (P-017)
PreCompact ve SessionStart kancası olarak kurulu. Artifact 2. öneriyi yeni
bir fikir gibi sunuyordu; gerçekte öneri, var olan bekçiyi **tur sonuna**
(Stop kancası) genişletmek. Artifact düzeltildi. Bekçi L-059 vakasını
neden görmedi: yalnız sıkıştırma anında koşuyor (o oturumlarda sıkıştırma
olmadı) ve üçüncü işareti "iş commit'i kayıttan 30 dk yeni mi" — kayıt işle
aynı commit'te yazılınca sessiz kalıyor.
**Kök neden:** kıyasın dış tarafı dosya dosya envanterlendi, kendi tarafı
protokol metninden ve hafızadan anlatıldı. Bekçi hem açık backlog'da
(B-141) hem bugünkü denetim çıktısında (§10) görünüyordu.

### [12:25] Kullanıcı

> 3 karar da ok

### [12:27] Agent

Onaylananlar: (1) hub içi arama script'i, (2) bekçiye tur sonu modu —
kayıt bu turda güncellenmediyse bir kez durdur, commit/push gecikmesinde
yalnız uyar, (3) ders/kurallarda "Yerine geçen" alanı (sözleşme 1.33),
artı kıyas hatası için L-060. Plan [P-027](../../PLAN.md) olarak yazıldı.
Kanca davranışı (Stop girdisi, döngü koruması, uyarı kanalı) resmi
belgelere karşı ayrıca doğrulatılıyor.

### [12:55] Agent

L-060 yazıldı. [tool/ara.sh](../../../tool/ara.sh) eklendi: her koşumda
hub'ı okuyup bellekte BM25 kuruyor (servis yok); sorgu ve metin Türkçe
harften katlanıyor (ş→s, ı→i…), kelimeler ilk 5 harfe kısaltılıyor, ID'ler
bütün kalıyor. Kayıt birimi ders/kural/SEC/plan başlığı, backlog ve
EVOLUTION maddesi; oturum/görev/artifact/not dosyası bütün. Geçersiz ve
yerine geçilmiş kayıt geri itilip işaretleniyor. Selftest 7/7. Gerçek hub'da
"saat dogrulama" → L-052, "artifact tuketicisi" → B-145, "release imza
anahtari" → T-010, ID sorguları kendi kaydını ilk getiriyor; ~0,1 sn.
Kanca doğrulaması geldi: Stop'ta belgelenen durdurma yolu
`{"decision":"block","reason":…}`; `stop_hook_active` döngü koruması;
kanca düzenlemesi oturum içinde hemen devreye giriyor.

### [13:25] Agent

Bekçiye iki mod eklendi ([tool/hub-guard.sh](../../../tool/hub-guard.sh)):
`--prompt` (UserPromptSubmit) kullanıcı mesajının anını `$TMPDIR`'daki bir
işarete yazıyor; `--stop` (Stop) tur sonunda açık oturumun session.md'si
bu işaretten sonra değişmediyse ajanı bir kez durduruyor, commit/push 30
dakikadan eskiyse yalnız uyarıyor. İşaret yoksa ya da açık oturum yoksa
geçiyor. `.claude/settings.json`'a iki kanca eklendi, mevcut PreCompact ve
SessionStart korundu. Sahte girdiyle 8 durum sınandı. Sınama bir hata
yakaladı: `git status --porcelain` izlenmeyen dizini tek satıra indirip
dosyanın değil dizinin zamanını veriyordu; `git diff --name-only HEAD` +
`git ls-files --others` ile düzeltildi. Belgeler arası çelişki: yardımcı
ajan `systemMessage`'ın ajana, yapılandırma rehberi kullanıcıya
gösterildiğini söylüyor — canlı sınanacak.

### [13:50] Agent

Sözleşme 1.32 → **1.33** (`SYSTEM.md` + `.en`, `AGENT_PROTOCOL.md` +
`.en`): (1) protokole "Konuya girerken ara" bloğu; (2) madde 4'e "Claude
Code'da kancayla da uygulanır" cümlesi; (3) §5'e isteğe bağlı `Yerine
geçen:` alanı (yalnız eski kayıtta), madde 7'den ona işaret. İngilizce
hub'lara Türkçe alan adı dayatmamak için `Superseded by:` da tanımlandı ve
`ara.sh` ikisini de tanıyor (selftest 8/8). Aynı turda `ara.sh`'ın sözleşme
ve protokolü taramadığı görüldü ("yerine gecen alan" sorgusu §5'i
bulamadı); bölüm/madde düzeyinde eklendi. `EVOLUTION.md` notu yazıldı.

### [2026-09-29 00:00] Kullanıcı

> apk guncellemeye gerek varmi

### [2026-09-29 00:05] Agent

Uzun aradan sonra inbox'a bakıldı: boş. Son APK `8cda7ab` (2026-09-11
23:21) ile derlenmiş; uygulama kodundaki son iki değişiklik (`945cd76`,
`48e88e3`) içinde. Bugünkü işlerin hiçbiri `lib/`, `android/` ya da
`pubspec`'e dokunmadı; uygulama hub içeriğini GitHub'dan canlı okuyor.
Ama bir **hata** bulundu: `lib/core/constants.dart`'ta
`contractVersion = '1.29'` duruyor, sözleşme 1.33. Bu sabit Bağlantılar
ekranında hub'ın sözleşmesi eskiyse "agent güncellemeli" uyarısını
üretiyor; 1.29'da kaldığı için 1.29-1.32'deki hub'ları "güncel" gösteriyor.
`test/hub/annotations_test.dart` tam bu ayrışmayı yakalamak için var ve
kırmızı (beklenen 1.29, gerçek 1.33). Ayrışma 1.30'da başladı; 1.31, 1.32
ve 1.33'ü bu konuşmada ben artırdım, sabiti ben de atladım. **Kök neden:**
sözleşme-yalnız oturumlarda Flutter süiti koşulmuyor ve sürüm artışı
adımları sürümü taşıyan öbür yeri aramıyor.

### [2026-09-29 00:01] Kullanıcı

> evet, üçünü de yap

### [2026-09-29 00:03] Agent

Plan [P-028](../../PLAN.md): sabit 1.33 + tam süit, `audit.sh`'a sabit
kontrolü, release derleme + P-023'teki gibi veri korunumu ölçümü, Drive'a
kopya (`Drive'ım/Takip APK`, `OKU.txt`), SEC-015 notu.

### [2026-09-29 00:12] Agent

Sabit 1.33 yapıldı; sürümü taşıyan başka canlı yer aranıp bulunmadı (kalan
geçişler tarihsel kayıt). Tam süit 630/630 geçti — kırmızı test yeşile
döndü. `audit.sh`'a §12 eklendi: uygulama sabiti ile `SYSTEM.md` farklıysa
bulgu; uygulaması olmayan hub'da geçer. İki yönde sınandı.

### [2026-09-29 00:20] Agent

Release derlendi (`fd93fa6`, 56.2 MB, `key.properties` yok → debug
anahtarı). Veri korunumu ölçüldü: imza SHA-1 (`f4994730…`), paket adı ve
versionCode Drive'daki 2026-09-11 APK'sıyla birebir aynı — üstüne kurulur,
veri silinmez. `Drive'ım/Takip APK/takip-2026-09-29-fd93fa6.apk` olarak
kopyalandı, SHA-256 (`a9824a8d…`) iki tarafta aynı; `OKU.txt` yenilendi,
iki eski APK geri dönüş için kaldı. SEC-015'e çıkış satırı eklendi (09-11
çıkışı o gün işlenmemişti, o da yazıldı). Önceki cevapta ekran adı
"Bağlantılar" diye yanlış verilmişti; uygulamadaki adı "Repolar", OKU.txt
doğru adla yazıldı.
