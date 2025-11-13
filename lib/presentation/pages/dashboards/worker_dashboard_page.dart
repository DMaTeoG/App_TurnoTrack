import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../providers/ai_coaching_provider.dart';
import '../../providers/analytics_provider.dart';
import '../ranking/ranking_page.dart';

/// Dashboard for Worker role - Personal stats and ranking
class WorkerDashboardPage extends ConsumerStatefulWidget {
  final UserModel user;

  const WorkerDashboardPage({super.key, required this.user});

  @override
  ConsumerState<WorkerDashboardPage> createState() =>
      _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends ConsumerState<WorkerDashboardPage> {
  @override
  Widget build(BuildContext context) {
    // Get real data from providers
    final dateRange = DateRange.currentMonth();
    final metricsAsync = ref.watch(userPerformanceMetricsProvider(dateRange));
    final aiCoachingState = ref.watch(aiCoachingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mi Desempeño'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: metricsAsync.when(
        data: (metrics) {
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh metrics data
              ref.invalidate(userPerformanceMetricsProvider(dateRange));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),

                  // Score Card with real data
                  _buildScoreCard(metrics.attendanceScore),
                  const SizedBox(height: 16),

                  // Quick Stats Row with real data
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle,
                          color: Colors.green,
                          title: 'Check-ins',
                          value: '${metrics.totalCheckIns}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.warning_amber,
                          color: Colors.orange,
                          title: 'Llegadas Tarde',
                          value: '${metrics.lateCheckIns}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ranking Card with real data from ranking provider
                  _buildRankingCardAsync(metrics.ranking ?? 0, dateRange),
                  const SizedBox(height: 16),

                  // Weekly Chart
                  _buildWeeklyChart(),
                  const SizedBox(height: 16),

                  // AI Coaching Card
                  _buildAICoachingCard(aiCoachingState),
                  const SizedBox(height: 80), // Bottom padding for FAB
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
                'Error al cargar datos',
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
                  ref.invalidate(userPerformanceMetricsProvider(dateRange));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateAIAdvice(),
        icon: const Icon(Icons.psychology),
        label: const Text('Consejos IA'),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: widget.user.photoUrl != null
                  ? NetworkImage(widget.user.photoUrl!)
                  : null,
              child: widget.user.photoUrl == null
                  ? Text(widget.user.fullName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${widget.user.fullName.split(' ').first}!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Este mes vas muy bien 💪',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _mutedTextColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(int currentScore) {
    final percentage = currentScore / 100;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Score de Asistencia',
              style: theme.textTheme.titleMedium?.copyWith(
                color: _mutedTextColor(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 12,
                      backgroundColor: _mutedTextColor(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(currentScore),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$currentScore',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/100',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _mutedTextColor(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getScoreMessage(currentScore),
              style: TextStyle(
                fontSize: 14,
                color: _getScoreColor(currentScore),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _mutedTextColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCardAsync(int ranking, DateRange dateRange) {
    final rankingParams = RankingParams(dateRange: dateRange, limit: 100);
    final rankingAsync = ref.watch(performanceRankingProvider(rankingParams));

    return rankingAsync.when(
      data: (rankings) {
        final totalWorkers = rankings.length;
        return _buildRankingInfoCard(
          title: 'Tu Posición',
          value: '#$ranking de $totalWorkers',
          trailing: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RankingPage(currentUser: widget.user),
                ),
              );
            },
            icon: const Icon(Icons.chevron_right),
          ),
        );
      },
      loading: () => Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Calculando posición...')),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[300]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al cargar ranking: $error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final theme = Theme.of(context);
    final positiveColor = AppTheme.success;
    final neutralColor = AppTheme.warning;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Última Semana',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                          return Text(
                            days[value.toInt() % 7],
                            style: theme.textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final values = [8.0, 8.2, 7.9, 8.5, 8.1, 0, 0];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index].toDouble(),
                          color: values[index] > 8.0
                              ? positiveColor
                              : neutralColor,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAICoachingCard(AICoachingState state) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Consejos de IA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.error != null)
              Text(
                state.error!,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
              )
            else if (state.advice != null)
              Text(
                state.advice!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              )
            else
              Text(
                'Toca el botón de abajo para recibir consejos personalizados basados en tu desempeño.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _mutedTextColor(),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _mutedTextColor([double opacity = 0.6]) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
    return base.withValues(alpha: opacity);
  }

  Widget _buildRankingInfoCard({
    required String title,
    required String value,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return '¡Excelente desempeño! 🌟';
    if (score >= 70) return 'Buen trabajo, sigue así 👍';
    return 'Hay oportunidad de mejorar 💪';
  }

  Future<void> _generateAIAdvice() async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando consejos con IA...'),
                SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Powered by Google Gemini',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Get real metrics from provider
    final dateRange = DateRange.currentMonth();
    final metricsAsync = ref.read(userPerformanceMetricsProvider(dateRange));

    await metricsAsync.when(
      data: (metrics) async {
        try {
          await ref
              .read(aiCoachingProvider.notifier)
              .generateAdvice(
                user: widget.user,
                metrics: metrics,
                language: 'es',
                coachingType:
                    'competitive', // Análisis competitivo para Dashboard
              );

          if (!mounted) return;

          // Cerrar loading
          Navigator.pop(context);

          // Obtener el consejo generado
          final aiState = ref.read(aiCoachingProvider);

          if (aiState.advice != null) {
            // Mostrar resultados en diálogo
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                content: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.blue.shade400],
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
                          Icon(Icons.psychology, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Consejos IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: SingleChildScrollView(
                          child: Text(
                            aiState.advice!,
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
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.purple,
                            ),
                            child: const Text('Entendido'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            throw Exception('No se generó ningún consejo');
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Cerrar loading

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al generar consejos: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      loading: () {
        if (!mounted) return;
        Navigator.pop(context);
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cargando métricas...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar métricas: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}
