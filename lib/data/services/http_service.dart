import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/env.dart';
import '../../core/backend_config.dart';

class HttpService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Headers base para todas las peticiones
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Método GET genérico
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      print('🔍 HttpService.get() - Endpoint: $endpoint');
      print('🔍 HttpService.get() - URL completa: ${BackendConfig.baseUrl}$endpoint');
      
      final headers = await _getHeaders();
      print('🔍 HttpService.get() - Headers: $headers');
      
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}$endpoint'),
        headers: headers,
      ).timeout(BackendConfig.connectionTimeout);

      print('🔍 HttpService.get() - Status code: ${response.statusCode}');
      print('🔍 HttpService.get() - Response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ HttpService.get() - Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Método POST genérico
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(BackendConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Método PUT genérico
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${BackendConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(BackendConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Método DELETE genérico
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${BackendConfig.baseUrl}$endpoint'),
        headers: headers,
      ).timeout(BackendConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Manejo de respuestas
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'Error en la petición');
    }
  }

  // Guardar token de autenticación
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Obtener token de autenticación
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Eliminar token de autenticación
  static Future<void> removeToken() async {
    await _storage.delete(key: 'auth_token');
  }
} 