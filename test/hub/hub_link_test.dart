import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/hub_link.dart';

/// Belgeler arası bağlantı (sözleşme 1.25 §15).
void main() {
  group('resolveHubLink', () {
    test('hub köküne göre yol + ID çapası', () {
      final link = resolveHubLink(
        'SECURITY.md#SEC-010',
        fromPath: 'hub/BACKLOG.md',
      );
      expect(link?.path, 'hub/SECURITY.md');
      expect(link?.anchor, 'SEC-010');
    });

    test('alt klasördeki hedef', () {
      final link = resolveHubLink(
        'knowledge/lessons.md#L-042',
        fromPath: 'hub/PLAN.md',
      );
      expect(link?.path, 'hub/knowledge/lessons.md');
    });

    test('göreli yol bulunduğu belgeye göre çözülür', () {
      final link = resolveHubLink(
        '../../SECURITY.md#SEC-013',
        fromPath: 'hub/sessions/2026-08-13-x/session.md',
      );
      expect(link?.path, 'hub/SECURITY.md');
      expect(link?.anchor, 'SEC-013');
    });

    test('yalnız çapa aynı belgeyi işaret eder', () {
      final link = resolveHubLink('#B-097', fromPath: 'hub/BACKLOG.md');
      expect(link?.path, 'hub/BACKLOG.md');
      expect(link?.anchor, 'B-097');
    });

    test('çapasız bağlantı belgeyi baştan açar', () {
      final link = resolveHubLink(
        'tasks/done/2026-08-13-repoyu-public-yap.md',
        fromPath: 'hub/BACKLOG.md',
      );
      expect(link?.path, 'hub/tasks/done/2026-08-13-repoyu-public-yap.md');
      expect(link?.anchor, isNull);
    });

    test('hub dışı bağlantılar çözülmez', () {
      // Uygulamanın işi hub'ı gezdirmek; tarayıcı açmak değil.
      for (final href in [
        'https://github.com/afgover/takip',
        'http://example.com',
        'mailto:ornek@example.com',
      ]) {
        expect(resolveHubLink(href, fromPath: 'hub/README.md'), isNull,
            reason: href);
      }
    });

    test('markdown olmayan hedef açılmaz', () {
      expect(
        resolveHubLink('lib/main.dart', fromPath: 'hub/BACKLOG.md'),
        isNull,
      );
    });

    test('kökün üstüne çıkan yol reddedilir', () {
      expect(
        resolveHubLink('../../../etc/passwd.md', fromPath: 'hub/BACKLOG.md'),
        isNull,
      );
    });

    test('boş ve null girdi', () {
      expect(resolveHubLink(null, fromPath: 'hub/BACKLOG.md'), isNull);
      expect(resolveHubLink('   ', fromPath: 'hub/BACKLOG.md'), isNull);
    });
  });

  group('anchorLineOf', () {
    const doc = '''
# Başlık

- [ ] B-09 · başka bir kayıt
- [x] B-097 · aranan kayıt
  - girintili B-098 satırı

## SEC-010 — bir güvenlik kaydı
''';

    test('liste maddesindeki ID bulunur', () {
      expect(anchorLineOf(doc, 'B-097'), 3);
    });

    test('başlıktaki ID bulunur', () {
      expect(anchorLineOf(doc, 'SEC-010'), 6);
    });

    test('kısmi eşleşme kabul edilmez', () {
      // `B-09` çapası `B-097`ye çarpmamalı: kendi satırı 2, sonrakine değil.
      expect(anchorLineOf(doc, 'B-09'), 2);
    });

    test('girintili satır atlanır', () {
      // Belge çapada ikiye bölünerek çiziliyor; girintili bir satırdan bölmek
      // listeyi ortasından koparırdı.
      expect(anchorLineOf(doc, 'B-098'), isNull);
    });

    test('bulunmayan çapa null', () {
      expect(anchorLineOf(doc, 'L-999'), isNull);
    });
  });
}
