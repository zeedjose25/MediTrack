import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/main.dart';

void main() {
  testWidgets('MediTrack app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MediTrackApp());

    expect(find.text('MediTrack'), findsOneWidget);
  });
}
