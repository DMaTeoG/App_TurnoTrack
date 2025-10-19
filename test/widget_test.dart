import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_turnotrack/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fake.fake',
    );
  });

  testWidgets('renderiza pantalla de login por defecto', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TurnoTrackApp()));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesion'), findsOneWidget);
  });
}
