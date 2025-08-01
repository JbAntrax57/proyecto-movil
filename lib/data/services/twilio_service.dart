import '../services/http_service.dart';

class TwilioService {
  // Enviar código de verificación usando el backend
  static Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
    try {
      print('📱 TwilioService.sendVerificationCode() - Enviando código a: $phoneNumber');
      
      final response = await HttpService.post('/twilio/send-code', {
        'phoneNumber': phoneNumber,
      });

      print('✅ TwilioService.sendVerificationCode() - Código enviado exitosamente');
      return {
        'success': true,
        'message': 'Código de verificación enviado',
        'data': response['data'],
      };
    } catch (e) {
      print('❌ TwilioService.sendVerificationCode() - Error: $e');
      return {
        'success': false,
        'message': 'Error al enviar código de verificación',
        'error': e.toString(),
      };
    }
  }

  // Verificar código usando el backend
  static Future<Map<String, dynamic>> verifyCode(String phoneNumber, String code) async {
    try {
      print('📱 TwilioService.verifyCode() - Verificando código para: $phoneNumber');
      
      final response = await HttpService.post('/twilio/verify-code', {
        'phoneNumber': phoneNumber,
        'code': code,
      });

      print('✅ TwilioService.verifyCode() - Código verificado exitosamente');
      return {
        'success': true,
        'message': 'Número verificado correctamente',
        'data': response['data'],
      };
    } catch (e) {
      print('❌ TwilioService.verifyCode() - Error: $e');
      return {
        'success': false,
        'message': 'Error al verificar código',
        'error': e.toString(),
      };
    }
  }

  // Formatear número de teléfono para Twilio (agregar código de país si no está presente)
  static String formatPhoneNumber(String phoneNumber) {
    // Si el número no empieza con +, agregar código de país por defecto
    if (!phoneNumber.startsWith('+')) {
      // Remover espacios, guiones y paréntesis
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Si empieza con 0, removerlo
      if (cleanNumber.startsWith('0')) {
        return '+52${cleanNumber.substring(1)}';
      }
      
      // Si empieza con 1, agregar código de país
      if (cleanNumber.startsWith('1')) {
        return '+52$cleanNumber';
      }
      
      // Si tiene 10 dígitos, agregar código de país
      if (cleanNumber.length == 10) {
        return '+52$cleanNumber';
      }
      
      // Si ya tiene código de país, solo agregar +
      if (cleanNumber.length > 10) {
        return '+$cleanNumber';
      }
    }
    
    return phoneNumber;
  }

  // Validar formato de número de teléfono
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remover espacios, guiones y paréntesis
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Validar que tenga al menos 10 dígitos
    final digitsOnly = cleanNumber.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length >= 10;
  }
} 