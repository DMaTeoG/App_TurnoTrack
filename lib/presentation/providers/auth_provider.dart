import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/datasources/supabase_datasource.dart';
import '../../core/enums/user_role.dart';

// Provider del cliente Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider del datasource
final supabaseDatasourceProvider = Provider<SupabaseDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseDatasource(client);
});

// Provider del estado de autenticación (Stream)
final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((data) => data.session?.user);
});

// Provider del usuario actual completo
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return null;

  final datasource = ref.watch(supabaseDatasourceProvider);
  return await datasource.getUserById(authState.id);
});

// Notifier para autenticación usando AsyncNotifier (Riverpod 3.x)
class AuthNotifier extends AsyncNotifier<UserModel?> {
  late SupabaseDatasource _datasource;

  @override
  Future<UserModel?> build() async {
    _datasource = ref.read(supabaseDatasourceProvider);
    final user = _datasource.getCurrentUser();
    if (user != null) {
      return await _datasource.getUserById(user.id);
    }
    return null;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _datasource.signIn(email, password);
      return user;
    });
  }

  Future<void> signOut() async {
    await _datasource.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshUser() async {
    final user = _datasource.getCurrentUser();
    if (user != null) {
      state = await AsyncValue.guard(() async {
        return await _datasource.getUserById(user.id);
      });
    }
  }

  // Getters de utilidad
  bool get isAuthenticated => state.value != null;
  UserRole? get userRole =>
      state.value?.role != null ? UserRole.fromString(state.value!.role) : null;
  bool get isWorker => userRole?.isWorker ?? false;
  bool get isSupervisor => userRole?.isSupervisor ?? false;
  bool get isManager => userRole?.isManager ?? false;
}

// Provider del notifier
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
); // Provider auxiliares para acceso rápido
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((state) => state.value != null));
});

final currentUserRoleProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider.select((state) => state.value?.role));
});
