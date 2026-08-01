---
id: A-2026-08-01-100
session: none
type: info
title: "Yeni bir projeyi takip sistemine dahil etme"
created: 2026-08-01T00:00:00Z
---

# Yeni Bir Projeyi Takip Sistemine Dahil Etme

Her proje **kendi takip reposunda** izlenir: `<proje>_takip` (örn.
`financer_takip`). Hub içeriği o reponun **`hub/` klasörüne** kurulur — bu
kural istisnasızdır (K-020, sözleşme 1.3).

---

## 1. Repoyu aç (kullanıcı)

GitHub'da **private** repo: `<proje>_takip`.

Ad kuralı önemli: uygulama repoyu adından tanımıyor, ama insan tarafında
"hangi repo hangi projenin takibi" sorusunu ad çözüyor.

## 2. Token'ın o repoyu kapsamasını sağla (kullanıcı)

İki yol var:

- **Mevcut token'a repoyu ekle** (önerilen). GitHub → Settings → Developer
  settings → Personal access tokens → Fine-grained tokens → ilgili token →
  Repository access → yeni repoyu da seç. Uygulamada repo eklerken "Token"
  seçicisinden mevcut bağlantının token'ını seçersin, yeniden girmen gerekmez.
- **Yeni token üret.** Repository access → Only select repositories →
  `<proje>_takip`; Permissions → Contents: **Read and write**, Metadata: Read.

> Token yalnızca cihazın güvenli deposunda durur; hiçbir dosyaya ve commit'e
> yazılmaz (R-005). Yedeklemesi Ayarlar → Yedekleme'den, parolayla şifreli
> olarak alınır (R-006).

## 3. Hub iskeletini kur (agent)

> Agent'a verilecek **tek parça talimat**:
> [`agent-kurulum-talimati.md`](agent-kurulum-talimati.md) — kendi kendine
> yeten, olduğu gibi yapıştırılabilir. Masaüstünde de bir kopyası var.

Agent şu yapıyı `<proje>_takip` reposunun `hub/` klasörüne kurar:

```
hub/
  SYSTEM.md            # format sözleşmesi (bu repodan kopyalanır)
  AGENT_PROTOCOL.md    # kayıt prosedürü (bu repodan kopyalanır)
  BACKLOG.md           # boş faz iskeleti
  EVOLUTION.md         # Aşama 0 açık
  sessions/README.md
  artifacts/README.md
  tasks/inbox/README.md
  tasks/active/README.md
  tasks/waiting/README.md   # agent kullanıcıyı bekliyor (sözleşme 1.4)
  tasks/done/README.md
  knowledge/rules.md
  knowledge/skills.md
  knowledge/lessons.md
```

`SYSTEM.md` ve `AGENT_PROTOCOL.md` projeden projeye değişmez; olduğu gibi
kopyalanır. `BACKLOG.md` ve `EVOLUTION.md` o projeye özgü başlar.

## 4. Uygulamaya ekle (kullanıcı)

Uygulamada üstteki **repo şeridine** dokun → **Repo ekle**:

- Repo: `<owner>/<proje>_takip`
- Ad (isteğe bağlı): listede görünecek kısa ad
- Token: mevcut bir bağlantının token'ını seç, ya da yenisini yapıştır

**Bağlan**'a bastığında uygulama iki kontrol yapar: `hub/` okunabiliyor mu ve
token yazabiliyor mu. Geçerse repo listeye eklenir ve aktif olur.

## 5. Agent'a ne söylemeli (kullanıcı)

O projede çalışan agent'a tek cümle yeter:

> Bu projenin takip hub'ı `<owner>/<proje>_takip`. Önce `hub/AGENT_PROTOCOL.md`
> dosyasını oku ve kayıt prosedürüne uy.

Gerisini protokol anlatıyor: oturum aç, her mesajı anında kaydet, ürettiğin
her belgeyi `artifacts/` altına koy, biten backlog maddesini işaretle, çıkan
kuralı/dersi `knowledge/`'a yaz, oturumu kapatırken özetle ve push'la.

İlk oturumda agent'a projenin kendisini de anlatman gerekir (ne yapıyor, nerede
duruyor, ilk hedef ne) — bunlar `EVOLUTION.md` Aşama 0'a ve `BACKLOG.md`'ye
yazılır ve bir daha anlatman gerekmez.

---

## Sık karşılaşılanlar

**"hub/ klasörüne erişilemedi" hatası.** Üç sebebi olabilir ve GitHub üçüne de
404 döndüğü için uygulama üçünü birden söyler (L-007): repo adı yanlış, token
bu repoyu kapsamıyor, ya da repoda henüz `hub/` klasörü yok. Sıra önemli:
**önce iskelet kurulur, sonra uygulamaya eklenir.**

**Token yazamıyor uyarısı.** Contents izni `Read and write` değil. Uygulama
bunu daha bağlanırken söylüyor, ilk görev gönderiminde değil (B-026).

**Aynı repoyu ikinci kez eklemek.** Kopya oluşmaz; mevcut kaydın token'ı
tazelenir. Süresi dolmuş token'ı yenilemenin yolu budur.

**Çevrimdışı.** Repo eklendikten sonra hub'ın tamamı cihaza iner ve değiştikçe
güncellenir (B-057); tarayıcı ağ olmadan da çalışır. Görev eklemek de
çevrimdışı çalışır: görev kuyruğa alınır, bağlantı gelince kendiliğinden
gönderilir (B-032).

## Projeyi arşive kaldırırken

Takip reposu silinmez. Proje bittiğinde ya da terk edildiğinde:

1. `EVOLUTION.md`'de aktif aşama kapatılır, kapanış gerekçesi yazılır.
2. `BACKLOG.md`'de açık maddeler "yapılmayacak" olarak işaretlenir (silinmez).
3. Repo GitHub'da **archive** edilir; kayıt salt okunur kalır.
4. Uygulamada Ayarlar → Repolar → kaldır. Yerel kopyası da silinir.

Arşive kaldırılan bir projenin belgeleri başka bir hub'a taşınacaksa,
`artifacts/reference/` altına kaynak yolu belirtilerek konur — örneği:
`artifacts/reference/project-taskr/arsiv-dizini.md`.
