#!/usr/bin/env bash
#
# Hub bekçisi — sözleşme 1.23'ün 30 dakika ritmini harness tarafından zorlar.
#
# Neden sözleşmede değil de burada: ajan bağlam sıkıştırmasının geldiğini
# **göremez**. Göremediği bir ana yazılmış kural, tetikleyicisini gözleyemeyen
# birine verilmiş emirdir; ölçüm de bunu doğruladı — iş commit'lerinin %40'ında
# kayıt 30 dakika içinde güncellenmemiş ve 318 oturumun 80'i `reconstructed`
# (A-2026-08-28-001). Sıkıştırmayı gören taraf harness, o yüzden kural buraya
# taşındı.
#
# İki mod:
#   --precompact     kayıt işin gerisindeyse çıkış 2 → sıkıştırma engellenir
#                    ve ajan, bağlamı hâlâ tamken kaydı yazar.
#   --session-start  sıkıştırmadan sonra ajana bağlam enjekte eder
#                    (PreCompact bunu yapamıyor, SessionStart yapabiliyor).
#
# **Bir kez engeller.** Otomatik sıkıştırma bağlam dolduğu için tetiklenir;
# ısrarla engellemek oturumu kilitlerdi. İşaret dosyası bu yüzden var: aynı
# oturumda ikinci kez engellemez, yalnız uyarır.
#
# Çıkış kodu: 0 geç (ya da bilgi verdi), 2 engelle.
set -uo pipefail

MODE="${1:---precompact}"
cd "$(dirname "$0")/.." || exit 0          # bekçi asla işi durdurmaz
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

STDIN_JSON="$(cat 2>/dev/null || true)"
SID="$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
MARK="${TMPDIR:-/tmp}/hub-guard-${SID:-nosession}.blocked"

# ── Kayıt işin gerisinde mi? Üç bağımsız işaret. ────────────────────────────
reasons=()

# 1) Commit'lenmemiş hub değişikliği
if [ -n "$(git status --porcelain -- hub 2>/dev/null)" ]; then
  reasons+=("hub/ altında commit'lenmemiş değişiklik var")
fi

# 2) Push'lanmamış hub commit'i — "push'lanmamış kayıt, yapılmamış kayıttır"
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  ahead=$(git rev-list --count '@{u}..HEAD' -- hub 2>/dev/null || echo 0)
  [ "${ahead:-0}" -gt 0 ] && reasons+=("$ahead hub commit'i push'lanmamış")
fi

# 3) Son iş commit'i, oturum kaydına son dokunuştan yeni mi
last_rec=$(git log -1 --format=%ct -- 'hub/sessions/*/session.md' 2>/dev/null || echo 0)
last_work=$(git log -1 --format=%ct --  hub ':!hub/sessions' 2>/dev/null || echo 0)
if [ "${last_work:-0}" -gt "${last_rec:-0}" ]; then
  mins=$(( (last_work - last_rec) / 60 ))
  [ "$mins" -gt 30 ] && reasons+=("son iş commit'i kayıttan $mins dakika yeni (v1.23: en fazla 30)")
fi

open_sess=$(grep -l '^status: open' hub/sessions/*/session.md 2>/dev/null | head -1)

if [ ${#reasons[@]} -eq 0 ]; then
  [ "$MODE" = "--session-start" ] && exit 0
  exit 0
fi

msg="Hub kaydı işin gerisinde: $(IFS='; '; echo "${reasons[*]}")."
[ -n "$open_sess" ] && msg="$msg Açık oturum: ${open_sess#hub/sessions/}."

case "$MODE" in
  --precompact)
    if [ -f "$MARK" ]; then
      # İkinci kez engellemez — kilitlenmeyi önlemek bilinçli.
      echo "$msg (Bir kez engellendi; ikinci kez geçiliyor.)" >&2
      exit 0
    fi
    : > "$MARK"
    echo "$msg Sıkıştırmadan ÖNCE session.md'yi güncelle, commit'le ve push'la (sözleşme 1.23, AGENT_PROTOCOL madde 4)." >&2
    exit 2
    ;;
  --session-start)
    ctx="Bağlam sıkıştırıldı ve sıkıştırma anında hub kaydı işin gerisindeydi: $msg Kaybolan ayrıntıyı uydurma — git geçmişinden (git log -p) türet, türettiğini kayda yaz ve gerekiyorsa frontmatter'a reconstructed: true koy."
    esc=$(printf '%s' "$ctx" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])' 2>/dev/null || printf '%s' "$ctx")
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
    exit 0
    ;;
esac
exit 0
