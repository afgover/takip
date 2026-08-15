# AGENT_PROTOCOL.md — Agent Kayıt Prosedürü

***Türkçe** (kanonik) · [English](AGENT_PROTOCOL.en.md)* — İngilizce sürüm
bundan türer; çeliştiklerinde bu dosya geçerlidir (`SYSTEM.md` §10).

Bu doküman, bu hub ile çalışan **her agent oturumunun uymak zorunda olduğu**
prosedürdür. Format ayrıntıları `SYSTEM.md`'dedir; burada *ne zaman ne yapılacağı*
tanımlanır. Prosedür, oturumun konusu ne olursa olsun geçerlidir.

## Oturum açılışında (ilk mesajdan hemen sonra)

0. **Hub'ın dilini oku** (`SYSTEM.md` → `**Hub dili:**`, sözleşme 1.19) ve bu
   oturumda ürettiğin her şeyi o dilde yaz: oturum kaydı, backlog maddeleri,
   knowledge kayıtları, görev gövdeleri. Alan yoksa `tr`. Hub'ın dili ile
   kullanıcının sana yazdığı dil farklıysa **kullanıcıya sor** — birini
   diğerine kendiliğinden tercih etme.
1. `sessions/<tarih>-<slug>/session.md` dosyasını `status: open` ile oluştur.
   **`author:` alanını da yaz** (v1.15) — oturumu kimin yürüttüğü. Bilmiyorsan
   kullanıcıya sor; hub çok kullanıcılıysa "kim yaptı" sorusunun cevabı burada
   başlar. `knowledge/` ve `SECURITY.md` kayıtları ayrı bir kimlik alanı
   taşımaz: `Kaynak:` alanı oturuma işaret ettiği için kimlik oradan
   çözülür — aynı bilgiyi iki yerde tutmak, ikisinin ayrışmasına davetiyedir.
2. `tasks/inbox/` klasörünü kontrol et:
   - Yeni görev varsa kullanıcıya bildir ("inbox'ta N yeni görev var: ...").
   - Kullanıcının talimatına göre ele al; ele aldığını `active/`e taşı.
   - Kullanıcı farklı bir konu açtıysa inbox'ı sadece raporla, kendiliğinden işleme.
3. `BACKLOG.md`'ye bak; yarım kalmış işleri hatırla.
   **Sözleşmeyi ana kopyayla karşılaştır** (`SYSTEM.md` §10) — tek komut,
   dosyayı hub'ının diline göre seç (v1.21: `tr` → `SYSTEM.md`, `en` →
   `SYSTEM.en.md`):
   `curl -fsSL https://raw.githubusercontent.com/afgover/takip/main/hub/SYSTEM.md
   -o /tmp/SYSTEM.master.md && diff /tmp/SYSTEM.master.md hub/SYSTEM.md`.
   İstek başarısız olursa kontrol **koşmamıştır**; "güncelim" diye yorumlama ve
   kayda "kontrol edildi" yazma.
4. **`SECURITY.md`'deki son `tarama` kaydının tarihine bak (§12).** 30 günden
   eskiyse — ya da hiç yoksa — projeye uygun bağımlılık/zafiyet taramasını koş
   ve sonucu `tarama` kaydı olarak yaz. Tarama tek seferlik bir onay değildir:
   koştuğu günün danışmanlık veritabanına göredir ve "taradık" cümlesi
   tekrarlanmazsa zamanla sessizce yanlışa döner.
   Tetikleyicinin takvim değil **kaydın kendisi** olması bilinçli: hatırlatma
   hub'da duruyor, yani unutulduğunda da görünür kalıyor.
   *(`takip` projesinde koşum: `tool/scan.sh`. Diğer projelerde karşılığı o
   projenin paket yöneticisidir; sonucun **doğrulanmış** olması şarttır —
   bilinen açığı olan bir sürüm de sorulmadan "temiz" yazılmaz, L-035.)*

5. **Geçici maddelere bak (`SYSTEM.md` §13).** Bölüm boşsa geçilir. Her
   maddenin "kimi ilgilendiriyor" satırı hub'ına uyuyorsa uygula ve
   kullanıcıya ne yaptığını söyle. Bu maddeler kalıcı kural değildir; ana
   kopya sildiğinde biter.

## Oturum boyunca (her mesaj alışverişinde)

> **30 dakika ritmi (v1.23).** İş yapılırken en geç 30 dakikada bir:
> (a) `session.md`, `BACKLOG.md` ve knowledge kayıtlarını güncelle ve
> **push'la** — oturum `open` kalır, özet kapanışa; (b) `tasks/inbox/`a bak,
> yeni görev varsa kullanıcıya söyle. Kullanıcı 30 dakikadan uzun bir aradan
> sonra döndüğünde ya da oturum sıkıştırma sonrası devam ediyorsa inbox
> kontrolünü tekrarla. Kaybolan iş en fazla 30 dakika olsun; `reconstructed`
> istisnası ihtiyaç olmaktan çıksın.

> **ID atarken (v1.15).** Yeni bir `T-`, `B-`, `L-`, `SK-`, `R-`, `SEC-`, `K-`
> ya da `A-` numarası vermeden **hemen önce** `git pull --rebase`, verdikten
> **hemen sonra** push et. Sayaçlar tekildir ve iki agent aynı anda çalışırsa
> ikisi de aynı numarayı seçer; dosyalar farklı olduğu için git bunu çakışma
> saymaz ve hata veren hiçbir şey olmaz. Pencereyi daraltmak bu yüzden
> prosedürün işi. Çakışma yine de olursa hub'ı okuyan test yakalar; düzeltmesi
> birini yeniden numaralandırmaktır.
>
> Numarayı **dosyadaki en büyükten** türet, hafızandan değil. Eşzamanlılık
> olmadan da çakışma çıkabilir: uzun bir oturumda "en son kaç vermiştim"
> sorusunun cevabı yalnız dosyada durur (2026-08-06'da tam bu şekilde
> B-111 iki kez verildi).

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
7b. **Üç ya da daha fazla adımlı bir işe başlarken planı
   [`PLAN.md`](PLAN.md)'ye yaz** (sözleşme [§14](SYSTEM.md#14)) — adımları
   *uygulamadan önce*, çünkü ağacın işi biteni listelemek değil, yarım kalanı
   görünür kılmak. Her adım bittiği anda işaretlenir; vazgeçilen adım silinmez,
   üstü çizilir ve **nedeni yazılır**. Tek komutluk işler ağaca girmez.
   Ağaç diğer akışların yerine geçmez: aynı bilgiyi backlog'a ve oturum kaydına
   ikinci kez yazmak yerine oraya **bağlantı** verilir. Adım satırı **kısadır**:
   ne yapıldığını söyler, nedeni bağlantı verilen kayda gider (v1.26).

   **Geç fark ettiysen atlamak yok (v1.26).** İşin çok adımlı olduğunu ancak
   bittiğinde anladıysan planı *o zaman* yaz ve `Türetilmiş: true` koy. Adımlar
   kayıttan (oturum, commit, backlog) **türetilir**; hatırlanmayan adım
   yazılmaz. Bu madde ölçülmüş bir davranıştan doğdu: 1.25'te geç fark eden
   agent'ın önünde yalnız "uydur" ve "atla" vardı, hepsi atladı ve ağaçlar boş
   kaldı. Eksik bir ağaç yanlış bir ağaçtan iyidir, ama **boş** ağaç ikisinden
   de kötüdür.
7c. **Başka bir kayda atıf yaparken bağlantı ver** (sözleşme
   [§15](SYSTEM.md#15)): `[SEC-010](SECURITY.md#SEC-010)`. Çapa kaydın ID'sidir,
   başlık metni değil. Bir belgede ID'nin **ilk** geçtiği yer bağlanır, sonraki
   tekrarları düz metin kalır.
8. Görev durum değişikliklerini klasör taşımayla ve doğru commit mesajıyla işle.
9. **Kullanıcıdan bir şey bekliyorsan görev aç ve `tasks/waiting/`e koy.**
   Sohbette söylemek yeterli değildir: sohbet kapanır, kullanıcı telefonunda
   hiçbir iz görmez. Kural şu — *"kullanıcı yapmadan ilerleyemiyorsam, bu bir
   `waiting/` görevidir."* Beklenen şeyi `## Notlar`a tek satırda, yapılabilir
   biçimde yaz ("GitHub'da fine-grained token üret; Contents: Read and write").
   Belirsiz beklentiler (`belki bir gün bakar`) `waiting/`e konmaz.
   Kullanıcı uygulamadan **"Yaptım"** dediğinde inbox'a bildirim görevi düşer;
   onu görünce asıl görevi `waiting/`ten çıkar ve bildirimi kapat.
10. **`notes/` senin işin değil (sözleşme 1.9 §11).** Oradaki dosyalar
   kullanıcının kendine aldığı notlardır: ID atama, taşıma, `result` yazma,
   "yapıldı" deme, silme, düzenleme. Bağlam olarak **okuyabilirsin** ("kullanıcı
   burada şunu not almış") ve oturum kaydında buna dayanabilirsin. Bir not
   gerçekten iş içeriyorsa kendiliğinden görev açma — kullanıcıya sor, gerekirse
   `tasks/waiting/`e bir soru koy. Kuralın nedeni somut: kullanıcı kendine not
   alırken agent'a iş açmış olmak istemiyor.
11. **Güvenlikle ilgili her iş `SECURITY.md`'ye kayıt düşer (§12).** Bağımlılık
   taraması, izin değişikliği, token/kimlik dokunuşu, veri saklama kararı,
   bulunan bir açık — hepsi. Yalnız oturum kaydına yazmak yetmez: "bu konuda ne
   yapmıştık" sorusunun cevabı oturumlara dağılmamalı. Giderilen bir açık
   silinmez, `Durum: kapali` yapılır ve nasıl giderildiği yazılır.
   **Sır yazılmaz** — kayıt neyin korunduğunu anlatır, korunan şeyin kendisini
   değil.

## Oturum kapanışında

9. `session.md`: `## Özet` bölümünü doldur, `status: closed` yap.
10. `EVOLUTION.md`'de aktif aşamanın bölümünü güncelle (bu oturumda aşama adına
    ne ilerledi, hangi kararlar verildi). Aşama tamamlandıysa kapat, yenisini aç.
11. Son bir tutarlılık kontrolü — **kendi adımlarını değil, hub'ın durumunu**
    sor: bu oturumda üretilen her dosya session.md'den linkli mi, biten her iş
    BACKLOG'da işaretli mi, taşınması gereken görev kaldı mı, ve
    **`sessions/` altında `status: open` kalan başka oturum var mı?** Varsa
    kapat: özetini kendi kaydından türet ve türetildiğini dosyada belirt.
    Bu madde bir oturumun dokuz gün açık kalmasından sonra eklendi (L-042):
    "bu oturumu kapat" diye sorulunca kimse bütüne bakmıyor.
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
