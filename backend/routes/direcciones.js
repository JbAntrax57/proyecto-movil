const express = require('express');
const { supabase } = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/direcciones/:usuarioId - Obtener direcciones de un usuario
router.get('/:usuarioId', async (req, res) => {
  try {
    const { usuarioId } = req.params;

    console.log('🔍 GET /api/direcciones/:usuarioId - Usuario ID:', usuarioId);

    const { data, error } = await supabase
      .from('direcciones')
      .select('*')
      .eq('usuario_id', usuarioId)
      .order('es_predeterminada', { ascending: false })
      .order('fecha_creacion', { ascending: false });

    if (error) {
      console.error('❌ Error obteniendo direcciones:', error);
      return res.status(500).json({
        error: 'Error al obtener direcciones',
        message: 'No se pudieron obtener las direcciones'
      });
    }

    console.log('🔍 GET /api/direcciones/:usuarioId - Direcciones encontradas:', data?.length || 0);

    res.json({
      success: true,
      data: data || []
    });

  } catch (error) {
    console.error('❌ Error en direcciones:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de direcciones'
    });
  }
});

// GET /api/direcciones/:usuarioId/:id - Obtener dirección específica
router.get('/:usuarioId/:id', authenticateToken, async (req, res) => {
  try {
    const { usuarioId, id } = req.params;

    // Verificar que el usuario autenticado es el propietario de la dirección
    if (req.user.id !== usuarioId && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para ver esta dirección'
      });
    }

    const { data, error } = await supabase
      .from('direcciones')
      .select('*')
      .eq('id', id)
      .eq('usuario_id', usuarioId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          error: 'Dirección no encontrada',
          message: 'La dirección especificada no existe'
        });
      }
      
      console.error('Error obteniendo dirección:', error);
      return res.status(500).json({
        error: 'Error al obtener dirección',
        message: 'No se pudo obtener la dirección'
      });
    }

    res.json({
      success: true,
      data: data
    });

  } catch (error) {
    console.error('Error en dirección específica:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de la dirección'
    });
  }
});

// POST /api/direcciones - Crear nueva dirección
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { 
      usuario_id, 
      nombre, 
      direccion, 
      referencias, 
      latitud, 
      longitud, 
      es_predeterminada = false 
    } = req.body;

    // Verificar que el usuario autenticado es el propietario
    if (req.user.id !== usuario_id && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para crear direcciones para este usuario'
      });
    }

    // Si la nueva dirección es predeterminada, quitar predeterminada de otras
    if (es_predeterminada) {
      await supabase
        .from('direcciones')
        .update({ es_predeterminada: false })
        .eq('usuario_id', usuario_id)
        .eq('es_predeterminada', true);
    }

    const { data, error } = await supabase
      .from('direcciones')
      .insert({
        usuario_id,
        nombre,
        direccion,
        referencias,
        latitud,
        longitud,
        es_predeterminada,
        fecha_creacion: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('Error creando dirección:', error);
      return res.status(500).json({
        error: 'Error al crear dirección',
        message: 'No se pudo crear la dirección'
      });
    }

    res.status(201).json({
      success: true,
      message: 'Dirección creada exitosamente',
      data: data
    });

  } catch (error) {
    console.error('Error creando dirección:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al crear la dirección'
    });
  }
});

// PUT /api/direcciones/:id - Actualizar dirección
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      nombre, 
      direccion, 
      referencias, 
      latitud, 
      longitud, 
      es_predeterminada 
    } = req.body;

    // Obtener la dirección actual para verificar el propietario
    const { data: direccionActual, error: getError } = await supabase
      .from('direcciones')
      .select('usuario_id')
      .eq('id', id)
      .single();

    if (getError) {
      return res.status(404).json({
        error: 'Dirección no encontrada',
        message: 'La dirección especificada no existe'
      });
    }

    // Verificar que el usuario autenticado es el propietario
    if (req.user.id !== direccionActual.usuario_id && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para modificar esta dirección'
      });
    }

    // Si la dirección se marca como predeterminada, quitar predeterminada de otras
    if (es_predeterminada) {
      await supabase
        .from('direcciones')
        .update({ es_predeterminada: false })
        .eq('usuario_id', direccionActual.usuario_id)
        .eq('es_predeterminada', true)
        .neq('id', id);
    }

    const { data, error } = await supabase
      .from('direcciones')
      .update({
        nombre,
        direccion,
        referencias,
        latitud,
        longitud,
        es_predeterminada,
        fecha_actualizacion: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Error actualizando dirección:', error);
      return res.status(500).json({
        error: 'Error al actualizar dirección',
        message: 'No se pudo actualizar la dirección'
      });
    }

    res.json({
      success: true,
      message: 'Dirección actualizada exitosamente',
      data: data
    });

  } catch (error) {
    console.error('Error actualizando dirección:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al actualizar la dirección'
    });
  }
});

// DELETE /api/direcciones/:id - Eliminar dirección
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Obtener la dirección actual para verificar el propietario
    const { data: direccionActual, error: getError } = await supabase
      .from('direcciones')
      .select('usuario_id')
      .eq('id', id)
      .single();

    if (getError) {
      return res.status(404).json({
        error: 'Dirección no encontrada',
        message: 'La dirección especificada no existe'
      });
    }

    // Verificar que el usuario autenticado es el propietario
    if (req.user.id !== direccionActual.usuario_id && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para eliminar esta dirección'
      });
    }

    const { error } = await supabase
      .from('direcciones')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Error eliminando dirección:', error);
      return res.status(500).json({
        error: 'Error al eliminar dirección',
        message: 'No se pudo eliminar la dirección'
      });
    }

    res.json({
      success: true,
      message: 'Dirección eliminada exitosamente'
    });

  } catch (error) {
    console.error('Error eliminando dirección:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al eliminar la dirección'
    });
  }
});

// PUT /api/direcciones/:id/predeterminada - Marcar dirección como predeterminada
router.put('/:id/predeterminada', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Obtener la dirección actual para verificar el propietario
    const { data: direccionActual, error: getError } = await supabase
      .from('direcciones')
      .select('usuario_id')
      .eq('id', id)
      .single();

    if (getError) {
      return res.status(404).json({
        error: 'Dirección no encontrada',
        message: 'La dirección especificada no existe'
      });
    }

    // Verificar que el usuario autenticado es el propietario
    if (req.user.id !== direccionActual.usuario_id && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para modificar esta dirección'
      });
    }

    // Quitar predeterminada de todas las direcciones del usuario
    await supabase
      .from('direcciones')
      .update({ es_predeterminada: false })
      .eq('usuario_id', direccionActual.usuario_id);

    // Marcar la dirección específica como predeterminada
    const { data, error } = await supabase
      .from('direcciones')
      .update({
        es_predeterminada: true,
        fecha_actualizacion: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Error marcando dirección como predeterminada:', error);
      return res.status(500).json({
        error: 'Error al marcar dirección como predeterminada',
        message: 'No se pudo marcar la dirección como predeterminada'
      });
    }

    res.json({
      success: true,
      message: 'Dirección marcada como predeterminada',
      data: data
    });

  } catch (error) {
    console.error('Error marcando dirección como predeterminada:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al marcar la dirección como predeterminada'
    });
  }
});

module.exports = router; 