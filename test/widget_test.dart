import 'package:flutter_test/flutter_test.dart';
import 'package:dj_aiodip/main.dart';
import 'package:dj_aiodip/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Welcome screen loads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();
    await tester.pumpWidget(DjAiodipApp(appState: state));
    await tester.pumpAndSettle();
    expect(find.text('AIODIP'), findsOneWidget);
    expect(find.text('Start free trial'), findsOneWidget);
  });
}
