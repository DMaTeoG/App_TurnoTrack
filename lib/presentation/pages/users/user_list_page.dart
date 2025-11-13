import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../providers/users_provider.dart';
import 'create_user_page.dart';

/// Página para listar y gestionar usuarios con scroll infinito
///
/// Features:
/// - Lista de workers con avatar
/// - Scroll infinito con paginación
/// - Pull to refresh
/// - Búsqueda con debounce
/// - Estado activo/inactivo visual
/// - Navegación a crear/editar
class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Cargar primera página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedUsersProvider.notifier).loadMore();
    });

    // Listener para scroll infinito
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      ref.read(paginatedUsersProvider.notifier).loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9); // Cargar al llegar al 90%
  }

  void _navigateToCreateUser() async {
    final result = await Navigator.of(
      context,
    ).push(SmoothPageRoute(page: const CreateUserPage()));

    if (result == true && mounted) {
      // Refrescar lista de usuarios
      ref.read(paginatedUsersProvider.notifier).refresh();
      ref.invalidate(userStatisticsProvider);

      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Usuario creado exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginationState = ref.watch(paginatedUsersProvider);
    final statistics = ref.watch(userStatisticsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onPrimary = colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(paginatedUsersProvider.notifier).refresh();
          ref.invalidate(userStatisticsProvider);
        },
        child: Column(
          children: [
            // Header con búsqueda
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.3 : 0.1,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Barra de búsqueda
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                      if (value.isEmpty) {
                        ref.read(paginatedUsersProvider.notifier).refresh();
                      } else {
                        ref.read(paginatedUsersProvider.notifier).search(value);
                      }
                    },
                    style: TextStyle(color: onPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o documento...',
                      hintStyle: TextStyle(
                        color: onPrimary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: onPrimary.withValues(alpha: 0.8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: onPrimary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: onPrimary.withValues(alpha: 0.12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingM),

                  // Estadísticas rápidas
                  statistics.when(
                    data: (stats) => Row(
                      children: [
                        _buildStatCard(context, 
                          'Total',
                          '${stats['total'] ?? 0}',
                          Icons.people,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        _buildStatCard(context, 
                          'Activos',
                          '${stats['active'] ?? 0}',
                          Icons.check_circle,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        _buildStatCard(context, 
                          'Inactivos',
                          '${stats['inactive'] ?? 0}',
                          Icons.cancel,
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (_, __) => Row(
                      children: [
                        _buildStatCard(context, 'Total', '-', Icons.people),
                        const SizedBox(width: AppTheme.spacingS),
                        _buildStatCard(context, 'Activos', '-', Icons.check_circle),
                        const SizedBox(width: AppTheme.spacingS),
                        _buildStatCard(context, 'Inactivos', '-', Icons.cancel),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de usuarios con paginación
            Expanded(
              child: paginationState.isLoading && paginationState.users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : paginationState.error != null &&
                        paginationState.users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: _mutedTextColor(context, 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${paginationState.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _mutedTextColor(context)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(paginatedUsersProvider.notifier)
                                  .refresh();
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      itemCount: paginationState.users.length + 1,
                      itemBuilder: (context, index) {
                        // Mostrar indicador de carga al final
                        if (index >= paginationState.users.length) {
                          return paginationState.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final user = paginationState.users[index];

                        return AnimatedListItem(
                          index: index,
                          child: _buildUserCardFromModel(user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedFAB(
        icon: Icons.person_add,
        label: 'Nuevo Usuario',
        onPressed: _navigateToCreateUser,
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onPrimary;
    final subtitleColor = textColor.withValues(alpha: 0.75);
    final cardColor = textColor.withValues(alpha: 0.15);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCardFromModel(dynamic user) {
    final isActive = user.isActive;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardColor;
    final iconColor = _mutedTextColor(context, 0.7);
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = colorScheme.outlineVariant.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.12,
    );
    final statusColor =
        isActive ? AppTheme.success : _mutedTextColor(context, 0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.accentBlue,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          user.fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.email,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (user.phone != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    user.phone!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  user.role.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () async {
          // Navegar a editar y esperar resultado
          final result = await Navigator.of(
            context,
          ).push(SmoothPageRoute(page: CreateUserPage(userId: user.id)));

          // Si se editó exitosamente, refrescar lista
          if (result == true && mounted) {
            ref.read(paginatedUsersProvider.notifier).refresh();
            ref.invalidate(userStatisticsProvider);
          }
        },
      ),
    );
  }

  Color _mutedTextColor(BuildContext context, [double opacity = 0.6]) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
    return base.withValues(alpha: opacity);
  }
}
