/// Uygulama genelinde kullanılan hata modeli (B-050'de UX'e bağlanacak).
sealed class HubError implements Exception {
  const HubError(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Token geçersiz / yetkisiz (401, 403).
class HubAuthError extends HubError {
  const HubAuthError(super.message);
}

/// SHA çakışması — dosya biz okuduğumuzdan beri değişti (409).
class HubConflictError extends HubError {
  const HubConflictError(super.message);
}

/// Ağ yok / zaman aşımı — outbox'a düşmeli (B-032).
class HubNetworkError extends HubError {
  const HubNetworkError(super.message);
}

/// Rate limit (429 veya kalan istek 0).
class HubRateLimitError extends HubError {
  const HubRateLimitError(super.message, {this.resetAt});
  final DateTime? resetAt;
}

/// İstenen yol repoda yok (404). Dizin listelemede bu hata "boş liste"ye
/// çevrilir; git'te boş dizin diye bir şey olmadığı için "içi boşalmış dizin"
/// ile "hiç olmayan dizin" ayırt edilemez (bkz. L-005).
class HubNotFoundError extends HubError {
  const HubNotFoundError(super.message);
}

/// Yukarıdakilerin hiçbirine girmeyen durum (5xx, beklenmeyen gövde, vb.).
class HubUnexpectedError extends HubError {
  const HubUnexpectedError(super.message, {this.statusCode});
  final int? statusCode;
}
