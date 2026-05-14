import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cloudinary configuration
class CloudinaryConfig {
  static const String cloudName =
      'dvehuzmqx'; // TODO: Replace with your cloud name
  static const String apiKey =
      '494257118678629'; // TODO: Replace with your API key
  static const String apiSecret =
      'Jnb7XZNuc88Ph2VdIxM-lvBI-4E'; // TODO: Replace with your API secret
  static const String uploadPreset = 'football_manager'; // unsigned preset

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  static String get deleteUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/destroy';
}

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final int width;
  final int height;
  final int bytes;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.width,
    required this.height,
    required this.bytes,
  });

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      secureUrl: json['secure_url'] as String,
      publicId: json['public_id'] as String,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      bytes: json['bytes'] as int? ?? 0,
    );
  }
}

/// Cloudinary service for image uploads
class CloudinaryService {
  final Dio _dio;

  CloudinaryService() : _dio = Dio();

  /// Upload an image file to Cloudinary
  Future<CloudinaryUploadResult> uploadImage(
    File imageFile, {
    String? folder,
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
      'upload_preset': CloudinaryConfig.uploadPreset,
      if (folder != null) 'folder': folder,
    });

    final response = await _dio.post(
      CloudinaryConfig.uploadUrl,
      data: formData,
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (response.statusCode == 200) {
      return CloudinaryUploadResult.fromJson(
          response.data as Map<String, dynamic>);
    }
    throw Exception('Upload failed: ${response.statusCode}');
  }

  /// Upload image from bytes (for web)
  Future<CloudinaryUploadResult> uploadImageBytes(
    List<int> bytes,
    String filename, {
    String? folder,
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'upload_preset': CloudinaryConfig.uploadPreset,
      if (folder != null) 'folder': folder,
    });

    final response = await _dio.post(
      CloudinaryConfig.uploadUrl,
      data: formData,
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (response.statusCode == 200) {
      return CloudinaryUploadResult.fromJson(
          response.data as Map<String, dynamic>);
    }
    throw Exception('Upload failed: ${response.statusCode}');
  }

  /// Delete an image from Cloudinary by public ID
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // For signed deletion (production), generate signature
      final response = await _dio.post(
        CloudinaryConfig.deleteUrl,
        data: {
          'public_id': publicId,
          'api_key': CloudinaryConfig.apiKey,
          'timestamp': timestamp,
          // signature: generate HMAC-SHA256 in production
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Generate optimized URL with transformations
  static String getOptimizedUrl(
    String publicId, {
    int? width,
    int? height,
    String format = 'webp',
    int quality = 80,
  }) {
    final transforms = <String>[];
    if (width != null) transforms.add('w_$width');
    if (height != null) transforms.add('h_$height');
    transforms.add('q_$quality');
    transforms.add('f_$format');
    transforms.add('c_fill');

    final transformStr = transforms.join(',');
    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/$transformStr/$publicId';
  }
}

final cloudinaryServiceProvider =
    Provider<CloudinaryService>((_) => CloudinaryService());
