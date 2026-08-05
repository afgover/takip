import 'package:flutter_test/flutter_test.dart';
import 'package:takip/core/constants.dart';
import 'package:takip/hub/annotations.dart';

/// Notlar kişiseldir (sözleşme 1.16).
///
/// 1.15'te `notes/<login>/` klasörü geldi ama uygulama hâlâ **bütün** not
/// dosyalarını tarıyordu: takımda herkes herkesin notunu belgede işaretli
/// görürdü. Bu, notu "kendine yazılan şey" olmaktan çıkarır — 1.9'da
/// (K-029) tam olarak bunun için ayrılmıştı.
void main() {
  const me = 'afgover';

  group('isMyNote', () {
    test('kendi klasörümdeki not görünür', () {
      expect(isMyNote('${Hub.notesDir}/afgover/2026-08-06-x.md', me), isTrue);
    });

    test('başkasının notu görünmez', () {
      expect(isMyNote('${Hub.notesDir}/mehmet/2026-08-06-x.md', me), isFalse);
    });

    test('görevler her zaman görünür — tasks/ ortak alan', () {
      for (final dir in [
        Hub.inboxDir,
        Hub.activeDir,
        Hub.waitingDir,
        Hub.doneDir,
      ]) {
        expect(isMyNote('$dir/2026-08-06-x.md', me), isTrue, reason: dir);
      }
    });

    test('kimliğimiz bilinmiyorsa hiçbir şey gizlenmez', () {
      // Süzmek her şeyi gizlerdi; bilinmeyen yüzünden veri saklamak, yanlış
      // tarafta hata yapmak olurdu.
      expect(isMyNote('${Hub.notesDir}/mehmet/2026-08-06-x.md', null), isTrue);
      expect(isMyNote('${Hub.notesDir}/mehmet/2026-08-06-x.md', ''), isTrue);
    });

    test('1.15 öncesi düz notlar gizlenmez', () {
      // O dosyalar ayrım yokken yazıldı; sahibi bilinmiyor. Gizlemek var olan
      // notları sessizce yok ederdi.
      expect(isMyNote('${Hub.notesDir}/2026-08-03-eski.md', me), isTrue);
    });

    test('benzer başlayan bir ad başkasının notunu sızdırmaz', () {
      // `afgover2` klasörü `afgover` ile başlıyor; klasör adı **tam**
      // eşleşmeli, önek değil.
      expect(isMyNote('${Hub.notesDir}/afgover2/x.md', me), isFalse);
      expect(isMyNote('${Hub.notesDir}/afgoverx/x.md', me), isFalse);
    });

    test('alt klasörlü not doğru sahibe atanır', () {
      expect(isMyNote('${Hub.notesDir}/afgover/alt/x.md', me), isTrue);
      expect(isMyNote('${Hub.notesDir}/mehmet/alt/x.md', me), isFalse);
    });
  });
}
