import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 246B-3C constrains bottom navigation height', () {
    final source = File('lib/features/home/home_shell.dart').readAsStringSync();

    expect(source, contains('bottomNavigationBar: _GetinBottomNavigationBar('));
    expect(source, contains('child: SizedBox(\n          height: 68,'));
    expect(
      source,
      isNot(contains('constraints: const BoxConstraints(minHeight: 64)')),
    );
    expect(source, contains('crossAxisAlignment: CrossAxisAlignment.stretch'));
  });

  test('Task 246B-3C keeps Home as tab zero', () {
    final source = File('lib/features/home/home_shell.dart').readAsStringSync();

    expect(source, contains('int _index = 0;'));
    expect(source, contains('HomeScreen('));
    expect(
        source, contains("(Icons.home_outlined, Icons.home_rounded, 'Home')"));
  });
}
