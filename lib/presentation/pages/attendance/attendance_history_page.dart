import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../providers/attendance_provider.dart';

/// Página para visualizar el historial de asistencias
///
/// Características:
/// - Lista de asistencias con filtros por fecha
/// - Vista de mapa con ubicación de check-in/check-out
/// - Fotos de cada registro
/// - Estadísticas: puntualidad, horas trabajadas, etc.
class AttendanceHistoryPage extends ConsumerStatefulWidget {
  const AttendanceHistoryPage({super.key, this.userId});

  /// ID del usuario a consultar (null = usuario actual)
  final String? userId;

  @override
  ConsumerState<AttendanceHistoryPage> createState() =>
      _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showAttendanceDetails(AttendanceModel attendance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _buildAttendanceDetailSheet(attendance, scrollController);
        },
      ),
    );
  }

  Widget _buildAttendanceDetailSheet(
    AttendanceModel attendance,
    ScrollController scrollController,
  ) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detalle de Asistencia',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fecha
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Fecha'),
            subtitle: Text(dateFormat.format(attendance.checkInTime)),
          ),

          // Check-in
          ListTile(
            leading: Icon(
              Icons.login,
              color: attendance.isLate ? Colors.red : Colors.green,
            ),
            title: const Text('Entrada'),
            subtitle: Text(timeFormat.format(attendance.checkInTime)),
            trailing: attendance.isLate
                ? Chip(
                    label: Text('${attendance.minutesLate} min tarde'),
                    backgroundColor: Colors.red.shade100,
                  )
                : const Chip(
                    label: Text('A tiempo'),
                    backgroundColor: Colors.green,
                  ),
          ),

          // Check-out
          if (attendance.checkOutTime != null)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Salida'),
              subtitle: Text(timeFormat.format(attendance.checkOutTime!)),
              trailing: Text(
                _calculateDuration(
                  attendance.checkInTime,
                  attendance.checkOutTime!,
                ),
              ),
            ),

          const Divider(height: 32),

          // Mapa Check-in
          Text(
            'Ubicación de Entrada',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    attendance.checkInLatitude,
                    attendance.checkInLongitude,
                  ),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.turnotrack.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          attendance.checkInLatitude,
                          attendance.checkInLongitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (attendance.checkInAddress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                attendance.checkInAddress!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

          const SizedBox(height: 16),

          // Foto Check-in
          Text(
            'Foto de Entrada',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              attendance.checkInPhotoUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.error, size: 50)),
                );
              },
            ),
          ),

          // Check-out Map y Photo (si existen)
          if (attendance.checkOutTime != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Text(
              'Ubicación de Salida',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (attendance.checkOutLatitude != null &&
                attendance.checkOutLongitude != null)
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        attendance.checkOutLatitude!,
                        attendance.checkOutLongitude!,
                      ),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.turnotrack.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              attendance.checkOutLatitude!,
                              attendance.checkOutLongitude!,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.orange,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (attendance.checkOutAddress != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  attendance.checkOutAddress!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            if (attendance.checkOutPhotoUrl != null) ...[
              const SizedBox(height: 16),
              Text(
                'Foto de Salida',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  attendance.checkOutPhotoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.error, size: 50)),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final attendancesAsync = ref.watch(
      userAttendanceHistoryProvider(
        AttendanceHistoryParams(
          userId: widget.userId,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Asistencias'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _selectDateRange,
            tooltip: 'Filtrar por fecha',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryBlue.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Del ${DateFormat('dd/MM/yyyy').format(_startDate)} al ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: const Text('Cambiar'),
                ),
              ],
            ),
          ),

          // Lista de asistencias
          Expanded(
            child: attendancesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 50, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
              data: (attendances) {
                if (attendances.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay registros en este período',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _selectDateRange,
                          child: const Text('Seleccionar otro período'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attendances.length,
                  itemBuilder: (context, index) {
                    final attendance = attendances[index];
                    return _buildAttendanceCard(attendance);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    final dateFormat = DateFormat('EEE, d MMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAttendanceDetails(attendance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto miniatura
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  attendance.checkInPhotoUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(attendance.checkInTime),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.login,
                          size: 16,
                          color: attendance.isLate ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeFormat.format(attendance.checkInTime),
                          style: TextStyle(
                            color: attendance.isLate
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        if (attendance.isLate) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${attendance.minutesLate} min)',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                    if (attendance.checkOutTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormat.format(attendance.checkOutTime!),
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Indicador
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
