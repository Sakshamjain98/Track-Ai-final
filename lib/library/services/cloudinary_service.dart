import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {

  /// Upload image to Cloudinary
  static Future<CloudinaryUploadResult> uploadImage({
    required XFile imageFile,
    String folder = 'recipes',
    Map<String, String>? tags,
  }) async {
    try {
      print('📤 Starting Cloudinary upload...');

      final file = File(imageFile.path);

      if (!await file.exists()) {
        throw CloudinaryException('Selected image file does not exist');
      }

      final bytes = await file.readAsBytes();
      print('📏 File size: ${bytes.length} bytes');

      // Check file size (max 10MB)
      if (bytes.length > 10 * 1024 * 1024) {
        throw CloudinaryException('File too large. Maximum size is 10MB.');
      }

      return await _uploadBytes(
        bytes: bytes,
        filename: imageFile.name,
        folder: folder,
        tags: tags,
      );
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      throw CloudinaryException('Failed to upload image: $e');
    }
  }

  /// Upload bytes to Cloudinary
  static Future<CloudinaryUploadResult> _uploadBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'recipes',
    Map<String, String>? tags,
  }) async {
    try {
      // Generate unique public ID
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final cleanFilename = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final publicId = '${folder}/${timestamp}_${cleanFilename.split('.').first}';

      print('🎯 Upload target: $publicId');

      // Create request
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      // Parameters
      final params = {
        'public_id': publicId,
        'folder': folder,
        'timestamp': timestamp,
        'api_key': CloudinaryConfig.apiKey,
      };

      // Add tags
      if (tags != null && tags.isNotEmpty) {
        params['tags'] = tags.values.join(',');
      }

      // Generate signature
      params['signature'] = _generateSignature(params);

      // Add to request
      params.forEach((key, value) {
        request.fields[key] = value;
      });

      print('🚀 Sending to Cloudinary...');

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        print('✅ Upload successful!');

        return CloudinaryUploadResult(
          publicId: jsonResponse['public_id'],
          secureUrl: jsonResponse['secure_url'],
          url: jsonResponse['url'],
          width: jsonResponse['width'] ?? 0,
          height: jsonResponse['height'] ?? 0,
          format: jsonResponse['format'] ?? 'jpg',
          bytes: jsonResponse['bytes'] ?? 0,
        );
      } else {
        throw CloudinaryException('Upload failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw CloudinaryException('Upload failed: $e');
    }
  }

  /// Generate signature for authentication
  static String _generateSignature(Map<String, String> params) {
    final sortedParams = Map.fromEntries(
        params.entries
            .where((entry) => entry.key != 'api_key' && entry.key != 'signature')
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key))
    );

    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    final stringToSign = '$paramString${CloudinaryConfig.apiSecret}';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  /// Get optimized image URL - FIXED METHOD
  static String getOptimizedUrl(
      String publicId, {
        int? width,
        int? height,
        String quality = 'auto',
        String format = 'auto',
      }) {
    try {
      String transformations = 'f_$format,q_$quality';
      if (width != null) transformations += ',w_$width';
      if (height != null) transformations += ',h_$height';

      final url = 'https://res.cloudinary.com/dqzvr8ele/image/upload/$transformations/$publicId';
      print('🖼️ Generated URL: $url');
      return url;
    } catch (e) {
      print('❌ Error generating optimized URL: $e');
      return 'https://res.cloudinary.com/dqzvr8ele/image/upload/$publicId';
    }
  }

  /// Delete image
  static Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final params = {
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': CloudinaryConfig.apiKey,
      };

      params['signature'] = _generateSignature(params);

      final response = await http.post(
        Uri.parse(CloudinaryConfig.destroyUrl),
        body: params,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      }

      return false;
    } catch (e) {
      print('❌ Error deleting image: $e');
      return false;
    }
  }
}

/// Upload result model
class CloudinaryUploadResult {
  final String publicId;
  final String secureUrl;
  final String url;
  final int width;
  final int height;
  final String format;
  final int bytes;

  CloudinaryUploadResult({
    required this.publicId,
    required this.secureUrl,
    required this.url,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'secureUrl': secureUrl,
      'url': url,
      'width': width,
      'height': height,
      'format': format,
      'bytes': bytes,
    };
  }
}

/// Custom exception
class CloudinaryException implements Exception {
  final String message;
  CloudinaryException(this.message);

  @override
  String toString() => message;
}
