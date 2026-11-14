import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sathi/core/widgets/clinical_widgets.dart';

void main() {
  testWidgets('MedicalCard renders child content properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MedicalCard(
            child: Text('Test Medical Record'),
          ),
        ),
      ),
    );

    expect(find.text('Test Medical Record'), findsOneWidget);
    expect(find.byType(MedicalCard), findsOneWidget);
  });
}
