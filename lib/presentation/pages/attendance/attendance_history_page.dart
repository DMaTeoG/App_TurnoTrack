import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

          // ===== ENTRADA (CHECK-IN) =====
          _buildSectionTitle('📍 Entrada', Colors.green),
          const SizedBox(height: 12),

          // Foto Check-in
          _buildPhotoCard(
            photoUrl: attendance.checkInPhotoUrl,
            time: timeFormat.format(attendance.checkInTime),
            label: 'Foto de entrada',
          ),
          const SizedBox(height: 12),

          // Mapa y Coordenadas Check-in
          _buildLocationCard(
            latitude: attendance.checkInLatitude,
            longitude: attendance.checkInLongitude,
            address: attendance.checkInAddress,
            color: Colors.green,
          ),

          // ===== SALIDA (CHECK-OUT) =====
          if (attendance.checkOutTime != null) ...[
            const Divider(height: 32),
            _buildSectionTitle('📍 Salida', Colors.orange),
            const SizedBox(height: 12),

            // Foto Check-out
            if (attendance.checkOutPhotoUrl != null)
              _buildPhotoCard(
                photoUrl: attendance.checkOutPhotoUrl!,
                time: timeFormat.format(attendance.checkOutTime!),
                label: 'Foto de salida',
              ),
            const SizedBox(height: 12),

            // Mapa y Coordenadas Check-out
            if (attendance.checkOutLatitude != null &&
                attendance.checkOutLongitude != null)
              _buildLocationCard(
                latitude: attendance.checkOutLatitude!,
                longitude: attendance.checkOutLongitude!,
                address: attendance.checkOutAddress,
                color: Colors.orange,
              ),
          ],
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
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
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

  // ===== HELPER WIDGETS PARA DETALLE =====

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard({
    required String photoUrl,
    required String time,
    required String label,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          GestureDetector(
            onTap: () {
              // Mostrar imagen en pantalla completa
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.black,
                  insetPadding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      Center(
                        child: InteractiveViewer(
                          child: Image.network(photoUrl, fit: BoxFit.contain),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Image.network(
                  photoUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error al cargar imagen',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Toca para ampliar',
                      style: TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required double latitude,
    required double longitude,
    String? address,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mapa
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
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
                        point: LatLng(latitude, longitude),
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_on, color: color, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coordenadas
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Coordenadas: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    // Botón para copiar coordenadas
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: '$latitude, $longitude'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coordenadas copiadas'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Dirección
                if (address != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Botón para abrir en Google Maps
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final url =
                        'https://www.google.com/maps?q=$latitude,$longitude';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Abrir en Google Maps'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
