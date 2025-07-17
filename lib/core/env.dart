// Gestión de variables de entorno
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiUrl => dotenv.env['API_URL']!;
  static String get fcmKey => dotenv.env['FCM_KEY']!;
} 