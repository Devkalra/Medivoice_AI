import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/prescription.dart';

class ApiService {
  // Change this to your backend URL
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000/api/v1'; // iOS simulator
  // static const String baseUrl = 'https://your-deployed-backend.com/api/v1'; // Production
   static const String baseUrl = 'http://192.168.1.6:8000/api/v1';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Analyze prescription image
  Future<PrescriptionResult> analyzePrescription(File imageFile) async {
    final uri = Uri.parse('$baseUrl/analyze-prescription');
    final request = http.MultipartRequest('POST', uri);

    final mimeType = _getMimeType(imageFile.path);
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: _parseMediaType(mimeType),
    ));

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 120),
        );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PrescriptionResult.fromJson(json);
    } else {
      final error = _parseError(response.body);
      throw ApiException(error, response.statusCode);
    }
  }

  /// Convert text to speech, returns base64 audio string
  Future<String> textToSpeech(String text, String language) async {
    final uri = Uri.parse('$baseUrl/text-to-speech');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'language': language}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return json['audio_base64'] as String? ?? '';
      }
      throw ApiException(json['error'] ?? 'TTS failed', 500);
    } else {
      throw ApiException(_parseError(response.body), response.statusCode);
    }
  }

  /// Convert full prescription to speech
  Future<String> prescriptionToSpeech(
      PrescriptionResult prescription, String language) async {
    final uri = Uri.parse('$baseUrl/prescription-tts?language=$language');
    final body = {
      'success': prescription.success,
      'patient_summary': prescription.patientSummary,
      'medications': prescription.medications
          .map((m) => {
                'name': m.name,
                'dosage': m.dosage,
                'frequency': m.frequency,
                'duration': m.duration,
                'purpose': m.purpose,
                'instructions': m.instructions,
              })
          .toList(),
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return json['audio_base64'] as String? ?? '';
      }
      throw ApiException(json['error'] ?? 'TTS failed', 500);
    } else {
      throw ApiException(_parseError(response.body), response.statusCode);
    }
  }

  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  http.MediaType _parseMediaType(String mimeType) {
    final parts = mimeType.split('/');
    return http.MediaType(parts[0], parts[1]);
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['detail'] ?? json['message'] ?? 'An error occurred';
    } catch (_) {
      return 'Server error. Please try again.';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
