enum TipoRegistro { entrada, salida }

class Empleado {
  const Empleado({
    required this.id,
    required this.documento,
    required this.nombre,
    this.supervisorId,
    this.activo = true,
  });

  final String id;
  final String documento;
  final String nombre;
  final String? supervisorId;
  final bool activo;

  Empleado copyWith({
    String? documento,
    String? nombre,
    String? supervisorId,
    bool? activo,
  }) {
    return Empleado(
      id: id,
      documento: documento ?? this.documento,
      nombre: nombre ?? this.nombre,
      supervisorId: supervisorId ?? this.supervisorId,
      activo: activo ?? this.activo,
    );
  }
}

class Registro {
  const Registro({
    required this.id,
    required this.empleadoId,
    required this.tipo,
    required this.tiempo,
    required this.latitud,
    required this.longitud,
    required this.precisionMetros,
    required this.codigoVerificacion,
    this.evidenciaUrl,
    this.creadoPor,
  });

  final String id;
  final String empleadoId;
  final TipoRegistro tipo;
  final DateTime tiempo;
  final double latitud;
  final double longitud;
  final double precisionMetros;
  final String codigoVerificacion;
  final String? evidenciaUrl;
  final String? creadoPor;

  Registro copyWith({
    DateTime? tiempo,
    double? latitud,
    double? longitud,
    double? precisionMetros,
    String? evidenciaUrl,
    String? codigoVerificacion,
  }) {
    return Registro(
      id: id,
      empleadoId: empleadoId,
      tipo: tipo,
      tiempo: tiempo ?? this.tiempo,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      precisionMetros: precisionMetros ?? this.precisionMetros,
      codigoVerificacion: codigoVerificacion ?? this.codigoVerificacion,
      evidenciaUrl: evidenciaUrl ?? this.evidenciaUrl,
      creadoPor: creadoPor,
    );
  }
}

