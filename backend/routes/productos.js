const express = require('express');
const { supabase } = require('../config/supabase');

const router = express.Router();

// GET /api/productos - Obtener productos con filtros
router.get('/', async (req, res) => {
  try {
    const { 
      negocioId, 
      activo = true, 
      categoria,
      search,
      page = 1, 
      limit = 20 
    } = req.query;
    
    let query = supabase
      .from('productos')
      .select('*')
      .order('nombre');

    // Filtrar por negocio
    if (negocioId) {
      query = query.eq('restaurante_id', negocioId);
    }

    // Filtrar por estado activo
    if (activo !== undefined) {
      query = query.eq('activo', activo === 'true');
    }

    // Filtrar por categoría
    if (categoria) {
      query = query.eq('categoria', categoria);
    }

    // Búsqueda por nombre o descripción
    if (search) {
      query = query.or(`nombre.ilike.%${search}%,descripcion.ilike.%${search}%`);
    }

    // Aplicar paginación
    const offset = (page - 1) * limit;
    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) {
      console.error('Error obteniendo productos:', error);
      return res.status(500).json({
        error: 'Error al obtener productos',
        message: 'No se pudieron obtener los productos'
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
    console.error('Error en productos:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de productos'
    });
  }
});

// GET /api/productos/:id - Obtener producto específico
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await supabase
      .from('productos')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          error: 'Producto no encontrado',
          message: 'El producto especificado no existe'
        });
      }
      
      console.error('Error obteniendo producto:', error);
      return res.status(500).json({
        error: 'Error al obtener producto',
        message: 'No se pudo obtener el producto'
      });
    }

    res.json({
      success: true,
      data: data
    });

  } catch (error) {
    console.error('Error en producto específico:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud del producto'
    });
  }
});

// GET /api/productos/negocio/:negocioId - Obtener productos de un negocio específico
router.get('/negocio/:negocioId', async (req, res) => {
  try {
    const { negocioId } = req.params;
    const { activo = true } = req.query;

    let query = supabase
      .from('productos')
      .select('*')
      .eq('restaurante_id', negocioId)
      .order('nombre');

    if (activo !== undefined) {
      query = query.eq('activo', activo === 'true');
    }

    const { data, error } = await query;

    if (error) {
      console.error('Error obteniendo productos del negocio:', error);
      return res.status(500).json({
        error: 'Error al obtener productos',
        message: 'No se pudieron obtener los productos del negocio'
      });
    }

    res.json({
      success: true,
      data: data || []
    });

  } catch (error) {
    console.error('Error en productos del negocio:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de productos del negocio'
    });
  }
});

module.exports = router; 