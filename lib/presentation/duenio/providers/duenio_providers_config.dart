import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_provider.dart';
import 'notificaciones_pedidos_provider.dart';
import 'pedidos_duenio_provider.dart';
import 'menu_duenio_provider.dart';
import 'repartidores_provider.dart';

class DuenioProvidersConfig {
  static List<ChangeNotifierProvider> getProviders() {
    return [
      ChangeNotifierProvider<DashboardProvider>(
        create: (_) => DashboardProvider(),
      ),
      ChangeNotifierProvider<NotificacionesPedidosProvider>(
        create: (_) => NotificacionesPedidosProvider(),
      ),
      ChangeNotifierProvider<PedidosDuenioProvider>(
        create: (_) => PedidosDuenioProvider(),
      ),
      ChangeNotifierProvider<MenuDuenioProvider>(
        create: (_) => MenuDuenioProvider(),
      ),
      ChangeNotifierProvider<RepartidoresProvider>(
        create: (_) => RepartidoresProvider(),
      ),
    ];
  }

  static MultiProvider getMultiProvider({
    required Widget child,
  }) {
    return MultiProvider(
      providers: getProviders(),
      child: child,
    );
  }
} 