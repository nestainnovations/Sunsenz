// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sunsenz/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const packageInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (call) async {
          if (call.method != 'getAll') return null;
          return <String, dynamic>{
            'appName': 'Sunsenz',
            'buildNumber': '1',
            'packageName': 'in.sunsenz.service',
            'version': '1.0.0',
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  testWidgets('shows splash screen when app starts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SunsenzServeApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
