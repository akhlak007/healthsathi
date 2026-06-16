import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../config/cloudinary_config.dart';

class CloudinaryService {
  Future<String> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required bool isPdf,
  }) async {
    final resourceType = isPdf ? 'raw' : 'image';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/$resourceType/upload',
    );

    print('[Cloudinary] Upload started: fileName=$fileName, isPdf=$isPdf');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = CloudinaryConfig.folder
      ..fields['public_id'] = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('[Cloudinary] Upload response status: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorBody = response.body;
      String errorMessage = errorBody;
      try {
        final decoded = jsonDecode(errorBody) as Map<String, dynamic>;
        errorMessage = decoded['error']?['message'] ?? errorBody;
      } catch (_) {}
      print('[Cloudinary] Upload failed: $errorMessage');
      throw Exception('Cloudinary upload failed: $errorMessage');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      print('[Cloudinary] Upload response missing secure_url: ${response.body}');
      throw Exception('Cloudinary upload failed: missing secure_url');
    }

    print('[Cloudinary] Upload successful');
    print('[Cloudinary] URL received: $secureUrl');
    return secureUrl;
  }
}
