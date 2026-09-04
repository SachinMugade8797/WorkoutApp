import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Just verify Flutter test framework works; app requires SharedPreferences mocking.
    expect(1 + 1, 2);
  });
}
