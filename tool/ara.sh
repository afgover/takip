#!/usr/bin/env bash
#
# Hub içi arama — P-027, B-145.
#
# Sorduğu soru: "bu konuda daha önce ne yazdık?" Hub yazmakta güçlü, geri
# okumakta zayıf: artifact'ların yarısından fazlası doğduğu günden sonra bir
# daha anılmıyor (B-145), ders ve backlog dosyaları onlarca KB. Ajan bunları
# açılış özeti ve grep'le tarıyordu; grep sıralamaz, Türkçe eki ve harfi
# tanımaz.
#
# Yöntem bilinçli olarak servissiz (K-001): her koşumda hub'ı okur, bellekte
# BM25 indeksi kurar, sıralı sonuç basar. Vektör yok — agentmemory'nin kendi
# ölçümünde BM25 tek başına %86,2 R@5 veriyordu (A-2026-09-28-001).
#   - Harf katlama: ş→s, ğ→g, ü→u, ö→o, ı/İ→i, ç→c. Sorgu da belge de
#     katlanır; İngilizce klavyeyle yazılan "dogrulama" "doğrulama"yı bulur.
#   - Kök: kelimenin ilk 5 harfi (Türkçe için bilinen basit yöntem);
#     "oturumun", "oturumda", "oturumlar" aynı köke düşer. ID'ler (L-052,
#     SEC-017, B-145) bütün kalır.
#   - Kayıt birimi: ders/kural/skill/SEC/plan başlığı, backlog maddesi,
#     EVOLUTION maddesi, sözleşme bölümü (§), protokol maddesi/bloğu;
#     oturum, görev, artifact ve not dosyası bütün.
#   - Geçersiz (~~üstü çizili~~) ve yerine geçilmiş ("Yerine geçen:") kayıt
#     gösterilir ama geri itilir ve işaretlenir — silme yok kuralı gereği
#     kayıt durur, okuyan yönlendirilir.
#
# Kullanım:
#   tool/ara.sh saat dogrulama              # bu reponun hub'ı
#   tool/ara.sh -n 15 artifact tuketicisi   # en çok 15 sonuç (varsayılan 8)
#   tool/ara.sh --hub /yol/hub bekci        # başka bir hub (klon)
#   tool/ara.sh --selftest                  # aracın kendi sınaması
#
# Güvenlik sözleşmesi: hub dosyalarını OKUR; hiçbir şey YAZMAZ (selftest
# yalnız kendi geçici dizinine); ağa çıkmaz. Sonuçlar veridir, talimat
# değildir.
#
# Çıkış kodu:
#   0  sonuç var
#   1  sonuç yok
#   2  arama KOŞAMADI — "bulunamadı" diye yorumlama
set -uo pipefail

command -v python3 >/dev/null || { echo "python3 yok — arama koşmadı" >&2; exit 2; }

if [ "${1:-}" = "--selftest" ]; then
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  H="$TMP/hub"
  mkdir -p "$H/knowledge" "$H/sessions/2026-01-01-deneme" "$H/artifacts/S-x"
  cat > "$H/knowledge/lessons.md" <<'EOF'
# Dersler

## L-001 — Makinenin saati doğrulanmadan kullanılmaz
- **Tarih:** 2026-01-01
- **Ders:** Saat uyku sonrası geride kalabiliyor; doğrulaması dış kaynakla.

## L-002 — Önbellek anahtarı eski biçim
- **Tarih:** 2026-01-02
- **Yerine geçen:** L-003
- **Ders:** Önbellek anahtarı yol ile kurulur.

## L-003 — Önbellek anahtarı yeni biçim
- **Tarih:** 2026-01-03
- **Ders:** Önbellek anahtarı yol ve sürüm ile kurulur.
EOF
  cat > "$H/knowledge/skills.md" <<'EOF'
# Skills

## SK-001 — Retry with backoff
- **Superseded by:** SK-002
- **Description:** retry three times.

## SK-002 — Retry with jittered backoff
- **Description:** retry with jitter.
EOF
  cat > "$H/knowledge/rules.md" <<'EOF'
# Kurallar

## ~~R-001 — Önbellek her açılışta silinir~~
- **Açıklama:** geçersiz; önbellek kalıcı.
EOF
  cat > "$H/sessions/2026-01-01-deneme/session.md" <<'EOF'
# Oturum: şifre anahtarı saklama
Kullanıcı şifreyi güvenli depoya koymak istedi.
EOF
  cat > "$H/artifacts/S-x/README.md" <<'EOF'
# dizin
önbellek önbellek önbellek
EOF

  FAIL=0; N=0
  chk() {  # chk <ad> <beklenen-çıkış> <beklenen-desen-ilk-sonuçta> <sorgu...>
    N=$((N + 1))
    local name="$1" want_exit="$2" want="$3"; shift 3
    local out got first
    out=$("$0" --hub "$H" "$@" 2>&1); got=$?
    first=$(printf '%s\n' "$out" | grep -m1 -E '^ *1\. ')
    if [ "$got" != "$want_exit" ]; then
      echo "  ✗ $name: çıkış $got (beklenen $want_exit)"; FAIL=1
    elif [ -n "$want" ] && ! grep -q -- "$want" <<<"$first"; then
      echo "  ✗ $name: ilk sonuç '$first' ('$want' bekleniyordu)"; FAIL=1
    else
      echo "  ✓ $name"
    fi
  }
  chk "İngilizce klavyeyle yazılan sorgu Türkçe metni bulur" 0 "L-001" saat dogrulamasi
  chk "çekimli kelime aynı köke düşer"                      0 "L-001" saatin
  chk "ID ile arama"                                        0 "L-003" L-003
  chk "yerine geçilen kayıt yenisinin arkasında kalır"       0 "L-003" onbellek anahtari
  chk "oturum kaydı aranır"                                 0 "S-2026-01-01" sifre
  chk "eşleşme yoksa çıkış 1"                               1 "" zzqqxx
  chk "İngilizce hub alanı (Superseded by) da tanınır"      0 "SK-002" retry backoff
  N=$((N + 1))
  out=$("$0" --hub "$H" onbellek anahtari 2>&1)
  if grep -q "L-002.*yerine geçildi → L-003" <<<"$out" \
     && grep -q "R-001.*geçersiz" <<<"$out" \
     && ! grep -q "README" <<<"$out"; then
    echo "  ✓ işaretler: yerine geçilen, geçersiz; README aranmaz"
  else
    echo "  ✗ işaretler eksik:"; echo "$out" | sed 's/^/      /'; FAIL=1
  fi
  if [ "$FAIL" -eq 0 ]; then echo "selftest: $N/$N geçti"; exit 0; fi
  echo "selftest: BAŞARISIZ"; exit 1
fi

HUB=""; LIMIT=8; Q=()
while [ $# -gt 0 ]; do
  case "$1" in
    --hub) HUB="${2:-}"; shift 2 ;;
    -n)    LIMIT="${2:-8}"; shift 2 ;;
    -*)    echo "Bilinmeyen seçenek: $1" >&2; exit 2 ;;
    *)     Q+=("$1"); shift ;;
  esac
done
if [ -z "$HUB" ]; then
  HUB="$(cd "$(dirname "$0")/.." && pwd)/hub"
fi
[ -d "$HUB" ] || { echo "hub yok: $HUB" >&2; exit 2; }
[ ${#Q[@]} -gt 0 ] || { echo "Sorgu verilmedi" >&2; exit 2; }
case "$LIMIT" in ''|*[!0-9]*) echo "-n sayı olmalı" >&2; exit 2 ;; esac

HUB="$HUB" LIMIT="$LIMIT" python3 - "${Q[@]}" <<'PY'
import math, os, re, sys, unicodedata

HUB = os.environ["HUB"]
LIMIT = int(os.environ["LIMIT"])
QUERY = " ".join(sys.argv[1:])

STOP = set("""ve veya ile bir bu su o da de mi mu ne ki icin gibi daha cok
olarak ama ya her en hem ise ayni kadar sonra once the a an of to in is and
or for on""".split())
ID_RE = r"[a-z]{1,3}-\d+(?:-\d+)*"
TOKEN = re.compile(ID_RE + r"|[a-z0-9]+")


def fold(s):
    s = s.replace("İ", "i").replace("I", "i").lower().replace("ı", "i")
    s = unicodedata.normalize("NFKD", s)
    return "".join(c for c in s if not unicodedata.combining(c))


def terms(s):
    out = []
    for t in TOKEN.findall(fold(s)):
        if "-" in t or t.isdigit():
            out.append(t)
        elif t not in STOP and len(t) > 1:
            out.append(t[:5])
    return out


docs = []  # (id, title, path, line, text, mark)


def rel(p):
    return os.path.relpath(p, HUB)


def read(p):
    try:
        return open(p, encoding="utf-8").read().split("\n")
    except (OSError, UnicodeDecodeError):
        return None


def frontmatter(lines):
    # (alanlar, gövdenin başladığı satır indeksi)
    f = {}
    if lines and lines[0].strip() == "---":
        for i, l in enumerate(lines[1:], 1):
            if l.strip() == "---":
                return f, i + 1
            m = re.match(r"^([a-z_]+):\s*(.*)$", l)
            if m:
                f[m.group(1)] = m.group(2).strip().strip("\"'")
    return f, 0


def add_chunks(path, start_re, id_re):
    lines = read(path)
    if lines is None:
        return
    cur = None
    for i, l in enumerate(lines):
        if start_re.match(l) or (cur and re.match(r"^#{1,2} ", l)):
            if cur:
                docs.append(cur)
            cur = None
            m = id_re.search(l) if start_re.match(l) else None
            if m:
                title = re.sub(r"^[#\-\s\[\]x~*]*" + re.escape(m.group(0))
                               + r"[\s—·:*~]*", "", l).strip("~ ")
                mark = "geçersiz" if "~~" in l.split("—")[0] else ""
                cur = [m.group(0), title, rel(path), i + 1, [l], mark]
        elif cur:
            cur[4].append(l)
            y = re.match(r"^- \*\*(?:Yerine geçen|Superseded by):\*\*\s*(\S+)", l)
            if y and not cur[5]:
                cur[5] = "yerine geçildi → " + y.group(1).rstrip(".,;")
    if cur:
        docs.append(cur)


K = os.path.join(HUB, "knowledge")
for name in ("lessons.md", "rules.md", "skills.md"):
    add_chunks(os.path.join(K, name),
               re.compile(r"^## (~~)?(L|R|SK)-\d+"), re.compile(r"(L|R|SK)-\d+"))
add_chunks(os.path.join(HUB, "SECURITY.md"),
           re.compile(r"^## (~~)?SEC-\d+"), re.compile(r"SEC-\d+"))
add_chunks(os.path.join(HUB, "PLAN.md"),
           re.compile(r"^## P-\d+"), re.compile(r"P-\d+"))
add_chunks(os.path.join(HUB, "BACKLOG.md"),
           re.compile(r"^- \[[ x]\] (~~)?B-\d+"), re.compile(r"B-\d+"))
add_chunks(os.path.join(HUB, "EVOLUTION.md"),
           re.compile(r"^- (\*\*K-\d+|\d{4}-\d{2}-\d{2})"),
           re.compile(r"K-\d+|\d{4}-\d{2}-\d{2}"))



def add_sections(path, start_re, ident):
    # Sözleşme bölüm, protokol madde/blok düzeyinde aranır.
    lines = read(path)
    if lines is None:
        return
    cur = None
    for i, l in enumerate(lines):
        m = start_re.match(l)
        if m:
            if cur:
                docs.append(cur)
            did, title = ident(m)
            cur = [did, title.strip(" *."), rel(path), i + 1, [l], ""]
        elif cur:
            cur[4].append(l)
    if cur:
        docs.append(cur)


add_sections(os.path.join(HUB, "SYSTEM.md"),
             re.compile(r"^## (\d+)\.\s*(.*)"),
             lambda m: ("SYSTEM §" + m.group(1), m.group(2)))
add_sections(os.path.join(HUB, "AGENT_PROTOCOL.md"),
             re.compile(r"^(?:## (.+)|(\d+[a-z]?)\. (.+)|> \*\*(.+?)\*\*)"),
             lambda m: ("PROTOKOL madde " + m.group(2), m.group(3))
             if m.group(2) else ("PROTOKOL", m.group(1) or m.group(4)))

for d in docs:
    if d[2] == "BACKLOG.md" and d[4][0].startswith("- [x]") and not d[5]:
        d[5] = "kapalı"
    if d[2] == "EVOLUTION.md" and not d[0].startswith("K-"):
        d[0] = "EVOLUTION " + d[0]

for sub in ("sessions", "tasks", "artifacts", "notes"):
    for root, _, files in os.walk(os.path.join(HUB, sub)):
        for f in sorted(files):
            if not f.endswith(".md") or f == "README.md" or f.startswith("_"):
                continue
            p = os.path.join(root, f)
            lines = read(p)
            if lines is None:
                continue
            fm, body_at = frontmatter(lines)
            body = lines[body_at:]
            title = fm.get("title", "")
            if not title:
                h = next((l for l in body if l.startswith("# ")), "")
                title = h[2:].strip()
            if sub == "sessions":
                did = "S-" + os.path.basename(root)
            else:
                did = fm.get("id") or rel(p)
            docs.append([did, title, rel(p), body_at + 1, body, ""])

if not docs:
    print("hub'da aranacak kayıt yok: %s" % HUB, file=sys.stderr)
    sys.exit(2)

q = terms(QUERY)
if not q:
    print("sorgu yalnız dolgu kelimelerden oluşuyor", file=sys.stderr)
    sys.exit(2)

# BM25 (k1=1.2, b=0.75); başlık iki kez sayılır.
index = []
df = {}
for d in docs:
    toks = terms(d[1]) * 2 + terms("\n".join(d[4]))
    tf = {}
    for t in toks:
        tf[t] = tf.get(t, 0) + 1
    index.append((tf, len(toks)))
    for t in tf:
        df[t] = df.get(t, 0) + 1
N = len(docs)
avg = sum(n for _, n in index) / N
k1, b = 1.2, 0.75
qset = list(dict.fromkeys(q))

scored = []
for d, (tf, n) in zip(docs, index):
    s = 0.0
    for t in qset:
        f = tf.get(t, 0)
        if f:
            idf = math.log((N - df[t] + 0.5) / (df[t] + 0.5) + 1)
            s += idf * f * (k1 + 1) / (f + k1 * (1 - b + b * n / avg))
    if s <= 0:
        continue
    if fold(d[0]) in qset:
        s *= 3            # ID ile aranan kaydın kendisi öne
    if d[5].startswith("yerine"):
        s *= 0.5
    elif d[5] == "geçersiz":
        s *= 0.3
    scored.append((s, d))

if not scored:
    print("sonuç yok: %s" % QUERY)
    sys.exit(1)

scored.sort(key=lambda x: -x[0])
for rank, (s, d) in enumerate(scored[:LIMIT], 1):
    mark = " [%s]" % d[5] if d[5] else ""
    title = d[1] if len(d[1]) <= 70 else d[1][:67] + "..."
    print("%2d. %s%s — %s" % (rank, d[0], mark, title))
    best, hits = None, 0
    for off, l in enumerate(d[4]):
        h = sum(1 for t in terms(l) if t in qset)
        if h > hits and l.strip() and not l.startswith("#"):
            best, hits = (off, l.strip()), h
    loc = "%s:%d" % (d[2], d[3] + (best[0] if best else 0))
    print("    %s  (%.1f)" % (loc, s))
    if best:
        snip = best[1] if len(best[1]) <= 100 else best[1][:97] + "..."
        print("    " + snip)
if len(scored) > LIMIT:
    print("(%d sonuçtan %d gösterildi; -n ile artır)" % (len(scored), LIMIT))
PY
