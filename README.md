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

Uygulama iskeleti: `lib/` (aşağıya bakın).

## Geliştirme

İskelet (B-021) SDK'sız ortamda elle yazıldı; platform klasörleri repoda yok.
İlk kurulumda:

```bash
flutter create . --platforms=android   # android/ klasörünü üretir, lib/'e dokunmaz
flutter pub get
flutter analyze                        # iskeletin ilk derleme doğrulaması (B-020)
flutter run
```

Mimari: `lib/github/` (saf GitHub REST) → `lib/hub/` (SYSTEM.md sözleşme
katmanı) → `lib/features/` (ekranlar). `github/` sözleşmeyi bilmez, `hub/`
UI'yi bilmez. Kod içindeki `TODO(B-0xx)` işaretleri hub'daki `BACKLOG.md`
maddelerine karşılık gelir.
