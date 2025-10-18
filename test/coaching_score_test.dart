import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coaching score heuristics', () {
    double calcularScore({
      required double puntualidad,
      required double cumplimientoTurnos,
      required double permanencia,
      required double incidencias,
    }) {
      final base = (puntualidad * 0.4) +
          (cumplimientoTurnos * 0.35) +
          (permanencia * 0.15) +
          ((100 - incidencias) * 0.10);
      final normalizado = base.clamp(40, 95).toDouble();
      return normalizado;
    }

    test('limita puntaje maximo a 95', () {
      final score = calcularScore(
        puntualidad: 100,
        cumplimientoTurnos: 100,
        permanencia: 100,
        incidencias: 0,
      );

      expect(score, 95);
    });

    test('penaliza incidencias altas', () {
      final score = calcularScore(
        puntualidad: 80,
        cumplimientoTurnos: 75,
        permanencia: 60,
        incidencias: 40,
      );

      expect(score, closeTo(73.3, 0.5));
    });
  });
}
