import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String baseUrl = 'https://local-sale-gls-project.onrender.com/api';
  bool isOnline = false;

  Future<bool> checkHealth() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(Uri.parse('$baseUrl/health'));
      final response = await request.close().timeout(const Duration(seconds: 2));
      isOnline = response.statusCode == 200;
      client.close();
      return isOnline;
    } catch (_) {
      isOnline = false;
      return false;
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(Uri.parse('$baseUrl$endpoint'));
      request.headers.set('Content-Type', 'application/json');
      final response = await request.close().timeout(const Duration(seconds: 3));
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client.postUrl(Uri.parse('$baseUrl$endpoint'));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(body));
      final response = await request.close().timeout(const Duration(seconds: 3));
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
