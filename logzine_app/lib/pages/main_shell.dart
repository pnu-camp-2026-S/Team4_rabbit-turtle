import 'package:flutter/material.dart';

import '../widgets/logzine_bottom_nav.dart';
import 'home_page.dart';
import 'discover_page.dart';
import 'library_page.dart';
import 'archive_page.dart';

/// 메인 셸 — 하단 4탭을 IndexedStack으로 유지해서
/// 탭을 오가도 각 화면의 스크롤/상태가 보존된다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// 셸 안의 화면에서 다른 탭으로 전환할 때 사용.
  /// (셸 밖에서 호출되면 스택을 비우고 메인 셸로 이동)
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    if (state != null) {
      state._select(index);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/main',
        (route) => false,
        arguments: index,
      );
    }
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _argsApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsApplied) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args <= 3) _index = args;
      _argsApplied = true;
    }
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomePage(),
          DiscoverPage(),
          LibraryPage(),
          ArchivePage(),
        ],
      ),
      bottomNavigationBar: LogzineBottomNav(
        currentIndex: _index,
        onSelect: _select,
      ),
    );
  }
}
