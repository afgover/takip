---
id: A-2026-08-01-023
session: none
type: report
title: "Progress Log"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/project_docs/PROGRESS_LOG.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Progress Log

## Phase 2 Tamamlandi (Mart 2026)

### 🚀 Tamamlanan Ozellikler
- [x] **SDK Downgrade (SDK 54)**: Expo Go uyumlulugu saglandi.
- [x] **Dependency Fix**: `babel-preset-expo` ve diger paketler SDK 54 ile hizalandi.
- [x] **Supabase Auth**: Anon key guncellendi, registration hatasi (email confirmation) cozuldu.
- [x] **Hierarchical Tag System**: 
    - [x] `LTREE` tabanli tag agaci (Postgres).
    - [x] `TagTreePicker` componenti (Create ve Filter ekranlari icin).
    - [x] Branch filtering (Ust tag secilince alt tagleri de kapsayan filtreleme).
- [x] **Twitter-like UI**: 
    - [x] Feed ekranlarinda Avatar ve Quick Create (Neler yapilacak?) girisi.
    - [x] Twitter stilinde akis ve interaction iconlari (Share).
- [x] **Dynamic Priority Logic**: 
    - [x] Deadline yaklastikca otomatik yukselen oncelik rakami.
    - [x] "Bugun" secilen gorevlerin ilk 3 spotta rastgele siralanmasi.
- [x] **Sharing Mechanism**:
    - [x] Nickname bazli kullanici arama.
    - [x] Gorev ve Tag paylasimi + Real-time bildirimler.
    - [x] Kabul/Red sistemi ve oge klonlama (Inbox/Sent toggle).
- [x] **Subtask Mechanics**:
    - [x] Otomatik tamamlanma orani (progress bar) ve DB trigger'lari.
- [x] **Push Notifications Fix**: SDK 53+ Expo Go uyumlulugu icin remote token registration Android'de bypass edildi (Local reminderlar calismaya devam ediyor).

## Phase 4: Sosyal ve Grup Paylasimi (Mart 2026)
### 📅 12 Mart 2026

- **Tag ve Filtreleme Geliştirmeleri:**
  - Ana sayfadaki tag filtresi akordeon/genişleyebilir yapıya geçirildi.
  - Tag ağacındaki (TagTreeScreen) hizalama hataları giderildi, root tagler sola yaslandı.
  - Görev oluşturma ekranında tagler artık bir ızgara yapısında görünüyor ve tek tıklamayla seçilip kaldırılabiliyor.
- **Zamanlama ve Oncelik Mantığı:**
  - "Gün Seç" ve "Deadline" seçenekleri "Tarih / Deadline" altında birleştirildi.
  - Geçmiş görevler için (overdue) öncelik artırma mantığı eklendi (her gün için +15 puan).
  - Görev kartlarında "X gün geçti!" uyarısı kırmızı renkle eklendi.
- **Sosyal ve Grup Geliştirmeleri:**
  - Sosyal sekmesinde arkadaşlara veya gruplara tıklandığında ilgili paylaşılan görevlerin listelenmesi sağlandı.
  - Görev kartlarına paylaşım bilgisi (Kişi/Grup ikonları) eklendi.
  - Gruptan ayrılınca son üye ise grubun otomatik silinmesi ve kurucu için silme butonu eklendi.
- [x] **Arkadaslik Sistemi**: 
    - [x] Nickname ile arkadas ekleme ve istek onaylama sistemi.
    - [x] Paylasim ekraninda sadece arkadaslarin listelenmesi (global arama kisitlandi).
- [x] **Grup Yapisi**:
    - [x] Arkadas gruplari olusturma ve grup uyeleriyle toplu gorev paylasimi.
    - [x] `SharedInbox` icinde Sosyal sekmesi ile yonetim.
- [x] **Tamamlanma Seffafligi**:
    - [x] Paylasilan gorevlerde "Kim tamamladı?" bilgisinin anlik goruntulenmesi.
    - [x] `TaskCard` ve `TaskDetail` ekranlarinda tamamlayan kullanici nickname'i.
- [x] **Performans**:
    - [x] Feed filtrelemede client-side "Local Filtering" moduna gecilerek "sak diye" tepki suresi saglandi.
    - [x] Gereksiz Quick Create row kaldirilarak Twitter-style akis sadelestirildi.
- [x] **Görev Detay Geliştirmeleri**:
    - [x] `TaskDetailScreen` üzerinde görev adının (title) düzenlenebilmesi sağlandı.
    - [x] Görevin paylaşıldığı kişi/gruplar listeleniyor.
    - [x] Detay ekranından doğrudan "+" ile yeni paylaşım yapılabiliyor.


### 🛠 Teknik Detaylar
- **Filtreleme**: `FilterStore` secilen taglarin alt dallarini otomatik olarak `taskStore` fetch logic'ine ekler.
- **Oncelik**: `fetchTasks` sirasinda deadline'i olan gorevlerin oncelik rakamlari `priorityService` araciligiyla otomatik guncellenir.
- **Paylasim**: Kullanici nickname bazli arama yapilabilir.

### 📋 Son Durum (Phase 3 Tamamlandi - Mart 2026)
- [x] **AI Analiz Ekrani**: 
    - [x] Performans skoru ve peak hour analizi.
    - [x] En hizli bitirilen tag tespiti.
    - [x] Modern dashboard UI.
- [x] **Push Notifications**: 
    - [x] `expo-notifications` entegrasyonu.
    - [x] Deadline'dan 1 saat once otomatik hatirlatici (Local).
- [x] **Smart Scheduling**: 
    - [x] Gecmis verilere gore "En uygun gun" onerisi.
    - [x] Create ekraninda tek tıkla uygulama (AI Suggestion Badge).
- [x] **Offline Sync**: 
    - [x] Zustand Persist + AsyncStorage ile offline veri saklama.
    - [x] Internet gelince session ve task verilerinin korunmasi.

### 🚀 Gelecek Vizyonu
1. **Desktop App**: Electron veya React Native macOS ile masaustu versiyonu.
2. **Apple Watch**: Hizli gorev ekleme ve bildirimler.
3. **Voice Command**: "Yarin sabah 9'da markete gitmeyi gorev ekle" komutuyla AI destekli create.

## Phase 5: Bakim ve Hata Giderme (Nisan 2026)
### 📅 18 Nisan 2026

- **FlashList v2 Uyumlanmasi:**
  - `FeedScreen.tsx` uzerindeki `estimatedItemSize` prop'u kaldirildi (v2'de gerek kalmadi/desteklenmiyor).
- **Tip Guvenligi ve Hata Giderme:**
  - `SharedSentScreen.tsx` icinde `recipient_id` null check eklendi (Grup paylasimlari icin null gelebilir).
### 📅 18 Nisan 2026 - Migration to Self-Hosted Supabase
- **Self-Hosting Infrastructure**: Deployed Supabase stack on Hetzner VPS using Docker Compose.
  - **API**: `http://178.104.159.14:8000`
  - **Studio**: `http://178.104.159.14:8001`
- **Migration**: Applied 11 migration files to the new database to replicate the schema and RLS policies.
- **App Update**: Switched the React Native app's `.env` to point to the new Hetzner backend.
- **Network**: Integrated services into the `coolify` Docker network for visibility.


## Phase 6: Profesyonel Offline Sync (Mayıs 2026)
### 📅 01 Mayıs 2026

- **Profesyonel Offline-First Altyapısı:**
  - **Mutation Queue (SyncStore):** Tüm yazma işlemleri (Ekleme, Güncelleme, Silme) önce yerel bir kuyruğa alınacak şekilde mimari değiştirildi.
  - **Client-Side UUID:** Görev kimlikleri (ID) artık sunucu yerine cihazda (`expo-crypto`) üretiliyor. Bu sayede çevrimdışı oluşturulan görevler ve alt görevler arasındaki ilişkiler kopmadan saklanabiliyor.
  - **İdempoent Backend:** Sunucu tarafındaki `create` endpoint'i `upsert` mantığına geçirildi. Aynı isteğin ağ hatası nedeniyle tekrar gelmesi durumunda mükerrer kayıt oluşması engellendi.
  - **Otomatik Senkronizasyon:** İnternet bağlantısı geldiği an (`NetInfo` dinleyicisi ile) kuyruktaki bekleyen işlemler sırayla ve arka planda sunucuya işleniyor.
  - **Optimistic UI:** Kullanıcı bir işlem yaptığında (örn: görevi tamamla), uygulama sunucudan yanıt beklemeden arayüzü anında güncelliyor.

### 🛠 Teknik Detaylar
- **Sync Logic:** `useSyncStore` (Zustand + AsyncStorage) tüm mutasyonları FIFO (First-In-First-Out) sırasıyla işler.
- **Hata Yönetimi:** 4xx (Client) hatalarında işlem kuyruktan atılır, 5xx veya ağ hatalarında kuyruk durdurulur ve internet geldiğinde tekrar denenir.
- **Veri Tutarlılığı:** `fetchTasks` işlemi sırasında yerelde henüz sunucuya gönderilmemiş ("in-flight") görevler korunur.
