import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('앱이 MainShell을 로드한다', (WidgetTester tester) async {
    await tester.pumpWidget(const HospitalNaviApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('CDSSentials'), findsOneWidget);
  });
}
