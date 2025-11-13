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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Ventas'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
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
                data: (stats) => _buildStatisticsHeader(context, stats),
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

  Widget _buildStatisticsHeader(BuildContext context, SalesStatistics stats) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final gradientStart = theme.colorScheme.primary;
    final gradientEnd = theme.colorScheme.primary.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.85 : 0.9,
    );

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del Mes',
            style: theme.textTheme.titleLarge?.copyWith(
              color: onPrimary,
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
    final theme = Theme.of(context);
    final iconColor = _mutedTextColor(context, 0.3);
    final titleColor = theme.textTheme.titleMedium?.color ?? Colors.white;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 120, color: iconColor),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            '¡No hay ventas registradas!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Comienza agregando tu primera venta',
            style: TextStyle(fontSize: 16, color: _mutedTextColor(context)),
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
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onPrimary, size: 24),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            label,
            style: TextStyle(color: onPrimary.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: onPrimary,
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
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.4 : 0.15,
    );
    final muted = _mutedTextColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            // Mostrar detalle de venta
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(sale.productCategory),
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 8),
                    const Text('Detalle de Venta'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      context,
                      'Categoría',
                      sale.productCategory ?? 'Sin categoría',
                    ),
                    _buildDetailRow(context, 'Fecha', dateFormat.format(sale.date)),
                    _buildDetailRow(context, 'Cantidad', '${sale.quantity} unidades'),
                    _buildDetailRow(
                      context,
                      'Monto',
                      currencyFormat.format(sale.amount),
                    ),
                    _buildDetailRow(
                      context,
                      'Precio unitario',
                      currencyFormat.format(sale.amount / sale.quantity),
                    ),
                    const Divider(),
                    Text(
                      'ID: ${sale.id}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
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
                    color: AppTheme.warning.withValues(alpha: 0.15),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sale.quantity} unidades',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(sale.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _mutedTextColor(context, 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Monto
                Text(
                  currencyFormat.format(sale.amount),
                  style: theme.textTheme.titleLarge?.copyWith(
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _mutedTextColor(context, 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}

Color _mutedTextColor(BuildContext context, [double opacity = 0.6]) {
  final theme = Theme.of(context);
  final base = theme.textTheme.bodyMedium?.color ??
      (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
  return base.withValues(alpha: opacity);
}
