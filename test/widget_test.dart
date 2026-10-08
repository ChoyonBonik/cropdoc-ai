import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_disease_detector/main.dart';

void main() {
  testWidgets('TomatoDiseaseDetectorApp loads dashboard smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TomatoDiseaseDetectorApp());
    expect(find.text('Tomato Leaf Doctor'), findsOneWidget);
    expect(find.text('Scan Leaf'), findsOneWidget);
    expect(find.text('No Leaf Image Selected'), findsOneWidget);
  });
}
