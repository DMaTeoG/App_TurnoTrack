import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_client_provider.dart';

enum UserRole { admin, supervisor, operador }

final userRoleProvider = Provider<UserRole>((ref) {
  final session = ref.watch(currentSessionProvider);
  final user = session?.user;
  final roleValue = user?.appMetadata['role'] ??
      user?.userMetadata?['role'] ??
      user?.userMetadata?['rol'] ??
      'operador';

  return UserRole.values.firstWhere(
    (role) => role.name == roleValue,
    orElse: () => UserRole.operador,
  );
});
