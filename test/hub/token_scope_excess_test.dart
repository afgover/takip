import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/hub_access.dart';
import 'package:takip/hub/hub_config.dart';
import 'package:takip/hub/token_scope.dart';

const _slug = 'afgover/takip';

TokenScopeWarning? excess(int? visible, int needed) => tokenScopeExcess(
      visibleRepos: visible,
      neededRepos: needed,
      slug: _slug,
    );

void main() {
  group('tokenScopeExcess — konuştuğu tek durum', () {
    test('N > K → uyarı, sayılar metinde geçiyor', () {
      final warning = excess(12, 2);

      expect(warning, isNotNull);
      expect(warning!.body, contains('12'));
      expect(warning.body, contains('2 hub'));
      // Fark da yazılıyor: "10 repo" kullanıcının ölçüyü görmesini sağlıyor.
      expect(warning.body, contains('10'));
    });

    test('tek hub varken metin repo adını söylüyor', () {
      expect(excess(9, 1)!.body, contains(_slug));
    });

    test('bir repo fazlası da uyarı — eşik uygulamanın ihtiyacı', () {
      expect(excess(2, 1), isNotNull);
    });
  });

  group('tokenScopeExcess — sustuğu durumlar', () {
    test('N ölçülemediyse susar (bilinmeyen "temiz" değildir)', () {
      expect(excess(null, 1), isNull);
    });

    test('N == K susar', () {
      expect(excess(2, 2), isNull);
    });

    test('N < K susar — bu bir hata değil, kontrolün işi değil', () {
      // Token'ın bağlı hub'lardan azını görmesi mümkün (bir bağlantı başka
      // token'la kurulmuş olabilir). Fazla erişim kontrolünün söyleyeceği
      // bir şey yok; erişim eksikse zaten istek 404 verir.
      expect(excess(1, 3), isNull);
    });

    test('K bilinmiyorsa susar', () {
      expect(excess(50, 0), isNull);
      expect(excess(50, -1), isNull);
    });

    test('hiçbir dalda "bu token dar" denmiyor', () {
      // Tek yönlü yorumun kendisi: fonksiyon ya uyarır ya susar; olumlu bir
      // güvence cümlesi hiçbir yoldan çıkmıyor (L-009, B-026).
      for (final (visible, needed) in [
        (null, 1),
        (1, 1),
        (0, 1),
        (1, 5),
      ]) {
        expect(excess(visible, needed), isNull);
      }
    });
  });

  group('reposNeededForToken', () {
    const token = 'ayni-token';
    const candidate = HubConfig(owner: 'a', repo: 'yeni', token: token);

    test('kayıt yokken ihtiyaç 1 — kurulmakta olan bağlantı', () {
      expect(reposNeededForToken(const [], candidate), 1);
    });

    test('aynı token\'ı kullanan bağlantılar sayılıyor (B-056)', () {
      // Aynı token'ı birden çok hub'da kullanmak teşvik edilen akış; ihtiyaç
      // bu yüzden "1" değil, o token'ın gerçekten gerektiği repo sayısı.
      final existing = [
        const HubConfig(owner: 'a', repo: 'bir', token: token),
        const HubConfig(owner: 'a', repo: 'iki', token: token),
      ];

      expect(reposNeededForToken(existing, candidate), 3);
    });

    test('başka token\'lı bağlantılar sayılmıyor', () {
      final existing = [
        const HubConfig(owner: 'a', repo: 'bir', token: token),
        const HubConfig(owner: 'a', repo: 'iki', token: 'baska'),
      ];

      expect(reposNeededForToken(existing, candidate), 2);
    });

    test('aday zaten kayıtlıysa iki kez sayılmıyor (token güncelleme)', () {
      final existing = [
        const HubConfig(owner: 'a', repo: 'yeni', token: token),
        const HubConfig(owner: 'a', repo: 'bir', token: token),
      ];

      expect(reposNeededForToken(existing, candidate), 2);
    });
  });
}
