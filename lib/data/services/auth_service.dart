import '../services/http_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  // Función para hashear contraseña con SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Login de usuario
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print('🔐 AuthService.login() - Intentando login para: $email');
      
      final response = await HttpService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      print('🔐 AuthService.login() - Login exitoso para: $email');
      return response['data'];
    } catch (e) {
      print('❌ AuthService.login() - Error en login: $e');
      return null;
    }
  }

  // Registro de usuario
  static Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String nombre,
    String rol = 'cliente',
    String? telefono,
    String? direccion,
  }) async {
    try {
      print('🔐 AuthService.register() - Intentando registro para: $email');
      
      final response = await HttpService.post('/auth/register', {
        'email': email,
        'password': password,
        'nombre': nombre,
        'rol': rol,
        'telefono': telefono,
        'direccion': direccion,
      });

      print('🔐 AuthService.register() - Registro exitoso para: $email');
      return response['data'];
    } catch (e) {
      print('❌ AuthService.register() - Error en registro: $e');
      return null;
    }
  }

  // Obtener información del usuario actual
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await HttpService.get('/auth/me');
      return response['data'];
    } catch (e) {
      print('❌ AuthService.getCurrentUser() - Error obteniendo usuario: $e');
      return null;
    }
  }

  // Verificar si el token es válido
  static Future<bool> isTokenValid() async {
    try {
      await getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verificar si un email ya existe
  static Future<bool> checkEmailExists(String email) async {
    try {
      print('🔐 AuthService.checkEmailExists() - Verificando email: $email');
      
      final response = await HttpService.post('/auth/check-email', {
        'email': email,
      });

      print('🔐 AuthService.checkEmailExists() - Email existe: ${response['exists']}');
      return response['exists'] ?? false;
    } catch (e) {
      print('❌ AuthService.checkEmailExists() - Error: $e');
      return false;
    }
  }
} 