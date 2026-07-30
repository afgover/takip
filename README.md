# takip — Taskr Uygulaması (çatı repo)

**project-taskr** sisteminin kullanıcı uygulaması bu repoda yaşar (Flutter,
Android öncelikli — K-009). Uygulama, hub'a bağlanan bir GitHub istemcisidir;
kendi backend'i yoktur.

## Sistemin yapısı (K-011, K-012)

Bu repo **kendi kendini barındırır**: uygulama kodu ve takip projesinin veri
hub'ı aynı repodadır (`takip_takip` gibi ek repo yoktur).

| Konum | Rol |
|---|---|
| `takip/lib/` (bu repo) | Uygulama kodu (Flutter) |
| `takip/hub/` (bu repo) | Veri hub'ı: oturumlar, görevler, backlog, bilgi tabanı |
| `taskr` | Eski uygulama — salt tarihçe |
| diğer projeler | Ayrı `<proje>_takip` hub repoları (işleyiş değişmez) |

Format sözleşmesi ve tasarım dokümanları hub'dadır:
- `hub/SYSTEM.md` — veri formatı sözleşmesi (yollar hub köküne göre)
- `hub/artifacts/reference/flutter-app-design.md` — uygulama tasarımı

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
