import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_coffee/core/widgets/getin_primary_button.dart';

void main() {
  testWidgets('Task 244 primary action survives compact width and large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: GetinPrimaryButton(
                label: 'Continue with this very long accessible action label',
                onPressed: () {},
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(56));
  });

  test('Task 244 bottom navigation exposes explicit selected semantics', () {
    final source = File('lib/features/home/home_shell.dart').readAsStringSync();

    expect(source, contains('Semantics('));
    expect(source, contains('button: true'));
    expect(source, contains('selected: selected'));
    expect(source, contains('excludeFromSemantics: true'));
    expect(source, contains('child: SizedBox('));
    expect(source, contains('height: 68'));
    expect(
      source,
      isNot(contains('constraints: const BoxConstraints(minHeight: 64)')),
    );
    expect(source, isNot(contains('height: 15')));
  });
}
