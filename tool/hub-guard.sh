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
# Dört mod:
#   --precompact     kayıt işin gerisindeyse çıkış 2 → sıkıştırma engellenir
#                    ve ajan, bağlamı hâlâ tamken kaydı yazar.
#   --session-start  sıkıştırmadan sonra ajana bağlam enjekte eder
#                    (PreCompact bunu yapamıyor, SessionStart yapabiliyor).
#   --prompt         (UserPromptSubmit, v1.33) kullanıcı mesajının geldiği
#                    anı bir işaret dosyasına yazar; başka bir şey yapmaz.
#   --stop           (Stop, v1.33) tur sonunda: açık oturumun session.md'si
#                    o işaretten sonra hiç değişmediyse ajanı BİR KEZ durdurur
#                    ({"decision":"block"}); commit/push 30 dakikadan eskiyse
#                    yalnız uyarır (systemMessage). Gerekçe L-059: sıkıştırma
#                    olmayan oturumda bekçi hiç koşmuyordu ve "sonuna
#                    biriktirme" art arda iki oturumda yakalanamadı.
#                    İşaret yoksa (kanca oturum ortasında kurulduysa) geçer;
#                    açık oturum yoksa geçer — oturum açmayı zorlamaz.
#
# **Bir kez engeller.** Otomatik sıkıştırma bağlam dolduğu için tetiklenir;
# ısrarla engellemek oturumu kilitlerdi. İşaret dosyası bu yüzden var: aynı
# oturumda ikinci kez engellemez, yalnız uyarır.
#
# Güvenlik sözleşmesi (SEC-016): bu script git durumunu OKUR; yalnız
# $TMPDIR'a oturum başına iki işaret dosyası YAZAR (.blocked, .prompt); ağa
# HİÇ çıkmaz; hiçbir repo dosyasını değiştirmez. Hata verirse, git yoksa, ikinci kez tetiklenirse GEÇER
# (fail open) — verebileceği en kötü zarar bir sıkıştırmayı bir kez
# geciktirmektir. Ana kopya: afgover/takip → tool/hub-guard.sh; kopyaların
# bayatlığını tool/audit.sh ölçer.
#
# Çıkış kodu: 0 geç (ya da bilgi verdi), 2 engelle.
set -uo pipefail

MODE="${1:---precompact}"
cd "$(dirname "$0")/.." || exit 0          # bekçi asla işi durdurmaz
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

STDIN_JSON="$(cat 2>/dev/null || true)"
SID="$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
# SID bir dosya adına giriyor; süzülmeden girerse "../" taşıyan bir stdin
# TMPDIR dışında dosya oluşturabilir/sıfırlayabilirdi. stdin'i harness'in
# kendisi veriyor (güvenilir sınır), ama bu script dağıtılacak — savunma
# ucuzken yapılır: yalnız [A-Za-z0-9._-] kalır, / ve boşluk atılır.
SID="$(printf '%s' "$SID" | tr -cd 'A-Za-z0-9._-' | cut -c1-64)"
MARK="${TMPDIR:-/tmp}/hub-guard-${SID:-nosession}.blocked"
PROMPT_MARK="${TMPDIR:-/tmp}/hub-guard-${SID:-nosession}.prompt"

if [ "$MODE" = "--prompt" ]; then
  : > "$PROMPT_MARK" 2>/dev/null
  exit 0
fi

# JSON dizesi: mesaja repo içinden dosya adı giriyor; kaçışsız bir tırnak
# bütün hook çıktısını geçersiz kılardı.
json_str() {
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null \
    || printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}

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

if [ "$MODE" = "--stop" ]; then
  # Döngü koruması: bu tur zaten bu kancanın durdurmasıyla devam ediyorsa geç.
  printf '%s' "$STDIN_JSON" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0
  [ -f "$PROMPT_MARK" ] || exit 0

  # 1) Kayıt bu turda güncellendi mi? Açık oturumlardan biri işaretten yeni
  #    olmalı (bu turda açılan ya da kapanan oturum da sayılır).
  if [ -n "$open_sess" ]; then
    fresh=0
    for s in $(grep -l '^status: open' hub/sessions/*/session.md 2>/dev/null); do
      [ "$s" -nt "$PROMPT_MARK" ] && fresh=1
    done
    if [ "$fresh" -eq 0 ]; then
      r="Hub bekçisi: açık oturumun kaydı (${open_sess#hub/}) bu turda güncellenmedi. AGENT_PROTOCOL madde 4: kullanıcının mesajı kısaltılmadan, cevabının özü karar/bulgu odaklı session.md'ye anında eklenir. Şimdi ekle; commit/push 30 dakika ritmine tabidir (v1.23). Bu tur için yalnız bir kez durduruldu."
      printf '{"decision":"block","reason":%s}\n' "$(json_str "$r")"
      exit 0
    fi
  fi

  # 2) Commit/push gecikmesi: yalnız uyar, 30 dakikayı aşmışsa.
  now=$(date +%s); stale=()
  oldest=0
  while IFS= read -r f; do
    [ -e "$f" ] || continue
    m=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
    { [ "$oldest" -eq 0 ] || [ "$m" -lt "$oldest" ]; } && oldest=$m
  # porcelain izlenmeyen dizini tek satıra indirir ("?? hub/x/"); dizinin
  # zamanı yanıltır. Dosyalar tek tek: değişen izlenenler + izlenmeyenler.
  done < <({ git diff --name-only HEAD -- hub; git ls-files --others --exclude-standard -- hub; } 2>/dev/null)
  [ "$oldest" -gt 0 ] && [ $(( (now - oldest) / 60 )) -gt 30 ] \
    && stale+=("commit'lenmemiş hub değişikliği $(( (now - oldest) / 60 )) dakikalık")
  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    first=$(git log --format=%ct '@{u}..HEAD' -- hub 2>/dev/null | tail -1)
    [ -n "$first" ] && [ $(( (now - first) / 60 )) -gt 30 ] \
      && stale+=("push'lanmamış hub commit'i $(( (now - first) / 60 )) dakikalık")
  fi
  if [ ${#stale[@]} -gt 0 ]; then
    w="Hub bekçisi: $(IFS='; '; echo "${stale[*]}") — v1.23 ritmi 30 dakika."
    printf '{"systemMessage":%s}\n' "$(json_str "$w")"
  fi
  exit 0
fi

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
    # JSON kaçışı: python3 varsa tam, yoksa en azından \ ve " kaçırılır —
    # mesaja repo içinden dosya adı giriyor ve kaçışsız bir tırnak bütün
    # hook çıktısını geçersiz kılardı.
    esc=$(printf '%s' "$ctx" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])' 2>/dev/null \
          || printf '%s' "$ctx" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
    exit 0
    ;;
esac
exit 0
