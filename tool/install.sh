#!/usr/bin/env bash
#
# Uygulamayı cihaza **veriyi silmeden** kurar.
#
# Neden `flutter install` değil: o komut `adb install` bir kez "Failure" derse
# paketi sessizce KALDIRIP yeniden kuruyor. Android'de kaldırma uygulama
# verisini de siler — yani cihazdaki bütün repo bağlantıları ve token'lar
# gider (L-014). Yardımcı olmaya çalışan bir davranışın bedeli, kullanıcının
# her repo için token'ı yeniden girmesi oluyor.
#
# Buradaki kural: `adb install -r` ya yerinde günceller ya da sesli hata verir.
# Kaldırma yok. Sesli hata kurtarılabilir; sessiz silme kurtarılamaz.
#
# Dağıtım izi (P-029): bu çağrıda derlenmiş bir release başarıyla kurulunca
# derlendiği commit `apk/<tarih>-<sha>` diye etiketlenir ve push'lanır.
# `audit.sh` §12 son etiketteki sözleşme sabitini SYSTEM.md ile karşılaştırır:
# kaynak kodu güncelleyip APK'yı derlememek (1.34-1.35'te olduğu gibi) artık
# açılışta görünür. Uygulama dosyalarında commit'lenmemiş değişiklik varsa
# APK hiçbir commit'e karşılık gelmez; o zaman etiket konmaz.
#
# Kullanım:
#   tool/install.sh                 # release derler ve kurar
#   tool/install.sh --debug         # debug derler ve kurar
#   tool/install.sh --no-build      # var olan APK'yı kurar
#   DEVICE=<cihaz-serisi> tool/install.sh
set -euo pipefail

MODE="release"
BUILD=1
for arg in "$@"; do
  case "$arg" in
    --debug)    MODE="debug" ;;
    --release)  MODE="release" ;;
    --no-build) BUILD=0 ;;
    *) echo "Bilinmeyen seçenek: $arg" >&2; exit 2 ;;
  esac
done

ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
[ -x "$ADB" ] || ADB="$(command -v adb || true)"
if [ -z "${ADB:-}" ] || [ ! -x "$ADB" ]; then
  echo "adb bulunamadı. ADB=/yol/adb tool/install.sh ile verebilirsin." >&2
  exit 1
fi

# Cihaz seçimi: DEVICE verilmemişse tek bağlı cihaz kullanılır.
if [ -z "${DEVICE:-}" ]; then
  # `mapfile` kullanılmıyor: macOS'un varsayılan bash'i 3.2 ve orada yok.
  DEVICES=()
  while IFS= read -r line; do
    [ -n "$line" ] && DEVICES+=("$line")
  done < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')

  if [ "${#DEVICES[@]}" -eq 0 ]; then
    echo "Bağlı cihaz yok." >&2
    exit 1
  elif [ "${#DEVICES[@]}" -gt 1 ]; then
    echo "Birden çok cihaz bağlı; hangisi olduğunu söyle:" >&2
    printf '  DEVICE=%s tool/install.sh\n' "${DEVICES[@]}" >&2
    exit 1
  fi
  DEVICE="${DEVICES[0]}"
fi

APK="build/app/outputs/flutter-apk/app-$MODE.apk"

# Release'i debug anahtarıyla imzalamak (SEC-010, B-101 açık) kendi cihazına
# kurmak için sorun değil; APK bu makineden çıkacaksa sorun. Uyarı burada
# duruyor çünkü Gradle'ın kendi uyarısını `flutter build` yutuyor — görünmeyen
# bir uyarı, olmayan bir uyarıdır.
if [ "$MODE" = "release" ] && [ ! -f android/key.properties ]; then
  cat <<'EOF'
==> Not: release, DEBUG anahtarıyla imzalanacak (SEC-010, B-101 açık).
    Kendi telefonuna kurmak için sorun değil. APK'yı paylaşacaksan önce
    kendi imza anahtarını üret: hub/tasks/waiting/2026-08-06-release-imza-anahtari.md
EOF
fi

# Etiket yalnız APK bir commit'e karşılık geliyorsa konur: bu çağrıda derlenmiş
# ve uygulama dosyaları commit'lenmiş olmalı. Hub dosyaları APK'yı etkilemez.
TAG_OK=0
if [ "$MODE" = "release" ] && [ "$BUILD" -eq 1 ]; then
  if [ -z "$(git status --porcelain -- lib android assets pubspec.yaml pubspec.lock 2>/dev/null)" ]; then
    TAG_OK=1
  else
    echo "==> Not: uygulama dosyalarında commit'lenmemiş değişiklik var; APK bir commit'e"
    echo "    karşılık gelmeyeceği için etiketlenmeyecek (audit.sh §12 onu göremez)."
  fi
fi

if [ "$BUILD" -eq 1 ]; then
  echo "==> $MODE derleniyor"
  flutter build apk "--$MODE"
fi

if [ ! -f "$APK" ]; then
  echo "APK yok: $APK (önce derle, ya da --no-build kullanma)" >&2
  exit 1
fi

echo "==> $DEVICE cihazına yerinde kuruluyor (kaldırma yok)"
# -r: var olan paketi yerinde günceller, veri korunur
# -t: debug/test derlemelerine izin verir
if OUT="$("$ADB" -s "$DEVICE" install -r -t "$APK" 2>&1)"; then
  echo "$OUT" | tail -2
else
  echo "$OUT" >&2
  cat >&2 <<'EOF'

Yerinde güncelleme başarısız. Paketi KALDIRMADIM — kaldırmak cihazdaki
bütün repo bağlantılarını ve token'ları silerdi.

Sık görülen sebep imza uyuşmazlığıdır (APK başka bir keystore ile
imzalanmış). Kaldırmadan önce:

  1. Ayarlar → Yedekleme → "Yedek oluştur" ile bağlantıları yedekle
     (parolayla şifreli tek metin; parola yöneticine kaydet).
  2. Sonra kaldır ve yeniden kur:
       adb -s <cihaz> uninstall us.gover.takip
       tool/install.sh
  3. Kurulumdan sonra Ayarlar → Yedekleme → "Geri yükle".
EOF
  exit 1
fi

if grep -qi 'Failure' <<<"$OUT"; then
  echo "adb 'Success' demedi; çıktıyı kontrol et." >&2
  exit 1
fi

echo "==> Tamam. Veri korundu; token'ı yeniden girmen gerekmiyor."

if [ "$TAG_OK" -eq 1 ]; then
  TAG="apk/$(date +%F)-$(git rev-parse --short HEAD)"
  CV=$(grep -oE "contractVersion = '[0-9.]+'" lib/core/constants.dart | grep -oE "[0-9.]+")
  if git tag -a "$TAG" -m "APK: $DEVICE cihazına kuruldu (tool/install.sh). Sözleşme sabiti ${CV:-?}." 2>/dev/null; then
    if git push -q origin "$TAG" 2>/dev/null; then
      echo "==> Dağıtım izi: $TAG (push'landı)"
    else
      echo "==> Dağıtım izi: $TAG (yerelde; push'lanamadı — git push origin $TAG)"
    fi
  else
    echo "==> Dağıtım izi zaten var: $TAG"
  fi
fi
