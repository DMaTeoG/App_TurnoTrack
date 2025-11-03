import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../data/models/user_model.dart';
import '../../providers/sales_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_sale_page.dart';

/// Página para listar y gestionar ventas
///
/// Features:
/// - Lista de ventas con fecha y monto
/// - Estadísticas de ventas del mes
/// - Pull to refresh
/// - FAB para agregar venta
class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ventas'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final salesAsync = ref.watch(salesListProvider(currentUser.id));
    final statisticsAsync = ref.watch(salesStatisticsProvider(currentUser.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Mis Ventas'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtros próximamente')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesListProvider(currentUser.id));
          ref.invalidate(salesStatisticsProvider(currentUser.id));
        },
        child: CustomScrollView(
          slivers: [
            // Estadísticas Header
            SliverToBoxAdapter(
              child: statisticsAsync.when(
                data: (stats) => _buildStatisticsHeader(stats),
                loading: () => const _LoadingStatistics(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Lista de ventas
            salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(context, ref, currentUser.id),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _SaleCard(sale: sales[index]),
                      childCount: sales.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'Error al cargar ventas',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        error.toString(),
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddSale(context, ref, currentUser.id),
        backgroundColor: AppTheme.warning,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
      ),
    );
  }

  Widget _buildStatisticsHeader(SalesStatistics stats) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Mes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.attach_money,
                  label: 'Total',
                  value: NumberFormat.currency(
                    locale: 'es_ES',
                    symbol: '\$',
                  ).format(stats.totalAmount),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _StatCard(
                  icon: Icons.shopping_cart,
                  label: 'Ventas',
                  value: stats.totalSales.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.inventory,
                  label: 'Unidades',
                  value: stats.totalQuantity.toString(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  label: 'Promedio',
                  value: NumberFormat.currency(
                    locale: 'es_ES',
                    symbol: '\$',
                  ).format(stats.averageSale),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 120, color: Colors.grey[300]),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            '¡No hay ventas registradas!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Comienza agregando tu primera venta',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddSale(context, ref, userId),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Venta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXL,
                vertical: AppTheme.spacingM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddSale(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final result = await Navigator.of(
      context,
    ).push(SmoothPageRoute(page: const AddSalePage()));

    if (result == true && context.mounted) {
      // Recargar lista
      ref.invalidate(salesListProvider(userId));
      ref.invalidate(salesStatisticsProvider(userId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Venta registrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// Widget para mostrar una estadística
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Card de venta individual
class _SaleCard extends StatelessWidget {
  final SalesData sale;

  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '\$');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            // TODO: Implementar detalle de venta
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Icono de categoría
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    _getCategoryIcon(sale.productCategory),
                    color: AppTheme.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                // Información de venta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.productCategory ?? 'Sin categoría',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sale.quantity} unidades',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(sale.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // Monto
                Text(
                  currencyFormat.format(sale.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'electrónica':
      case 'electronica':
        return Icons.phone_android;
      case 'ropa':
        return Icons.checkroom;
      case 'alimentos':
        return Icons.restaurant;
      case 'hogar':
        return Icons.home;
      case 'deportes':
        return Icons.sports_soccer;
      default:
        return Icons.shopping_bag;
    }
  }
}

/// Widget de carga para estadísticas
class _LoadingStatistics extends StatelessWidget {
  const _LoadingStatistics();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
