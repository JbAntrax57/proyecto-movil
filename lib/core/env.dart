// env.dart - Gestión de variables de entorno para la app
// Utiliza la clase Env para acceder a variables sensibles como API_URL y FCM_KEY.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Obtiene la URL base de la API desde el entorno
  static String get apiUrl => dotenv.env['API_URL']!;
  // Obtiene la clave de FCM desde el entorno
  static String get fcmKey => dotenv.env['FCM_KEY']!;
  // URL de tu proyecto Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://yyjpkxrjwhaueanbteua.supabase.co';
  // Clave anónima de tu proyecto Supabase
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5anBreHJqd2hhdWVhbmJ0ZXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyODUxODUsImV4cCI6MjA2Nzg2MTE4NX0.AqvEVE8Nln4qSIu-Tu0aNpwgK5at7i34vaSyaz9PWJE';
}
// Fin de env.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 