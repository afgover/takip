# takip — Taskr Uygulaması (çatı repo)

**project-taskr** sisteminin kullanıcı uygulaması bu repoda yaşar (Flutter,
Android öncelikli — K-009). Uygulama, veri hub'ına bağlanan bir GitHub
istemcisidir; kendi backend'i yoktur.

## Sistemin yapısı (K-011)

| Repo | Rol |
|---|---|
| `takip` (bu repo) | Uygulama kodu (Flutter) |
| [`taskr_takip`](https://github.com/afgover/taskr_takip) | Veri hub'ı: oturumlar, görevler, backlog, bilgi tabanı |
| `taskr` | Eski uygulama — salt tarihçe |

Format sözleşmesi ve tasarım dokümanları hub'dadır:
- `taskr_takip/SYSTEM.md` — veri formatı sözleşmesi
- `taskr_takip/artifacts/reference/flutter-app-design.md` — uygulama tasarımı

Uygulama iskeleti Faz 2'de (backlog B-021) eklenecek.
