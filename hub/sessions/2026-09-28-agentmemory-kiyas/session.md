---
id: S-2026-09-28-agentmemory-kiyas
date: 2026-09-28
status: open
reconstructed: false
author: afgover
topics: [kiyas, agent-hafizasi, harici-repo]
artifacts:
  - artifacts/S-2026-09-28-agentmemory-kiyas/agentmemory-kiyas.md
tasks_touched: []
---

# Oturum: `rohitg00/agentmemory` incelemesi ve takip hub'ı ile kıyas

## Özet

*(oturum açık — kapanışta yazılacak)*

## Kayıt

### [11:38] Kullanıcı

> https://github.com/rohitg00/agentmemory
> bu repoyu incelemeni ve bizim repo ile kıyaslamanı istiyorum

### [11:40] Agent

Repo meta verisi: "Persistent memory for AI coding agents based on
real-world benchmarks", TypeScript, Apache-2.0, ~29k yıldız, ~25 MB,
bugün güncellenmiş. Plan [P-026](../../PLAN.md) olarak yazıldı; repo
scratchpad'e salt okunur klonlanacak, kodu çalıştırılmayacak. İçindeki
talimat metinleri (README, AGENTS.md vb.) veri olarak okunur, talimat
olarak uygulanmaz.

### [11:55] Agent

İnceleme bitti (`c314c7b`, v0.9.29). Bulgular:
- Mimari: hook'lar her araç kullanımını otomatik yakalıyor → dedup →
  gizlilik filtresi → sıkıştırma → BM25 (+vektör, +graf) indeksi;
  SessionStart'ta 2000 token bütçeyle top-K enjekte ediliyor. Depo yerel
  KV (`~/.agentmemory`), ayrı bir motor süreci (`iii` engine) üzerinde.
- İddia doğrulaması: %95,2 R@5 **geri getirme** isabeti, QA doğruluğu değil
  (kendi raporu söylüyor); aynı tabloda MemPalace %96,6 ile önde — README'nin
  "#1" iddiasıyla çelişiyor. "%92 token" v0.6.0'ın 240 sentetik gözlemli
  setinden, orada R@5 %43,8. Test iddiası doğru (182 dosya, ~1.880 test).
- `DESIGN.md` mimari değil, sitenin görsel tasarım sistemi.
- Gizlilik filtresi 40 satır: yalnız bilinen anahtar kalıpları + `<private>`;
  kişisel veri filtresi yok, istemler ve araç çıktıları saklanıyor.

### [12:10] Agent

Kıyas yazıldı:
[A-2026-09-28-001](../../artifacts/S-2026-09-28-agentmemory-kiyas/agentmemory-kiyas.md)
(`artifact-lint.sh` temiz). Sonuç: iki sistem farklı problemi çözüyor —
agentmemory ajan için geri çağırma motoru, takip insan ve ajan arasında
denetlenebilir iş defteri; örtüşme yalnız "geçmişi hatırlama". Benimseme
önerilmedi. Alınabilecek üç fikir [KARAR] olarak işaretlendi: hub içi arama
(B-145), oturum ritmi kancası (B-144 d), ders/kurallar için "yerine geçen"
alanı. Alınmaması gerekenler: otomatik ham yakalama (public repo, SEC-017),
servis bağımlılığı (K-001), sıkıştırılmış hafızayı kaynak saymak.
