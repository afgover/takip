import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/models/activity.dart';

ActivityEntry parse(String message) =>
    ActivityEntry.fromCommit(message: message, sha: 'abc123');

void main() {
  group('SYSTEM.md §8 önekleri insan diline çevrilir', () {
    test('görev geçişleri', () {
      expect(parse('task(T-001): active → done').text, 'T-001 tamamlandı');
      expect(parse('task(T-001): inbox → active').text, 'T-001 ele alındı');
      expect(parse('task(T-001): not eklendi').text, 'T-001 için not eklendi');
    });

    test('uygulamadan gelen görev ayırt edilir', () {
      expect(
        parse("task(pending): inbox'a eklendi (app)").text,
        'Yeni görev eklendi (uygulamadan)',
      );
      expect(
        parse("task(pending): inbox'a eklendi").text,
        'Yeni görev eklendi',
      );
    });

    test('oturum, artifact ve diğerleri', () {
      expect(parse('session(S-2026-07-30-x): oturum açıldı').text,
          'Oturum açıldı');
      expect(parse('session(S-2026-07-30-x): oturum kapandı').text,
          'Oturum kapandı');
      expect(parse('artifact(A-2026-07-30-001): Flutter tasarımı eklendi').text,
          'Flutter tasarımı eklendi');
      expect(parse('backlog: B-014 tamamlandı').text, 'B-014 tamamlandı');
      expect(parse('evolution: Aşama 1 kapandı').text, 'Aşama 1 kapandı');
      expect(parse('knowledge: L-003 eklendi').text, 'L-003 eklendi');
      expect(parse("system: sözleşme 1.1'e güncellendi").text,
          "sözleşme 1.1'e güncellendi");
    });

    test('tür doğru atanır', () {
      expect(parse('task(T-1): x').kind, ActivityKind.task);
      expect(parse('knowledge: x').kind, ActivityKind.knowledge);
      expect(parse('session(S-1): x').subject, 'S-1');
    });
  });

  group('kod commit\'leri', () {
    test('§8 dışındaki commit kod olarak işaretlenir (K-012)', () {
      final entry = parse('feat(B-023): GitHub Contents API katmanı');

      expect(entry.kind, ActivityKind.code);
      expect(entry.kind.isHubRecord, isFalse);
      expect(entry.text, 'feat(B-023): GitHub Contents API katmanı');
    });

    test('öneksiz commit de kod sayılır', () {
      expect(parse('bir şeyler düzeltildi').kind, ActivityKind.code);
    });

    test('hub kayıtları hub kaydı sayılır', () {
      expect(parse('backlog: B-1 tamamlandı').kind.isHubRecord, isTrue);
    });
  });

  test('yalnız ilk satır kullanılır', () {
    final entry = parse('task(T-002): active → done\n\nUzun gövde\nsatırları.');
    expect(entry.text, 'T-002 tamamlandı');
  });

  test('tanınmayan görev kalıbı uydurulmaz, ham hâli kalır', () {
    expect(parse('task(T-009): arşive taşındı').text, 'T-009: arşive taşındı');
  });
}
