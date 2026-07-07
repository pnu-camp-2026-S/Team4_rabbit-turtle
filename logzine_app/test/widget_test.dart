import 'package:flutter_test/flutter_test.dart';

import 'package:logzine_app/main.dart';
import 'package:logzine_app/widgets/logzine_logo.dart';

void main() {
  testWidgets('스플래시(로고)로 시작해 웰컴 화면으로 넘어간다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 스플래시: 로고만 중앙에
    expect(find.byType(LogzineLogo), findsOneWidget);
    expect(find.text('Start with Email'), findsNothing);

    // 스플래시 시간(1.7s) + 페이드 전환(0.65s) 경과 → 웰컴
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('Start with Email'), findsOneWidget);
    expect(find.text('Browse without login'), findsOneWidget);
    expect(find.byType(LogzineLogo), findsOneWidget);
  });
}
