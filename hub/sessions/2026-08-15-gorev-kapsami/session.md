---
id: S-2026-08-15-gorev-kapsami
date: 2026-08-15
status: open
reconstructed: false
author: afgover
topics: [coklu-hub, bekleyenler, gorev-ekleme, kapsam]
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
