---
id: S-2026-07-30-repo-yapisi-netlestirme
date: 2026-07-30
status: closed
topics: [repo-yapisi, karar]
artifacts: []
tasks_touched: []
---

# Oturum: Repo rollerinin netleştirilmesi

## Özet
Önceki oturumun sonunda sorulan yapı sorusunun cevabı geldi ve kayda geçirildi.
K-013 karara bağlandı: `taskr` kendi kendine devam eden ayrı bir proje (salt
tarihçe değil); `taskr_takip` orijinal taskr projesinin takip hub'ı olacak
(kullanım dışı değil); `takip` projesi K-012 gereği takip dosyalarını kendi
içinde (`hub/`) tutar, `takip_takip` açılmaz. EVOLUTION.md'ye K-013 eklendi ve
K-007/K-011/K-012'ye güncelleme notları düşüldü; README repo tablosu ve
flutter-app-design'daki K-011 notu düzeltildi. Kod veya hub yapısında
değişiklik gerekmedi. Açık uç: `taskr_takip` içinde duran takip-projesi hub
geçmişinin taskr takibi başlatılırken ele alınması (taskr tarafının işi, bu
repo dışında).

## Kayıt

### [17:30] Kullanıcı
> önceki sessionda yarım kalan işleri devam ettirelim, sessionı taskr reposu
> üzerinden başlatmıştık, son gelen sorunun cevabı şu şekilde:
> biraz karmaşa oldu detaylı olarak istediğim şeyi anlatayım,
> taskr zaten kendi kendine devam eden bir proje, project-taskr branchı
> üzerinden şu anda geliştirdiğimiz takip projesinin daha önceki bir
> versiyonunu oluşturmuştuk, daha sonra bunu şu anda yaptığımız takip
> branchine evrilttik, taskr_takip reposu orjinal taskr projesinin takibi
> için kullanılacak,
> takip reposunda yeni projenin kodları var,
> normalde bir projenin takip dosyalarını _takip uzantılı 2. bir repo
> üzerinden kullanalım diye sözleşmiştik,
> fakat sadece takip reposu için bu kuralı uygulamayalım ve takip_takip adlı
> 2. bir repo oluşturmayıp, takip dosyalarını orjinal takip reposu içerisinde
> tutalım, bunu sadece ben kullanacağım işin bir risk oluşturmayacaktır

### [17:35] Agent
Cevap, önceki oturumda uygulanan K-012'yi teyit etti ve kayıtlardaki iki
yanlışı ortaya çıkardı: (1) `taskr` "salt tarihçe" değil, kendi başına devam
eden ayrı bir proje; (2) `taskr_takip` "kullanım dışı" değil, standart
`<proje>_takip` modeline uygun olarak orijinal taskr projesinin takip hub'ı
olacak. K-013 olarak karara bağlandı; EVOLUTION.md'deki K-007/K-011/K-012
notları, README repo tablosu ve flutter-app-design referansındaki K-011 notu
buna göre güncellendi. `takip/hub/` yapısında değişiklik gerekmedi — mevcut
durum (kod + hub aynı repoda, `takip_takip` yok) kullanıcının istediğiyle
birebir örtüşüyor.
