/// User roles in the application
enum UserRole {
  worker('worker', 'Trabajador'),
  supervisor('supervisor', 'Supervisor'),
  manager('manager', 'Gerente');

  const UserRole(this.value, this.displayName);

  final String value;
  final String displayName;

  /// Get role from string value
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.value == role.toLowerCase(),
      orElse: () => UserRole.worker,
    );
  }

  /// Check if role has supervisor permissions
  bool get isSupervisor =>
      this == UserRole.supervisor || this == UserRole.manager;

  /// Check if role has manager permissions
  bool get isManager => this == UserRole.manager;

  /// Check if role is worker only
  bool get isWorker => this == UserRole.worker;
}
