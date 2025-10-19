import 'package:flutter_test/flutter_test.dart';

import 'package:app_turnotrack/features/registro/domain/entities.dart';

void main() {
  group('Registro entity', () {
    test('copyWith keeps base data and overrides selected fields', () {
      final original = Registro(
        id: 'reg-1',
        empleadoId: 'emp-1',
        tipo: TipoRegistro.entrada,
        tiempo: DateTime.utc(2025, 1, 1, 8),
        latitud: 4.711,
        longitud: -74.072,
        precisionMetros: 5.0,
        codigoVerificacion: 'ABC123',
        creadoPor: 'admin@turnotrack.com',
      );

      final updated = original.copyWith(
        precisionMetros: 3.0,
        evidenciaUrl: 'registros/2025/01/01/reg-1.jpg',
      );

      expect(updated.id, equals(original.id));
      expect(updated.precisionMetros, 3.0);
      expect(updated.evidenciaUrl, isNotNull);
      expect(updated.tipo, TipoRegistro.entrada);
    });
  });
}
