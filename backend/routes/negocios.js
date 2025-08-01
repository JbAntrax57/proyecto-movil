const express = require('express');
const { supabase } = require('../config/supabase');

const router = express.Router();

// GET /api/negocios - Obtener todos los negocios
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, estado = 'activo', categoria } = req.query;
    
    let query = supabase
      .from('negocios')
      .select('*, negocios_categorias(categoria_id, categorias_principales(nombre))')
      .order('nombre');

    // Filtrar por estado si se especifica (asumiendo que la columna se llama 'activo')
    if (estado) {
      query = query.eq('activo', estado === 'activo');
    }

    // Filtrar por categoría si se especifica
    if (categoria) {
      query = query.select('*, negocios_categorias!inner(categoria_id)')
        .eq('negocios_categorias.categoria_id', categoria);
    }

    // Aplicar paginación
    const offset = (page - 1) * limit;
    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) {
      console.error('Error obteniendo negocios:', error);
      return res.status(500).json({
        error: 'Error al obtener negocios',
        message: 'No se pudieron obtener los negocios'
      });
    }

    res.json({
      success: true,
      data: data || [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count || data?.length || 0
      }
    });

  } catch (error) {
    console.error('Error en negocios:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de negocios'
    });
  }
});

// GET /api/negocios/categorias - Obtener categorías
router.get('/categorias', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('categorias_principales')
      .select('*')
      .eq('activo', true)
      .order('nombre');

    if (error) {
      console.error('Error obteniendo categorías:', error);
      return res.status(500).json({
        error: 'Error al obtener categorías',
        message: 'No se pudieron obtener las categorías'
      });
    }

    res.json({
      success: true,
      data: data || []
    });

  } catch (error) {
    console.error('Error en categorías:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de categorías'
    });
  }
});

// GET /api/negocios/categoria/:categoria - Obtener negocios por categoría
router.get('/categoria/:categoria', async (req, res) => {
  try {
    const { categoria } = req.params;
    const { page = 1, limit = 20 } = req.query;
    
    const { data, error } = await supabase
      .from('negocios')
      .select('*, negocios_categorias(categoria_id, categorias_principales(nombre))')
      .eq('negocios_categorias.categorias_principales.nombre', categoria)
      .eq('activo', true)
      .order('nombre');

    if (error) {
      console.error('Error obteniendo negocios por categoría:', error);
      return res.status(500).json({
        error: 'Error al obtener negocios por categoría',
        message: 'No se pudieron obtener los negocios'
      });
    }

    res.json({
      success: true,
      data: data || []
    });

  } catch (error) {
    console.error('Error en negocios por categoría:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de negocios por categoría'
    });
  }
});

// GET /api/negocios/:id - Obtener negocio específico
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await supabase
      .from('negocios')
      .select('*, negocios_categorias(categoria_id, categorias_principales(nombre))')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          error: 'Negocio no encontrado',
          message: 'El negocio especificado no existe'
        });
      }
      
      console.error('Error obteniendo negocio:', error);
      return res.status(500).json({
        error: 'Error al obtener negocio',
        message: 'No se pudo obtener el negocio'
      });
    }

    res.json({
      success: true,
      data: data
    });

  } catch (error) {
    console.error('Error en negocio específico:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud del negocio'
    });
  }
});

// GET /api/negocios/:id/productos - Obtener productos de un negocio
router.get('/:id/productos', async (req, res) => {
  try {
    const { id } = req.params;
    const { activo } = req.query;

    console.log('🔍 GET /api/negocios/:id/productos - Negocio ID:', id);
    console.log('🔍 GET /api/negocios/:id/productos - Parámetro activo:', activo);

    let query = supabase
      .from('productos')
      .select('*')
      .eq('restaurante_id', id)
      .order('nombre');

    // Solo filtrar por activo si se especifica explícitamente
    if (activo !== undefined) {
      const activoBool = activo === 'true' || activo === true;
      console.log('🔍 GET /api/negocios/:id/productos - Filtrando por activo:', activoBool);
      query = query.eq('activo', activoBool);
    } else {
      console.log('🔍 GET /api/negocios/:id/productos - No filtrando por activo, trayendo todos');
    }

    const { data, error } = await query;

    if (error) {
      console.error('❌ Error obteniendo productos:', error);
      return res.status(500).json({
        error: 'Error al obtener productos',
        message: 'No se pudieron obtener los productos'
      });
    }

    console.log('🔍 GET /api/negocios/:id/productos - Productos encontrados:', data?.length || 0);
    if (data && data.length > 0) {
      const activos = data.filter(p => p.activo === true);
      const inactivos = data.filter(p => p.activo === false);
      console.log('🔍 GET /api/negocios/:id/productos - Activos:', activos.length, 'Inactivos:', inactivos.length);
    }

    res.json({
      success: true,
      data: data || []
    });

  } catch (error) {
    console.error('❌ Error en productos del negocio:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de productos'
    });
  }
});

// GET /api/negocios/:id/dueno - Obtener dueño del negocio
router.get('/:id/dueno', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data, error } = await supabase
      .from('usuarios')
      .select('id, name, email')
      .eq('restaurante_id', id)
      .eq('rol', 'duenio')
      .limit(1)
      .maybeSingle();

    if (error) {
      console.error('Error obteniendo dueño del negocio:', error);
      return res.status(500).json({
        error: 'Error al obtener dueño del negocio',
        message: 'No se pudo obtener la información del dueño'
      });
    }

    res.json({
      success: true,
      data: data || null
    });

  } catch (error) {
    console.error('Error en dueño del negocio:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud del dueño'
    });
  }
});

module.exports = router; 