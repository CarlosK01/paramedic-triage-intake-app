import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paramedic_triage_intake/features/triage/presentation/pages/triage_intake_page.dart';
import 'package:paramedic_triage_intake/features/triage/presentation/providers/triage_providers.dart';

import 'fakes.dart';

void main() {
  Widget buildTestApp(WidgetTester tester, {required bool isOnline}) {
    // The form + record list is taller than the default 800x600 test
    // surface, so the "Submitted Records" section falls below the fold and
    // the ListView's sliver never builds it. Use a tall surface so
    // everything is on-screen without needing to scroll in every test.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      triageLocalDataSourceProvider.overrideWithValue(FakeLocalDataSource()),
      mockApiServiceProvider.overrideWithValue(FakeApiService()),
      connectivityServiceProvider
          .overrideWithValue(FakeConnectivityService(isOnline: isOnline)),
    ]);
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TriageIntakePage()),
    );
  }

  testWidgets(
      'filling the form and submitting saves the record and shows it in the list',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp(tester, isOnline: true));
    await tester.pumpAndSettle();

    expect(find.text('No records submitted yet.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Patient Name'), 'Jane Doe');
    await tester.enterText(
        find.widgetWithText(TextField, 'Condition Description'), 'Chest pain');
    await tester.tap(find.text('1')); // Priority 1 - critical
    await tester.pump();

    await tester.tap(find.text('Submit Triage Record'));
    await tester.pumpAndSettle();

    expect(find.text('Triage record saved.'), findsOneWidget);
    expect(find.text('Jane Doe'), findsWidgets);
    expect(find.text('No records submitted yet.'), findsNothing);
  });

  testWidgets('submitting a blank form shows validation errors, not a crash',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp(tester, isOnline: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit Triage Record'));
    await tester.pumpAndSettle();

    expect(find.text('Please fix the highlighted fields.'), findsOneWidget);
    expect(find.text('No records submitted yet.'), findsOneWidget);
  });

  testWidgets(
      'submitting while offline still saves locally and never shows a crash/error screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp(tester, isOnline: false));
    await tester.pumpAndSettle();

    expect(find.byType(TriageIntakePage), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Patient Name'), 'John Smith');
    await tester.enterText(
        find.widgetWithText(TextField, 'Condition Description'), 'Broken arm');
    await tester.tap(find.text('3'));
    await tester.pump();

    await tester.tap(find.text('Submit Triage Record'));
    await tester.pumpAndSettle();

    expect(find.text('Triage record saved.'), findsOneWidget);
    expect(find.text('John Smith'), findsWidgets);
    expect(find.text('1 pending'), findsOneWidget);
  });
}
