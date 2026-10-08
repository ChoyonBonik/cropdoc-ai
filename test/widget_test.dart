import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_disease_detector/main.dart';

void main() {
  testWidgets('CropDocApp loads dashboard smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CropDocApp());
    expect(find.text('CropDoc AI'), findsOneWidget);
    expect(find.text('Scan Leaf'), findsOneWidget);
    expect(find.text('No Leaf Image Selected'), findsOneWidget);
  });
}
