import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraService {
  Future<XFile?> captureSelfie({ResolutionPreset preset = ResolutionPreset.medium}) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return null;
    }

    final camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();

    try {
      final file = await controller.takePicture();
      return file;
    } finally {
      await controller.dispose();
    }
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

