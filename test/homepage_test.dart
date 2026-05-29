// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:coldcall/core/dart_mappable_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coldcall/main.dart';

void main() {
  registerJsonMappers();

  testWidgets('MyApp', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // await tester.pumpAndSettle(Duration(seconds: 20));
    await tester.pump(Duration(seconds: 10));

    expect(find.text('Ошибка'), findsNothing);
    expect(find.text('Позвонить'), findsOneWidget);

    // await tester.tap(find.byIcon(Icons.history));
    // await tester.pump();

    // expect(find.text('Ошибка'), findsNothing);
    // expect(find.text('Синхронизировано'), findsOneWidget);
  });
}
