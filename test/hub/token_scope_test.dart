import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/token_scope.dart';

TokenScopeWarning? inspect(String token, {String? scopes}) => inspectTokenScope(
      token: token,
      oauthScopes: scopes,
      slug: 'afgover/takip',
    );

void main() {
  group('inspectTokenScope — uyarı üretilmeyen durumlar', () {
    test('fine-grained token: başlık hiç gelmez, uyarı da yok', () {
      expect(inspect('github_pat_1234'), isNull);
    });

    test('tanınmayan önek + başlık yok → sessiz', () {
      // 2021 öncesi üretilmiş öneksiz token'lar böyle görünür. Bilinmeyeni
      // "geniş" saymak, her kullanıcıyı boş yere uyarmak olurdu.
      expect(inspect('40karakterlikeskitoken'), isNull);
    });

    test('başlık boş gelirse sinyal sayılmaz', () {
      expect(inspect('github_pat_1234', scopes: ''), isNull);
      expect(inspect('github_pat_1234', scopes: '  ,  '), isNull);
    });
  });

  group('inspectTokenScope — uyarı üretilen durumlar', () {
    test('klasik önek tek başına yeter', () {
      // Başlık gelmese bile klasik token tek repoya kısıtlanamaz.
      final warning = inspect('ghp_1234');
      expect(warning, isNotNull);
      expect(warning!.scopes, isEmpty);
      expect(warning.body, contains('afgover/takip'));
      expect(warning.body, contains('bütün repolara'));
    });

    test('scope başlığı okunur ve ağır olanlar tek tek anlatılır', () {
      final warning = inspect('ghp_1234', scopes: 'repo, gist, workflow');

      expect(warning, isNotNull);
      expect(warning!.scopes, ['repo', 'gist', 'workflow']);
      expect(warning.body, contains('repo — bütün repolara'));
      expect(warning.body, contains('gist —'));
      expect(warning.body, contains('workflow —'));
    });

    test('başlık öneksiz bir token için de konuşur', () {
      // Sinyal ikisinden **biri** yeterli: başlık doluysa token klasiktir,
      // öneki tanımasak da.
      final warning = inspect('eski-token', scopes: 'repo');
      expect(warning, isNotNull);
      expect(warning!.scopes, ['repo']);
    });

    test('tanınmayan scope uyarıyı engellemez, listede kalır', () {
      final warning = inspect('ghp_1234', scopes: 'repo, yeni_scope');
      expect(warning!.scopes, contains('yeni_scope'));
      // Tanınmayan scope için açıklama uydurulmaz.
      expect(warning.body, isNot(contains('yeni_scope —')));
    });

    test('uyarı ne yapılacağını söyler', () {
      final body = inspect('ghp_1234')!.body;
      expect(body, contains('Only select repositories'));
      expect(body, contains('Contents: Read and write'));
    });
  });

  group('parseOauthScopes', () {
    test('virgülle ayrılmış başlığı böler ve kırpar', () {
      expect(parseOauthScopes('repo, gist'), ['repo', 'gist']);
      expect(parseOauthScopes('repo'), ['repo']);
    });

    test('yok / boş / yalnız ayraç → boş liste', () {
      expect(parseOauthScopes(null), isEmpty);
      expect(parseOauthScopes(''), isEmpty);
      expect(parseOauthScopes(' , , '), isEmpty);
    });
  });
}
