---
id: S-2026-08-04-isaretler-kart-etiketi
date: 2026-08-04
status: closed
reconstructed: false
topics: [isaretler, ui-metni]
artifacts: []
tasks_touched: []
---

# Oturum: İşaretler kartında "tüm repolar" yazmaya devam ediyordu

## Özet
[S-2026-08-04-isaretler-aktif-repo](../2026-08-04-isaretler-aktif-repo/session.md)'nun
eksik kalan parçası: liste aktif repoya bağlandı ama Tarayıcı'daki **kartın alt
satırı** hâlâ "tüm repolar" diyordu. Kullanıcının ilk gördüğü yer orasıydı —
kartta bir şey, ekranda başka bir şey yazıyordu.

Kaçmasının sebebi mekanik: etiket başka bir dosyada, tek bir string
literalinde duruyordu ve hiçbir test ona bakmıyordu. Derleyici bir metnin
bayatladığını söyleyemez.

Etiket kardeşleriyle aynı biçime çekildi (`tasks/ · notes/` — diğer kartlar da
hub kaynağını yazıyor). Kapsam iddiası artık kartta hiç geçmiyor: hangi repo
olduğu ekranın kendisinde yazıyor, tek yerde. `browse_repo.dart`'taki bayat
yorum da düzeltildi.

**Önlem test hâline getirildi:** tarayıcı testi kartın alt satırını doğruluyor
ve kartlarda "repolar" geçmemesini şart koşuyor. → L-037, B-107

399 test, analyze temiz.

## Kayıt

### Kullanıcı
> telefonda isaretler altinda tum repolar yaziyo hala

### Agent
İki bayat metin bulundu: Tarayıcı kartının alt satırı (kullanıcının gördüğü) ve
`docContentForProvider`'ın doküman yorumu. İkisi de düzeltildi, ders L-037
olarak yazıldı: bir ekranın **kapsamı** değişince o ekrana **giden** metinler
de değişir — kart/menü etiketleri, boş durum metinleri, yardım satırları.
Bunlar ekranın parçası gibi düşünülmez ama kullanıcı için ekranın **ilk**
cümlesidir.
