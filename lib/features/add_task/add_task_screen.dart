import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Görev ekleme: başlık, açıklama, öncelik, kategori.
/// Kategoriler (K-010): varsayılanlar + mevcut görevlerden türetilenler +
/// serbest giriş. TODO(B-030): kaydet → tasks/inbox'a PUT; başarısızsa
/// outbox'a (B-032).
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  String _priority = 'normal';
  String _category = Hub.defaultCategories.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görev Ekle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TextField(
            decoration: InputDecoration(
                labelText: 'Başlık', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
                labelText: 'Açıklama', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(
                labelText: 'Öncelik', border: OutlineInputBorder()),
            items: [
              for (final p in Hub.priorities)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
                labelText: 'Kategori', border: OutlineInputBorder()),
            items: [
              for (final c in Hub.defaultCategories)
                DropdownMenuItem(value: c, child: Text(c)),
              // TODO(B-030): mevcut görevlerden türetilen kategoriler +
              // "yeni kategori..." serbest girişi (K-010).
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: null, // TODO(B-030)
            child: const Text('Hub\'a Gönder'),
          ),
        ],
      ),
    );
  }
}
