import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<void> start() async {
    await http.post(Uri.parse("$baseUrl/start"));
  }

  static Future<void> stop() async {
    await http.post(Uri.parse("$baseUrl/stop"));
  }

  static Future<void> mute() async {
    await http.post(Uri.parse("$baseUrl/mute"));
  }

  static Future<Map<String, dynamic>> getState() async {
    final res = await http.get(Uri.parse("$baseUrl/state"));
    return jsonDecode(res.body);
  }
}
