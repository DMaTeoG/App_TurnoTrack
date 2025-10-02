class EmpleadoModel {
  const EmpleadoModel({
    required this.id,
    required this.documento,
    required this.nombre,
    required this.rol,
    this.supervisorId,
    this.email,
    this.telefono,
    this.activo = true,
  });

  final String id;
  final String documento;
  final String nombre;
  final String rol;
  final String? supervisorId;
  final String? email;
  final String? telefono;
  final bool activo;

  EmpleadoModel copyWith({
    String? documento,
    String? nombre,
    String? rol,
    String? supervisorId,
    String? email,
    String? telefono,
    bool? activo,
  }) {
    return EmpleadoModel(
      id: id,
      documento: documento ?? this.documento,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      supervisorId: supervisorId ?? this.supervisorId,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
    );
  }
}

