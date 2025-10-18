import 'package:flutter_test/flutter_test.dart';

import 'package:app_turnotrack/features/analitica/data/analytics_repo.dart';

void main() {
  test('calculates average hours from series', () {
    final series = [
      SerieTiempo(fecha: DateTime.utc(2025, 1, 1), valor: 8.0),
      SerieTiempo(fecha: DateTime.utc(2025, 1, 2), valor: 9.0),
      SerieTiempo(fecha: DateTime.utc(2025, 1, 3), valor: 10.0),
    ];

    final totalHoras = series.fold<double>(0, (acc, item) => acc + item.valor);
    final promedio = totalHoras / series.length;

    expect(promedio, closeTo(9.0, 0.001));
  });
}
