import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/all_tasks.dart';
import 'package:takip/hub/models/task.dart';

/// Bekleyenler listesinin sıralaması (T-013).
TaskSummary task({
  required String name,
  DateTime? date,
  String? priority = 'normal',
  TaskStatus status = TaskStatus.inbox,
}) =>
    TaskSummary(
      path: 'hub/tasks/inbox/$name',
      fileName: name,
      sha: 'sha',
      status: status,
      date: date,
      title: name,
      priority: priority,
      category: 'gorev',
    );

void main() {
  final a = task(
      name: 'a.md', date: DateTime.utc(2026, 8, 1), priority: 'low');
  final b = task(
      name: 'b.md', date: DateTime.utc(2026, 8, 5), priority: 'urgent');
  final c = task(
      name: 'c.md', date: DateTime.utc(2026, 8, 3), priority: 'high');

  List<String> names(List<TaskSummary> t) => t.map((e) => e.fileName).toList();

  test('varsayılan sıralama listeye dokunmaz', () {
    // `waitingFirst`, deponun zaten ürettiği sıra (K-022: bekleyen üstte).
    // Burada yeniden sıralamak, aynı kuralı iki yerde tutmak olurdu.
    const order = TaskOrder();
    expect(order.isDefault, isTrue);
    expect(names(order.apply([b, a, c])), ['b.md', 'a.md', 'c.md']);
  });

  test('tarihe göre azalan: yeniden eskiye', () {
    const order = TaskOrder(sort: TaskSort.date);
    expect(names(order.apply([a, b, c])), ['b.md', 'c.md', 'a.md']);
  });

  test('tarihe göre artan: eskiden yeniye', () {
    const order = TaskOrder(sort: TaskSort.date, ascending: true);
    expect(names(order.apply([a, b, c])), ['a.md', 'c.md', 'b.md']);
  });

  test('önceliğe göre azalan: urgent → low', () {
    const order = TaskOrder(sort: TaskSort.priority);
    expect(names(order.apply([a, c, b])), ['b.md', 'c.md', 'a.md']);
  });

  test('önceliğe göre artan: low → urgent', () {
    const order = TaskOrder(sort: TaskSort.priority, ascending: true);
    expect(names(order.apply([b, c, a])), ['a.md', 'c.md', 'b.md']);
  });

  group('bilinmeyen değer her iki yönde de sona gider', () {
    // Yönle birlikte başa gelseydi, "artan"da listenin tepesi bilgisizlerle
    // dolardı. Bilinmeyen bir öncelik gerçek: yerel kopya inmeden okunamıyor.
    final unknown = task(name: 'z.md', date: null, priority: null);

    test('tarih', () {
      for (final asc in [true, false]) {
        final order = TaskOrder(sort: TaskSort.date, ascending: asc);
        expect(names(order.apply([unknown, a, b])).last, 'z.md',
            reason: 'ascending: $asc');
      }
    });

    test('öncelik', () {
      for (final asc in [true, false]) {
        final order = TaskOrder(sort: TaskSort.priority, ascending: asc);
        expect(names(order.apply([unknown, a, b])).last, 'z.md',
            reason: 'ascending: $asc');
      }
    });
  });

  test('eşit değerlerde sıra kararlı kalır', () {
    // Aynı liste iki kez çizilirken sıra oynarsa kullanıcı listenin
    // kendiliğinden değiştiğini sanır.
    final x = task(name: 'x.md', date: DateTime.utc(2026, 8, 2));
    final y = task(name: 'y.md', date: DateTime.utc(2026, 8, 2));
    const order = TaskOrder(sort: TaskSort.date);

    expect(names(order.apply([y, x])), ['x.md', 'y.md']);
    expect(names(order.apply([x, y])), ['x.md', 'y.md']);
  });

  test('apply girdiyi değiştirmez', () {
    final input = [b, a, c];
    const TaskOrder(sort: TaskSort.date).apply(input);
    expect(names(input), ['b.md', 'a.md', 'c.md']);
  });

  group('seçim davranışı', () {
    test('aynı ölçüte ikinci dokunuş yönü çevirir', () {
      var order = const TaskOrder();
      order = _select(order, TaskSort.date);
      expect(order.ascending, isFalse);
      order = _select(order, TaskSort.date);
      expect(order.ascending, isTrue);
    });

    test('başka ölçüte geçince yön sıfırlanır', () {
      var order = const TaskOrder(sort: TaskSort.date, ascending: true);
      order = _select(order, TaskSort.priority);
      expect(order.sort, TaskSort.priority);
      expect(order.ascending, isFalse);
    });

    test('varsayılana dönmek yön taşımaz', () {
      var order = const TaskOrder(sort: TaskSort.date, ascending: true);
      order = _select(order, TaskSort.waitingFirst);
      expect(order.isDefault, isTrue);
      // İkinci dokunuş da bir şey çevirmemeli: yönü olmayan bir ölçüt.
      expect(_select(order, TaskSort.waitingFirst).isDefault, isTrue);
    });
  });
}

/// `TaskOrderNotifier.select`'in saf karşılığı — mantık orada tek satır ve
/// testin bir `ProviderContainer` kurmasına değmiyor; ikisi ayrışırsa
/// notifier'ın kendisi tek satırlık bir sarmalayıcı olduğu için görülür.
TaskOrder _select(TaskOrder state, TaskSort sort) =>
    sort == state.sort && sort.hasDirection
        ? state.with_(ascending: !state.ascending)
        : TaskOrder(sort: sort, ascending: false);
