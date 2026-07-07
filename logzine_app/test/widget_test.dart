import 'package:flutter_test/flutter_test.dart';

import 'package:logzine_app/main.dart';
import 'package:logzine_app/widgets/logzine_logo.dart';

void main() {
  testWidgets('앱이 로그인 웰컴 화면으로 시작한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Start with Email'), findsOneWidget);
    expect(find.text('Browse without login'), findsOneWidget);
    // 로고는 이제 이미지 워드마크(LogzineLogo)로 표시된다.
    expect(find.byType(LogzineLogo), findsOneWidget);
  });
}
