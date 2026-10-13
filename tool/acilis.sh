#!/usr/bin/env bash
#
# Açılış kontrolleri — tek komut (sözleşme 1.28, Ö1).
#
# Neden: protokolün açılış adımları ayrı ayrı araç çağrısıyla koşulduğunda
# her çağrı bağlamın tamamını yeniden taşıyor; ölçülen ek maliyetin ana
# kaynağı tur sayısıydı (A-2026-08-30-001: +%28/oturum, 11 çağrıya karşı 2).
# Bu script maddeleri tek çağrıda koşar ve kompakt bir özet basar.
#
# Kara kutu riskine karşı iki kural (A-2026-08-30-001 §6):
#   - Koşamayan kontrol "koştu" diye GÖSTERİLMEZ; "KOŞMADI" satırı basılır
#     ve ajan o maddeyi elle yapar (L-035).
#   - Script özetin kaynağıdır, yetkisi değil: ajan şüphelendiği her satırda
#     dosyanın kendisine iner.
#
# Güvenlik sözleşmesi: git durumunu ve hub dosyalarını OKUR; hiçbir şey
# YAZMAZ; ağa yalnız iki GET atar (github.com Date başlığı, ana kopya diff'i).
#
# Kullanım:
#   tool/acilis.sh                   # bu reponun hub'ı
#   tool/acilis.sh --hub /yol/hub    # başka bir hub (v1.34; Projects
#                                    # thread'leri betiği takip klonundan
#                                    # kendi hub'larına koşar)
#
# Çıkış: 0 = temiz, 1 = dikkat isteyen madde var, 2 = koşamayan kontrol var.
set -uo pipefail
HUB=""
while [ $# -gt 0 ]; do
  case "$1" in
    --hub) HUB="${2:-}"; shift 2 ;;
    *) echo "Bilinmeyen seçenek: $1" >&2; exit 2 ;;
  esac
done
TOOL="$(cd "$(dirname "$0")" && pwd)"
if [ -z "$HUB" ]; then
  cd "$TOOL/.." || exit 2
  HUB="hub"
fi
HUB="${HUB%/}"
[ -d "$HUB" ] || { echo "hub yok: $HUB"; exit 2; }

ATTN=0; FAIL=0
say()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; ATTN=1; }
kos()  { printf '  ✗ KOŞMADI: %s — elle yap\n' "$*"; FAIL=1; }

say "Açılış — $(date '+%Y-%m-%d %H:%M %z')"

# 0) Hub dili
DIL=$(sed -n 's/^\*\*Hub dili:\*\* *//p' "$HUB/SYSTEM.md" | head -1)
DIL=${DIL:-tr}
ok "hub dili: $DIL"

# 0b) Çalışma ortamı (§16, v1.34) — ORTAM.md yoksa klasik
ORTAM=$(sed -n 's/^\*\*Çalışma ortamı:\*\* *//p' "$HUB/ORTAM.md" 2>/dev/null | head -1 | tr -d ' ')
[ "$ORTAM" = "projects" ] || ORTAM="klasik"
ok "çalışma ortamı: $ORTAM"

# 1) Saat — dış referansla (L-052)
NET=$(curl -fsSI --max-time 10 https://github.com 2>/dev/null | grep -i '^date:' | awk '{print $3" "$4" "$5}')
if [ -z "$NET" ]; then
  kos "saat doğrulaması (ağ isteği başarısız)"
else
  YEREL=$(LC_ALL=C date -u '+%d %b %Y')
  if [ "$NET" = "$YEREL" ]; then ok "saat ağla aynı gün ($YEREL UTC)"
  else warn "SAAT UYUŞMUYOR: yerel '$YEREL' / ağ '$NET' — kayıt yazmadan önce dur (L-052)"; fi
fi

# 2) Sözleşme — ana kopya diff'i (madde 3); dosya hub diline göre
SF=$([ "$DIL" = "en" ] && echo SYSTEM.en.md || echo SYSTEM.md)
MASTER=$(curl -fsSL --max-time 15 "https://raw.githubusercontent.com/afgover/takip/main/hub/$SF" 2>/dev/null)
if [ -z "$MASTER" ]; then
  kos "sözleşme karşılaştırması (ana kopya çekilemedi)"
else
  # Hub kendi kopyasını dil eki olmadan SYSTEM.md'ye yazar (§10, v1.21);
  # ana kopya dil ekli olabilir, yerel dosya her zaman SYSTEM.md.
  if [ "$MASTER" = "$(cat "$HUB/SYSTEM.md")" ]; then ok "sözleşme ana kopyayla aynı ($(sed -n 's/.*ürümü:\*\* *//p;s/.*ersion:\*\* *//p' "$HUB/SYSTEM.md" | head -1))"
  else warn "sözleşme ana kopyadan FARKLI — güncelle (raw ~5 dk önbellekler; az önce push'landıysa yanlış alarm olabilir)"; fi
fi

# 2b) Yerel kopya uzaktan geride mi (v1.34)
# Ölçülen vaka (2026-10-09): Projects thread'i financer_takip'in bu Mac'teki
# kopyasında açıldı; kopya 225 commit gerideydi (iş bulutta ve başka
# oturumlarda yürümüştü) ve thread bayat bir "tarama 32 gün" bulgusu
# raporladı — gerçekte tarama 2 günlüktü. Kontrol yalnız ls-remote ile
# OKUR; fetch yapmaz, hiçbir ref'i değiştirmez.
UZAK=$(git -C "$HUB" ls-remote origin HEAD 2>/dev/null | awk '{print $1}')
if [ -z "$UZAK" ]; then
  kos "uzak kopya karşılaştırması (ls-remote başarısız)"
elif git -C "$HUB" merge-base --is-ancestor "$UZAK" HEAD 2>/dev/null; then
  ok "yerel kopya uzaktaki son commit'i içeriyor"
else
  warn "YEREL KOPYA GERİDE: uzaktaki ${UZAK:0:7} yerelde yok — kayıt yazmadan ve bulgu raporlamadan önce git pull --rebase"
fi

# 3) Tarama yaşı (madde 4 — 30 gün)
# awk sırası: madde 4'ün istediği şey son `tarama` kaydının tarihi. Tarih
# satırı Tür satırından ÖNCE geldiği için önce tarih yakalanıp tür görülünce
# basılıyor. Tarih hesabı python3 ile: BSD/GNU `date` bayrakları uyumsuz.
SON=$(awk '/\*\*Tarih:\*\*/{d=$3} /\*\*Tür:\*\* tarama/{print d}' "$HUB/SECURITY.md" 2>/dev/null | sort | tail -1)
if [ -z "$SON" ]; then warn "hiç tarama kaydı yok — madde 4 taramayı ister"
else
  YAS=$(python3 -c "from datetime import date; print((date.today()-date.fromisoformat('$SON')).days)" 2>/dev/null)
  [ -z "$YAS" ] && YAS=999
  if [ "$YAS" -le 30 ]; then ok "son tarama $SON ($YAS gün)"
  else warn "son tarama $SON ($YAS gün) — 30 günü aştı, yenile (madde 4)"; fi
fi

# 4) Açık oturum (madde 1)
ACIK=$(grep -l '^status: open' "$HUB"/sessions/*/session.md 2>/dev/null || true)
if [ "$ORTAM" = "projects" ] && [ -n "$ACIK" ]; then
  # §16: thread oturumları birlikte açık kalabilir; terk eşiği 7 gün (son
  # commit'e göre, yoksa dosya zamanına göre). Klasikler kendi aralarında
  # tek açık kuralına tabi.
  KLASIK=""
  for f in $ACIK; do
    ad=${f#"$HUB"/sessions/}; ad=${ad%/session.md}
    if grep -q '^surface: projects' "$f"; then
      ts=$(git -C "$(dirname "$f")" log -1 --format=%ct -- session.md 2>/dev/null)
      [ -z "$ts" ] && ts=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
      gun=$(( ($(date +%s) - ${ts:-0}) / 86400 ))
      if [ "$gun" -gt 7 ]; then warn "TERK EDİLMİŞ THREAD OTURUMU: $ad ($gun gün) — §16: türetilmiş özetle kapat"
      else printf '  · açık thread oturumu: %s (%s gün — §16 izin veriyor)\n' "$ad" "$gun"; fi
    else KLASIK="$KLASIK $f"; fi
  done
  NK=$(printf '%s' "$KLASIK" | wc -w | tr -d ' ')
  if [ "$NK" -gt 1 ]; then
    for f in $KLASIK; do warn "AÇIK KLASİK OTURUM: ${f#"$HUB"/sessions/} — birden çok açık olamaz (madde 1)"; done
  elif [ "$NK" -eq 1 ]; then
    printf '  · açık klasik oturum: %s (tek — §2 izin veriyor)\n' "$(echo $KLASIK | sed 's|.*/sessions/||;s|/session.md||')"
  fi
  NACIK=-1
else
  NACIK=$(printf '%s' "$ACIK" | grep -c . || true)
fi
if [ "$NACIK" -eq -1 ]; then :
elif [ "$NACIK" -eq 0 ]; then ok "açık oturum yok"
elif [ "$NACIK" -eq 1 ]; then
  # Tek açık oturum meşru (§2: en yeni açık kalabilir) — büyük olasılıkla bu
  # oturumun kendisi; uyarı değil bilgi.
  printf '  · açık oturum: %s (tek — §2 izin veriyor)\n' "$(echo "$ACIK" | sed 's|.*/sessions/||;s|/session.md||')"
  # v1.35: ilk mesaj yalnız proje adıysa bu oturuma devam edilir; 2 günden
  # eskiyse önce kullanıcıya sorulur (son commit'e göre, yoksa dosya zamanı).
  ts=$(git -C "$(dirname "$ACIK")" log -1 --format=%ct -- session.md 2>/dev/null)
  [ -z "$ts" ] && ts=$(stat -f %m "$ACIK" 2>/dev/null || stat -c %Y "$ACIK" 2>/dev/null || echo 0)
  gun=$(( ($(date +%s) - ${ts:-0}) / 86400 ))
  if [ "$gun" -gt 2 ]; then printf '    ilk mesaj proje adıysa: oturum %s gündür bekliyor — devam mı, kapat+yeni mi, kullanıcıya sor (v1.35)\n' "$gun"
  else printf '    ilk mesaj proje adıysa: bu oturuma [devam] başlığıyla devam et (v1.35)\n'; fi
else for f in $ACIK; do warn "AÇIK OTURUM: ${f#"$HUB"/sessions/} — birden çok açık olamaz (madde 1)"; done; fi

# 5) inbox / waiting (madde 2, 9)
IN=$(ls "$HUB/tasks/inbox" 2>/dev/null | grep -v '^README' || true)
if [ -z "$IN" ]; then ok "inbox boş"
else warn "inbox'ta $(echo "$IN" | wc -l | tr -d ' ') görev:"; echo "$IN" | sed 's/^/      · /'; fi
WT=$(ls "$HUB/tasks/waiting" 2>/dev/null | grep -v '^README' || true)
[ -n "$WT" ] && printf '  · waiting (%s): %s\n' "$(echo "$WT" | wc -l | tr -d ' ')" "$(echo "$WT" | tr '\n' ' ')"

# 6) BACKLOG açık maddeleri — seçici bakış (Ö2, sayım denetimli)
say "BACKLOG — açık maddeler (satırlar özettir: bir maddeye dayanıp İŞ YAPMADAN önce gövdesi okunur)"
ACIKLAR=$(grep -nE '^- \[ \] (\*\*)?B-[0-9]+' "$HUB/BACKLOG.md" 2>/dev/null | grep -v 'B-001 · (sorumlu)' || true)
SAYI=$(printf '%s' "$ACIKLAR" | grep -c . || true)
BOYUT=$(wc -c < "$HUB/BACKLOG.md" | tr -d ' ')
if [ "$SAYI" -eq 0 ] && [ "$BOYUT" -gt 10000 ]; then
  kos "BACKLOG deseni boş döndü ama dosya ${BOYUT}B — biçim değişmiş olabilir, dosyaya elle bak"
else
  printf '%s\n' "$ACIKLAR" | sed 's/^/  /' | cut -c1-110
  ok "$SAYI açık madde (desen: '- [ ] B-' ya da '- [ ] **B-')"
fi

# 7) Geçici maddeler (§13)
grep -qE '^### G-[0-9]+' "$HUB/SYSTEM.md" && printf '  · §13 geçici madde var — oku ve hub\x27ına uyuyorsa uygula\n'

# 8) Hub denetimi (madde 4b)
if [ -x "$TOOL/audit.sh" ]; then
  say "Denetim (tool/audit.sh --quiet)"
  # rc boru hattından DEĞİL komutun kendisinden alınır — sed'in çıkışını
  # okumak, denetim bulgularını sessizce yutuyordu (ilk koşumda ölçüldü).
  AOUT=$("$TOOL/audit.sh" --hub "$(cd "$HUB" && pwd)" --quiet 2>&1); rc=$?
  printf '%s\n' "$AOUT" | sed 's/^/  /'
  [ $rc -eq 1 ] && ATTN=1
  [ $rc -eq 2 ] && kos "denetim"
else
  kos "denetim (tool/audit.sh bulunamadı)"
fi

echo
[ $FAIL -eq 1 ] && { say "Koşamayan kontrol var — o maddeleri elle yap; 'kontrol edildi' yazma."; exit 2; }
[ $ATTN -eq 1 ] && { say "Dikkat isteyen madde var."; exit 1; }
say "Açılış temiz."
