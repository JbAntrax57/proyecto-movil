# Funcionalidad de Direcciones - Documentación

## Descripción General

Se ha implementado una nueva funcionalidad que permite a los clientes gestionar sus direcciones de entrega desde la aplicación. Esta funcionalidad incluye:

- **Registro de direcciones**: Los clientes pueden agregar múltiples direcciones con nombres descriptivos
- **Dirección predeterminada**: Los clientes pueden marcar una dirección como predeterminada
- **Selección en pedidos**: Al realizar un pedido, los clientes pueden seleccionar entre sus direcciones guardadas
- **Gestión completa**: Editar, eliminar y marcar direcciones como predeterminadas

## Arquitectura Implementada

### 1. Modelo de Datos (`lib/data/models/direccion_model.dart`)

```dart
class DireccionModel {
  final String? id;
  final String usuarioId;
  final String nombre;
  final String direccion;
  final String? referencias;
  final double? latitud;
  final double? longitud;
  final bool esPredeterminada;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
}
```

### 2. Servicio de Datos (`lib/data/services/direcciones_service.dart`)

Maneja todas las operaciones CRUD con la base de datos:
- `obtenerDirecciones(String usuarioId)`
- `crearDireccion(DireccionModel direccion)`
- `actualizarDireccion(DireccionModel direccion)`
- `eliminarDireccion(String direccionId)`
- `marcarComoPredeterminada(String direccionId, String usuarioId)`
- `obtenerDireccionPredeterminada(String usuarioId)`

### 3. Provider de Estado (`lib/presentation/cliente/providers/direcciones_provider.dart`)

Gestiona el estado de las direcciones en la aplicación:
- Lista de direcciones del usuario
- Dirección seleccionada actualmente
- Estados de carga y errores
- Métodos para todas las operaciones

### 4. Pantalla de Gestión (`lib/presentation/cliente/screens/direcciones_screen.dart`)

Interfaz completa para gestionar direcciones:
- Lista de direcciones con opciones de edición
- Modal para agregar/editar direcciones
- Confirmaciones para eliminar
- Marcado de dirección predeterminada

## Base de Datos

### Tabla `direcciones`

```sql
CREATE TABLE IF NOT EXISTS direcciones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    usuario_id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    direccion TEXT NOT NULL,
    referencias TEXT,
    latitud DOUBLE PRECISION,
    longitud DOUBLE PRECISION,
    es_predeterminada BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT fk_direcciones_usuario 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuarios(email) 
        ON DELETE CASCADE,
    
    CONSTRAINT unique_predeterminada_por_usuario 
        UNIQUE (usuario_id, es_predeterminada) 
        WHERE es_predeterminada = TRUE
);
```

### Índices para Rendimiento

```sql
CREATE INDEX IF NOT EXISTS idx_direcciones_usuario_id ON direcciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_direcciones_predeterminada ON direcciones(usuario_id, es_predeterminada);
CREATE INDEX IF NOT EXISTS idx_direcciones_fecha_creacion ON direcciones(fecha_creacion DESC);
```

## Integración con el Flujo de Pedidos

### Modificación del Carrito (`lib/presentation/cliente/screens/carrito_screen.dart`)

El modal de selección de ubicación ahora incluye:

1. **Direcciones guardadas**: Lista de direcciones del usuario con opción de selección rápida
2. **Ubicación actual**: Botón para obtener ubicación GPS
3. **Dirección manual**: Campo para ingresar dirección manualmente
4. **Gestión de direcciones**: Botón para ir a gestionar direcciones si no hay ninguna guardada

### Flujo de Usuario

1. **Cliente va a "Mi Perfil"**
2. **Selecciona "Registrar direcciones"**
3. **Agrega sus direcciones** (Casa, Trabajo, etc.)
4. **Marca una como predeterminada** (opcional)
5. **Al realizar un pedido**, selecciona entre:
   - Sus direcciones guardadas
   - Ubicación actual
   - Dirección manual

## Características Implementadas

### ✅ Funcionalidades Completadas

- [x] Modelo de datos completo
- [x] Servicio de base de datos
- [x] Provider de estado
- [x] Pantalla de gestión de direcciones
- [x] Integración con el carrito
- [x] Base de datos con restricciones
- [x] Traducciones en español e inglés
- [x] Validaciones de formularios
- [x] Confirmaciones de eliminación
- [x] Estados de carga y errores
- [x] Dirección predeterminada
- [x] Navegación entre pantallas

### 🎨 Interfaz de Usuario

- **Diseño moderno**: Cards con sombras y bordes redondeados
- **Iconografía clara**: Iconos de ubicación y acciones
- **Estados visuales**: Indicadores de selección y predeterminada
- **Responsive**: Adaptable a diferentes tamaños de pantalla
- **Accesibilidad**: Textos descriptivos y navegación clara

### 🔒 Seguridad y Validaciones

- **Validación de formularios**: Campos requeridos y formatos
- **Confirmaciones**: Para acciones destructivas (eliminar)
- **Restricciones de BD**: Una sola dirección predeterminada por usuario
- **Manejo de errores**: Mensajes claros y recuperación

## Instalación y Configuración

### 1. Ejecutar Script SQL

```bash
# Ejecutar el script de creación de tabla
psql -d tu_base_de_datos -f create_direcciones_table.sql
```

### 2. Verificar Dependencias

Asegúrate de que las siguientes dependencias estén en `pubspec.yaml`:

```yaml
dependencies:
  provider: ^6.0.0
  supabase_flutter: ^1.0.0
```

### 3. Configurar Provider

En el archivo principal de la aplicación, agregar el provider:

```dart
MultiProvider(
  providers: [
    // ... otros providers
    ChangeNotifierProvider(create: (_) => DireccionesProvider()),
  ],
  child: MyApp(),
)
```

## Uso de la Funcionalidad

### Para el Cliente

1. **Acceder a direcciones**: Mi Perfil → Registrar direcciones
2. **Agregar dirección**: Toca el botón "+" y completa el formulario
3. **Marcar predeterminada**: Usa el menú de opciones en cada dirección
4. **Seleccionar en pedido**: Al realizar un pedido, elige entre tus direcciones guardadas

### Para el Desarrollador

```dart
// Obtener direcciones del usuario
final direcciones = await direccionesProvider.cargarDirecciones(userEmail);

// Crear nueva dirección
final nuevaDireccion = DireccionModel(
  usuarioId: userEmail,
  nombre: 'Casa',
  direccion: 'Calle 123, Ciudad',
  referencias: 'Casa azul',
  esPredeterminada: true,
  fechaCreacion: DateTime.now(),
);

await direccionesProvider.crearDireccion(nuevaDireccion);
```

## Archivos Modificados/Creados

### Nuevos Archivos
- `lib/data/models/direccion_model.dart`
- `lib/data/services/direcciones_service.dart`
- `lib/presentation/cliente/providers/direcciones_provider.dart`
- `lib/presentation/cliente/screens/direcciones_screen.dart`
- `create_direcciones_table.sql`
- `README_DIRECCIONES.md`

### Archivos Modificados
- `lib/presentation/cliente/screens/perfil_screen.dart` - Agregada opción "Registrar direcciones"
- `lib/presentation/cliente/screens/carrito_screen.dart` - Integrado modal de direcciones
- `lib/core/localization.dart` - Agregadas traducciones

## Próximas Mejoras

- [ ] Integración con mapas para selección visual de ubicación
- [ ] Autocompletado de direcciones usando APIs de geocoding
- [ ] Historial de direcciones utilizadas
- [ ] Sincronización offline de direcciones
- [ ] Compartir direcciones entre dispositivos
- [ ] Validación de direcciones reales

## Soporte

Para reportar problemas o solicitar nuevas características, contacta al equipo de desarrollo. 