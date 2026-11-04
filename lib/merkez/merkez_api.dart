import 'package:dio/dio.dart';

/// Merkez sunucusu: tüm hub'ların indeksi ve tek cevap kapısı (asistan K-009).
///
/// Adres derlemede değiştirilebilir; sır değildir. Belirteç yalnız secure
/// storage'da durur (bkz. `merkez_providers.dart`).
const merkezBaseUrl = String.fromEnvironment(
  'MERKEZ_URL',
  defaultValue: 'https://merkez.gover.us',
);

enum MerkezErrorKind {
  /// Parola yanlış ya da belirtecin süresi doldu.
  unauthorized,

  /// Çift ya da çelişen cevap, görev artık beklemiyor (409).
  conflict,

  /// İstek geçersiz: seçenek listede yok, görev bulunamadı (400, 404).
  rejected,

  /// Çok fazla deneme (429).
  rateLimited,

  /// Sunucuya ulaşılamadı.
  network,

  /// Sunucu tarafı hata (5xx).
  server,
}

class MerkezError implements Exception {
  const MerkezError(this.kind, [this.serverMessage]);

  final MerkezErrorKind kind;

  /// Sunucunun açıklaması. Yalnız 4xx'te gösterilir; sır içermez.
  final String? serverMessage;

  @override
  String toString() => 'MerkezError($kind)';
}

class TodayTotals {
  const TodayTotals({
    required this.pendingDecisions,
    required this.withOptions,
    required this.awaitingAgent,
    required this.parked,
  });

  factory TodayTotals.fromJson(Map<String, dynamic> json) => TodayTotals(
        pendingDecisions: _int(json['pendingDecisions']),
        withOptions: _int(json['withOptions']),
        awaitingAgent: _int(json['awaitingAgent']),
        parked: _int(json['parked']),
      );

  final int pendingDecisions;
  final int withOptions;
  final int awaitingAgent;
  final int parked;
}

class TodayTask {
  const TodayTask({
    required this.title,
    required this.priority,
    required this.options,
    required this.overdue,
    required this.awaitingAgent,
    this.taskId,
    this.due,
  });

  factory TodayTask.fromJson(Map<String, dynamic> json) => TodayTask(
        taskId: json['taskId'] as String?,
        title: json['title'] as String? ?? '',
        priority: json['priority'] as String? ?? 'normal',
        due: json['due'] as String?,
        overdue: json['overdue'] == true,
        awaitingAgent: json['awaitingAgent'] == true,
        options: (json['options'] as List?)?.map((o) => '$o').toList() ??
            const [],
      );

  /// Elle yazılmış eski kayıtlarda yok; o görevlere buradan cevap verilemez.
  final String? taskId;
  final String title;
  final String priority;
  final String? due;
  final bool overdue;
  final bool awaitingAgent;
  final List<String> options;
}

class TodayHub {
  const TodayHub({
    required this.slug,
    required this.project,
    required this.status,
    required this.inboxCount,
    required this.waiting,
  });

  factory TodayHub.fromJson(Map<String, dynamic> json) => TodayHub(
        slug: json['slug'] as String,
        project: json['project'] as String? ?? json['slug'] as String,
        status: json['status'] as String? ?? 'aktif',
        inboxCount: _int(json['inboxCount']),
        waiting: (json['waiting'] as List? ?? const [])
            .map((t) => TodayTask.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  final String slug;
  final String project;
  final String status;
  final int inboxCount;
  final List<TodayTask> waiting;

  bool get isActive => status == 'aktif';
}

class TodayData {
  const TodayData({
    required this.totals,
    required this.hubs,
    required this.failedHubs,
    this.lastIndexedAt,
  });

  factory TodayData.fromJson(Map<String, dynamic> json) => TodayData(
        totals: TodayTotals.fromJson(
            json['totals'] as Map<String, dynamic>? ?? const {}),
        hubs: (json['hubs'] as List? ?? const [])
            .map((h) => TodayHub.fromJson(h as Map<String, dynamic>))
            .toList(),
        failedHubs:
            (json['failedHubs'] as List?)?.map((h) => '$h').toList() ?? const [],
        lastIndexedAt: DateTime.tryParse(json['lastIndexedAt'] as String? ?? ''),
      );

  final TodayTotals totals;
  final List<TodayHub> hubs;
  final List<String> failedHubs;
  final DateTime? lastIndexedAt;
}

/// Kapalı katalogdaki bir komut ve son çalışması (Merkez `/commands`).
class MerkezCommand {
  const MerkezCommand({
    required this.name,
    required this.titleTr,
    required this.titleEn,
    this.lastStatus,
  });

  final String name;
  final String titleTr;
  final String titleEn;

  /// queued | running | done | failed; hiç çalışmadıysa null.
  final String? lastStatus;

  bool get isActive => lastStatus == 'queued' || lastStatus == 'running';

  /// Yanıtın `recent` listesi en yeni önce gelir.
  static List<MerkezCommand> listFromJson(Map<String, dynamic> json) {
    final recent = (json['recent'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return (json['catalog'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((c) {
      final name = c['name'] as String;
      final title = c['title'] as Map<String, dynamic>? ?? const {};
      final last = recent.where((r) => r['type'] == name).firstOrNull;
      return MerkezCommand(
        name: name,
        titleTr: title['tr'] as String? ?? name,
        titleEn: title['en'] as String? ?? name,
        lastStatus: last?['status'] as String?,
      );
    }).toList();
  }
}

int _int(Object? value) => value is num ? value.toInt() : 0;

/// Merkez'in uygulamanın kullandığı üç ucu. Bilinmeyen alan yok sayılır:
/// sunucu önce güncellenebilir.
class MerkezApi {
  MerkezApi(this._dio);

  final Dio _dio;

  static Dio buildDio() => Dio(BaseOptions(
        baseUrl: merkezBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ));

  Options _auth(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  Future<String> login(String password) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'password': password},
        );
        final token = res.data?['accessToken'];
        if (token is! String || token.isEmpty) {
          throw const MerkezError(MerkezErrorKind.server);
        }
        return token;
      });

  Future<TodayData> today(String token) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/today',
          options: _auth(token),
        );
        return TodayData.fromJson(res.data ?? const {});
      });

  Future<void> answer(
    String token, {
    required String hub,
    required String taskId,
    String? option,
    String? text,
  }) =>
      _guard(() async {
        await _dio.post<dynamic>(
          '/hubs/${Uri.encodeComponent(hub)}/tasks/${Uri.encodeComponent(taskId)}/answer',
          data: {
            if (option != null) 'option': option,
            if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
          },
          options: _auth(token),
        );
      });

  Future<List<MerkezCommand>> commands(String token) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/commands',
          options: _auth(token),
        );
        return MerkezCommand.listFromJson(res.data ?? const {});
      });

  Future<void> runCommand(String token, String name) => _guard(() async {
        await _dio.post<dynamic>(
          '/commands/${Uri.encodeComponent(name)}/run',
          options: _auth(token),
        );
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  MerkezError _map(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return const MerkezError(MerkezErrorKind.network);
    final data = e.response?.data;
    final raw = data is Map ? data['message'] : null;
    final message = raw is String ? raw : null;
    return switch (status) {
      401 => const MerkezError(MerkezErrorKind.unauthorized),
      409 => MerkezError(MerkezErrorKind.conflict, message),
      429 => const MerkezError(MerkezErrorKind.rateLimited),
      >= 400 && < 500 => MerkezError(MerkezErrorKind.rejected, message),
      _ => const MerkezError(MerkezErrorKind.server),
    };
  }
}
