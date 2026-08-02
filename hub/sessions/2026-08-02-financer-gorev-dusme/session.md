---
id: S-2026-08-02-financer-gorev-dusme
date: 2026-08-02
status: closed
topics: [coklu-repo, gorev, hijyen]
artifacts: []
tasks_touched: []
---

# Oturum: financer_takip'e görev düşme

## Özet
Kısa oturum: kullanıcının isteğiyle `financer_takip` hub'ına `.DS_Store` /
`.gitignore` hijyen görevi düşüldü (orada **T-002**, `inbox/`).

Görev yazılırken repo incelendi ve iki şey daha görüldü:

1. **`financer_takip`'te `.gitignore` hiç yok** — yalnız `.DS_Store` değil,
   bundan sonraki her geçici dosya sessizce commit'lenebilir. Görev bunu da
   kapsayacak şekilde yazıldı.
2. **O repodaki `SYSTEM.md` sürüm 1.3**, ama `tasks/waiting/` klasörünü zaten
   kullanıyorlar. Yani kullandıkları klasörü kendi sözleşme kopyaları
   tanımlamıyor. Kullanıcıya bildirildi; ayrı görev açılıp açılmayacağı ona
   bırakıldı (başka projenin hub'ına kendiliğinden ikinci görev düşürmek
   istenen işin dışına çıkardı).

Ayrıca doğrulandı: kullanıcı `financer_takip`'teki **T-001** için de
uygulamadan "Yaptım" demiş (2026-08-01T11:03:58Z); bildirim orada `inbox/`ta
duruyor, asıl görev hâlâ `waiting/`te — o projede çalışan agent henüz
almamış. **`waiting/` mekanizması ikinci bir projede, bu oturumdan bağımsız
olarak çalışmış.**

## Kayıt

### Kullanıcı
> .DS_Store için görev düş

### Agent
`financer_takip` klonu güncellendi ve durum ölçüldü: `.DS_Store` gerçekten
izleniyor (`git ls-files`), `.gitignore` ise **hiç yok**. Görev bu iki
bulguyu birlikte ele alacak şekilde yazıldı; `git rm --cached` ile izlemeyi
bırakmanın dosyayı diskten silmediği de not edildi.

Görev o reponun sözleşmesine uygun biçimde `hub/tasks/inbox/`'a kondu
(**T-002**, öncelik `low`, `created_by: agent`) ve `task(T-002): inbox'a
eklendi` mesajıyla push'landı. `waiting/` değil `inbox/`: bu, kullanıcıdan
değil o projenin agent'ından beklenen bir iş.

Yan bulgu olarak `SYSTEM.md`'nin orada 1.3 kaldığı görüldü. Bu, `waiting/`
klasörünü kullanan ama onu tanımlamayan bir hub demek — yeni bir agent
sözleşmeyi okuyup klasörün ne işe yaradığını bilemez. Kullanıcıya söylendi,
karar ona bırakıldı.
