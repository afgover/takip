---
id: S-2026-08-04-guvenlik-taramasi
date: 2026-08-04
status: open
reconstructed: false
topics: [guvenlik, bagimlilik-taramasi, token-kapsami]
artifacts:
  - artifacts/S-2026-08-04-guvenlik-taramasi/bagimlilik-ve-yapilandirma-taramasi.md
tasks_touched: []
---

# Oturum: Açık güvenlik işleri — SEC-005 ve SEC-006

## Özet
(oturum kapanışında yazılacak)

## Kayıt

### Kullanıcı
> repodaki gorevlerden devam et

### Agent
Açılış kontrolü: `tasks/inbox/` boş, `active/` ve `waiting/` boş — bekleyen
kullanıcı görevi yok. Sözleşme §10 kontrolü gereksiz: bu repo ana kopyanın
kendisi (1.11).

`BACKLOG.md`'de agent'ın tek başına ilerletebileceği iki açık madde kaldı,
ikisi de güvenlik: **B-091** (SEC-005 bağımlılık/zafiyet taraması) ve
**B-092** (SEC-006 token kapsamı doğrulaması). Diğer açık maddeler ya
kullanıcıya bağlı (B-052 bir haftalık kullanım, B-097 public karar,
B-098 store) ya da 2. plana alınmış Faz 6 işleri. Sıra: B-091 → B-092.

### Agent — B-091 (SEC-005 taraması)
Tarama koşuldu, tam çıktı
[artifact A-2026-08-04-001](../../artifacts/S-2026-08-04-guvenlik-taramasi/bagimlilik-ve-yapilandirma-taramasi.md)'de,
özeti SEC-008'de.

**Zafiyet:** `pubspec.lock`'taki 68 paketin tamamı OSV'ye (Pub ekosistemi)
soruldu → **bilinen zafiyet yok**. Bunu "temiz" diye yazmadan önce sorgunun
gerçekten çalıştığı doğrulandı: bilinen açıkları olan sürümlerden (archive
3.3.0, http 0.13.0, dio 4.0.0) kurulu bir kontrol grubu beklenen GHSA
kayıtlarını döndürdü. Doğrulanmamış bir "0 bulgu", olmayan bir güvence verir.

**Sır:** çalışma ağacı ve **git geçmişinin tamamı** token/anahtar desenlerine
karşı tarandı → eşleşme yok. SEC-001'in bağımsız doğrulaması.

**İki yeni bulgu:**
- **SEC-009** — `allowBackup` tanımlı değil, Android varsayılanı `true`:
  cihazdaki **şifresiz hub kopyası** (SEC-007) Google hesabına çıkabiliyor.
  SEC-007 riski "cihaz ele geçerse" diye kabul edilmişti; kapsamı kabul
  edildiğinden genişmiş. Token yedekten zaten geri gelmiyor (Keystore anahtarı
  dışa aktarılamaz), yani yedeklemeyi kapatmanın maliyeti yok. → B-100
- **SEC-010** — release derlemesi Flutter şablonundan gelen **debug
  anahtarıyla** imzalanıyor. Bugün etkisi sınırlı (APK sadece kendi cihaza
  kuruluyor) ama B-097'nin "Releases'ta APK" adımının ön koşulu. → B-101

Ayrıca SEC-011 açıldı: tarama koştuğu günün veritabanına göredir; tekrar
aralığına karar verilmedikçe "taradık" cümlesi zamanla sessizce yanlışa döner.
→ B-102
