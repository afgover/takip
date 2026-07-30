# tasks/

Görevlerin evi. **Durum = klasör**; şema ve kurallar `SYSTEM.md` §4.

```
inbox/    yeni — app (kullanıcı) veya agent ekledi, henüz ele alınmadı
active/   agent ele aldı, üzerinde çalışılıyor
done/     tamamlandı (arşiv, silinmez)
```

- App yalnızca `inbox/`'a yazar (R-001).
- Klasörler arası taşımayı yalnızca agent yapar.
- Dosya adı: `<YYYY-MM-DD>-<slug>.md` · Şablon: `_template.md`
