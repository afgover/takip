# artifacts/

Oturumlarda üretilen rapor / plan / analiz / info / tasarım dosyaları.
Şema: `SYSTEM.md` §3.

```
artifacts/<session-id>/<dosya-adi>.md   oturuma bağlı üretimler
artifacts/reference/                    oturumdan bağımsız kalıcı referanslar
```

Her dosya frontmatter taşır (`id`, `session`, `type`, `title`, `created`) ve
üretildiği oturumun `session.md` dosyasındaki `artifacts:` listesine eklenir.
