const express = require('express');
const { supabase } = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/pedidos - Obtener pedidos con filtros
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { 
      usuarioEmail, 
      restauranteId, 
      estado,
      page = 1, 
      limit = 20 
    } = req.query;
    
    let query = supabase
      .from('pedidos')
      .select('*')
      .order('created_at', { ascending: false });

    // Filtrar por usuario
    if (usuarioEmail) {
      query = query.eq('usuario_email', usuarioEmail);
    }

    // Filtrar por restaurante
    if (restauranteId) {
      query = query.eq('restaurante_id', restauranteId);
    }

    // Filtrar por estado
    if (estado) {
      query = query.eq('estado', estado);
    }

    // Aplicar paginación
    const offset = (page - 1) * limit;
    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) {
      console.error('Error obteniendo pedidos:', error);
      return res.status(500).json({
        error: 'Error al obtener pedidos',
        message: 'No se pudieron obtener los pedidos'
      });
    }

    // Si hay pedidos, obtener sus detalles
    let pedidosConDetalles = data || [];
    if (pedidosConDetalles.length > 0) {
      const pedidosIds = pedidosConDetalles.map(p => p.id);
      
      // Obtener todos los detalles de una vez
      const { data: detallesData, error: detallesError } = await supabase
        .from('detalles_pedidos')
        .select('*')
        .in('pedido_id', pedidosIds);

      if (!detallesError && detallesData) {
        // Agrupar detalles por pedido
        const detallesPorPedido = {};
        detallesData.forEach(detalle => {
          if (!detallesPorPedido[detalle.pedido_id]) {
            detallesPorPedido[detalle.pedido_id] = [];
          }
          detallesPorPedido[detalle.pedido_id].push(detalle);
        });

        // Combinar pedidos con sus detalles
        pedidosConDetalles = pedidosConDetalles.map(pedido => ({
          ...pedido,
          productos: detallesPorPedido[pedido.id] || []
        }));
      }
    }

    res.json({
      success: true,
      data: pedidosConDetalles,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count || data?.length || 0
      }
    });

  } catch (error) {
    console.error('Error en pedidos:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de pedidos'
    });
  }
});

// GET /api/pedidos/:id - Obtener pedido específico con detalles
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Obtener el pedido
    const { data: pedido, error: pedidoError } = await supabase
      .from('pedidos')
      .select('*')
      .eq('id', id)
      .single();

    if (pedidoError) {
      if (pedidoError.code === 'PGRST116') {
        return res.status(404).json({
          error: 'Pedido no encontrado',
          message: 'El pedido especificado no existe'
        });
      }
      
      console.error('Error obteniendo pedido:', pedidoError);
      return res.status(500).json({
        error: 'Error al obtener pedido',
        message: 'No se pudo obtener el pedido'
      });
    }

    // Obtener los detalles del pedido
    const { data: detalles, error: detallesError } = await supabase
      .from('detalles_pedidos')
      .select('*')
      .eq('pedido_id', id);

    if (detallesError) {
      console.error('Error obteniendo detalles del pedido:', detallesError);
      return res.status(500).json({
        error: 'Error al obtener detalles del pedido',
        message: 'No se pudieron obtener los detalles del pedido'
      });
    }

    // Combinar pedido con sus detalles
    const pedidoConDetalles = {
      ...pedido,
      productos: detalles || []
    };

    res.json({
      success: true,
      data: pedidoConDetalles
    });

  } catch (error) {
    console.error('Error en pedido específico:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud del pedido'
    });
  }
});

// POST /api/pedidos - Crear nuevo pedido
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { 
      usuario_email, 
      restaurante_id, 
      direccion_entrega,
      productos,
      total,
      notas 
    } = req.body;

    // Validar datos requeridos
    if (!usuario_email || !restaurante_id || !productos || productos.length === 0) {
      return res.status(400).json({
        error: 'Datos incompletos',
        message: 'Faltan datos requeridos para crear el pedido'
      });
    }

    // Crear el pedido
    const { data: pedido, error: pedidoError } = await supabase
      .from('pedidos')
      .insert({
        usuario_email,
        restaurante_id,
        direccion_entrega,
        total,
        notas,
        estado: 'pendiente',
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (pedidoError) {
      console.error('Error creando pedido:', pedidoError);
      return res.status(500).json({
        error: 'Error al crear pedido',
        message: 'No se pudo crear el pedido'
      });
    }

    // Crear los detalles del pedido
    const detalles = productos.map(producto => ({
      pedido_id: pedido.id,
      producto_id: producto.id,
      cantidad: producto.cantidad,
      precio_unitario: producto.precio,
      subtotal: producto.precio * producto.cantidad,
      opciones: producto.opciones || {}
    }));

    const { error: detallesError } = await supabase
      .from('detalles_pedidos')
      .insert(detalles);

    if (detallesError) {
      console.error('Error creando detalles del pedido:', detallesError);
      // Intentar eliminar el pedido creado
      await supabase.from('pedidos').delete().eq('id', pedido.id);
      
      return res.status(500).json({
        error: 'Error al crear detalles del pedido',
        message: 'No se pudieron crear los detalles del pedido'
      });
    }

    res.status(201).json({
      success: true,
      message: 'Pedido creado exitosamente',
      data: pedido
    });

  } catch (error) {
    console.error('Error creando pedido:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al crear el pedido'
    });
  }
});

// PUT /api/pedidos/:id/estado - Actualizar estado del pedido
router.put('/:id/estado', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!estado) {
      return res.status(400).json({
        error: 'Estado requerido',
        message: 'El estado del pedido es requerido'
      });
    }

    const { data, error } = await supabase
      .from('pedidos')
      .update({
        estado,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Error actualizando estado del pedido:', error);
      return res.status(500).json({
        error: 'Error al actualizar estado del pedido',
        message: 'No se pudo actualizar el estado del pedido'
      });
    }

    res.json({
      success: true,
      message: 'Estado del pedido actualizado',
      data: data
    });

  } catch (error) {
    console.error('Error actualizando estado del pedido:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al actualizar el estado del pedido'
    });
  }
});

module.exports = router; 