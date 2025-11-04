import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/user_model.dart';
import '../../providers/analytics_provider.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Panel Gerencial'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
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
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                    color: isSelected ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    period,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
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
      childAspectRatio: 1.4,
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tendencia de Asistencia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay datos de tendencia disponibles',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final months = [
                    'Ene',
                    'Feb',
                    'Mar',
                    'Abr',
                    'May',
                    'Jun',
                    'Jul',
                    'Ago',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dic',
                  ];

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
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
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.attendanceRate,
                                ),
                              )
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
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.punctualityRate,
                                ),
                              )
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
                loading: () => const Center(child: CircularProgressIndicator()),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay datos de desempeño disponibles',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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
                        'Error al cargar distribución',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay supervisores registrados',
                            style: TextStyle(
                              color: Colors.grey[600],
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey[50],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            supervisor.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(supervisor.name),
                        subtitle: Text(
                          '${supervisor.teamSize} personas en equipo',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            supervisor.avgScore.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.green,
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay datos de áreas disponibles',
                            style: TextStyle(
                              color: Colors.grey[600],
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
              backgroundColor: Colors.grey[200],
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generate attendance predictions using AI
  String _generatePredictionFromKPIs({
    required int totalCheckIns,
    required int lateCheckIns,
    required double punctualityRate,
    required double avgScore,
  }) {
    final StringBuffer prediction = StringBuffer();

    prediction.writeln('📊 **Análisis de Asistencia**\n');

    // Análisis de puntualidad
    if (punctualityRate >= 90) {
      prediction.writeln(
        '✅ **Excelente puntualidad** (${punctualityRate.toStringAsFixed(1)}%)',
      );
      prediction.writeln('El equipo mantiene un alto nivel de puntualidad.\n');
    } else if (punctualityRate >= 70) {
      prediction.writeln(
        '⚠️ **Puntualidad aceptable** (${punctualityRate.toStringAsFixed(1)}%)',
      );
      prediction.writeln(
        'Hay margen de mejora. Considera recordatorios automáticos.\n',
      );
    } else {
      prediction.writeln(
        '🚨 **Alerta de puntualidad** (${punctualityRate.toStringAsFixed(1)}%)',
      );
      prediction.writeln(
        'Requiere atención inmediata. Revisa políticas y comunicación.\n',
      );
    }

    // Análisis de llegadas tardías
    final latePercentage = totalCheckIns > 0
        ? (lateCheckIns / totalCheckIns * 100)
        : 0.0;
    if (latePercentage > 20) {
      prediction.writeln(
        '📉 **Alto índice de retrasos** (${latePercentage.toStringAsFixed(1)}%)',
      );
      prediction.writeln(
        'Sugerencia: Analizar causas comunes (transporte, horarios).\n',
      );
    } else if (latePercentage > 10) {
      prediction.writeln(
        '📊 Retrasos moderados (${latePercentage.toStringAsFixed(1)}%)',
      );
      prediction.writeln('Monitorear tendencia en próximas semanas.\n');
    }

    // Análisis de desempeño general
    if (avgScore >= 4.0) {
      prediction.writeln(
        '⭐ **Desempeño sobresaliente** (${avgScore.toStringAsFixed(1)}/5.0)',
      );
    } else if (avgScore >= 3.0) {
      prediction.writeln(
        '✔️ Desempeño adecuado (${avgScore.toStringAsFixed(1)}/5.0)',
      );
    } else if (avgScore > 0) {
      prediction.writeln(
        '⚠️ Desempeño bajo (${avgScore.toStringAsFixed(1)}/5.0)',
      );
      prediction.writeln('Considera planes de mejora individualizados.');
    }

    // Recomendaciones generales
    prediction.writeln('\n💡 **Recomendaciones:**');
    if (punctualityRate < 85) {
      prediction.writeln(
        '• Implementar sistema de notificaciones previas al turno',
      );
    }
    if (latePercentage > 15) {
      prediction.writeln(
        '• Revisar y ajustar horarios según necesidades del equipo',
      );
    }
    prediction.writeln('• Mantener comunicación constante con supervisores');
    prediction.writeln(
      '• Reconocer y recompensar buenos hábitos de asistencia',
    );

    return prediction.toString();
  }

  Future<void> _generateAttendancePredictions() async {
    // Show loading dialog immediately
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando predicciones con IA...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Obtener KPIs para generar predicción basada en datos reales
      final dateRange = DateRange.lastWeek();
      final kpis = await ref.read(organizationKPIsProvider(dateRange).future);

      final totalCheckIns = kpis['total_check_ins'] as int? ?? 0;
      final lateCheckIns = kpis['late_check_ins'] as int? ?? 0;
      final punctualityRate =
          (kpis['punctuality_rate'] as num?)?.toDouble() ?? 0.0;
      final avgScore =
          (kpis['avg_attendance_score'] as num?)?.toDouble() ?? 0.0;

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Generar predicción simple basada en los KPIs
      final prediction = _generatePredictionFromKPIs(
        totalCheckIns: totalCheckIns,
        lateCheckIns: lateCheckIns,
        punctualityRate: punctualityRate,
        avgScore: avgScore,
      );

      // Show predictions dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple),
              SizedBox(width: 8),
              Text('Predicciones IA'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Análisis basado en datos de la última semana',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Mostrar error detallado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error Detallado'),
                  content: SingleChildScrollView(child: Text(e.toString())),
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
    }
  }
}
