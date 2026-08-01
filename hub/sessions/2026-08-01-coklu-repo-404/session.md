---
id: S-2026-08-01-coklu-repo-404
date: 2026-08-01
status: closed
topics: [hata, coklu-repo, token, waiting]
artifacts: []
tasks_touched: [T-004, T-005]
---

# Oturum: Çoklu repoda "Bulunamadı" hatası ve waiting döngüsünün ilk koşumu

## Özet
İki iş: `waiting/` mekanizmasının ilk uçtan uca koşumu kapatıldı ve ikinci
repoda çıkan "Bulunamadı" hatası kök nedenine kadar takip edilip düzeltildi.

**Görev döngüsü (T-004/T-005).** Kullanıcı yedeği aldı, uygulamadan "Yaptım"
dedi; bildirim `inbox/`a sözleşmeye uygun düştü (`waiting-done` etiketi, asıl
görevin yolu ve ID'si gövdede). Asıl görev `waiting/ → done/` taşındı,
bildirim kapatıldı. **Zincirin hiçbir halkası sohbete bağlı kalmadı.**

**Hata (B-066).** `financer_takip`'e geçince üst şeritte "Bulunamadı"
çıkıyordu. Yapısal sebepler tek tek elendi: repo var ve commit'li, `hub/`
iskeleti eksiksiz (başka bir agent kurmuş), doğrulamasız ekleme yolu yok —
yani token `/contents/hub` için çalışmış olmalıydı.

Cihaz bağlanınca ölçüldü. Logcat HTTP ayrıntısı vermedi (istek log'layan katman
yok), ama **ekran verdi**: görev listesi ve tarayıcı financer verisini
gösteriyordu, yani `contents` ve `trees` çalışıyordu; yalnız yoklamanın
`commits` isteği 404 alıyordu. Ve hata **geçiciydi** — bir sonraki yoklamada
kendiliğinden siliniyordu.

Bu asimetri kök nedeni verdi: isteğin **adresi** sağlayıcı kurulurken
sabitleniyor, **token'ı** istek gönderilirken okunuyordu. Aktif bağlantı bu iki
an arasında değişirse A reposunun adresine B reposunun token'ı gidiyor; private
repoda GitHub'ın cevabı 404. `contents`/`trees` sonradan, bağlantı oturduktan
sonra atıldığı için çalışıyordu.

Düzeltme: token artık isteğin **yolundan** seçiliyor (`githubSlugOf` +
`bySlug`), "o an aktif olan" kavramından bağımsız. Cihazda iki ardışık repo
geçişiyle doğrulandı. 261 test, analyze temiz. → L-019

## Kayıt

### Kullanıcı
> yedegi aldim, yaptim dedim,
> 2. repoyu ekledim, secinde ustte bulunamadi uyarisi cikiyor

### Agent
Bildirim görevi `inbox/`a düşmüştü ve sözleşmeye tam uygundu. T-004 ve T-005
`done/`a taşındı; **sözleşme 1.4'ün ilk uçtan uca koşumu tamamlandı.**

Hata için önce yapısal sebepler elendi (repo, iskelet, ekleme yolları); hiçbiri
tutmadı. Kullanıcının repo adını vermesiyle `financer_takip` klonlanıp
incelendi: hub iskeleti eksiksiz, hatta yeni `waiting/` klasörü kullanılmış
(T-001, admin onayı — `urgent`). Repo private olduğu için API token'sız
sınanamadı; kullanıcının token'ı kullanılmadı.

### Kullanıcı
> telefonu takiyorum, logcat ten bak

### Agent
Logcat'te HTTP ayrıntısı yoktu — uygulamada istek log'layan bir katman yok.
Bunun yerine uygulama arayüzü üzerinden ölçüldü:

| Gözlem | Sonuç |
|---|---|
| Repo geçişi sonrası görev listesi doldu | `contents` çalışıyor |
| Tarayıcı → Oturumlar listelendi | `trees` çalışıyor |
| Şeritte "Bulunamadı" | `commits` 404 |
| ~1 dk sonra şerit temiz | hata **geçici** |

Bu dört gözlem birlikte kök nedeni verdi (L-019): adres ve kimlik farklı
anlarda okunuyordu. Tek repolu dönemde pencere zararsızdı; çoklu repoda araya
bağlantı değişimi girebiliyor.

Düzeltme uygulandı, cihaza kuruldu ve **hatanın çıktığı tam hareket** iki kez
tekrarlandı (financer → takip → financer): şerit temiz kaldı.

Yan bulgu, kullanıcıya iletildi: `financer_takip` kökünde `.DS_Store`
commit'lenmiş — zararsız ama `.gitignore`'a girmesi iyi olur.
