#!/usr/bin/env bash
#
# Artifact yazım biçimi denetimi — sözleşme 1.29, SYSTEM.md §3.
#
# Sorduğu soru: "bu dosya telefonda okunabilir mi?" Kurallar zevk meselesi
# değil, `flutter_markdown` 0.7.7'nin ölçülmüş sınırları: HTML çizilmez, `h4`
# ve altı gövde metnine düşer, kod bloğu sarmaz, dar ekranda geniş tablo sütun
# başına üç karaktere iner. Bir kurala hatırlanarak uyulmuyor — bu yüzden
# makinece koşuyor.
#
# Kullanım:
#   tool/artifact-lint.sh hub/artifacts/S-.../rapor.md   # tek dosya
#   tool/artifact-lint.sh --all                          # kural sonrası hepsi
#   tool/artifact-lint.sh --all --since 2026-09-11       # başka bir eşikten
#   tool/artifact-lint.sh --selftest                     # kapının kendi testi
#
# Çıkış kodu:
#   0  temiz
#   1  bulgu var
#   2  denetim KOŞAMADI — sonucu "temiz" diye yazma
set -uo pipefail

command -v python3 >/dev/null || { echo "python3 yok — denetim koşmadı" >&2; exit 2; }

if [ "${1:-}" = "--selftest" ]; then
  # T-025: eşik atlaması `created`'ı tırnaklı ya da eksik dosyalarda
  # sessizce yanlış çalışıyordu (bkz. aşağıdaki python bloğu). Dört satır
  # burada sınama olarak duruyor; tırnaklı ve eksik `created` kırmızıya
  # düşmeli, gerçekten eski dosya hâlâ atlanmalı.
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  ART="$TMP/hub/artifacts/S-selftest"
  mkdir -p "$ART"
  SELF="$0"

  cat > "$ART/kontrol.md" <<'EOF'
---
id: A-selftest-1
type: rapor
title: kontrol
created: 2026-09-24T10:00:00Z
---

# kontrol

## Özet
tek satır.
EOF

  cat > "$ART/tirnakli.md" <<'EOF'
---
id: A-selftest-2
type: rapor
title: tirnakli
created: "2026-09-24T10:00:00Z"
---

# tirnakli

## Özet
tek satır.
EOF

  cat > "$ART/eksik.md" <<'EOF'
---
id: A-selftest-3
type: rapor
title: eksik
---

# eksik

## Özet
tek satır.
EOF

  cat > "$ART/eski.md" <<'EOF'
---
id: A-selftest-4
type: rapor
title: eski
created: "2026-08-01T00:00:00Z"
---

# eski

## Özet
tek satır.
EOF

  cat > "$ART/README.md" <<'EOF'
# dizin belgesi

Frontmatter'sız; artifact değil.
EOF

  FAIL=0; N=0
  chk() {
    N=$((N + 1))
    local name="$1" want_exit="$2" want_grep="$3"; shift 3
    local out got_exit
    out=$("$SELF" --since 2026-09-11 "$@" 2>&1); got_exit=$?
    if [ "$got_exit" != "$want_exit" ]; then
      echo "  ✗ $name: çıkış $got_exit (beklenen $want_exit)"; echo "$out" | sed 's/^/      /'
      FAIL=1
    elif [ -n "$want_grep" ] && ! grep -q "$want_grep" <<<"$out"; then
      echo "  ✗ $name: '$want_grep' çıktıda yok"; echo "$out" | sed 's/^/      /'
      FAIL=1
    else
      echo "  ✓ $name"
    fi
  }

  chk "kontrol (tırnaksız, sağlam) denetlenir"          1 "1 dosya denetlendi" "$ART/kontrol.md"
  chk "tırnaklı created de denetlenir (eski hata: atlanıyordu)" 1 "1 dosya denetlendi" "$ART/tirnakli.md"
  chk "created eksikse atlanmaz, bulgu verir"           1 "eksik: created" "$ART/eksik.md"
  chk "gerçekten eski + tırnaklı → hâlâ atlanır (KOŞMADI, temiz değil)" 2 "" "$ART/eski.md"
  chk "README denetlenmez ama sayılır"                   2 "1 README" "$ART/README.md"
  chk "README yanında gerçek artifact denetlenmeye devam eder" 1 "1 dosya denetlendi" "$ART/README.md" "$ART/kontrol.md"

  # audit.sh §11 çıkış 2'nin sebebini yalnız stderr'den okur.
  N=$((N + 1))
  so=$("$SELF" --since 2026-09-11 "$ART/eski.md" 2>/dev/null)
  se=$("$SELF" --since 2026-09-11 "$ART/eski.md" 2>&1 >/dev/null)
  if [ -z "$so" ] && grep -q "KOŞMADI" <<<"$se"; then
    echo "  ✓ KOŞMADI mesajı stderr'de (audit.sh okuyabilir)"
  else
    echo "  ✗ KOŞMADI mesajı stderr'de değil — stdout: '$so'"; FAIL=1
  fi

  if [ "$FAIL" -eq 0 ]; then echo "selftest: $N/$N geçti"; exit 0; fi
  echo "selftest: BAŞARISIZ"; exit 1
fi

ALL=0
SINCE="2026-09-11"   # kuralın yürürlük tarihi; öncesi denetlenmez
FILES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --all)   ALL=1; shift ;;
    --since) SINCE="${2:-}"; shift 2 ;;
    -*) echo "Bilinmeyen seçenek: $1" >&2; exit 2 ;;
    *) FILES+=("$1"); shift ;;
  esac
done

if [ "$ALL" -eq 1 ]; then
  cd "$(dirname "$0")/.." || exit 2
  [ -d hub/artifacts ] || { echo "hub/artifacts yok" >&2; exit 2; }
  while IFS= read -r f; do FILES+=("$f"); done < <(find hub/artifacts -name '*.md' | sort)
fi

[ ${#FILES[@]} -gt 0 ] || { echo "Dosya verilmedi (--all ya da yol)" >&2; exit 2; }

SINCE="$SINCE" python3 - "${FILES[@]}" <<'PY'
import os, re, sys

since = os.environ.get("SINCE", "")
findings = 0
checked = 0
skipped = 0
readme = 0
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}")


def parse_date(raw):
    # YAML'da tarih tırnaklı da yazılabilir (`created: "2026-…"`); tırnağı
    # soymadan yapılan string karşılaştırması `"` (0x22) her zaman `2`
    # (0x32) harfinden küçük çıktığı için sessizce "eşik öncesi" sanıyordu.
    v = raw.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "'\"":
        v = v[1:-1]
    return v

EMOJI = re.compile(
    "[\\U0001F000-\\U0001FAFF"              # emoji blokları
    "\\u2190-\\u21FF\\u2300-\\u27BF"        # oklar, çeşitli simgeler
    "\\u2B00-\\u2BFF\\uFE0F]"               # geometrik simgeler, varyasyon
)
# Bozuk kodlamanın imzası: UTF-8 baytları Latin-1 sanılınca çıkan desen.
# "·" -> "Â·", emoji -> "â"/"ð" + kontrol karakteri;
# ucu da ekranda bos kutu olarak gorunur.
MOJIBAKE = re.compile(
    "\\u00c2[\\s\\u00b7]"                   # A-sapkali + bosluk/orta nokta
    "|\\u00e2[\\u0080-\\u009f\\ufffd]"      # a-sapkali + C1 kontrol
    "|\\u00f0\\u009f"                       # dort baytlik emojinin izi
)
HTML = re.compile(r"</?(table|div|br|span|p|ul|li|b|i|h[1-6])\b[^>]*>", re.I)
INLINE_CODE = re.compile(r"`[^`]*`")
# Sözlük iki dilde de tanınır: hub'ın dili `tr` ya da `en` olabilir ve
# linter dosyaya bakarak hangisinde olduğunu bilmez (SYSTEM.md §10, v1.21).
MARKERS = {"[BLOKER]", "[EKSIK]", "[TAMAM]", "[DOGRULANMALI]", "[RISK]",
           "[KARAR]",
           "[BLOCKER]", "[MISSING]", "[DONE]", "[UNVERIFIED]", "[DECISION]"}


def frontmatter(lines):
    if not lines or lines[0].strip() != "---":
        return None, 0
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], i + 1
    return None, 0


for path in sys.argv[1:]:
    # README dizin belgesidir, artifact değil — uygulama da artifact
    # listesinden eliyor (lib/hub/browse_repo.dart). Sayılır, sessiz kalmaz.
    if os.path.basename(path) == "README.md":
        readme += 1
        continue
    try:
        raw = open(path, encoding="utf-8").read()
    except (OSError, UnicodeDecodeError) as exc:
        print("  ! %s: okunamadı (%s)" % (path, exc))
        findings += 1
        continue

    lines = raw.split("\n")
    fm, body_at = frontmatter(lines)
    fields = {}
    if fm:
        for line in fm:
            m = re.match(r"^([a-z_]+):\s*(.*)$", line)
            if m:
                fields[m.group(1)] = m.group(2).strip()

    created_raw = fields.get("created", "")
    created = parse_date(created_raw)
    created_ok = bool(DATE_RE.match(created))
    if since and created_ok and created[:10] < since:
        skipped += 1
        continue   # kural yürürlüğe girmeden önce yazılmış; denetlenmez
    # created eksik ya da ayrıştırılamıyorsa (tırnak soyulduktan sonra bile
    # `YYYY-MM-DD` değilse) eşik öncesi sayılıp atlanmaz — denetlenir ve
    # aşağıdaki zorunlu-alan kontrolü bunu bulgu olarak yazar.
    checked += 1

    out = []

    def bad(msg):
        out.append(msg)

    for key in ("id", "session", "type", "title", "created"):
        if key not in fields:
            bad("frontmatter eksik: %s" % key)
    if "created" in fields and not created_ok:
        bad("frontmatter bozuk: created ayrıştırılamadı (%r)" % created_raw)

    body = lines[body_at:]
    heads = [(i, l) for i, l in enumerate(body) if re.match(r"^#{1,6}\s", l)]
    ozet = [i for i, l in heads if re.match(r"^##\s+(Özet|Summary)\s*$", l)]
    if not ozet:
        bad("`## Özet` bölümü yok")
    else:
        start = ozet[0] + 1
        nxt = next((i for i, _ in heads if i > ozet[0]), len(body))
        filled = [l for l in body[start:nxt] if l.strip()]
        if len(filled) > 5:
            bad("`## Özet` %d satır — en çok 5" % len(filled))

    if sum(1 for _, l in heads if l.startswith("# ")) != 1:
        bad("tam olarak bir `#` başlık olmalı (belgenin adı)")
    for i, l in heads:
        if re.match(r"^#{4,}\s", l):
            bad("satır %d: `####` ve altı başlık kullanılmaz" % (body_at + i + 1))

    in_code = False
    in_table = False
    for n, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            continue
        limit = 72 if in_code else 80
        if len(line) > limit:
            bad("satır %d: %d karakter — sınır %d" % (n, len(line), limit))

        # Satır içi kod (`...`) denetim dışı: kuralı **anlatan** belge, örnek
        # verdiği için kuralı çiğnemiş sayılamaz. Kod, yazılmış değil
        # alıntılanmış metindir.
        quoted = INLINE_CODE.sub("", line)

        if EMOJI.search(quoted):
            bad("satır %d: emoji var — ASCII işaret sözlüğü kullanılır" % n)
        if MOJIBAKE.search(quoted):
            bad("satır %d: bozuk kodlama izi (UTF-8/Latin-1)" % n)
        if not in_code and HTML.search(quoted):
            bad("satır %d: HTML etiketi — ekranda çizilmez, düz metin görünür" % n)

        is_row = (not in_code and line.startswith("|")
                  and line.rstrip().endswith("|"))
        if is_row:
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            # Sütun sayısı tablo başına bir kez söylenir: aynı tablonun her
            # satırı için tekrarlamak bir kusuru beş bulgu gibi gösterirdi.
            if len(cells) > 3 and not in_table:
                bad("satır %d: tablo %d sütun — en çok 3" % (n, len(cells)))
            for cell in cells:
                if len(cell) > 40 and not set(cell) <= set("-: "):
                    bad("satır %d: hücre %d karakter — en çok 40" % (n, len(cell)))
                    break
        in_table = is_row

        # Satırdaki **her** işaret denetlenir: ilkinde durmak, geçerli bir
        # işaretin arkasına gizlenmiş uydurma işareti görmezden gelirdi.
        for m in re.finditer(r"(?<!\S)\[([A-Z][A-Z_]{2,})\](?!\()", quoted):
            tag = "[%s]" % m.group(1)
            if tag not in MARKERS:
                bad("satır %d: %s sözlükte yok (SYSTEM.md §3)" % (n, tag))

    if "artifacts/" not in path.replace(os.sep, "/"):
        bad("dosya `artifacts/` altında değil")

    if out:
        findings += len(out)
        print("  ! %s" % path)
        for msg in out:
            print("      %s" % msg)

atlanan = "atlanan: %d eşik öncesi, %d README" % (skipped, readme)
if findings:
    print("\n%d bulgu (%d dosya denetlendi; %s)." % (findings, checked, atlanan))
    sys.exit(1)
if checked == 0:
    # Çıkış 2'nin mesajı stderr'e: çağıran (audit.sh §11) sebebi oradan okur.
    print("KOŞMADI (0 dosya denetlendi; %s) — sonucu temiz sayma" % atlanan,
          file=sys.stderr)
    sys.exit(2)
print("temiz (%d dosya denetlendi; %s; eşik %s)." % (checked, atlanan, since))
PY
