#!/usr/bin/env bash
#
# Hub denetimi — P-014.
#
# Sorduğu soru: "sözleşme uygulanıyor mu?" — ve cevabı **kaydın kendisinden
# değil**, kaydın dışından arar. Gerekçe L-052'de ölçüldü: hub iki saat
# boyunca kendi içinde kusursuz tutarlı ve tamamen yanlış bir tarih taşıdı;
# bütün kayıtlar birbirini doğruluyordu. Bir belgeyi kendi iddiasıyla
# doğrulamak, hiç doğrulamamaktır.
#
# Bu yüzden buradaki her kontrol **mekanik**tir: git grafiği ve zaman
# damgaları, dosya yolları, frontmatter alanları, klasör geçişleri, ID
# dizileri. Düzyazıya bakan tek bir kontrol yok — "yapıldı" cümlesi ölçüm
# değildir, o cümlenin yazıldığının kanıtıdır.
#
# Kullanım:
#   tool/audit.sh                    # bu reponun hub'ı
#   tool/audit.sh --hub /yol/hub     # başka bir hub (klon)
#   tool/audit.sh --quiet            # yalnız bulgular
#
# Çıkış kodu:
#   0  bulgu yok
#   1  bulgu var (kayda geçir)
#   2  denetim KOŞAMADI — sonucu "temiz" diye yazma
set -uo pipefail

HUB=""
QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --hub)   HUB="${2:-}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    *) echo "Bilinmeyen seçenek: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$HUB" ]; then
  cd "$(dirname "$0")/.." || exit 2
  HUB="$PWD/hub"
fi
[ -d "$HUB" ] || { echo "Hub bulunamadı: $HUB" >&2; exit 2; }

command -v python3 >/dev/null || { echo "python3 yok — denetim koşmadı" >&2; exit 2; }
git -C "$HUB" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "Hub bir git deposunda değil — mekanik kontrollerin çoğu koşamaz" >&2; exit 2; }

python3 - "$HUB" "$QUIET" <<'PY'
import os, re, subprocess, sys, datetime, collections, difflib

HUB, QUIET = sys.argv[1], sys.argv[2] == "1"
ROOT = subprocess.run(["git","-C",HUB,"rev-parse","--show-toplevel"],
                      capture_output=True, text=True).stdout.strip()
REL  = os.path.relpath(HUB, ROOT)

BOLD, OFF = "\033[1m", "\033[0m"
findings = []
def say(t):
    if not QUIET: print(f"\n{BOLD}{t}{OFF}")
def ok(t):
    if not QUIET: print(f"  ✓ {t}")
def info(t):
    if not QUIET: print(f"  · {t}")
def warn(t):
    findings.append(t); print(f"  ! {t}")

def git(*a):
    return subprocess.run(["git","-C",ROOT,*a], capture_output=True, text=True).stdout

def add_commit(path):
    """Dosyayı ekleyen ilk commit'in (sha, tarih) ikilisi — yeniden adlandırma izlenir."""
    out = git("log","--follow","--diff-filter=A","--format=%H %cI","--","path" if False else path)
    lines = [l for l in out.strip().split("\n") if l]
    return lines[-1].split() if lines else (None, None)

def frontmatter(p):
    try: t = open(p, encoding="utf-8").read()
    except Exception: return {}, ""
    if not t.startswith("---"): return {}, t
    end = t.find("\n---", 3)
    if end < 0: return {}, t
    fm = {}
    for line in t[3:end].split("\n"):
        if ":" in line and not line.startswith(" "):
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip().strip('"')
    return fm, t[end+4:]

# `author:` alanı sözleşmeye v1.15'te girdi. R-008: yeni alan opsiyoneldir ve
# yokluğu "önceden yazılmış" demektir — o tarihten önceki oturumlar suçlanmaz.
# Eşik hafızadan değil, alanı ekleyen commit'ten türetilir.
_a = git("log","--diff-filter=M","--format=%cs","-S","author:","--",f"{REL}/SYSTEM.md")
AUTHOR_SINCE = _a.strip().split("\n")[-1] if _a.strip() else None

# Görevin yol zinciri. Taşımalar dosya **adı değişerek** yapılabiliyor
# (2026-08-01'de inbox'taki uzun ad done'da kısaldı), bu yüzden ne `--follow`
# ne de ad araması yeter: aynı commit'te bir yol eklenip başka bir yol
# silindiyse bu bir taşımadır. Zincir buradan kurulur.
_MOVES = None
def _load_moves():
    global _MOVES
    _MOVES = collections.defaultdict(list)     # eklenen yol -> [aynı commit'te silinen yollar]
    cur_add, cur_del, msg = [], [], ""
    def flush():
        # Bir commit birden çok taşıma taşıyabiliyor (2d3e8d9'da iki tane vardı).
        # Her eklenen yolu, silinenler arasından **adı en çok benzeyene** bağla;
        # rastgele eşleşme zinciri yanlış göreve bağlar ve bulgu uydurur.
        for a in cur_add:
            if cur_del:
                best = max(cur_del, key=lambda d: difflib.SequenceMatcher(
                    None, os.path.basename(a), os.path.basename(d)).ratio())
                _MOVES[a].append((best, msg))
            else:
                _MOVES[a].append((None, msg))
    for line in git("log","--all","--name-status","--format=@%s","--",
                    f"{REL}/tasks").split("\n"):
        if line.startswith("@"):
            flush(); cur_add, cur_del, msg = [], [], line[1:]
        elif line.startswith(("A\t","D\t")):
            (cur_add if line[0]=="A" else cur_del).append(line[2:].strip())
        elif line.startswith("R"):
            parts = line.split("\t")
            if len(parts) == 3:          # git'in kendi gördüğü taşıma: doğrudan kenar
                _MOVES[parts[2]].append((parts[1], msg))
    flush()

def chain(relpath, depth=0):
    """Görevin geçtiği durum klasörleri + zincirin nerede bittiğinin gerekçesi."""
    if _MOVES is None: _load_moves()
    full = f"{REL}/{relpath}"
    seen, note = set(), "zincir yok"
    while full and depth < 12:
        m = re.search(r"tasks/(\w+)/", full)
        if m: seen.add(m.group(1))
        prevs = _MOVES.get(full)
        if not prevs: note = "hiç taşınmamış — doğrudan burada doğmuş"; break
        prev, msg = prevs[0]
        if prev is None:
            note = ("hub taşınmasıyla geldi" if "taşın" in msg
                    else "doğrudan burada doğmuş")
            break
        full, depth = prev, depth + 1
        note = "zincir izlendi"
    return seen, f"görülen: {', '.join(sorted(seen))}; {note}"

TODAY = datetime.date.today()
def days(d):
    try: return (TODAY - datetime.date.fromisoformat(d[:10])).days
    except Exception: return None

# ── 1. Kayıt tarihi, onu ekleyen commit'in tarihiyle uyuşuyor mu (L-052) ──────
sess_dir = os.path.join(HUB, "sessions")
say("1. Tarih tutarlılığı — kaydın yazdığı gün, kaydın doğduğu gün mü?")
ahead, late = 0, 0
for name in sorted(os.listdir(sess_dir)) if os.path.isdir(sess_dir) else []:
    f = os.path.join(sess_dir, name, "session.md")
    if not os.path.isfile(f): continue
    fm, _ = frontmatter(f)
    sha, when = add_commit(os.path.relpath(f, ROOT))
    if not when or "date" not in fm: continue
    rec, com = fm["date"][:10], when[:10]
    if rec == com: continue
    # İki yön iki farklı şey söyler ve karıştırılırsa ikisi de görünmez olur:
    #   kayıt commit'inden GERİDE → iş gece yarısını aşmış ya da geç push'lanmış
    #   kayıt commit'inden İLERİDE → **imkânsız**; makinenin saati yanlış (L-052)
    if rec > com:
        ahead += 1
        warn(f"oturum {name}: kayıt {rec} diyor ama commit {com} — kayıt kendi "
             f"commit'inden ileride, saat yanlış olmalı (L-052)")
    else:
        gap = (datetime.date.fromisoformat(com) - datetime.date.fromisoformat(rec)).days
        late += 1
        (info if gap <= 1 else warn)(
            f"oturum {name}: {rec} tarihli kayıt {com}'de push'lanmış ({gap} gün)")
if not ahead: ok("hiçbir kayıt kendi commit'inin ilerisinde değil")
if not late: ok("kayıtlar yazıldıkları gün push'lanmış")

# ── 2. Oturum prosedürü ──────────────────────────────────────────────────────
say("2. Oturum prosedürü (AGENT_PROTOCOL madde 1, 9-11)")
open_s, no_sum, no_auth, total = [], [], [], 0
for name in sorted(os.listdir(sess_dir)) if os.path.isdir(sess_dir) else []:
    f = os.path.join(sess_dir, name, "session.md")
    if not os.path.isfile(f): continue
    total += 1
    fm, body = frontmatter(f)
    if fm.get("status") == "open": open_s.append((name, fm.get("date","?")))
    if "author" not in fm and (AUTHOR_SINCE is None or fm.get("date","") > AUTHOR_SINCE):
        no_auth.append(name)
    m = re.search(r"^##\s*Özet\s*$(.*?)(?=^##\s|\Z)", body, re.M | re.S)
    if fm.get("status") == "closed" and (not m or len(m.group(1).strip()) < 40):
        no_sum.append(name)
info(f"{total} oturum kaydı")
for n, d in open_s:
    age = days(d)
    warn(f"oturum {n} hâlâ `open`" + (f" — {age} gün" if age is not None else ""))
if not open_s: ok("açık kalmış oturum yok")
for n in no_sum: warn(f"oturum {n} `closed` ama `## Özet` boş/çok kısa")
if not no_sum: ok("kapanmış oturumların hepsinde özet var")
for n in no_auth: warn(f"oturum {n}: `author` alanı yok (v1.15)")
if not no_auth: ok("bütün oturumlarda `author` var")

# ── 3. Kayıt anında mı, sonradan toplu mu yazıldı (madde 4) ──────────────────
say("3. Oturum kaydı anında mı tutulmuş? (madde 4: sonuna biriktirme yok)")
batch = 0
for name in sorted(os.listdir(sess_dir)) if os.path.isdir(sess_dir) else []:
    f = os.path.join(sess_dir, name, "session.md")
    if not os.path.isfile(f): continue
    fm, body = frontmatter(f)
    if fm.get("reconstructed") == "true": continue      # dürüstçe işaretli
    rel = os.path.relpath(f, ROOT)
    ncommit = len([l for l in git("log","--follow","--format=%H","--",rel).strip().split("\n") if l])
    nentry  = len(re.findall(r"^###\s*\[", body, re.M))
    if ncommit == 1 and nentry >= 4:
        batch += 1
        warn(f"oturum {name}: {nentry} kayıt satırı tek commit'te yazılmış "
             f"— sonuna biriktirilmiş görünüyor")
if not batch: ok("kayıtlar birden çok commit'e yayılmış (anlık tutulmuş)")

# ── 4. ID tekrarı ────────────────────────────────────────────────────────────
say("4. ID tekrarı (madde: sayaçlar tekildir)")
dups = 0
for fn, pat in (("BACKLOG.md", r"\b(B-\d{3})\b(?=\s*·)"),
                ("SECURITY.md", r"^##\s+(SEC-\d{3})\b"),
                ("PLAN.md", r"^##\s+(P-\d{3})\b"),
                ("knowledge/lessons.md", r"^##\s+(L-\d{3})\b"),
                ("knowledge/rules.md", r"^##\s+(R-\d{3})\b")):
    p = os.path.join(HUB, fn)
    if not os.path.isfile(p): continue
    txt = open(p, encoding="utf-8").read()
    # Dosya başlığındaki format örneği kayıt değildir: ilk `## ` başlığından
    # önceki her şey atlanır (B-001/B-002 örnek satırları buradaydı).
    i = txt.find("\n## ")
    ids = re.findall(pat, txt[i:] if i > 0 else txt, re.M)
    for i, n in collections.Counter(ids).items():
        if n > 1:
            warn(f"{fn}: {i} {n} kez tanımlanmış"); dups += 1
if not dups: ok("tekrarlanan ID yok")

# ── 5. Görev akışı ───────────────────────────────────────────────────────────
say("5. Görev akışı (madde 8: durum değişikliği klasör taşımayla)")
tasks = os.path.join(HUB, "tasks")
by_id, no_result, no_opt, skipped, migrated, pending_out = collections.defaultdict(list), [], [], [], [], []
for state in ("inbox","active","waiting","done"):
    d = os.path.join(tasks, state)
    if not os.path.isdir(d): continue
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".md") or fn == "README.md": continue
        p = os.path.join(d, fn)
        fm, _ = frontmatter(p)
        tid = fm.get("id")
        if tid: by_id[tid].append(f"{state}/{fn}")
        if state == "done" and fm.get("result","none") in ("none","",'""'):
            no_result.append(fn)
        # App görevi `id: pending` ile yazar ve ID'yi agent atar
        # (lib/hub/task_repo.dart). inbox dışında `pending` görmek, o adımın
        # hiç koşmadığı anlamına gelir: o göreve artık hiçbir kayıttan
        # bağlantı verilemez.
        if state != "inbox" and fm.get("id") == "pending":
            pending_out.append(f"{state}/{fn}")
        if state == "waiting" and "options" not in fm:
            no_opt.append(fn)
        if state == "done" and fm.get("created_by") == "user":
            seen, why = chain(f"tasks/{state}/{fn}")
            if not ({"inbox","active"} & seen):
                # Hub başka bir repodan taşındıysa zincirin öncesi orada kaldı;
                # bu denetçinin göremediği bir şeydir, kusur değil.
                (migrated if "taşınmasıyla" in why else skipped).append(f"{fn} ({why})")
counts = {s: len([f for f in os.listdir(os.path.join(tasks,s))
                  if f.endswith('.md') and f != 'README.md'])
          for s in ("inbox","active","waiting","done")
          if os.path.isdir(os.path.join(tasks,s))}
info("görev sayısı: " + ", ".join(f"{k}={v}" for k,v in counts.items()))
for t, w in by_id.items():
    if len(w) > 1: warn(f"görev ID {t} birden çok dosyada: {', '.join(w)}")
if not any(len(w) > 1 for w in by_id.values()): ok("mükerrer görev ID'si yok")
for f in pending_out: warn(f"{f}: `id: pending` — inbox'tan çıkmış ama ID atanmamış")
if not pending_out: ok("inbox dışında `id: pending` görev yok")
for f in no_result: warn(f"done/{f}: `result` boş — ne olduğu okunamıyor")
if not no_result: ok("kapanan görevlerin hepsinde `result` var")
for f in skipped: warn(f"done/{f}: inbox/ ya da active/ üzerinden geçmemiş")
if not skipped: ok("kullanıcı görevleri klasör zincirini izlemiş")
for f in migrated: info(f"done/{f} — zincirin öncesi başka repoda")
for f in no_opt: info(f"waiting/{f}: `options` yok (G-001 kapsamı olabilir)")

# ── 6. Bekleyenlerin yaşı ────────────────────────────────────────────────────
say("6. Bekleyen ve duran işler")
for state, limit in (("waiting", 30), ("active", 14), ("inbox", 7)):
    d = os.path.join(tasks, state)
    if not os.path.isdir(d): continue
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".md") or fn == "README.md": continue
        fm, _ = frontmatter(os.path.join(d, fn))
        age = days(fm.get("updated") or fm.get("created") or "")
        if age is not None and age > limit:
            warn(f"{state}/{fn}: {age} gündür hareketsiz (eşik {limit})")
if not any(f.startswith(("waiting/","active/","inbox/")) for f in findings):
    ok("eşiği aşan durgun görev yok")

# ── 7. Tarama kaydının yaşı ──────────────────────────────────────────────────
say("7. Tarama tetikleyicisi (madde 4 — 30 gün)")
sec = os.path.join(HUB, "SECURITY.md")
if os.path.isfile(sec):
    txt = open(sec, encoding="utf-8").read()
    blocks = re.split(r"^##\s+", txt, flags=re.M)
    scans = [re.search(r"\*\*Tarih:\*\*\s*(\d{4}-\d{2}-\d{2})", b).group(1)
             for b in blocks
             if "**Tür:** tarama" in b and re.search(r"\*\*Tarih:\*\*\s*(\d{4}-\d{2}-\d{2})", b)]
    if not scans:
        warn("hiç `tarama` kaydı yok — madde 4 taramayı şart koşuyor")
    else:
        last = max(scans); age = days(last)
        (ok if age <= 30 else warn)(f"son tarama {last} ({age} gün)")
else:
    warn("SECURITY.md yok")

# ── 8. App ↔ GitHub: gecikme iki ayrı sayıdır ────────────────────────────────
say("8. App ↔ GitHub akışı")
app = [l for l in git("log","--format=%H %cI %s","--",REL).strip().split("\n")
       if l.endswith("(app)")]
info(f"{len(app)} app commit'i")

# Tek bir "gecikme" sayısı yanıltıcı: kullanıcının görevi yazması ile ajanın
# onu görmesi arasında iki farklı mekanizma var ve ikisi farklı şeyler söyler.
#   push  = kullanıcı → GitHub   (bağlantı ve çevrimdışı kuyruk; app'in işi)
#   pick  = GitHub → ajan        (oturumun ne zaman açıldığı; iş akışını bu etkiler)
push_lag, pick_lag = [], []
for state in ("inbox","active","waiting","done"):
    d = os.path.join(tasks, state)
    if not os.path.isdir(d): continue
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".md") or fn == "README.md": continue
        fm, _ = frontmatter(os.path.join(d, fn))
        if fm.get("created_by") != "user": continue
        hist = [l.split(" ",1) for l in
                git("log","--all","--format=%H %cI","--",f"{REL}/tasks/*/{fn}")
                .strip().split("\n") if l]
        if not hist: continue
        added_at = hist[-1][1]                    # en eski dokunuş = inbox'a düşüş
        moved_at = hist[-2][1] if len(hist) > 1 else None   # ajanın ilk dokunuşu
        try:
            c = datetime.datetime.fromisoformat(fm["created"].replace("Z","+00:00"))
            a = datetime.datetime.fromisoformat(added_at)
            push_lag.append(((a - c).total_seconds(), f"{state}/{fn}"))
            if moved_at:
                m = datetime.datetime.fromisoformat(moved_at)
                pick_lag.append(((m - a).total_seconds(), f"{state}/{fn}"))
        except Exception: pass

def stat(lbl, xs, limit, note):
    if not xs:
        info(f"{lbl}: ölçülemedi"); return
    xs.sort()
    med, worst = xs[len(xs)//2][0], xs[-1]
    info(f"{lbl}: ortanca {med/3600:.1f} sa, en uzun {worst[0]/3600:.1f} sa ({worst[1]})")
    over = [x for x in xs if x[0] > limit]
    if over: warn(f"{lbl}: {len(over)} görev {limit/3600:.0f} saati aştı — {note}")

stat("kullanıcı → GitHub (push)", push_lag, 6*3600,
     "çevrimdışı kuyruk ya da bağlantı; app tarafı")
stat("GitHub → ajan (ilk dokunuş)", pick_lag, 48*3600,
     "görev görülene kadar bekledi; iş akışını asıl bu etkiler")

print()
if findings:
    print(f"{BOLD}{len(findings)} bulgu.{OFF} Kayda geçir: SECURITY.md / BACKLOG.md.")
    sys.exit(1)
print(f"{BOLD}Bulgu yok.{OFF}")
PY
