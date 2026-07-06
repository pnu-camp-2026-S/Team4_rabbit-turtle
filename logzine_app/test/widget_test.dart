import 'package:flutter_test/flutter_test.dart';

import 'package:logzine_app/main.dart';

void main() {
  testWidgets('앱이 로그인 웰컴 화면으로 시작한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Start with Email'), findsOneWidget);
    expect(find.text('Browse without login'), findsOneWidget);
    expect(find.text('LOGZINE'), findsOneWidget);
  });
}
