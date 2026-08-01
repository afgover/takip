# waiting/ — kullanıcıyı bekleyen görevler

Agent'ın kullanıcıdan somut bir şey beklediği görevler (SYSTEM.md §4, v1.4).
Beklenen şey `## Notlar`da tek satırda yazılıdır.

Kullanıcı işi bitirince uygulamadaki "Yaptım" düğmesine basar; app `inbox/`a
bildirim görevi yazar, agent asıl görevi buradan taşır. Dosyaları yalnız agent
taşır.
