import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_disease_detector/main.dart';
import 'package:gemini_disease_detector/widgets/diagnosis_report_view.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cropdoc_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

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

    expect(find.text('Early Blight (Alternaria solani)'), findsOneWidget);
    expect(find.text('Clinical Report'), findsOneWidget);
    expect(find.text('Action Checklist'), findsOneWidget);

    // Switch to Action Checklist tab
    await tester.tap(find.text('Action Checklist'));
    await tester.pumpAndSettle();

    expect(find.text('Treatment Progress'), findsOneWidget);
    expect(find.text('Prune affected leaves immediately'), findsOneWidget);
    expect(find.text('Apply copper fungicide every 7 days'), findsOneWidget);
  });

  testWidgets('CropDocApp navigates to HistoryScreen via AppBar action',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CropDocApp());

    // Tap History button in AppBar
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Scan History & Archive'), findsOneWidget);
    expect(find.text('Search by disease name...'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);
  });
}
