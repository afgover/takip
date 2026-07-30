---
id: S-2026-07-30-b025-frontmatter-markdown
date: 2026-07-30
status: closed
topics: [gelistirme, sozlesme, flutter]
artifacts: []
tasks_touched: []
---

# Oturum: B-025 — Frontmatter parser + markdown render altyapısı

## Özet
B-025 tamamlandı.

**Frontmatter:** satır tabanlı ayrıştırmaya geçildi (regex yerine); CRLF, BOM,
kapanmayan blok, boş blok ve gövdedeki `---` yatay çizgisi artık doğru ele
alınıyor. Bozuk YAML çökertmiyor: `isMalformed` işaretlenip dosyanın tamamı
gövde olarak veriliyor, yani içerik gizlenmiyor. Tipli erişimciler eklendi
(`str`, `strOr`, `list`, `dateTime`) — modeller tip kontrolünü tekrarlamayacak.

Serializer önemliydi: app'in yazdığını agent okuyacak, dolayısıyla çıktı her
durumda geçerli YAML olmalı. Eski hâli yalnız `:` içeren değeri tırnaklıyordu;
`"` içeren başlık, `true`/`42` gibi görünen metin ya da satır sonu sözleşmeyi
bozardı. Yeni kural SK-004'te; ölçüt `parse(serialize(x)) == x`. Gövdenin
round-trip'te boş satır biriktirmesi de giderildi.

**Markdown:** `features/common/hub_markdown.dart` — temadan türeyen stil
(açık/koyu uyumlu) ve GitHub eklenti seti. Eklenti seti şart, çünkü sözleşmenin
kendi yazım alışkanlıkları temel markdown'da yok: R-004'ün `~~üstü çizili~~`
işareti, BACKLOG'un `- [x]` kutuları, SYSTEM.md'nin tabloları. Bağlantı dokunuşu
karar verilmeden yukarı iletiliyor (Faz 4 uygulama içi gezinmeye bağlayacak).
`markdown` paketi doğrudan bağımlılık yapıldı (`ExtensionSet` için).

**Sözleşme uyum testi:** parser uydurma örneklerle değil, repodaki gerçek hub
dosyalarıyla da koşuyor — sözleşme ile uygulama arasında sessiz kayma olursa
(L-004'ün işaret ettiği risk) test kırılır.

Sonuç: 55 test geçiyor, `flutter analyze` temiz.

## Kayıt

### Kullanıcı
> b025 devam

### Agent
B-025 uygulanıyor: `hub/frontmatter.dart` sağlamlaştırılıyor (CRLF/BOM, bozuk
YAML'a dayanıklılık, tipli erişimciler, güvenli YAML üretimi) ve
`features/common/` altına tema uyumlu markdown render altyapısı yazılıyor.
Yazma yolu (B-030) bu serializer'a bağlanacağı için üretilen frontmatter'ın
her durumda geçerli YAML olması kritik.
