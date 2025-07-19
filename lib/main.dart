// main.dart - Punto de entrada de la aplicación Flutter
// Esta app implementa un sistema multirol (Cliente, Repartidor, Dueño, Admin) con navegación dinámica y gestión de estado robusta.
// Aquí se inicializa Supabase y se definen las rutas principales para cada tipo de usuario.
// Cada pantalla principal está documentada y comentada para facilitar el onboarding de nuevos desarrolladores.

import 'package:flutter/material.dart';
import 'presentation/cliente/screens/login_screen.dart';
import 'presentation/cliente/screens/menu_screen.dart';
import 'presentation/cliente/screens/negocios_screen.dart';
import 'presentation/admin/screens/dashboard_screen.dart';
import 'presentation/duenio/screens/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'package:provider/provider.dart';
import 'presentation/cliente/providers/carrito_provider.dart';
import 'core/router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'presentation/duenio/providers/notificaciones_pedidos_provider.dart';
import 'core/env.dart'; // Importa las variables de entorno
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importa flutter_dotenv
// Importa las pantallas principales de cada rol si existen
// Si no, usa un Scaffold temporal

// Función principal: inicializa Firebase y ejecuta la app
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para inicializaciones asíncronas
  
  // Carga las variables de entorno desde el archivo .env
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Archivo .env cargado correctamente');
  } catch (e) {
    print('⚠️ Error cargando .env: $e');
    // Continuar sin el archivo .env, usar valores por defecto
  }
  
  // Inicializa Supabase en vez de Firebase
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    print('✅ Supabase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Supabase: $e');
    // Si falla la inicialización, usar valores por defecto
    await Supabase.initialize(
      url: 'https://yyjpkxrjwhaueanbteua.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5anBreHJqd2hhdWVhbmJ0ZXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyODUxODUsImV4cCI6MjA2Nzg2MTE4NX0.AqvEVE8Nln4qSIu-Tu0aNpwgK5at7i34vaSyaz9PWJE',
    );
    print('✅ Supabase inicializado con valores por defecto');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => NotificacionesPedidosProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Widget raíz de la aplicación. Define el MaterialApp y las rutas principales por rol.
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    // Solicitar permisos de notificaciones
    await _solicitarPermisosNotificaciones();
    
    // Inicializar sistema de notificaciones global
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificacionesProvider = Provider.of<NotificacionesPedidosProvider>(context, listen: false);
      notificacionesProvider.inicializarSistema();
    });
  }

  Future<void> _solicitarPermisosNotificaciones() async {
    if (Platform.isAndroid) {
      // Android 13+ requiere pedir el permiso en tiempo de ejecución
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } else if (Platform.isIOS) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'App Demo Multirol',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router, // Usar GoRouter centralizado
    );
  }
}

// Pantalla de registro temporal (placeholder para futuros flujos de registro de usuario)
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')), 
      body: const Center(child: Text('Pantalla de registro (por implementar)')),
    );
  }
}

// Pantalla principal temporal para repartidor (se reemplazará por la vista real de repartidor)
class RepartidorHomeScreen extends StatelessWidget {
  const RepartidorHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio Repartidor')), 
      body: const Center(child: Text('Vista principal Repartidor')), 
    );
  }
}
// Pantalla principal temporal para admin (no se usa, se usa AdminDashboardScreen)
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio Admin')), 
      body: const Center(child: Text('Vista principal Admin')), 
    );
  }
}