---
id: T-024
title: "Sözleşme: ID numarası komşu girişten türetilince çakışıyor (vault_takip'te B-123/B-124 ikişer kez verildi)"
created_by: agent
created: "2026-09-19T20:15:00Z"
updated: "2026-09-19T20:15:00Z"
priority: normal
category: tartisma
tags: [sozlesme, agent-protocol, id, cakisma, vault]
session: none
result: none
options: ["Ana kopyaya v1.31 olarak ekle + SYSTEM.md 1.30→1.31 + vault_takip'i senkronla", "Yalnız kuralı ekle, sürüm artırma (açıklama sayılsın)", "Kuralı ekleme; vault_takip'teki yerel eklemeyi geri al ve yalnız senkronla"]
multi: false
---

# Sözleşme: ID numarası komşu girişten türetilince çakışıyor

## İstek

Vault oturumundan geliyor. **Karar ana kopyada verilmeli**, çünkü önerilen
değişiklik `hub/AGENT_PROTOCOL.md` ve `hub/SYSTEM.md`'yi ilgilendiriyor ve
buradan bütün hub'lara akıyor.

### Ne oldu

`vault_takip/hub/BACKLOG.md`'de **B-123 ve B-124 numaraları ikişer kez
verildi**. Bir oturum (2026-09-18, Vault) iki yeni giriş yazarken bu
numaraları seçti; oysa aynı numaralar başka bir oturumun kayıtlarında
(pano temizliği, etiket satırı) zaten kullanılmıştı. Düzeltildi:
çakışan iki giriş B-128 / B-129 oldu, gövdelerindeki çapraz atıf da
güncellendi. Çakışma artık yok (`sort | uniq -d` boş dönüyor).

### Kural eksik değildi — ölçüm eksikti

`AGENT_PROTOCOL.md`'nin "ID atarken (v1.15)" bloğu zaten şunu söylüyor:

> Numarayı **dosyadaki en büyükten** türet, hafızandan değil. … (2026-08-06'da
> tam bu şekilde B-111 iki kez verildi).

Kural okundu ve yine de ihlal edildi. Sebep, kuralın **söylemediği** şeydi:
"en büyük" nerede aranacak? Yeni giriş, ilgili maddenin (B-122) hemen altına
eklendi ve numara **komşu girişten** türetildi. `BACKLOG.md` kronolojik
sıralı değil — başka bir oturumun daha yeni kayıtları (B-123…B-127) aşağıda
duruyordu. Yerel bakış tutarlı bir cevap verdi, yalnızca yanlış cevabı.

İkinci gözlem: çakışma **sessizdi**. İki ayrı ID'yi aynı dosyaya yazmak git
için çakışma değil; hiçbir araç uyarmadı, hata vermedi. Sessiz bozulmada tek
koruma, yazdıktan sonra koşulan ucuz bir denetim komutu.

### Önerilen metin (v1.15 bloğunun altına eklenecek)

```markdown
> **"En büyük" komşu giriş değildir.** Dosya kronolojik sıralı DEĞİL: yeni
> kayıtlar araya da girebiliyor, dolayısıyla ekleyeceğin yerin üstündeki
> madde çoğu zaman en büyük numarayı taşımıyor. Numara, dosyanın tamamı
> taranarak bulunur ve ekledikten sonra çakışma denetlenir:
>
> ```
> grep -oE '\*\*B-[0-9]+\*\*' hub/BACKLOG.md | sort -u | tail -1   # en büyük
> grep -oE '\*\*B-[0-9]+\*\*' hub/BACKLOG.md | sort | uniq -d      # çakışma
> ```
>
> İkinci komut boş dönmelidir; bir şey döndüyse sonradan yazılan kayıt
> yeniden numaralandırılır ve **gövdesindeki çapraz atıflar da** düzeltilir.
> Aynı kalıp öbür sayaçlar için de geçerlidir — desen `B-`'nin yerine
> `T-`, `L-`, `SK-`, `R-`, `SEC-`, `K-`, `A-` konarak ve ilgili dosyaya
> bakılarak kullanılır.
```

Not: `T-` sayaçları görev dosyalarının frontmatter'ında durduğu için desen
orada `^id: T-[0-9]+` olur; metne bunu da eklemek gerekebilir.

## Notlar

**2026-09-19 (Vault oturumu) — kararı etkileyen iki ek bulgu:**

1. **vault_takip sözleşmesi 1.28'de, ana kopya 1.30'da.** İki sürüm geride:
   v1.29 (artifact yazım biçimi) ve v1.30 (madde numaralarında depo öneki)
   hiç inmemiş. §10'un her oturum açılışında istediği `diff` karşılaştırması
   o oturumda koşulmamış. Yani kararla birlikte bir **senkronlama** da
   gerekiyor.

2. **Ajan, öneriyi önce türetilmiş kopyaya yazdı.** Kullanıcı "AGENT_PROTOCOL'e
   de ekle" deyince metin `vault_takip/hub/AGENT_PROTOCOL.md`'ye eklendi
   (commit `afgover/vault_takip@89a3360`) — yani L-020/L-022'de anlatılan
   sessiz ayrışmanın bir örneği üretildi. Senkronlamada o ek silinecek;
   kalıcı olması için ana kopyaya girmesi gerekiyor. Sürüm artışı önerildiğinde
   kullanıcı "takip repo oturumuna gönder, orada karar verelim" dedi, bu görev
   o yüzden açıldı.

**Karar verilmesi gerekenler:**

- Metin ana kopyaya girsin mi, girecekse hangi sürüm etiketiyle (v1.31)?
- `SYSTEM.md` sürümü 1.30 → 1.31 artsın mı? (Öneri metni bir format
  değişikliği değil, var olan prosedür maddesinin ölçüm tarafı — sürüm
  artışının gerekip gerekmediği ana kopyanın kararı.)
- Ders kaydı ana kopyaya da geçsin mi? Vault hub'ında
  **L-034 — "Bir kuralın varlığı, kuralın uygulanabilir olduğu anlamına
  gelmiyor"** olarak yazıldı (`afgover/vault_takip@89a3360`).
- vault_takip ne zaman 1.30/1.31'e senkronlansın?

**İlgili kayıtlar:** `afgover/vault_takip` → B-130 (oturum kaydı), L-034
(ders), commit `89a3360` (yerel prosedür eklemesi + B-130 önlem maddesi).
