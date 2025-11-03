import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import 'auth_provider.dart';

// ============================================
// PROVIDERS BÁSICOS
// ============================================

/// Provider de lista de ventas por usuario
/// Caché de 2 minutos
final salesListProvider = FutureProvider.family
    .autoDispose<List<SalesData>, String>((ref, userId) async {
      // Mantener vivo por 2 minutos
      ref.keepAlive();

      final timer = Timer(const Duration(minutes: 2), () {
        ref.invalidateSelf();
      });

      ref.onDispose(() => timer.cancel());

      final datasource = ref.watch(supabaseDatasourceProvider);
      return datasource.getSalesByUser(
        userId,
        DateTime.now().subtract(const Duration(days: 90)), // Últimos 3 meses
        DateTime.now(),
      );
    });

/// Provider de estadísticas de ventas
final salesStatisticsProvider = FutureProvider.family
    .autoDispose<SalesStatistics, String>((ref, userId) async {
      final sales = await ref.watch(salesListProvider(userId).future);
      return SalesStatistics.fromSales(sales);
    });

/// Modelo de estadísticas de ventas
class SalesStatistics {
  final double totalAmount;
  final int totalQuantity;
  final int totalSales;
  final double averageSale;
  final DateTime? lastSaleDate;
  final Map<String, int> categoryCounts;

  const SalesStatistics({
    required this.totalAmount,
    required this.totalQuantity,
    required this.totalSales,
    required this.averageSale,
    this.lastSaleDate,
    this.categoryCounts = const {},
  });

  factory SalesStatistics.fromSales(List<SalesData> sales) {
    if (sales.isEmpty) {
      return const SalesStatistics(
        totalAmount: 0,
        totalQuantity: 0,
        totalSales: 0,
        averageSale: 0,
      );
    }

    final totalAmount = sales.fold<double>(0, (sum, sale) => sum + sale.amount);
    final totalQuantity = sales.fold<int>(
      0,
      (sum, sale) => sum + sale.quantity,
    );
    final categoryCounts = <String, int>{};

    for (final sale in sales) {
      if (sale.productCategory != null) {
        categoryCounts[sale.productCategory!] =
            (categoryCounts[sale.productCategory!] ?? 0) + 1;
      }
    }

    sales.sort((a, b) => b.date.compareTo(a.date));

    return SalesStatistics(
      totalAmount: totalAmount,
      totalQuantity: totalQuantity,
      totalSales: sales.length,
      averageSale: totalAmount / sales.length,
      lastSaleDate: sales.first.date,
      categoryCounts: categoryCounts,
    );
  }
}
