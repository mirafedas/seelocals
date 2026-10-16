import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seelocals/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SeeLocalsApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the placeholder screen in English by default', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pumpApp(tester);

    expect(find.text('Meet people in real life'), findsOneWidget);
  });

  testWidgets('follows the device locale', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('uk')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pumpApp(tester);

    expect(find.text('Знайомтеся з людьми наживо'), findsOneWidget);
  });

  testWidgets('switching the language re-renders the text', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pumpApp(tester);
    await tester.tap(find.text('Polski'));
    await tester.pumpAndSettle();

    expect(find.text('Poznawaj ludzi na żywo'), findsOneWidget);
    expect(find.text('Język urządzenia'), findsOneWidget);

    await tester.tap(find.text('Język urządzenia'));
    await tester.pumpAndSettle();

    expect(find.text('Meet people in real life'), findsOneWidget);
  });
}
