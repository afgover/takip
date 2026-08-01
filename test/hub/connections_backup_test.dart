import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/connections_backup.dart';
import 'package:takip/hub/hub_config.dart';

HubConfig conn(String slug, {String token = 'gizli-token', String? label}) {
  final parsed = HubConfig.parseRepo(slug)!;
  return HubConfig(
    owner: parsed.owner,
    repo: parsed.repo,
    token: token,
    label: label,
  );
}

void main() {
  final sample = [
    conn('afgover/takip', token: 'github_pat_bir', label: 'Takip'),
    conn('afgover/baska', token: 'github_pat_iki'),
  ];

  test('yedek çözülünce bütün bağlantılar aynen geri gelir', () async {
    final backup = await ConnectionsBackup.export(sample, passphrase: 'p4rola');
    final restored =
        await ConnectionsBackup.import(backup, passphrase: 'p4rola');

    expect(restored, hasLength(2));
    expect(restored.map((c) => c.slug), ['afgover/takip', 'afgover/baska']);
    expect(restored.map((c) => c.token), ['github_pat_bir', 'github_pat_iki']);
    expect(restored.first.label, 'Takip');
    expect(restored.last.label, isNull);
  });

  test('token yedek metninde düz görünmez', () async {
    final backup = await ConnectionsBackup.export(sample, passphrase: 'p4rola');

    // Asıl korunan şey bu: yedeği ele geçiren, parolasız token göremez.
    expect(backup, isNot(contains('github_pat_bir')));
    expect(backup, isNot(contains('afgover')));
    expect(backup, startsWith('${ConnectionsBackup.formatVersion}.'));
  });

  test('yanlış parola çözmez', () async {
    final backup = await ConnectionsBackup.export(sample, passphrase: 'dogru');

    expect(
      () => ConnectionsBackup.import(backup, passphrase: 'yanlis'),
      throwsA(isA<BackupError>()),
    );
  });

  test('kurcalanmış yedek çözmez', () async {
    final backup = await ConnectionsBackup.export(sample, passphrase: 'p4rola');
    final parts = backup.split('.');
    // Şifreli gövdenin son karakterini değiştir.
    final body = parts[3];
    final tampered = body.substring(0, body.length - 1) +
        (body.endsWith('A') ? 'B' : 'A');

    expect(
      () => ConnectionsBackup.import(
        [parts[0], parts[1], parts[2], tampered].join('.'),
        passphrase: 'p4rola',
      ),
      throwsA(isA<BackupError>()),
      reason: 'AES-GCM kimlik doğrulamalı: bozuk veri sessizce çözülmemeli',
    );
  });

  test('aynı parolayla alınan iki yedek aynı olmaz', () async {
    final first = await ConnectionsBackup.export(sample, passphrase: 'p4rola');
    final second = await ConnectionsBackup.export(sample, passphrase: 'p4rola');

    // Salt ve nonce her seferinde yeniden üretiliyor.
    expect(first, isNot(second));
    // Yine de ikisi de aynı içeriği vermeli.
    final a = await ConnectionsBackup.import(first, passphrase: 'p4rola');
    final b = await ConnectionsBackup.import(second, passphrase: 'p4rola');
    expect(a.map((c) => c.slug), b.map((c) => c.slug));
  });

  test('tanınmayan sürüm reddedilir', () async {
    final backup = await ConnectionsBackup.export(sample, passphrase: 'p4rola');
    final parts = backup.split('.');

    expect(
      () => ConnectionsBackup.import(
        ['takip-backup-v9', parts[1], parts[2], parts[3]].join('.'),
        passphrase: 'p4rola',
      ),
      throwsA(
        isA<BackupError>().having(
          (e) => e.message,
          'message',
          contains('sürüm'),
        ),
      ),
    );
  });

  test('bozuk metin anlaşılır hata verir', () async {
    for (final bad in ['', 'saçmalık', 'a.b.c', 'takip-backup-v1.x.y']) {
      expect(
        () => ConnectionsBackup.import(bad, passphrase: 'p4rola'),
        throwsA(isA<BackupError>()),
        reason: '"$bad" için anlaşılır hata bekleniyor',
      );
    }
  });

  test('base64 dolgusu atılıp geri konsa da veri bozulmaz', () async {
    // Dolgu atma bilinçli (kopyalarken `=` kayboluyor); her uzunlukta
    // çözülebildiğini garanti altına alalım.
    for (var count = 1; count <= 4; count++) {
      final many = [
        for (var i = 0; i < count; i++) conn('a/repo$i', token: 't' * i),
      ];
      final backup = await ConnectionsBackup.export(many, passphrase: 'p');
      final restored = await ConnectionsBackup.import(backup, passphrase: 'p');
      expect(restored.map((c) => c.slug), many.map((c) => c.slug));
    }
  });

  test('boş parola reddedilir', () async {
    expect(
      () => ConnectionsBackup.export(sample, passphrase: ''),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('boş liste yedeklenip geri yüklenebilir', () async {
    final backup = await ConnectionsBackup.export(const [], passphrase: 'p');
    expect(await ConnectionsBackup.import(backup, passphrase: 'p'), isEmpty);
  });

  test('yedek gövdesi geçerli JSON taşır (biçim sözleşmesi)', () async {
    final backup = await ConnectionsBackup.export(sample, passphrase: 'p');
    final restored = await ConnectionsBackup.import(backup, passphrase: 'p');

    // Dışa aktarılan yapı, HubConfig'in kendi JSON biçimiyle aynı olmalı;
    // ileride alan eklenirse round-trip bunu yakalar.
    expect(
      jsonEncode(restored.first.toJson()),
      jsonEncode(sample.first.toJson()),
    );
  });
}
