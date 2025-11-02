import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Utilidad para optimizar imágenes antes de subirlas
/// Reduce tamaño significativamente manteniendo calidad
class ImageOptimizer {
  // Configuración por defecto
  static const int defaultMaxWidth = 800;
  static const int defaultMaxHeight = 800;
  static const int defaultQuality = 85;
  static const int maxSizeKB = 2048; // 2MB

  /// Comprimir imagen manteniendo calidad visual
  ///
  /// [file] - Archivo de imagen original
  /// [maxWidth] - Ancho máximo en píxeles (default: 800)
  /// [maxHeight] - Alto máximo en píxeles (default: 800)
  /// [quality] - Calidad JPEG 0-100 (default: 85)
  ///
  /// Retorna archivo comprimido o lanza excepción
  static Future<File> compressImage(
    File file, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
  }) async {
    try {
      // Obtener directorio temporal
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = path.join(dir.path, '${timestamp}_compressed.jpg');

      // Comprimir imagen
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('Error al comprimir imagen');
      }

      return File(result.path);
    } catch (e) {
      throw Exception('Error en compresión: $e');
    }
  }

  /// Obtener tamaño de archivo en KB
  static Future<double> getFileSizeKB(File file) async {
    try {
      final bytes = await file.length();
      return bytes / 1024;
    } catch (e) {
      throw Exception('Error al obtener tamaño: $e');
    }
  }

  /// Obtener tamaño en MB
  static Future<double> getFileSizeMB(File file) async {
    final sizeKB = await getFileSizeKB(file);
    return sizeKB / 1024;
  }

  /// Validar que el archivo no exceda el tamaño máximo
  /// Por defecto valida 2MB
  static Future<bool> isValidSize(File file, {int maxKB = maxSizeKB}) async {
    try {
      final sizeKB = await getFileSizeKB(file);
      return sizeKB <= maxKB;
    } catch (e) {
      return false;
    }
  }

  /// Obtener información de reducción de tamaño
  /// Útil para mostrar al usuario
  static Future<CompressionInfo> getCompressionInfo(
    File originalFile,
    File compressedFile,
  ) async {
    final originalSize = await getFileSizeKB(originalFile);
    final compressedSize = await getFileSizeKB(compressedFile);
    final reduction = ((originalSize - compressedSize) / originalSize * 100);

    return CompressionInfo(
      originalSizeKB: originalSize,
      compressedSizeKB: compressedSize,
      reductionPercentage: reduction,
    );
  }

  /// Comprimir y validar en un solo paso
  /// Retorna archivo comprimido o lanza excepción si excede tamaño
  static Future<File> compressAndValidate(
    File file, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    int maxSizeKB = maxSizeKB,
  }) async {
    // Comprimir
    final compressed = await compressImage(
      file,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );

    // Validar tamaño
    final isValid = await isValidSize(compressed, maxKB: maxSizeKB);
    if (!isValid) {
      final sizeKB = await getFileSizeKB(compressed);
      throw ImageTooLargeException(
        'Imagen demasiado grande: ${sizeKB.toStringAsFixed(2)}KB (máx: ${maxSizeKB}KB)',
        currentSizeKB: sizeKB,
        maxSizeKB: maxSizeKB.toDouble(),
      );
    }

    return compressed;
  }

  /// Limpiar archivos temporales de compresión
  static Future<void> cleanTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();

      for (var file in files) {
        if (file.path.contains('_compressed.jpg')) {
          await file.delete();
        }
      }
    } catch (e) {
      // Silencioso, no crítico en producción
      if (kDebugMode) {
        debugPrint('Error limpiando archivos temporales: $e');
      }
    }
  }
}

/// Información de compresión
class CompressionInfo {
  final double originalSizeKB;
  final double compressedSizeKB;
  final double reductionPercentage;

  CompressionInfo({
    required this.originalSizeKB,
    required this.compressedSizeKB,
    required this.reductionPercentage,
  });

  String get originalSizeMB => (originalSizeKB / 1024).toStringAsFixed(2);
  String get compressedSizeMB => (compressedSizeKB / 1024).toStringAsFixed(2);
  String get reductionText => '${reductionPercentage.toStringAsFixed(1)}%';

  @override
  String toString() {
    return 'Original: ${originalSizeKB.toStringAsFixed(2)}KB → '
        'Comprimida: ${compressedSizeKB.toStringAsFixed(2)}KB '
        '(reducción: $reductionText)';
  }
}

/// Excepción cuando la imagen excede el tamaño máximo
class ImageTooLargeException implements Exception {
  final String message;
  final double currentSizeKB;
  final double maxSizeKB;

  ImageTooLargeException(
    this.message, {
    required this.currentSizeKB,
    required this.maxSizeKB,
  });

  @override
  String toString() => message;
}
