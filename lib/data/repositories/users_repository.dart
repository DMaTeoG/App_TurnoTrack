import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_datasource.dart';
import '../models/user_model.dart';
import '../../core/utils/image_optimizer.dart';
import '../../domain/repositories/i_user_repository.dart';

/// Repository para gestión de usuarios (workers, supervisors, managers)
/// Compatible con RLS policies del schema consolidado
/// Implementa IUserRepository siguiendo SOLID principles
class UsersRepository implements IUserRepository {
  final SupabaseDatasource _datasource;

  UsersRepository(this._datasource);

  // ============================================
  // CREATE
  // ============================================

  /// Crear nuevo usuario (worker o supervisor)
  /// Solo supervisors y managers pueden crear workers
  /// Solo managers pueden crear supervisors
  Future<UserModel> createUser({
    required String email,
    required String fullName,
    required String role, // 'worker', 'supervisor', 'manager'
    String? phone,
    String? photoUrl,
    String? supervisorId,
    bool isActive = true,
  }) async {
    try {
      // Validar rol
      if (!['worker', 'supervisor', 'manager'].contains(role)) {
        throw Exception('Rol inválido: $role');
      }

      // Si es worker, debe tener supervisor
      if (role == 'worker' && supervisorId == null) {
        throw Exception('Workers deben tener un supervisor asignado');
      }

      final userData = {
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'photo_url': photoUrl,
        'supervisor_id': supervisorId,
        'is_active': isActive,
      };

      final response = await _datasource.client
          .from('users')
          .insert(userData)
          .select()
          .single();

      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique violation
        throw Exception('El email ya está registrado');
      } else if (e.code == '42501') {
        // Insufficient privilege
        throw Exception('No tienes permisos para crear este tipo de usuario');
      }
      throw Exception('Error al crear usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear usuario: $e');
    }
  }

  /// Crear worker (implementa IUserRepository)
  @override
  Future<UserModel> createWorker({
    required String email,
    required String fullName,
    required String supervisorId,
    String? photoUrl,
  }) async {
    return await createUser(
      email: email,
      fullName: fullName,
      role: 'worker',
      supervisorId: supervisorId,
      photoUrl: photoUrl,
    );
  }

  // ============================================
  // READ
  // ============================================

  /// Obtener usuario autenticado actual (implementa IUserRepository)
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _datasource.client.auth.currentUser;
      if (currentUser == null) return null;

      return await getUserById(currentUser.id);
    } catch (e) {
      throw Exception('Error al obtener usuario actual: $e');
    }
  }

  /// Obtener usuario por ID (implementa IUserRepository)
  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final user = await _datasource.getUserById(userId);
      if (user == null) {
        throw Exception('Usuario no encontrado');
      }
      return user;
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Listar todos los usuarios activos (solo managers)
  Future<List<UserModel>> getAllUsers({bool activeOnly = true}) async {
    try {
      final query = _datasource.client.from('users').select();

      if (activeOnly) {
        query.eq('is_active', true);
      }

      final response = await query.order('full_name', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('No tienes permisos para listar usuarios');
      }
      throw Exception('Error al listar usuarios: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Listar workers de un supervisor específico
  Future<List<UserModel>> getWorkersBySupervisor(String supervisorId) async {
    try {
      final response = await _datasource.client
          .from('users')
          .select()
          .eq('role', 'worker')
          .eq('supervisor_id', supervisorId)
          .eq('is_active', true)
          .order('full_name', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener workers del supervisor: $e');
    }
  }

  /// Listar todos los supervisores activos
  Future<List<UserModel>> getSupervisors({bool activeOnly = true}) async {
    try {
      final query = _datasource.client
          .from('users')
          .select()
          .eq('role', 'supervisor');

      if (activeOnly) {
        query.eq('is_active', true);
      }

      final response = await query.order('full_name', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener supervisores: $e');
    }
  }

  /// Buscar usuarios por nombre o email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _datasource.client
          .from('users')
          .select()
          .or('full_name.ilike.%$query%,email.ilike.%$query%')
          .eq('is_active', true)
          .order('full_name', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }

  // ============================================
  // UPDATE
  // ============================================

  /// Actualizar información de usuario (implementa IUserRepository)
  @override
  Future<UserModel> updateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (updates.isEmpty) {
        throw Exception('No hay datos para actualizar');
      }

      final response = await _datasource.client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('No tienes permisos para actualizar este usuario');
      }
      throw Exception('Error al actualizar usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar: $e');
    }
  }

  /// Activar/desactivar usuario
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await updateUser(userId, {'is_active': isActive});
    } catch (e) {
      throw Exception('Error al cambiar estado del usuario: $e');
    }
  }

  /// Desactivar usuario (implementa IUserRepository)
  @override
  Future<void> deactivateUser(String userId) async {
    await toggleUserStatus(userId, false);
  }

  // ============================================
  // STORAGE (Fotos de perfil)
  // ============================================

  /// Subir foto de perfil a Supabase Storage con optimización automática
  ///
  /// Optimiza la imagen antes de subirla:
  /// - Comprime a 800x800px
  /// - Calidad JPEG 85%
  /// - Límite máximo 2MB
  /// - Formato: profile-photos/{userId}/{timestamp}.jpg
  Future<String> uploadProfilePhoto({
    required String userId,
    required File photoFile,
  }) async {
    try {
      // 1. OPTIMIZAR IMAGEN antes de subir (Performance Optimization)
      File fileToUpload;
      try {
        fileToUpload = await ImageOptimizer.compressAndValidate(
          photoFile,
          maxWidth: 800,
          maxHeight: 800,
          quality: 85,
          maxSizeKB: 2048,
        );
      } on ImageTooLargeException catch (e) {
        throw Exception(
          'La imagen es demasiado grande: ${e.currentSizeKB.toStringAsFixed(0)}KB. '
          'Máximo permitido: ${e.maxSizeKB.toStringAsFixed(0)}KB',
        );
      } catch (e) {
        throw Exception('Error optimizando imagen: $e');
      }

      // 2. Subir imagen optimizada
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = await _datasource.uploadPhoto(
        'profile-photos',
        fileName,
        fileToUpload,
      );

      return path;
    } on StorageException catch (e) {
      if (e.statusCode == '401') {
        throw Exception('No estás autenticado para subir fotos');
      } else if (e.statusCode == '403') {
        throw Exception('No tienes permisos para subir fotos');
      }
      throw Exception('Error al subir foto: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al subir foto: $e');
    }
  }

  /// Eliminar foto de perfil del storage
  Future<void> deleteProfilePhoto(String photoUrl) async {
    try {
      // Extraer path del URL público
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments
          .sublist(pathSegments.indexOf('profile-photos') + 1)
          .join('/');

      await _datasource.client.storage.from('profile-photos').remove([
        fileName,
      ]);
    } catch (e) {
      throw Exception('Error al eliminar foto: $e');
    }
  }

  // ============================================
  // DELETE (Soft delete)
  // ============================================

  // ============================================
  // STATISTICS
  // ============================================

  /// Obtener estadísticas de usuarios
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final allUsers = await getAllUsers(activeOnly: false);

      final active = allUsers.where((u) => u.isActive).length;
      final inactive = allUsers.where((u) => !u.isActive).length;
      final workers = allUsers
          .where((u) => u.role == 'worker' && u.isActive)
          .length;
      final supervisors = allUsers
          .where((u) => u.role == 'supervisor' && u.isActive)
          .length;

      return {
        'total': allUsers.length,
        'active': active,
        'inactive': inactive,
        'workers': workers,
        'supervisors': supervisors,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
