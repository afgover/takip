import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hub/hub_watcher.dart';

/// Yoklamayı uygulamanın ön plan/arka plan durumuna bağlar (B-024).
///
/// Arka plandayken yoklamak hem bataryayı hem istek limitini boşa harcar;
/// kullanıcı uygulamaya döndüğünde zaten hemen bir kontrol yapılır. Servis
/// bu kararı bilmez, yalnızca [HubWatcher.start] / [HubWatcher.stop] çağrılır.
class HubWatcherScope extends ConsumerStatefulWidget {
  const HubWatcherScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HubWatcherScope> createState() => _HubWatcherScopeState();
}

class _HubWatcherScopeState extends ConsumerState<HubWatcherScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(hubWatcherProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final watcher = ref.read(hubWatcherProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      watcher.start();
    } else {
      watcher.stop();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
