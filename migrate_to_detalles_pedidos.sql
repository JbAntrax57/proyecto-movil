-- Script de migración para convertir datos existentes
-- Convierte el campo JSON 'productos' en la tabla 'pedidos' a la nueva tabla 'detalles_pedidos'

-- 1. Primero, crear la tabla detalles_pedidos si no existe
CREATE TABLE IF NOT EXISTS detalles_pedidos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id UUID,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    cantidad INTEGER NOT NULL DEFAULT 1,
    img VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Crear índices
CREATE INDEX IF NOT EXISTS idx_detalles_pedidos_pedido_id ON detalles_pedidos(pedido_id);
CREATE INDEX IF NOT EXISTS idx_detalles_pedidos_producto_id ON detalles_pedidos(producto_id);

-- 3. Migrar datos existentes
-- Esta función migra los datos del campo JSON 'productos' a la tabla 'detalles_pedidos'
DO $$
DECLARE
    pedido_record RECORD;
    producto_json JSONB;
    producto_record RECORD;
BEGIN
    -- Iterar sobre todos los pedidos que tienen el campo 'productos' con datos
    FOR pedido_record IN 
        SELECT id, productos 
        FROM pedidos 
        WHERE productos IS NOT NULL 
        AND productos != '[]'::jsonb
        AND productos != 'null'::jsonb
    LOOP
        -- Iterar sobre cada producto en el array JSON
        FOR producto_json IN SELECT * FROM jsonb_array_elements(pedido_record.productos)
        LOOP
            -- Extraer datos del producto JSON
            INSERT INTO detalles_pedidos (
                pedido_id,
                producto_id,
                nombre,
                descripcion,
                precio,
                cantidad,
                img,
                created_at
            ) VALUES (
                pedido_record.id,
                COALESCE((producto_json->>'id')::UUID, (producto_json->>'producto_id')::UUID, NULL),
                COALESCE(producto_json->>'nombre', 'Producto sin nombre'),
                producto_json->>'descripcion',
                COALESCE((producto_json->>'precio')::DECIMAL, 0.00),
                COALESCE((producto_json->>'cantidad')::INTEGER, 1),
                producto_json->>'img',
                pedido_record.created_at
            );
        END LOOP;
    END LOOP;
END $$;

-- 4. Verificar la migración
SELECT 
    'Pedidos con productos JSON' as tipo,
    COUNT(*) as cantidad
FROM pedidos 
WHERE productos IS NOT NULL 
AND productos != '[]'::jsonb
AND productos != 'null'::jsonb

UNION ALL

SELECT 
    'Detalles de pedidos migrados' as tipo,
    COUNT(*) as cantidad
FROM detalles_pedidos;

-- 5. Mostrar algunos ejemplos de datos migrados
SELECT 
    p.id as pedido_id,
    p.usuario_email,
    p.restaurante_id,
    p.estado,
    COUNT(dp.id) as cantidad_detalles,
    SUM(dp.precio * dp.cantidad) as total_calculado
FROM pedidos p
LEFT JOIN detalles_pedidos dp ON p.id = dp.pedido_id
WHERE dp.id IS NOT NULL
GROUP BY p.id, p.usuario_email, p.restaurante_id, p.estado
ORDER BY p.created_at DESC
LIMIT 10;

-- 6. Opcional: Eliminar el campo 'productos' de la tabla 'pedidos' después de verificar
-- ALTER TABLE pedidos DROP COLUMN productos; 