---
id: S-2026-07-30-hub-tasima
date: 2026-07-30
status: closed
topics: [kurulum, tasima]
artifacts:
  - artifacts/reference/flutter-app-design.md
tasks_touched: []
---

# Oturum: Hub reposuna taşınma

## Özet
Kullanıcı hub reposunu (`afgover/takip`) oluşturdu ve her şeyin buraya
taşınmasını, taskr reposundaki ön çalışmadan kurtulunmasını istedi.
`hub-template/` iskeleti bu reponun köküne taşındı; Flutter uygulama tasarımı
sözleşmeye uygun frontmatter'la `artifacts/reference/flutter-app-design.md`
olarak kaydedildi. B-013 ve B-014 backlog'da işaretlendi, `EVOLUTION.md`
Aşama 1 durumu güncellendi (K-006: hub adı `takip`). taskr reposundaki
`project-taskr-hub/` klasörü kaldırıldı. Bu repo artık tek doğru kaynak.
Sıradaki adımlar: B-015 (kullanıcı: uygulama token'ı) ve B-016 (sözleşmenin
ilk görev döngüsüyle testi).

## Kayıt

### Kullanıcı
> project-taskr'dan kurtulup yeni repo `takip`e taşı her şeyi.

### Agent
`afgover/takip` session'a eklendi ve klonlandı (boş repo). İskelet köke
kopyalandı; Flutter tasarımı referans artifact'ine dönüştürüldü ve backlog'daki
yol referansları güncellendi. B-013/B-014 tamamlandı olarak işaretlendi,
EVOLUTION Aşama 1 güncellendi. Commit'ler SYSTEM.md §8 öneklerine göre atıldı
ve `main`'e push'landı. Ardından taskr reposundan `project-taskr-hub/` silindi.
