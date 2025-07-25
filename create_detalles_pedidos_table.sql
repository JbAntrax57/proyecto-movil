-- Script para crear la tabla detalles_pedidos
-- Esta tabla reemplazará el campo JSON 'productos' en la tabla 'pedidos'

-- Crear la tabla detalles_pedidos
CREATE TABLE IF NOT EXISTS detalles_pedidos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    cantidad INTEGER NOT NULL DEFAULT 1,
    img VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_detalles_pedidos_pedido_id ON detalles_pedidos(pedido_id);
CREATE INDEX IF NOT EXISTS idx_detalles_pedidos_producto_id ON detalles_pedidos(producto_id);

-- Crear trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_detalles_pedidos_updated_at 
    BEFORE UPDATE ON detalles_pedidos 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios sobre la estructura
COMMENT ON TABLE detalles_pedidos IS 'Detalles de productos en cada pedido';
COMMENT ON COLUMN detalles_pedidos.id IS 'ID único del detalle';
COMMENT ON COLUMN detalles_pedidos.pedido_id IS 'Referencia al pedido';
COMMENT ON COLUMN detalles_pedidos.producto_id IS 'Referencia al producto';
COMMENT ON COLUMN detalles_pedidos.nombre IS 'Nombre del producto al momento del pedido';
COMMENT ON COLUMN detalles_pedidos.descripcion IS 'Descripción del producto al momento del pedido';
COMMENT ON COLUMN detalles_pedidos.precio IS 'Precio del producto al momento del pedido';
COMMENT ON COLUMN detalles_pedidos.cantidad IS 'Cantidad solicitada';
COMMENT ON COLUMN detalles_pedidos.img IS 'URL de la imagen del producto al momento del pedido'; 