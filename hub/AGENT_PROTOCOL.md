# AGENT_PROTOCOL.md — Agent Kayıt Prosedürü

Bu doküman, bu hub ile çalışan **her agent oturumunun uymak zorunda olduğu**
prosedürdür. Format ayrıntıları `SYSTEM.md`'dedir; burada *ne zaman ne yapılacağı*
tanımlanır. Prosedür, oturumun konusu ne olursa olsun geçerlidir.

## Oturum açılışında (ilk mesajdan hemen sonra)

1. `sessions/<tarih>-<slug>/session.md` dosyasını `status: open` ile oluştur.
2. `tasks/inbox/` klasörünü kontrol et:
   - Yeni görev varsa kullanıcıya bildir ("inbox'ta N yeni görev var: ...").
   - Kullanıcının talimatına göre ele al; ele aldığını `active/`e taşı.
   - Kullanıcı farklı bir konu açtıysa inbox'ı sadece raporla, kendiliğinden işleme.
3. `BACKLOG.md`'ye bak; yarım kalmış işleri hatırla.

## Oturum boyunca (her mesaj alışverişinde)

4. **Her kullanıcı mesajını ve her cevabını** `session.md`'ye anında ekle —
   oturum sonuna biriktirme. Kullanıcı mesajları kısaltılmadan; agent cevapları
   karar/bulgu/iş odaklı özetlenerek yazılır, uzun çıktılar artifact'e gider.
5. Rapor, plan, analiz, info niteliğinde **her üretilen dosyayı**
   `artifacts/<session-id>/` altına frontmatter'ıyla kaydet ve `session.md`'nin
   `artifacts:` listesine ekle.
6. Bir backlog maddesi tamamlandığında `BACKLOG.md`'de **anında** işaretle
   (tarih + link). Konuşma sırasında yeni iş ortaya çıktıysa ilgili faza ekle.
7. Yeni bir kural, skill veya ders ortaya çıktığında `knowledge/` altındaki
   ilgili dosyaya ID'li kayıt ekle. "Sonra yazarım" yok — çıktığı anda yazılır.
8. Görev durum değişikliklerini klasör taşımayla ve doğru commit mesajıyla işle.
9. **Kullanıcıdan bir şey bekliyorsan görev aç ve `tasks/waiting/`e koy.**
   Sohbette söylemek yeterli değildir: sohbet kapanır, kullanıcı telefonunda
   hiçbir iz görmez. Kural şu — *"kullanıcı yapmadan ilerleyemiyorsam, bu bir
   `waiting/` görevidir."* Beklenen şeyi `## Notlar`a tek satırda, yapılabilir
   biçimde yaz ("GitHub'da fine-grained token üret; Contents: Read and write").
   Belirsiz beklentiler (`belki bir gün bakar`) `waiting/`e konmaz.
   Kullanıcı uygulamadan **"Yaptım"** dediğinde inbox'a bildirim görevi düşer;
   onu görünce asıl görevi `waiting/`ten çıkar ve bildirimi kapat.

## Oturum kapanışında

9. `session.md`: `## Özet` bölümünü doldur, `status: closed` yap.
10. `EVOLUTION.md`'de aktif aşamanın bölümünü güncelle (bu oturumda aşama adına
    ne ilerledi, hangi kararlar verildi). Aşama tamamlandıysa kapat, yenisini aç.
11. Son bir tutarlılık kontrolü: bu oturumda üretilen her dosya session.md'den
    linkli mi, biten her iş BACKLOG'da işaretli mi, taşınması gereken görev
    kaldı mı?
12. Tüm değişiklikleri anlamlı commit'ler halinde push'la. Hub'a push'lanmamış
    kayıt, yapılmamış kayıttır.

## Değişmez kurallar

- **Kayıt dışı iş yok:** Hub'a yansımayan hiçbir çalışma "yapılmış" sayılmaz.
- **Sözleşmeye sadakat:** `SYSTEM.md` şemasının dışında dosya/format icat etme.
  Format değişikliği gerekiyorsa önce kullanıcıya öner, onaylanırsa `SYSTEM.md`
  sürümünü artır ve `EVOLUTION.md`'ye kaydet.
- **Silme yok:** Oturum, artifact, done-görev ve knowledge kayıtları silinmez;
  geçersizleşen kayıt üstü çizilerek işaretlenir.
- **App'in alanına saygı:** `tasks/inbox/`'taki kullanıcı görevlerini yalnızca
  kullanıcının isteği doğrultusunda ele al; kendi kararınla silme veya değiştirme
  (taşıma ve not ekleme serbest).
- **Commit disiplini:** Her commit `SYSTEM.md` §8'deki önek kurallarına uyar;
  ilgisiz değişiklikler aynı commit'e konmaz.
