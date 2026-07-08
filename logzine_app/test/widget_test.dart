import 'package:flutter_test/flutter_test.dart';

import 'package:logzine_app/main.dart';
import 'package:logzine_app/widgets/logzine_bookmark.dart';

void main() {
  testWidgets('스플래시(북마크 리본)로 시작해 웰컴 화면으로 넘어간다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 스플래시: 북마크 리본 로고가 중앙에
    expect(find.byType(LogzineBookmark), findsOneWidget);
    expect(find.text('Start with Email'), findsNothing);

    // 스플래시 조립(2.5s) + 전환(3.1s) 경과 → 웰컴
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pumpAndSettle();

    expect(find.text('Start with Email'), findsOneWidget);
    expect(find.text('Browse without login'), findsOneWidget);
    // 웰컴 로고도 동일한 리본+워드마크 lockup
    expect(find.byType(LogzineLockup), findsOneWidget);
  });
}
