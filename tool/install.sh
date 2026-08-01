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
# Kullanım:
#   tool/install.sh                 # release derler ve kurar
#   tool/install.sh --debug         # debug derler ve kurar
#   tool/install.sh --no-build      # var olan APK'yı kurar
#   DEVICE=R5CW71GRKPB tool/install.sh
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
