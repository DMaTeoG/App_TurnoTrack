import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/export_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';

/// Pantalla de generación de reportes con exportación CSV
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? _dateRange;
  String _reportType = 'attendance';
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<ExportState>(exportNotifierProvider, (previous, next) {
      if (next is ExportSuccess) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.green),
        );
      } else if (next is ExportError) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generar Reporte',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            _buildReportTypeSelector(theme),
            const SizedBox(height: 24),

            _buildDateRangeSelector(theme),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download),
                label: Text(
                  _isGenerating ? 'Generando...' : 'Generar Reporte CSV',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo de Reporte', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            // Usar SegmentedButton (Material 3) en lugar de Radio deprecado
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'attendance',
                  label: Text('Asistencias'),
                  icon: Icon(Icons.access_time),
                ),
                ButtonSegment(
                  value: 'performance',
                  label: Text('Métricas'),
                  icon: Icon(Icons.analytics),
                ),
              ],
              selected: {_reportType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _reportType = newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(ThemeData theme) {
    return Card(
      child: InkWell(
        onTap: _selectDateRange,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _dateRange == null
                      ? 'Seleccionar fechas'
                      : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _generateReport() async {
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un rango de fechas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      if (_reportType == 'attendance') {
        // Obtener asistencias usando el provider existente
        final attendances = await ref
            .read(attendanceRepositoryProvider)
            .getAttendanceByUser(
              userId: ref.read(authNotifierProvider).value!.id,
              startDate: _dateRange!.start,
              endDate: _dateRange!.end,
            );
        await ref
            .read(exportNotifierProvider.notifier)
            .exportAttendance(attendances);
      } else {
        // Obtener métricas usando el provider existente
        final dateRange = DateRange(
          startDate: _dateRange!.start,
          endDate: _dateRange!.end,
        );
        final metrics = await ref.read(
          userPerformanceMetricsProvider(dateRange).future,
        );
        await ref.read(exportNotifierProvider.notifier).exportPerformance([
          metrics,
        ]);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
