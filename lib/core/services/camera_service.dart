import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) {
      throw Exception('No se encontraron cámaras');
    }

    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  CameraController? get controller => _controller;

  Future<File> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Cámara no inicializada');
    }

    final XFile picture = await _controller!.takePicture();
    final File imageFile = File(picture.path);

    // Comprimir y optimizar la imagen
    return await compressImage(imageFile);
  }

  Future<File> compressImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return file;

    // Redimensionar si es muy grande
    if (image.width > 1920) {
      image = img.copyResize(image, width: 1920);
    }

    // Comprimir
    final compressedBytes = img.encodeJpg(
      image,
      quality: AppConstants.photoQuality,
    );

    // Verificar tamaño
    if (compressedBytes.length > AppConstants.maxPhotoSizeKB * 1024) {
      // Si aún es muy grande, reducir más la calidad
      final moreCompressed = img.encodeJpg(image, quality: 70);
      await file.writeAsBytes(moreCompressed);
    } else {
      await file.writeAsBytes(compressedBytes);
    }

    return file;
  }

  void dispose() {
    _controller?.dispose();
  }
}
