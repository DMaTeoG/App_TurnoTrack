import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  Future<XFile?> captureSelfie({
    ResolutionPreset preset = ResolutionPreset.medium,
  }) async {
    try {
      final status = await Permission.camera.status;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return null;
      }
      if (status.isDenied || status.isRestricted) {
        final requestResult = await Permission.camera.request();
        if (!requestResult.isGranted) {
          return null;
        }
      }

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
    } on CameraException catch (error) {
      debugPrint('Camera error: ${error.code} - ${error.description}');
      return null;
    } catch (error) {
      debugPrint('Unexpected camera error: $error');
      return null;
    }
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});
