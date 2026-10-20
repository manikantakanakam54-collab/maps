import 'package:flutter_test/flutter_test.dart';
import 'package:lpu_maps/main.dart';
import 'package:lpu_maps/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('LPU Maps app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.init();

    await tester.pumpWidget(LpuMapsApp(prefs: prefs));
    await tester.pump();

    expect(find.text('Welcome to LPU Maps'), findsOneWidget);
  });
}
