# Migración de Productos JSON a Tabla Detalles_Pedidos

## Resumen
Este documento describe cómo migrar desde el campo JSON `productos` en la tabla `pedidos` a una nueva tabla separada `detalles_pedidos` para mejorar la normalización de la base de datos.

## Cambios Realizados

### 1. Nueva Estructura de Base de Datos

#### Tabla `detalles_pedidos`
```sql
CREATE TABLE detalles_pedidos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id UUID REFERENCES productos(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    cantidad INTEGER NOT NULL DEFAULT 1,
    img VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Nuevos Servicios y Helpers

#### `DetallesPedidosService` (`lib/data/services/detalles_pedidos_service.dart`)
- `crearDetallesPedido()`: Crear detalles de un pedido
- `obtenerDetallesPedido()`: Obtener detalles de un pedido específico
- `obtenerDetallesMultiplesPedidos()`: Obtener detalles de múltiples pedidos eficientemente
- `calcularTotalPedido()`: Calcular total basado en detalles

#### `PedidosHelper` (`lib/shared/utils/pedidos_helper.dart`)
- `obtenerPedidosConDetalles()`: Obtener pedidos con sus detalles incluidos
- `formatearFecha()`: Formatear fechas de manera consistente
- `getEstadoColor()` y `getEstadoIcon()`: Helpers para UI

### 3. Modificaciones en el Código

#### Archivos Modificados:
1. **`carrito_screen.dart`**: Modificado para crear pedidos sin campo JSON y usar la nueva tabla
2. **`pedidos_screen.dart` (dueño)**: Usa `PedidosHelper` para obtener pedidos con detalles
3. **`pedidos_screen.dart` (cliente)**: Usa `PedidosHelper` para obtener pedidos con detalles
4. **`historial_pedidos_screen.dart`**: Usa `PedidosHelper` para obtener pedidos con detalles
5. **`pedidos_screen.dart` (repartidor)**: Usa `PedidosHelper` para obtener pedidos con detalles

## Instrucciones de Migración

### Paso 1: Ejecutar Scripts SQL

1. **Crear la nueva tabla**:
   ```sql
   -- Ejecutar create_detalles_pedidos_table.sql
   ```

2. **Migrar datos existentes**:
   ```sql
   -- Ejecutar migrate_to_detalles_pedidos.sql
   ```

### Paso 2: Verificar la Migración

1. **Verificar que los datos se migraron correctamente**:
   ```sql
   SELECT COUNT(*) FROM detalles_pedidos;
   SELECT COUNT(*) FROM pedidos WHERE productos IS NOT NULL;
   ```

2. **Comparar totales**:
   ```sql
   -- Verificar que los totales coinciden
   SELECT 
       p.id,
       p.total as total_original,
       SUM(dp.precio * dp.cantidad) as total_calculado
   FROM pedidos p
   LEFT JOIN detalles_pedidos dp ON p.id = dp.pedido_id
   WHERE dp.id IS NOT NULL
   GROUP BY p.id, p.total;
   ```

### Paso 3: Probar la Aplicación

1. **Crear un nuevo pedido** desde la aplicación
2. **Verificar que se crean los detalles** en la tabla `detalles_pedidos`
3. **Verificar que se muestran correctamente** en todas las pantallas

### Paso 4: Limpiar (Opcional)

Una vez que todo funcione correctamente, puedes eliminar el campo JSON:

```sql
-- SOLO DESPUÉS de verificar que todo funciona
ALTER TABLE pedidos DROP COLUMN productos;
```

## Ventajas de la Nueva Estructura

### 1. Normalización
- Elimina redundancia de datos
- Mejora la integridad referencial
- Facilita consultas complejas

### 2. Rendimiento
- Índices específicos en `pedido_id` y `producto_id`
- Consultas más eficientes
- Mejor escalabilidad

### 3. Mantenibilidad
- Código más limpio y organizado
- Separación clara de responsabilidades
- Facilita futuras modificaciones

### 4. Funcionalidad
- Historial de precios al momento del pedido
- Mejor trazabilidad
- Consultas más flexibles

## Compatibilidad

El código mantiene compatibilidad con la estructura anterior:
- Los pedidos siguen teniendo un campo `productos` (pero ahora se calcula dinámicamente)
- Las pantallas existentes no requieren cambios mayores
- El helper `PedidosHelper` abstrae la complejidad

## Troubleshooting

### Error: "No se encontraron detalles para el pedido"
- Verificar que la migración se ejecutó correctamente
- Revisar que los `pedido_id` coinciden entre tablas

### Error: "Error al crear detalles del pedido"
- Verificar que la tabla `detalles_pedidos` existe
- Revisar permisos de inserción en Supabase

### Pedidos sin productos
- Verificar que el campo `productos` en `pedidos` no esté vacío
- Revisar la lógica de migración en el script

## Archivos Creados/Modificados

### Nuevos Archivos:
- `create_detalles_pedidos_table.sql`
- `migrate_to_detalles_pedidos.sql`
- `lib/data/services/detalles_pedidos_service.dart`
- `lib/shared/utils/pedidos_helper.dart`
- `README_MIGRACION_DETALLES_PEDIDOS.md`

### Archivos Modificados:
- `lib/presentation/cliente/screens/carrito_screen.dart`
- `lib/presentation/duenio/screens/pedidos_screen.dart`
- `lib/presentation/cliente/screens/pedidos_screen.dart`
- `lib/presentation/cliente/screens/historial_pedidos_screen.dart`
- `lib/presentation/repartidor/screens/pedidos_screen.dart` 