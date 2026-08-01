import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'hub_config.dart';

/// Bağlantıların (repo + token) parolayla şifrelenmiş yedeği.
///
/// **Neden var:** cihaz verisi kaçınılmaz olarak kaybolabiliyor — fabrika
/// ayarları, "verileri temizle", yeni telefon, ya da kurulumun paketi
/// kaldırmak zorunda kalması (L-014). Tek repoda bunun bedeli bir token
/// girmek; çok repoda her repo için ayrı token girmek demek ve sistem
/// kullanılmaz hâle geliyor.
///
/// **Neden şifreli:** yedek, token'ların kendisini taşır. Düz metin olsaydı
/// panoya düşen dizeyi pano geçmişi tutan her uygulama görebilirdi ve
/// kullanıcının repolarına yazma yetkisi o dizede olurdu. Parola, yedeği
/// tek başına işe yaramaz kılar.
///
/// Şifreleme kendi elimizle yazılmadı: PBKDF2-HMAC-SHA256 ile anahtar
/// türetimi ve AES-GCM ile şifreleme `package:cryptography`'den geliyor.
/// AES-GCM aynı zamanda **kimlik doğrulamalı**dır: yanlış parola ve
/// kurcalanmış yedek aynı hatayı verir, sessizce bozuk veri çözülmez.
abstract final class ConnectionsBackup {
  /// Yedek biçimi sürümü. Çözme, tanımadığı sürümü reddeder — ileride biçim
  /// değişirse eski yedek sessizce yanlış yorumlanmasın.
  static const formatVersion = 'takip-backup-v1';

  /// PBKDF2 tur sayısı. Telefonda ~1 sn'lik gecikme, sözlük saldırısında
  /// saldırganın her denemesine aynı maliyeti bindirir.
  static const iterations = 150000;

  static const _saltBytes = 16;
  static const _nonceBytes = 12;

  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );
  static final _cipher = AesGcm.with256bits();

  /// Bağlantıları tek bir metne çevirir.
  ///
  /// Biçim: `takip-backup-v1.<salt>.<nonce>.<şifreli+mac>` (parçalar base64url).
  /// Salt her dışa aktarmada yeniden üretilir; aynı parolayla alınan iki yedek
  /// aynı görünmez.
  static Future<String> export(
    List<HubConfig> connections, {
    required String passphrase,
    Random? random,
  }) async {
    if (passphrase.isEmpty) {
      throw ArgumentError.value(passphrase, 'passphrase', 'Parola boş olamaz');
    }

    final rnd = random ?? Random.secure();
    final salt = _randomBytes(rnd, _saltBytes);
    final nonce = _randomBytes(rnd, _nonceBytes);

    final key = await _kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final plain = utf8.encode(
      jsonEncode({
        'version': formatVersion,
        'connections': [for (final c in connections) c.toJson()],
      }),
    );

    final box = await _cipher.encrypt(plain, secretKey: key, nonce: nonce);

    return [
      formatVersion,
      _b64(salt),
      _b64(nonce),
      _b64([...box.cipherText, ...box.mac.bytes]),
    ].join('.');
  }

  /// Yedeği çözer. Parola yanlışsa ya da metin kurcalanmışsa
  /// [BackupError] atar — ikisi ayırt edilmez, edilmemeli.
  static Future<List<HubConfig>> import(
    String backup, {
    required String passphrase,
  }) async {
    final parts = backup.trim().split('.');
    if (parts.length != 4) {
      throw const BackupError(
        'Yedek metni tanınmadı. Tamamını kopyaladığından emin ol.',
      );
    }
    if (parts.first != formatVersion) {
      throw BackupError(
        'Bu yedek farklı bir sürümle alınmış (${parts.first}). '
        'Uygulamanın bu sürümü $formatVersion bekliyor.',
      );
    }

    final Uint8List salt, nonce, payload;
    try {
      salt = _unb64(parts[1]);
      nonce = _unb64(parts[2]);
      payload = _unb64(parts[3]);
    } catch (_) {
      throw const BackupError('Yedek metni bozuk görünüyor.');
    }

    // Son 16 bayt GCM etiketi; gövde en az bir bayt olmalı.
    const macBytes = 16;
    if (payload.length <= macBytes) {
      throw const BackupError('Yedek metni eksik.');
    }

    final key = await _kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final box = SecretBox(
      payload.sublist(0, payload.length - macBytes),
      nonce: nonce,
      mac: Mac(payload.sublist(payload.length - macBytes)),
    );

    final List<int> plain;
    try {
      plain = await _cipher.decrypt(box, secretKey: key);
    } on SecretBoxAuthenticationError {
      // Yanlış parola ile kurcalanmış yedek burada aynı yola çıkar. Ayırt
      // etmeye çalışmak, saldırgana "parola doğruydu ama veri bozuk" gibi
      // bilgi sızdırmak olurdu.
      throw const BackupError(
        'Parola yanlış ya da yedek bozulmuş. Yedeği ve parolayı kontrol et.',
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      final list = decoded['connections'] as List<dynamic>;
      return [
        for (final item in list)
          HubConfig.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      throw const BackupError('Yedek çözüldü ama içeriği okunamadı.');
    }
  }

  static Uint8List _randomBytes(Random rnd, int length) =>
      Uint8List.fromList([for (var i = 0; i < length; i++) rnd.nextInt(256)]);

  /// Doldurma karakteri olmadan: yedek elle kopyalanacak bir metin, sondaki
  /// `=` işaretleri kopyalamada sık kayboluyor.
  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  /// [_b64]'ün tersi — atılan dolguyu geri koyar, çünkü çözücü onu bekler.
  static Uint8List _unb64(String value) {
    final remainder = value.length % 4;
    final padded = remainder == 0 ? value : value + '=' * (4 - remainder);
    return base64Url.decode(padded);
  }
}

/// Yedekleme/geri yükleme hatası — mesajı doğrudan kullanıcıya gösterilir.
class BackupError implements Exception {
  const BackupError(this.message);
  final String message;

  @override
  String toString() => message;
}
