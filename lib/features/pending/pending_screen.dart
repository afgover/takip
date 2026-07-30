import 'package:flutter/material.dart';

/// Bekleyen görevler: tasks/inbox + tasks/active.
/// TODO(B-031): taskRepoProvider.listPending() ile gerçek liste, durum
/// rozetleri (inbox/active), detay görünümü; outbox'taki "gönderilecek"
/// görevler en üstte (B-032).
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bekleyenler')),
      body: const Center(child: Text('Görev listesi — B-031')),
    );
  }
}
