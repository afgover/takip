import '../../core/utils.dart';
import 'task.dart';

/// Gönderilmeye hazır görev — dosya adı, içerik ve commit mesajı birlikte.
///
/// Ayrı bir tip olmasının nedeni B-032: ağ yokken görev **taslak olarak**
/// saklanıp sonra gönderilecek. O yüzden taslak, üretildiği andaki hâliyle
/// (tarih, slug, frontmatter) diske yazılabilir olmalı; sonradan yeniden
/// üretilirse tarih kayar ve kullanıcının gördüğü görev başka bir dosya olur.
class TaskDraft {
  const TaskDraft({
    required this.fileName,
    required this.content,
    required this.commitMessage,
    required this.title,
    required this.createdAt,
  });

  /// Kullanıcı girdisinden sözleşmeye uygun taslak üretir (SYSTEM.md §4, §8).
  factory TaskDraft.create({
    required String title,
    String description = '',
    String priority = 'normal',
    String category = 'gorev',
    List<String> tags = const [],
    DateTime? now,
  }) {
    final at = now ?? DateTime.parse(isoNow());
    final trimmed = title.trim();
    final task = HubTask(
      // ID'yi agent atar (SYSTEM.md §4); app numara uydurmaz.
      id: 'pending',
      title: trimmed,
      createdBy: 'user',
      created: isoNow(),
      updated: isoNow(),
      priority: priority,
      category: category.trim(),
      tags: tags,
      session: 'none',
      result: 'none',
      status: TaskStatus.inbox,
      path: '',
      body: _body(trimmed, description.trim()),
    );

    return TaskDraft(
      fileName: taskFileName(at, trimmed),
      content: task.toFileContent(),
      commitMessage: "task(pending): inbox'a eklendi (app)",
      title: trimmed,
      createdAt: at,
    );
  }

  factory TaskDraft.fromJson(Map<String, dynamic> json) => TaskDraft(
        fileName: json['fileName'] as String,
        content: json['content'] as String,
        commitMessage: json['commitMessage'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String fileName;
  final String content;
  final String commitMessage;

  /// Kuyrukta beklerken listede göstermek için.
  final String title;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'content': content,
        'commitMessage': commitMessage,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Aynı taslağın farklı dosya adıyla kopyası — ad çakışmasında kullanılır
  /// (B-033).
  TaskDraft withFileName(String name) => TaskDraft(
        fileName: name,
        content: content,
        commitMessage: commitMessage,
        title: title,
        createdAt: createdAt,
      );

  static String _body(String title, String description) => '# $title\n\n'
      '## İstek\n'
      '${description.isEmpty ? '(açıklama girilmedi)' : description}\n\n'
      '## Notlar\n';
}
