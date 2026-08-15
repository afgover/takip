---
id: S-2026-08-15-gorev-kapsami
date: 2026-08-15
status: open
reconstructed: false
author: afgover
topics: [coklu-hub, bekleyenler, gorev-ekleme, kapsam, backlog, bayat-madde]
artifacts: []
tasks_touched: []
---

# Oturum: Görev kapsamı — liste aktif repoya daraldı, hedef repo seçilebilir oldu

## Özet
(oturum açık)

## Kayıt

### Kullanıcı
> eklenen gorevlerin herpsi suzgecsiz baglanan bir ajana ulasiyor, sadece
> repoya ekli gorevlerin gosterilmesi icin duzenleme yap,
> eklenen gorev uygulamanin takip reposuna gonderilmiyor mu? ajan nasil tum
> gorevleri gorebiliyor?

### Agent — mekanizma ölçüldü, önce soru cevaplandı

Kod okundu; kullanıcının sorduğu iki şeyin cevabı:

- **Eklenen görev aktif repoya gidiyor, gönderiliyor.** Yol:
  `AddTaskScreen._submit` → `taskRepoProvider` → `contentsApiProvider`,
  owner/repo'yu `hubConfigProvider`dan yani aktif bağlantıdan alıyor →
  `hub/tasks/inbox/` PUT. Ekle ekranında hedef seçici **yoktu**; hedef,
  kabuğun tepesindeki repo şeridinde yazan repoydu.
- **Ajan bütün görevleri göremez.** Bir agent yalnız kendi reposunun `hub/`ını
  okur. "Hepsi tek yerde" izlenimi iki şeyden gelebiliyordu: (a) Bekleyenler
  ekranı bütün bağlı repoları tek listede birleştiriyordu (B-067,
  *"Aktif repo kavramı burada yok"*), (b) görevler hep aynı repo aktifken
  eklendiği için fiilen tek inbox'a yığılmıştı. Yani süzgeçsiz olan ajan
  değil, ekrandı.

Farklı düzeltmeler olduğu için kullanıcıya seçenekli soruldu; seçim: listeyi
aktif repoya daralt + Ekle ekranına hedef repo + önce yanlış yönlenmeyi
araştır.

### Agent — yanlış yönlenme araştırması

İki ölçüm:

1. **Bu reponun inbox'ına bugüne kadar hiç yabancı görev düşmemiş.** Git
   geçmişinde `hub/tasks/inbox/`a eklenen 18 dosyanın hepsi takip'in kendi işi.
2. **Damgasız tek yazma yolu Ekle ekranıydı.** Yazma yollarının tamamı
   çıkarıldı: `selection_record.dart` (görev/not/işaret silme) ve
   `task_detail_screen.dart` (bekleyen bildirimi) hedefi `summary.repoSlug` ile
   **açıkça** damgalayıp `taskRepoForSlugProvider`a veriyor; outbox damgayı
   koruyor ([L-045](../../knowledge/lessons.md#L-045) düzeltmesi yerinde).
   Yalnız `TaskDraft.create` `repoSlug` taşımıyordu ve Ekle ekranı paylaşılan
   `taskRepoProvider`ı kullanıyordu.

Yani **sessiz bir yanlış yönlenme kalmamıştı**; kalan, hedefin örtük olmasıydı.
Birleşik listeyle yan yana gelince sonucu aynı kapıya çıkıyor: bütün görevler
tek bir inbox'ta topluyor. → [L-048](../../knowledge/lessons.md#L-048)

### Agent — iki düzenleme uygulandı

**[B-131](../../BACKLOG.md#B-131) — Bekleyenler aktif repoya daraldı.**
`allPendingTasksProvider` → `activeRepoPendingTasksProvider` (ad artık kapsamı
söylüyor). Filtrenin repo boyutu ve satırlardaki repo etiketi kalktı; diskteki
eski `repos` seçimi **okunmuyor**, yoksa kullanıcının açamayacağı görünmez bir
filtre listeyi boşaltabilirdi.

**[B-132](../../BACKLOG.md#B-132) — Ekle ekranında hedef repo.** İki+ bağlantı
varken seçici çiziliyor, varsayılan aktif repo, seçim yapılırsa korunuyor.
İstek, `author`, hub dili ve kuyruk damgası **hedeften** türüyor; damga taslak
üretilirken basılıyor.

Alan `DropdownButtonFormField` değil `DropdownButton`: `FormField` seçimi kendi
sakladığı için, kullanıcı üstteki şeritten repo değiştirdiğinde alan eski adı
göstermeye devam eder ve gösterilen hedef ile yazılan hedef yeniden ayrışırdı —
düzeltilen hatanın aynısı.

**Ölçüm:** `flutter analyze` temiz, **540 test geçti** (533 + 7 yeni).
Yeni testler davranışı kuruyor: iki repolu kurulumda liste yalnız aktifi
gösteriyor, repo değişince öbürüne geçiyor; seçilen repoya yazılıyor (aktif
repoya değil) ve ağ yokken kuyruğa giren taslak seçilen repoyu taşıyor.

**Sözleşmeden sapma:** iş üç adımı geçti ama [§14](../../SYSTEM.md#14)'ün
istediği plan ağacı **yazılmadı** — çok adımlı olduğu anlaşıldığında adımlar
bitmişti. Geriye dönük bir ağaç uydurmak yerine sapma buraya yazıldı; plan
ağacının işi yarım kalanı görünür kılmak, bitmişi listelemek değil.

### Kullanıcı
> takip reposu için oturum aç. Başlangıç olarak son durumu özetle: git durumu
> (branch, bekleyen değişiklikler, son commitler) ve yarım kalan iş var mı.

### Agent — açılış kontrolleri ve durum özeti

Kullanıcı yeni oturum istedi; bu oturum `open` durduğu için soruldu, seçim
**mevcut kayıtta devam** oldu. Bu yüzden yeni `session.md` açılmadı.

Açılış kontrolleri (AGENT_PROTOCOL madde 0–5) koştu:

- Hub dili `tr`, kullanıcı da Türkçe yazıyor — uyuşuyor.
- `tasks/inbox/` boş, `active/` boş; `status: open` kalan başka oturum yok
  (frontmatter'a bakıldı — düz `grep` üç dosya döndürüyor ama ikisinde ifade
  gövde metninde geçiyor).
- Çalışma ağacı temiz, `git fetch` sonrası `origin/main` ile eşit.
- **Sözleşme kontrolü koştu** ([§10](../../SYSTEM.md#10)): `curl` + `diff`,
  ana kopyayla fark yok.
- Son `tarama` kaydı [SEC-008](../../SECURITY.md#SEC-008), 2026-08-04 → 11
  günlük, 30 gün eşiğinin altında; tarama koşulmadı.
- [§13](../../SYSTEM.md#13) geçici madde G-001: `waiting/`teki tek görev
  ([T-010](../../tasks/waiting/2026-08-06-release-imza-anahtari.md)) zaten
  `options` taşıyor — idempotent.

Yarım kalan iş olarak üç şey raporlandı: bu oturumun kendisi (özeti boş,
`status: open`), backlog'un 11 gerçek açık maddesi ve `PLAN.md`'de açık adım
kalmadığı. Kullanıcı bunlardan **B-052**'yi seçti.

### Agent — B-052 ve B-053 ölçülerek kapatıldı

İki madde bir teslimat değil **süreç** tarif ediyordu; ikisinin de içeriği
yaşanmış, ikisi de açık kalmıştı. Kapatma kararı yeniden yapmakla değil
kayıttan **ölçmekle** verildi:

**[B-052](../../BACKLOG.md#B-052) — bir hafta gerçek kullanım.** Kullanım
2026-08-01'de (cihazın bağlandığı gün, B-015/B-020 kapanışı) başladı → 15 gün,
istenenin iki katı. "Sürtünme noktalarını inbox'a görev olarak at" kısmı da
gerçekleşmiş: git geçmişinde inbox'a düşen görevler arasında 2026-08-04'te 2,
2026-08-10'da 4 ve 2026-08-11'de 1 tanesi telefondan açılmış kullanıcı
görevi (T-012…T-016).

**[B-053](../../BACKLOG.md#B-053) — revizyon turu.** Revizyon koştu ama **bir
tur olarak değil, sürekli**: ilk gün B-054/B-055/B-056 (kurulum veriyi
siliyordu, yedek yoktu, token yeniden kullanılamıyordu), B-099 (notsuz işaret
gürültü çıktı), T-012…T-016 → B-120…B-124, B-126/B-127 (çoklu hub'da yanlış
yönlenme), B-131/B-132 (kapsam). Madde açık kalmasının sebebi iş eksikliği
değil, "tur"un hiçbir zaman başlayıp bitmemesiydi.

**Bağlı iki madde ölçüldü, ikisi de kapanmadı** — ön koşulları artık
çözülebildiği için değerlendirildi:

- **[B-063](../../BACKLOG.md#B-063)** (tek repoda çoklu proje): ön koşulu
  "ayrı repo modelinin gerçek kullanımda yetersiz kalması". Çoklu hub fiilen
  yaşandı (2026-08-12, 2026-08-15) ama çıkan sürtünme repo modelinde değil
  **uygulamanın kapsam gösteriminde**ydi. Tetikleyici oluşmadı.
- **[B-064](../../BACKLOG.md#B-064)** ("Pro versiyon"): dört tetikleyicinin
  hiçbiri çıkmadı — kullanıcı tek ve GitHub hesabı var, medya eki istenmedi,
  yoklama aralığı yeterli, repo dışı entegrasyon talebi yok. Yol "tek ürün +
  opsiyonel bileşen" olarak sürüyor.

Ölçmenin asıl bulgusu, maddelerin kendisinden büyük: içeriği çoktan yaşanmış
bir maddenin arkasında **iki karar beklemede duruyordu**. →
[L-049](../../knowledge/lessons.md#L-049)
