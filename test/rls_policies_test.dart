import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RLS policies', () {
    test('operador solo ve sus registros', () async {
      // TODO: integrar con supabase local usando tokens simulados.
    }, skip: 'Requiere entorno Supabase local con politicas RLS.');

    test('supervisor no accede a otros equipos', () async {
      // TODO: integrar con supabase local usando tokens simulados.
    }, skip: 'Requiere entorno Supabase local con politicas RLS.');
  });
}
