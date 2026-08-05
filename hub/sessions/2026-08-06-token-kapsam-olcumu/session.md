---
id: S-2026-08-06-token-kapsam-olcumu
date: 2026-08-06
status: closed
reconstructed: false
topics: [guvenlik, token, olcum]
artifacts: []
tasks_touched: [T-006]
---

# Oturum: Token kapsamı ölçüldü (T-006)

## Özet
SEC-012'nin bilinmeyeni ölçüldü: **`GET /user/repos` fine-grained bir token'la
kapsamı yansıtıyor.** Kullanıcının token'ı 1 repo döndürdü; hesapta en az iki
repo var (`takip`, `financer_takip`), yani uç nokta hepsini değil yalnız
token'ın kapsadığını veriyor.

Bu, B-092'de "belgelenmemiş, tahmin yazmayalım" diye açık bırakılan noktanın
kanıta bağlanması. Ölçüm kullanıcı tarafından yapıldı, çünkü token agent'a
geçmemeli (SEC-001) — görev tam da bu kısıt için `waiting/`e konmuştu ve
sistem amaçlandığı gibi işledi.

**Verdiğim komut iki kez hatalıydı, ikisi de düzeltildi:**
1. `read -rsp` bash sözdizimi; kullanıcı zsh kullanıyor ve orada `-p`
   "coprocess'ten oku" demek. zsh karşılığı `read -rs "T?Token: "`.
2. Sayım `grep -c` ile yapılıyordu — o **satır** sayar ve GitHub JSON'u tek
   satır döndürür, yani sonuç repo sayısı değil her zaman `1` olurdu. Fark
   edilmeseydi "1 repo görüyor" sonucu **ölçümden değil hatadan** gelecekti ve
   tam da doğru görünen bir sayı olduğu için yakalanması zordu. Sayım JSON'un
   kendisinden yapılacak şekilde değiştirildi (`json.load` → `len`).

İkincisi bu haftanın tekrar eden temasının bir örneği daha (L-035, L-038,
L-039): doğru görünen bir çıktı, doğru bir ölçüm demek değil.

**Kayıt hâlâ `acik`:** ölçümün mümkün olduğu anlaşıldı ama uygulamada bir
kontrol yok. Kapanması B-103'e bağlı ve B-103'ün asıl sorusu artık teknik
değil tasarım: eşik ne olacak?

## Kayıt

### Kullanıcı
> read: -p: no coprocess

### Agent
İki hata bulundu ve söylendi: zsh sözdizimi ve `grep -c`'nin tek satırlık
JSON'da yanlış sayması. Düzeltilmiş komut verildi.

### Kullanıcı
> Token: giris bekliyor ne yazayim

### Agent
Ne yapıştıracağı açıklandı; token'ın sohbete değil yalnız kendi terminaline
girmesi gerektiği vurgulandı. Token elinde yoksa iki alternatif sunuldu:
ölçüm için tek kullanımlık bir token üretip sonra silmek, ya da ölçümü tümden
atlayıp SEC-012'yi "ölçülmedi" olarak bırakmak.

### Kullanıcı
> 1

### Agent
Sonuç yorumlandı: hesapta ≥2 repo varken token 1 görüyor → uç nokta filtreliyor
→ kapsam **ölçülebilir**. T-006 kapatıldı, SEC-012 ölçüm sonucuyla güncellendi
(kayıt açık kalıyor: ölçüm mümkün ama kontrol yok), B-103 yeniden yazıldı.

Ölçümün sınırı da kayda geçti: tek veri noktası ve tek yön. Kanıtlanan "dar
token az repo görür"; "All repositories token'ı hepsini görür" doğrudan
sınanmadı, filtrelemenin varlığından çıkarıldı.
