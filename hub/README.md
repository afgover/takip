# Taskr Hub

Bu repo, **project-taskr** sisteminin veri omurgasıdır. Kod içermez; agent'ın
ürettiği tüm kayıtları ve kullanıcının uygulama üzerinden atadığı görevleri tutar.

Sistemin nasıl işlediği iki dokümanda tanımlıdır:

- **`SYSTEM.md`** — format sözleşmesi: hangi klasörde ne durur, dosya şemaları,
  adlandırma kuralları. Hem agent hem kullanıcı uygulaması bu sözleşmeye uyar.
- **`AGENT_PROTOCOL.md`** — agent'ın her oturumda uygulamak zorunda olduğu
  kayıt prosedürü.

## Klasör haritası

```
SYSTEM.md            Format sözleşmesi (önce bunu oku)
AGENT_PROTOCOL.md    Agent'ın kayıt prosedürü
BACKLOG.md           Yapılacak işler — canlı, tek doğru kaynak
EVOLUTION.md         Projenin aşama aşama evrimi — sürekli güncellenir
sessions/            Oturum kayıtları (kullanıcı-agent diyaloğu, tamamı)
artifacts/           Oturumlarda üretilen rapor / plan / info dosyaları
tasks/               Görevler: inbox/ (yeni) → active/ (ele alındı) → done/ (bitti)
knowledge/           rules.md, skills.md, lessons.md — kurallar, yetenekler, dersler
```

## Erişim modeli

- **Agent:** repoya tam yazma erişimi; `AGENT_PROTOCOL.md`'ye göre yazar.
- **Kullanıcı uygulaması:** yalnızca bu repoya scope'lanmış fine-grained token
  (`Contents: Read & write`, `Metadata: Read`). Görevleri `tasks/inbox/`'a yazar,
  geri kalan her şeyi okur.
