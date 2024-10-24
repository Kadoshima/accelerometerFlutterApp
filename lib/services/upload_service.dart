// lib/services/upload_service.dart
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadService {
  final String baseUrl =
      dotenv.env['API_BASE_URI'] ?? 'https://api.example.com';

  Future<void> uploadCSV(String csvData, String token) async {
    final url = Uri.parse('$baseUrl/upload');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'text/csv',
        'Authorization': 'Bearer $token',
      },
      body: csvData,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload data');
    }
  }
}
