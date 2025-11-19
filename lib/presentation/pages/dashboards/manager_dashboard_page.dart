import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/user_model.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/ai_coaching_provider.dart';

/// Dashboard for Manager role - Organization-wide KPIs and insights
class ManagerDashboardPage extends ConsumerStatefulWidget {
  final UserModel user;

  const ManagerDashboardPage({super.key, required this.user});

  @override
  ConsumerState<ManagerDashboardPage> createState() =>
      _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends ConsumerState<ManagerDashboardPage> {
  String _selectedPeriod = 'Mes';

  @override
  Widget build(BuildContext context) {
    // Get real data from provider
    final dateRange = DateRange.currentMonth();
    final kpisAsync = ref.watch(organizationKPIsProvider(dateRange));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Panel Gerencial'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt),
            tooltip: 'Asistencia del Equipo',
            onPressed: () {
              Navigator.pushNamed(context, '/team-attendance');
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              Navigator.pushNamed(context, '/reports');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: kpisAsync.when(
        data: (kpis) {
          // Extract KPIs from map with safe defaults
          final totalEmployees = kpis['total_employees'] as int? ?? 0;
          final activeToday = kpis['active_today'] as int? ?? 0;
          final orgAvgScore =
              (kpis['average_score'] as num?)?.toDouble() ?? 0.0;
          final totalCheckInsToday = kpis['total_check_ins'] as int? ?? 0;
          final lateToday = kpis['late_today'] as int? ?? 0;
          final supervisors = kpis['supervisors'] as int? ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(organizationKPIsProvider(dateRange));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),

                  // KPI Cards Grid with real data
                  _buildKPIGrid(
                    totalEmployees,
                    activeToday,
                    orgAvgScore,
                    lateToday,
                    totalCheckInsToday,
                    supervisors,
                  ),
                  const SizedBox(height: 16),

                  // Attendance Trend Chart
                  _buildAttendanceTrendChart(),
                  const SizedBox(height: 16),

                  // Performance Distribution
                  _buildPerformanceDistribution(),
                  const SizedBox(height: 16),

                  // Supervisors Performance
                  _buildSupervisorsSection(),
                  const SizedBox(height: 16),

                  // Department Comparison
                  _buildTopSupervisorsList(),
                  const SizedBox(height: 16),

                  // Critical Alerts
                  _buildCriticalAlerts(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error al cargar KPIs',
                style: TextStyle(fontSize: 18, color: _mutedTextColor()),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: _mutedTextColor(0.6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(organizationKPIsProvider(dateRange));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón para crear usuarios
          FloatingActionButton(
            heroTag: 'createUser',
            onPressed: () {
              Navigator.pushNamed(context, '/users');
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 12),
          // Botón de predicciones IA
          FloatingActionButton.extended(
            heroTag: 'predictions',
            onPressed: () => _generateAttendancePredictions(),
            icon: const Icon(Icons.psychology),
            label: const Text('IA'),
            backgroundColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outlineColor = colorScheme.outlineVariant.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.4 : 0.2,
    );
    final unselectedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        Colors.grey.shade700;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['Semana', 'Mes', 'Trimestre', 'Año'].map((period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = period),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : outlineColor,
                    ),
                  ),
                  child: Text(
                    period,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : unselectedColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(
    int totalEmployees,
    int activeToday,
    double orgAvgScore,
    int lateToday,
    int totalCheckInsToday,
    int supervisors,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildKPICard(
          title: 'Empleados Totales',
          value: '$totalEmployees',
          subtitle: '$supervisors supervisores',
          icon: Icons.people,
          color: Colors.blue,
          trend: '+5%',
          trendUp: true,
        ),
        _buildKPICard(
          title: 'Activos Hoy',
          value: '$activeToday',
          subtitle: totalEmployees > 0
              ? '${((activeToday / totalEmployees) * 100).toStringAsFixed(1)}% asistencia'
              : '0% asistencia',
          icon: Icons.check_circle,
          color: Colors.green,
          trend: '+2%',
          trendUp: true,
        ),
        _buildKPICard(
          title: 'Score Promedio',
          value: orgAvgScore.toStringAsFixed(1),
          subtitle: 'Organización completa',
          icon: Icons.star,
          color: Colors.amber,
          trend: '+1.5',
          trendUp: true,
        ),
        _buildKPICard(
          title: 'Llegadas Tarde',
          value: '$lateToday',
          subtitle: totalCheckInsToday > 0
              ? '${((lateToday / totalCheckInsToday) * 100).toStringAsFixed(1)}% del total'
              : '0% del total',
          icon: Icons.access_time,
          color: Colors.orange,
          trend: '-3%',
          trendUp: true,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
  }) {
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;
    final tertiaryText =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
        Colors.grey.shade500;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono y trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (trendUp ? Colors.green : Colors.red).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 11,
                          color: trendUp ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Valor principal
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Título
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: secondaryText,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: tertiaryText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildAttendanceTrendChart() {
  final trendAsync = ref.watch(attendanceTrendProvider);

  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tendencia de Asistencia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              trendAsync.when(
                data: (trends) {
                  if (trends.isEmpty) return const SizedBox.shrink();
                  final lastTwo = trends.length >= 2
                      ? trends.sublist(trends.length - 2)
                      : trends;
                  final isPositive =
                      lastTwo.length == 2 &&
                      lastTwo.last.punctualityRate >
                          lastTwo.first.punctualityRate;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPositive
                          ? '↑ Tendencia positiva'
                          : '↓ Tendencia negativa',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: trendAsync.when(
              data: (trends) {
                if (trends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: _mutedTextColor(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay datos de tendencia disponibles',
                          style: TextStyle(
                            color: _mutedTextColor(),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final months = [
                  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
                ];

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: _surfaceStrokeColor(),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < trends.length) {
                              final month = trends[value.toInt()].month;
                              return Text(
                                months[month.month - 1],
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Asistencia
                      LineChartBarData(
                        spots: trends
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.attendanceRate,
                                ))
                            .toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                      // Puntualidad
                      LineChartBarData(
                        spots: trends
                            .asMap()
                            .entries
                            .map((e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.punctualityRate,
                                ))
                            .toList(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 100,
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar tendencia',
                      style: TextStyle(
                        color: _mutedTextColor(),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Asistencia', Colors.blue),
              const SizedBox(width: 20),
              _buildLegendItem('Puntualidad', Colors.green),
            ],
          ),
        ],
      ),
    ),
  );
}


  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: _mutedTextColor())),
      ],
    );
  }


Widget _buildPerformanceDistribution() {
  final distributionAsync = ref.watch(performanceDistributionProvider);

  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de Desempeño',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: distributionAsync.when(
              data: (distribution) {
                if (distribution.total == 0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart_outline,
                          size: 48,
                          color: _mutedTextColor(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay datos de desempeño disponibles',
                          style: TextStyle(
                            color: _mutedTextColor(),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(
                                value: distribution.excellent.toDouble(),
                                title: '${distribution.excellent}',
                                color: Colors.green,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: distribution.good.toDouble(),
                                title: '${distribution.good}',
                                color: Colors.amber,
                                radius: 55,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: distribution.needsImprovement.toDouble(),
                                title: '${distribution.needsImprovement}',
                                color: Colors.orange,
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPerformanceLabel(
                            'Excelente (90-100)',
                            Colors.green,
                            distribution.excellent,
                          ),
                          const SizedBox(height: 12),
                          _buildPerformanceLabel(
                            'Bueno (70-89)',
                            Colors.amber,
                            distribution.good,
                          ),
                          const SizedBox(height: 12),
                          _buildPerformanceLabel(
                            'Mejorar (<70)',
                            Colors.orange,
                            distribution.needsImprovement,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar distribución',
                      style: TextStyle(
                        color: _mutedTextColor(),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  
  
  Widget _buildPerformanceLabel(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$value empleados',
              style: TextStyle(fontSize: 11, color: _mutedTextColor()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupervisorsSection() {
    final supervisorsAsync = ref.watch(supervisorsPerformanceProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rendimiento por Supervisor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/users');
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            supervisorsAsync.when(
              data: (supervisors) {
                if (supervisors.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: _mutedTextColor(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay supervisores registrados',
                            style: TextStyle(
                              color: _mutedTextColor(),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: supervisors.map((supervisor) {
                    final hasTeam = supervisor.teamSize > 0;
                    final scoreText = hasTeam
                        ? supervisor.avgScore.toStringAsFixed(1)
                        : 'N/A';
                    final scoreColor = hasTeam ? Colors.green : Colors.grey;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hasTeam ? Colors.blue : Colors.grey,
                          child: Text(
                            supervisor.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(supervisor.name),
                        subtitle: Text(
                          hasTeam
                              ? '${supervisor.teamSize} personas en equipo'
                              : 'Sin equipo asignado',
                          style: TextStyle(
                            color: hasTeam ? null : _mutedTextColor(),
                            fontStyle: hasTeam ? null : FontStyle.italic,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            scoreText,
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar supervisores',
                        style: TextStyle(
                          color: _mutedTextColor(),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSupervisorsList() {
    final departmentsAsync = ref.watch(departmentComparisonProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativa por Área',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            departmentsAsync.when(
              data: (departments) {
                if (departments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 48,
                            color: _mutedTextColor(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay datos de áreas disponibles',
                            style: TextStyle(
                              color: _mutedTextColor(),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final colors = [
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.pink,
                ];

                return Column(
                  children: departments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dept = entry.value;
                    return _buildDepartmentBar(
                      dept.department,
                      dept.score,
                      colors[index % colors.length],
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar comparativa',
                        style: TextStyle(
                          color: _mutedTextColor(),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentBar(String department, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                department,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: _surfaceStrokeColor(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlerts() {
    final alertsAsync = ref.watch(criticalAlertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.green[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay alertas críticas',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¡Todo está funcionando correctamente!',
                    style: TextStyle(color: _mutedTextColor(), fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Alertas Críticas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...alerts.map((alert) {
                  final color = alert.severity == AlertSeverity.high
                      ? Colors.red
                      : Colors.orange;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: color.withValues(alpha: 0.05),
                    child: ListTile(
                      leading: Icon(Icons.warning, color: color),
                      title: Text(alert.title),
                      subtitle: Text(alert.description),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(alert.title),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert.description),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tipo: ${alert.severity.name}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
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
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Verificando alertas...',
                style: TextStyle(color: _mutedTextColor(), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                'Error al cargar alertas',
                style: TextStyle(color: _mutedTextColor(), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAttendancePredictions() async {
    // Mostrar loading directamente (sin confirmación doble)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Generando análisis estratégico...'),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Powered by Google Gemini',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Obtener KPIs organizacionales
      final dateRange = DateRange.lastWeek();
      final kpis = await ref.read(organizationKPIsProvider(dateRange).future);

      // Llamar a Gemini con análisis estratégico para Manager
      final insights = await ref
          .read(aiCoachingProvider.notifier)
          .generateManagerInsights(organizationKPIs: kpis, language: 'es');

      if (!mounted) return;

      // Cerrar loading
      Navigator.pop(context);

      if (insights != null) {
        // Mostrar resultados en diálogo ejecutivo
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.indigo.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.business_center,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Análisis Estratégico',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'C-Level Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      child: Text(
                        insights,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Entendido'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        throw Exception('No se generó ningún análisis');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar análisis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _mutedTextColor([double opacity = 0.6]) {
    final theme = Theme.of(context);
    final base =
        theme.textTheme.bodyMedium?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
    final double alpha = opacity.clamp(0.0, 1.0).toDouble();
    return base.withValues(alpha: alpha);
  }

  Color _surfaceStrokeColor([double opacity = 0.12]) {
    final theme = Theme.of(context);
    return theme.colorScheme.onSurface.withValues(alpha: opacity);
  }
}
