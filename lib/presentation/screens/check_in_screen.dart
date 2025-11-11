import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/attendance_provider.dart';
import '../widgets/location_map_widget.dart';
import '../../core/utils/image_optimizer.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  File? _capturedImage;

  CheckInStep _currentStep = CheckInStep.location;
  bool _locationVerified = false;
  String? _currentLocation;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _verifyLocation();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _verifyLocation() async {
    setState(() => _isProcessing = true);

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      final address = await locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _locationVerified = true;
          _currentLocation = address ?? 'Unknown location';
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error obtaining location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();

      if (mounted) {
        setState(() {
          _capturedImage = File(image.path);
          _currentStep = CheckInStep.review;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al tomar la foto')));
      }
    }
  }

  Future<void> _submitCheckIn() async {
    if (_capturedImage == null || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faltan datos de foto o ubicación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Optimize image before uploading
      final optimizedImage = await ImageOptimizer.compressImage(
        _capturedImage!,
      );

      // Submit check-in (sistema simple: solo entradas)
      await ref
          .read(attendanceProvider.notifier)
          .checkIn(
            photoFile: optimizedImage,
            latitude: _latitude!,
            longitude: _longitude!,
            address: _currentLocation,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Entrada registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar entrada: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _capturedImage == null)
            Positioned.fill(child: CameraPreview(_cameraController!)),

          // Captured image preview
          if (_capturedImage != null)
            Positioned.fill(
              child: Image.file(_capturedImage!, fit: BoxFit.cover),
            ),

          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(theme),

                const Spacer(),

                // Status indicators
                if (_currentStep == CheckInStep.location)
                  _buildLocationStatus(theme),

                if (_currentStep == CheckInStep.camera)
                  _buildCameraInstructions(theme),

                if (_currentStep == CheckInStep.review)
                  _buildReviewControls(theme),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Registrar Entrada',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                TimeOfDay.now().format(context),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildLocationStatus(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            _locationVerified ? Icons.check_circle : Icons.location_on,
            color: _locationVerified ? Colors.green : theme.colorScheme.primary,
            size: 48,
          ).animate().scale(duration: 600.ms),

          const SizedBox(height: 16),

          Text(
            _locationVerified
                ? '¡Ubicación Verificada!'
                : 'Verificando Ubicación...',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          if (_currentLocation != null)
            Text(
              _currentLocation!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 16),

          // Show map if location is verified
          if (_locationVerified && _latitude != null && _longitude != null)
            Consumer(
              builder: (context, ref, child) {
                final locationsAsync = ref.watch(allowedLocationsProvider);
                return locationsAsync.when(
                  data: (locations) => LocationMapWidget(
                    currentLatitude: _latitude!,
                    currentLongitude: _longitude!,
                    allowedLocations: locations,
                    height: 200,
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => LocationMapWidget(
                    currentLatitude: _latitude!,
                    currentLongitude: _longitude!,
                    allowedLocations: const [],
                    height: 200,
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                );
              },
            ),

          const SizedBox(height: 24),

          if (_locationVerified)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _currentStep = CheckInStep.camera);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tomar Foto'),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildCameraInstructions(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.face, size: 48, color: Colors.blue),
          const SizedBox(height: 12),
          Text(
            'Posiciona tu rostro',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Asegúrate de estar bien iluminado',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: 1500.ms,
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.0, 1.0),
              ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildReviewControls(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          const SizedBox(height: 12),
          Text(
            '¿Confirmar entrada?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _capturedImage = null;
                        _currentStep = CheckInStep.camera;
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirmar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3, end: 0);
  }
}

enum CheckInStep { location, camera, review }
