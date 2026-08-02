---
id: S-2026-08-02-secim-menusu
date: 2026-08-02
status: closed
topics: [secim, menu, kullanilabilirlik]
artifacts: []
tasks_touched: []
---

# Oturum: Seçim menüsü sadeleştirildi

## Özet
Cihazda doğrulama sırasında görüldü: Android'in seçim menüsü cihazdaki
uygulamalarla doluyor (Opera'da arama, DuckDuckGo, ChatGPT, Perplexity, Çevir,
Samsung Pass, Acrobat…) ve uygulamanın kendi eylemi taşma menüsünün **dibine**
düşüyordu. Kullanıcı menüde yalnız dört eylem istedi.

Menü artık **tamamen** uygulamanın: **Sarı işaretle · Kırmızı çiz · Görev
oluştur · Kopyala**. Sistemin varsayılan öğeleri hiç eklenmiyor.

Sarı ve kırmızı **tek dokunuşla** kayıt oluşturuyor (sırasıyla `yorum` ve
`duzeltme`), sayfa açılmıyor — okurken akış bölünmesin diye. Not girmek isteyen
"Görev oluştur"u kullanıyor; o sayfa dört türü de sunmayı sürdürüyor.

Yazma yolu tek tutuldu: her iki yol da `createSelectionRecord`'dan geçiyor, ağ
yoksa kayıt outbox'a düşüyor (B-032). 287 test, analyze temiz.

## Kayıt

### Kullanıcı
> diger ogeleri istemiyorum, sadece higlight, kirmizi alti cizme ve gorev
> olusturma secenekleri yer alsin, bir de kopyala olsun

### Agent
Menü kurulurken `state.contextMenuButtonItems` (sistem öğeleri) artık hiç
eklenmiyor; liste dört öğeden ibaret. Seçim boşken menü de boş — seçim
olmadan işaretlenecek ya da alıntılanacak bir şey yok.

Kopyalama için `state.copySelection` kullanılmadı (deprecate edilmiş);
`Clipboard.setData` ile doğrudan yazılıyor.

Hızlı işaretlemede tür eşlemesi: **sarı = `yorum`** ("buraya bak"),
**kırmızı = `duzeltme`** ("burası yanlış"). Bu, sözleşme 1.5'te düzeltmenin
zaten kırmızı altı çizili başlamasıyla tutarlı.

Kurulum yapıldı ve crash yok; ancak telefon ekran zaman aşımıyla kilitlendiği
için menü **gözle doğrulanamadı**. Bir önceki sürümde aynı akış ekran
görüntüsüyle doğrulanmıştı (seçim, menü, kayıt sayfası); değişen yalnız
menünün içeriği.
