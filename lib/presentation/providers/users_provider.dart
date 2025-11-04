import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/users_repository.dart';
import '../../data/models/user_model.dart';
import 'auth_provider.dart';

// ============================================
// PROVIDERS BÁSICOS
// ============================================

/// Provider del repositorio de usuarios
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final datasource = ref.watch(supabaseDatasourceProvider);
  return UsersRepository(datasource);
});

/// Provider de la lista de supervisores activos
/// Caché de 5 minutos para reducir consultas innecesarias
final supervisorsListProvider = FutureProvider.autoDispose<List<UserModel>>((
  ref,
) async {
  // Mantener vivo por 5 minutos
  ref.keepAlive();

  final timer = Timer(const Duration(minutes: 5), () {
    ref.invalidateSelf();
  });

  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(usersRepositoryProvider);
  return repository.getSupervisors(activeOnly: true);
});

/// Provider de la lista de todos los usuarios
/// Caché de 2 minutos para balance entre frescura y performance
final allUsersListProvider = FutureProvider.autoDispose<List<UserModel>>((
  ref,
) async {
  // Mantener vivo por 2 minutos
  ref.keepAlive();

  final timer = Timer(const Duration(minutes: 2), () {
    ref.invalidateSelf();
  });

  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(usersRepositoryProvider);
  return repository.getAllUsers(activeOnly: true);
});

/// Provider de estadísticas de usuarios
/// Caché de 1 minuto para datos que cambian frecuentemente
final userStatisticsProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  // Mantener vivo por 1 minuto
  ref.keepAlive();

  final timer = Timer(const Duration(minutes: 1), () {
    ref.invalidateSelf();
  });

  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUserStatistics();
});

/// Provider para obtener un usuario por ID
/// Se usa para cargar datos al editar
final userByIdProvider = FutureProvider.family.autoDispose<UserModel, String>((
  ref,
  String userId,
) async {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUserById(userId);
});

// ============================================
// HELPERS PARA OPERACIONES
// ============================================

/// Crear nuevo usuario con cuenta de Auth
/// Usar en formularios: await ref.read(createUserProvider)(params)
final createUserProvider = Provider((ref) {
  final repository = ref.read(usersRepositoryProvider);
  final supabase = ref.read(supabaseDatasourceProvider).client;

  return ({
    required String email,
    required String fullName,
    required String password,
    required String role,
    String? phone,
    File? photoFile,
    String? supervisorId,
    bool isActive = true,
  }) async {
    try {
      // 1. Crear usuario en Supabase Auth usando signUp
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear cuenta de usuario');
      }

      // 2. Crear registro en tabla users con el mismo ID
      final userResponse = await supabase
          .from('users')
          .insert({
            'id': authResponse.user!.id,
            'email': email,
            'full_name': fullName,
            'role': role,
            'phone': phone,
            'supervisor_id': supervisorId,
            'is_active': isActive,
          })
          .select()
          .single();

      final user = UserModel.fromJson(userResponse);

      // 3. Si hay foto, subirla y actualizar
      if (photoFile != null) {
        final photoUrl = await repository.uploadProfilePhoto(
          userId: user.id,
          photoFile: photoFile,
        );

        return await repository.updateUser(user.id, {'photo_url': photoUrl});
      }

      return user;
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('El email ya está registrado');
      }
      throw Exception('Error de autenticación: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Error en base de datos: ${e.message}');
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  };
});

/// Actualizar usuario
final updateUserProvider = Provider((ref) {
  final repository = ref.read(usersRepositoryProvider);

  return ({
    required String userId,
    String? fullName,
    String? phone,
    File? newPhotoFile,
    String? supervisorId,
    bool? isActive,
  }) async {
    try {
      String? photoUrl;

      // Subir nueva foto si existe
      if (newPhotoFile != null) {
        photoUrl = await repository.uploadProfilePhoto(
          userId: userId,
          photoFile: newPhotoFile,
        );
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (supervisorId != null) updates['supervisor_id'] = supervisorId;
      if (isActive != null) updates['is_active'] = isActive;

      return await repository.updateUser(userId, updates);
    } catch (e) {
      rethrow;
    }
  };
});

/// Toggle user status
final toggleUserStatusProvider = Provider((ref) {
  final repository = ref.read(usersRepositoryProvider);

  return (String userId, bool isActive) async {
    try {
      await repository.toggleUserStatus(userId, isActive);
    } catch (e) {
      rethrow;
    }
  };
});

// ============================================
// PAGINACIÓN (Performance Optimization)
// ============================================

/// Estado de paginación para usuarios
class PaginationState {
  final List<UserModel> users;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  const PaginationState({
    required this.users,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    this.error,
  });

  factory PaginationState.initial() {
    return const PaginationState(
      users: [],
      currentPage: 0,
      hasMore: true,
      isLoading: false,
    );
  }

  PaginationState copyWith({
    List<UserModel>? users,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return PaginationState(
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier para paginación de usuarios (Riverpod 3.x compatible)
class PaginatedUsersNotifier extends Notifier<PaginationState> {
  static const _pageSize = 20;

  @override
  PaginationState build() {
    return PaginationState.initial();
  }

  /// Cargar más usuarios
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(usersRepositoryProvider);

      // Por ahora usar getAllUsers (ya implementado)
      final allUsers = await repository.getAllUsers(activeOnly: true);

      // Simular paginación del lado del cliente
      final start = state.currentPage * _pageSize;
      final end = start + _pageSize;
      final newUsers = allUsers.skip(start).take(_pageSize).toList();

      state = state.copyWith(
        users: [...state.users, ...newUsers],
        currentPage: state.currentPage + 1,
        hasMore: end < allUsers.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refrescar lista completa
  void refresh() {
    state = PaginationState.initial();
    loadMore();
  }

  /// Buscar usuarios (resetea la paginación)
  Future<void> search(String query) async {
    if (query.isEmpty) {
      refresh();
      return;
    }

    state = PaginationState.initial().copyWith(isLoading: true);

    try {
      final repository = ref.read(usersRepositoryProvider);
      final results = await repository.searchUsers(query);
      state = state.copyWith(
        users: results,
        currentPage: 1,
        hasMore: false, // No más páginas para búsqueda
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider de paginación de usuarios
final paginatedUsersProvider =
    NotifierProvider<PaginatedUsersNotifier, PaginationState>(() {
      return PaginatedUsersNotifier();
    });
