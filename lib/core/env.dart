// env.dart - Gestión de variables de entorno para la app
// Utiliza la clase Env para acceder a variables sensibles como API_URL y FCM_KEY.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Obtiene la URL base de la API desde el entorno
  static String get apiUrl => dotenv.env['API_URL']!;
  // Obtiene la clave de FCM desde el entorno
  static String get fcmKey => dotenv.env['FCM_KEY']!;
}
// Fin de env.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 