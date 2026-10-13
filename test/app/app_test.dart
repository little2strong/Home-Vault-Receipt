import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:home_vault_receipt/app/app.dart';
import 'package:home_vault_receipt/core/services/key_value_store.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('first launch goes from splash to the welcome screen', (
    tester,
  ) async {
    await tester.pumpWidget(App(store: MemoryStore()));
    expect(find.text('home vault'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Less paper.\nMore peace of mind.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('a new account lands on the dashboard with its vault', (
    tester,
  ) async {
    await tester.pumpWidget(App(store: MemoryStore()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(1), 'alex@example.com');
    await tester.enterText(find.byType(EditableText).at(2), 'secret123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    // New accounts verify their email first.
    expect(find.text('Check your inbox.'), findsOneWidget);
    await tester.tap(find.text('I have verified my email'));
    await tester.pumpAndSettle();

    expect(find.text('Everything,\nin its place.'), findsOneWidget);
    expect(find.text('Add a receipt'), findsOneWidget);
  });
}
