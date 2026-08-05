#!/usr/bin/env bash
#
# Güvenlik taraması — SEC-011 / B-102.
#
# Ağustos 2026'da elle koşulan taramanın (SEC-008) tekrar edilebilir hâli.
# Elle koşumun sorunu tekrarında ortaya çıkıyor: OSV toplu sorgusu, sır
# desenleri ve Android kontrolleri her seferinde yeniden hatırlanmak zorunda
# kalıyor ve bir sonraki koşum sessizce **eksik** oluyor.
#
# Dört parça:
#   1. Bilinen zafiyet  — pubspec.lock'taki her paket OSV'ye sorulur
#   2. Sürüm güncelliği — flutter pub outdated (doğrudan bağımlılıklar)
#   3. Sır taraması     — çalışma ağacı + git geçmişinin tamamı
#   4. Android          — yedekleme kuralları, izinler, release imzası
#
# Parça 1 sürekli izleme için Dependabot'a da devredildi (repo ayarlarından
# açık); burada durmasının sebebi ikisinin farklı anlarda konuşması: Dependabot
# yeni bir danışmanlık çıktığında, bu script "şu an durum ne" diye sorulduğunda.
#
# Kullanım:
#   tool/scan.sh              # hepsi
#   tool/scan.sh --quick      # ağ gerektiren parçayı (OSV) atla
#
# Çıkış kodu:
#   0  bulgu yok
#   1  bulgu var (kayda geçir)
#   2  tarama DOĞRULANAMADI — sonucu "temiz" diye yazma (aşağıya bak)
set -uo pipefail

cd "$(dirname "$0")/.."

QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1

FINDINGS=0
say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; FINDINGS=$((FINDINGS+1)); }
info() { printf '  · %s\n' "$*"; }

printf '\033[1mGüvenlik taraması\033[0m — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ---------------------------------------------------------------------------
# 1. Bilinen zafiyetler (OSV)
#
# Buradaki kritik kısım **kontrol grubu** (L-035): boş bir sonuç, "açık yok"
# kadar kolay "sorgu bozuldu" da demektir ve ikisi ekranda birebir aynı görünür.
# Bilinen açıkları olan sürümler de soruluyor; onlar da boş dönerse tarama
# kendini geçersiz ilan edip 2 ile çıkıyor. Doğrulanmamış bir "temiz",
# olmayan bir güvence verir.
# ---------------------------------------------------------------------------
if [ "$QUICK" -eq 1 ]; then
  say "1. Bilinen zafiyetler — atlandı (--quick)"
else
  say "1. Bilinen zafiyetler (OSV)"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  python3 - "$TMP" <<'PY'
import json, re, sys
tmp = sys.argv[1]
pkgs, name, in_pkgs = [], None, False
for ln in open('pubspec.lock'):
    if ln.startswith('packages:'):
        in_pkgs = True; continue
    if in_pkgs and ln.startswith('sdks:'):
        break
    if in_pkgs:
        m = re.match(r'^  ([A-Za-z0-9_]+):\s*$', ln)
        if m: name = m.group(1)
        m2 = re.match(r'^    version: "(.+)"\s*$', ln)
        if m2 and name:
            pkgs.append((name, m2.group(1))); name = None

# Kontrol grubu: bilinen danışmanlıkları olan sürümler. Sorgu çalışıyorsa
# bunlar DOLU dönmek zorunda.
control = [('archive', '3.3.0'), ('http', '0.13.0'), ('dio', '4.0.0')]
json.dump({'pkgs': pkgs, 'control': control}, open(f'{tmp}/meta.json', 'w'))
json.dump(
    {'queries': [{'package': {'name': n, 'ecosystem': 'Pub'}, 'version': v}
                 for n, v in pkgs + control]},
    open(f'{tmp}/query.json', 'w'))
print(f'  · {len(pkgs)} paket soruluyor (+{len(control)} kontrol)')
PY

  if ! curl -sS --max-time 60 -X POST -H 'Content-Type: application/json' \
      -d @"$TMP/query.json" https://api.osv.dev/v1/querybatch -o "$TMP/osv.json"; then
    # "Koşmadı" ile "bulgu var" aynı şey değil ve ikisi de "temiz" değil.
    # Ağ hatası da doğrulanamamış koşumdur → 2.
    printf '\n\033[1mOSV'"'"'ye ulaşılamadı — tarama koşmadı, kayıt yazma.\033[0m\n'
    exit 2
  else
    python3 - "$TMP" <<'PY' || exit 2
import json, sys
tmp = sys.argv[1]
meta = json.load(open(f'{tmp}/meta.json'))
pkgs, control = [tuple(x) for x in meta['pkgs']], [tuple(x) for x in meta['control']]

# Yanıt beklediğimiz biçimde mi? Uç nokta değişmiş ya da hata döndürmüş
# olabilir; bunu traceback'e bırakmak "koşmadı"yı "çöktü" gibi gösterir.
try:
    body = json.load(open(f'{tmp}/osv.json'))
except json.JSONDecodeError:
    print('  ! OSV yanıtı JSON değil — tarama koşmadı.')
    sys.exit(2)
res = body.get('results')
if not isinstance(res, list) or len(res) != len(pkgs) + len(control):
    print('  ! OSV yanıtı beklenen biçimde değil — tarama koşmadı.')
    print(f'    Yanıt: {str(body)[:200]}')
    sys.exit(2)

project, checks = res[:len(pkgs)], res[len(pkgs):]

# Önce aracın çalıştığını kanıtla.
proven = sum(1 for r in checks if r.get('vulns'))
if proven == 0:
    print('  ! KONTROL GRUBU BOŞ DÖNDÜ — sorgu bozuk olabilir.')
    print('    Bu koşumun sonucu geçersizdir; "temiz" diye kaydetme (L-035).')
    sys.exit(2)
print(f'  · kontrol grubu doğrulandı ({proven}/{len(control)} beklenen bulgu geldi)')

hits = 0
for (n, v), r in zip(pkgs, project):
    vulns = r.get('vulns', [])
    if vulns:
        hits += 1
        print(f"  ! {n} {v}: " + ', '.join(x['id'] for x in vulns))
if hits == 0:
    print(f'  ✓ {len(pkgs)} pakette bilinen zafiyet yok')
sys.exit(1 if hits else 0)
PY
    case $? in
      0) ;;
      2) printf '\n\033[1mTarama doğrulanamadı — kayıt yazma.\033[0m\n'; exit 2 ;;
      *) FINDINGS=$((FINDINGS+1)) ;;
    esac
  fi
fi

# ---------------------------------------------------------------------------
# 2. Sürüm güncelliği
#
# Bulgu sayılmıyor: geride kalmak bir açık değil. Yine de raporlanıyor, çünkü
# ana sürüm farkı bir danışmanlık çıktığında yamayı "sürüm yükselt"ten
# "kırıcı değişikliği karşıla"ya çeviriyor (SEC-008).
# ---------------------------------------------------------------------------
say "2. Sürüm güncelliği (bilgi)"
if command -v flutter >/dev/null 2>&1; then
  flutter pub outdated 2>/dev/null \
    | awk '/^direct dependencies:/{p=1;next} /^dev_dependencies:|^transitive/{p=0} p && NF' \
    | sed 's/^/  · /' || info "okunamadı"
else
  info "flutter yok, atlandı"
fi

# ---------------------------------------------------------------------------
# 3. Sır taraması
# ---------------------------------------------------------------------------
say "3. Sır taraması"
SECRET_RE='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|OPENSSH|EC) PRIVATE KEY'

if grep -rnE "$SECRET_RE" lib/ android/ tool/ test/ hub/ 2>/dev/null | grep -v Binary; then
  warn "çalışma ağacında sır deseni eşleşti (yukarıda)"
else
  ok "çalışma ağacı temiz"
fi

# Geçmiş ayrı taranıyor: silinmiş bir sır çalışma ağacında görünmez ama
# repoda durmaya devam eder.
if git log --all -p --no-color 2>/dev/null | grep -qE "$SECRET_RE"; then
  warn "git GEÇMİŞİNDE sır deseni eşleşti — token'ı iptal et, sonra temizliği planla"
else
  ok "git geçmişi temiz"
fi

# ---------------------------------------------------------------------------
# 4. Android yapılandırması
# ---------------------------------------------------------------------------
say "4. Android yapılandırması"
MANIFEST=android/app/src/main/AndroidManifest.xml
GRADLE=android/app/build.gradle.kts

# SEC-009 gerilemesi: `flutter create` manifesti yeniden üretirse bu öznitelikler
# sessizce gider ve veri yeniden buluta çıkmaya başlar.
if grep -q 'android:dataExtractionRules' "$MANIFEST" && \
   grep -q 'android:fullBackupContent' "$MANIFEST"; then
  ok "yedekleme kuralları bağlı (SEC-009)"
else
  warn "yedekleme kuralları EKSİK — cihazdaki şifresiz kopya buluta çıkabilir (SEC-009)"
fi

PERMS="$(grep -o 'android.permission.[A-Z_]*' "$MANIFEST" | sort -u | tr '\n' ' ')"
info "izinler: ${PERMS:-yok}"
if [ "$(printf '%s' "$PERMS" | wc -w)" -gt 1 ]; then
  warn "birden çok izin var — her biri gerekli mi, gözden geçir"
fi

if grep -q 'signingConfigs.getByName("debug")' "$GRADLE"; then
  warn "release derlemesi DEBUG anahtarıyla imzalanıyor (SEC-010, B-101)"
else
  ok "release kendi imza yapılandırmasını kullanıyor"
fi

# ---------------------------------------------------------------------------
say "Sonuç"
if [ "$FINDINGS" -eq 0 ]; then
  ok "bulgu yok"
  echo
  echo "  SECURITY.md'ye 'tarama' kaydı düş (Tür: tarama, Durum: kapali)."
  exit 0
fi
warn "$FINDINGS bulgu — SECURITY.md'ye kaydet, gerekiyorsa BACKLOG'a madde aç"
exit 1
