-- Crear tabla de direcciones para los clientes
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
    
    -- Foreign key para referenciar al usuario
    CONSTRAINT fk_direcciones_usuario 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuarios(email) 
        ON DELETE CASCADE
);
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_direcciones_usuario_id ON direcciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_direcciones_predeterminada ON direcciones(usuario_id, es_predeterminada);
CREATE INDEX IF NOT EXISTS idx_direcciones_fecha_creacion ON direcciones(fecha_creacion DESC);

-- Índice único parcial para asegurar que solo una dirección sea predeterminada por usuario
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_predeterminada_por_usuario 
    ON direcciones(usuario_id) 
    WHERE es_predeterminada = TRUE;

-- Comentarios sobre la tabla
COMMENT ON TABLE direcciones IS 'Tabla para almacenar las direcciones de los clientes';
COMMENT ON COLUMN direcciones.id IS 'Identificador único de la dirección';
COMMENT ON COLUMN direcciones.usuario_id IS 'Email del usuario (referencia a tabla usuarios)';
COMMENT ON COLUMN direcciones.nombre IS 'Nombre descriptivo de la dirección (ej: Casa, Trabajo)';
COMMENT ON COLUMN direcciones.direccion IS 'Dirección física completa';
COMMENT ON COLUMN direcciones.referencias IS 'Referencias adicionales para ubicar la dirección';
COMMENT ON COLUMN direcciones.latitud IS 'Coordenada de latitud (opcional)';
COMMENT ON COLUMN direcciones.longitud IS 'Coordenada de longitud (opcional)';
COMMENT ON COLUMN direcciones.es_predeterminada IS 'Indica si es la dirección predeterminada del usuario';
COMMENT ON COLUMN direcciones.fecha_creacion IS 'Fecha de creación del registro';
COMMENT ON COLUMN direcciones.fecha_actualizacion IS 'Fecha de última actualización'; 