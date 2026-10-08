import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_disease_detector/main.dart';
import 'package:gemini_disease_detector/widgets/diagnosis_report_view.dart';

void main() {
  testWidgets('CropDocApp loads dashboard smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CropDocApp());
    expect(find.text('CropDoc AI'), findsOneWidget);
    expect(find.text('Scan Leaf'), findsOneWidget);
    expect(find.text('No Leaf Image Selected'), findsOneWidget);
  });

  testWidgets('DiagnosisReportView renders clinical report and checklist',
      (WidgetTester tester) async {
    const mockReport = '''
# Diagnosis: Early Blight (Alternaria solani)
## Visual Symptoms:
- Brown concentric rings on lower leaves
## Treatment Plan:
- Prune affected leaves immediately
- Apply copper fungicide every 7 days
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DiagnosisReportView(diagnosisText: mockReport),
          ),
        ),
      ),
    );

    expect(find.text('AI DIAGNOSIS RESULT'), findsOneWidget);
    expect(find.text('Clinical Report'), findsOneWidget);
    expect(find.text('Action Checklist'), findsOneWidget);

    // Switch to Action Checklist tab
    await tester.tap(find.text('Action Checklist'));
    await tester.pumpAndSettle();

    expect(find.text('Treatment Progress'), findsOneWidget);
    expect(find.text('Prune affected leaves immediately'), findsOneWidget);
    expect(find.text('Apply copper fungicide every 7 days'), findsOneWidget);
  });
}
