class SupervisorModel {
  const SupervisorModel({
    required this.id,
    required this.documento,
    required this.nombre,
    required this.email,
    this.telefono,
    this.activo = true,
  });

  final String id;
  final String documento;
  final String nombre;
  final String email;
  final String? telefono;
  final bool activo;

  SupervisorModel copyWith({
    String? documento,
    String? nombre,
    String? email,
    String? telefono,
    bool? activo,
  }) {
    return SupervisorModel(
      id: id,
      documento: documento ?? this.documento,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
    );
  }
}

