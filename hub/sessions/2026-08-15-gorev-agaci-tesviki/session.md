---
id: S-2026-08-15-gorev-agaci-tesviki
date: 2026-08-15
status: open
reconstructed: false
author: afgover
topics: [plan-agaci, sozlesme, tesvik, coklu-hub]
artifacts: []
tasks_touched: []
---

# Oturum: Görev ağacı neden boş — agent'ı teşvik etme

## Özet
(oturum açık)

## Kayıt

### Kullanıcı
> görev ağacını hiç bi repo doldurmamış, tam olarak anlaşılmıyor sanıyorum

### Agent — ölçüm: `takip`'te ağaç dolu, sorun başka yerde

Gerçek `PLAN.md` ayrıştırıcıdan geçirildi: **3 plan, 27 adım**, hepsi
ayrıştırılıyor. Yani `takip`'te veri var. Ölçüm iki başka şey gösterdi:

1. **Üç planın da durumu `tamamlandi`.** Ağacın işi yarım kalanı görünür
   kılmak; şu an görünür yarım iş yok, ekran üç kapalı planı listeliyor.
2. **Adım satırları paragrafa dönüşmüş.** Sözleşme "ağacın değeri
   seyrekliğinde" diyor ama bunu **plan sayısı** için söylüyor; adım satırının
   uzunluğuna dair bir sınır yok. P-003'ün adımlarına gerekçe sıkıştırıldığı
   için telefonda ağaç değil duvar görünüyor.

**Ayrıca gerçek bir ayrıştırıcı hatası bulundu** → [B-133](../../BACKLOG.md#B-133):
adım satırı alt satıra sarktığında devam satırı `title`'a ekleniyor ve `·`
ayracı bir daha aranmıyor. Dokuz adımda tamamlanma tarihi ya kayıp ya
başlığın içine gömülü.

### Kullanıcı
> düzeltiyorum, sadece copilot ağacı doldurmuş, diğerleri plan süreçleri
> içermesine rağmen ağaçları boş, agentı geçmiş planları da ekleyecek
> şekilde teşvik edebiliriz

### Agent — doktrin gerilimi işaretlendi

Öneri, hub'da **yazılı olan** bir doktrinle çelişiyor; karar verilmeden önce
gerilim kullanıcıya gösterildi. Ayrıntı aşağıda, kullanıcı kararı bekleniyor.
