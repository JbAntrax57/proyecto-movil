const express = require('express');
const { supabase } = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/carrito/:userEmail - Obtener carrito de un usuario
router.get('/:userEmail', authenticateToken, async (req, res) => {
  try {
    const { userEmail } = req.params;

    // Verificar que el usuario autenticado es el propietario del carrito
    if (req.user.email !== userEmail && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para ver este carrito'
      });
    }

    // Obtener el carrito más reciente del usuario
    const { data: carrito, error } = await supabase
      .from('carritos')
      .select('carrito')
      .eq('email', userEmail)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        // No se encontró carrito, devolver lista vacía
        return res.json({
          success: true,
          data: []
        });
      }
      
      console.error('Error obteniendo carrito:', error);
      return res.status(500).json({
        error: 'Error al obtener carrito',
        message: 'No se pudo obtener el carrito'
      });
    }

    // Parsear el carrito
    let items = [];
    if (carrito.carrito) {
      try {
        if (typeof carrito.carrito === 'string') {
          items = JSON.parse(carrito.carrito);
        } else {
          items = carrito.carrito;
        }
      } catch (e) {
        console.error('Error parseando carrito:', e);
        items = [];
      }
    }

    res.json({
      success: true,
      data: items
    });

  } catch (error) {
    console.error('Error en carrito:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud del carrito'
    });
  }
});

// POST /api/carrito/agregar - Agregar item al carrito
router.post('/agregar', authenticateToken, async (req, res) => {
  try {
    const { userEmail, productoId, cantidad, opciones } = req.body;

    // Verificar que el usuario autenticado es el propietario del carrito
    if (req.user.email !== userEmail && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para modificar este carrito'
      });
    }

    // Obtener información del producto
    const { data: producto, error: productoError } = await supabase
      .from('productos')
      .select('*')
      .eq('id', productoId)
      .single();

    if (productoError || !producto) {
      return res.status(404).json({
        error: 'Producto no encontrado',
        message: 'El producto especificado no existe'
      });
    }

    // Obtener el carrito actual
    const { data: carritoActual, error: carritoError } = await supabase
      .from('carritos')
      .select('id, carrito')
      .eq('email', userEmail)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single();

    let items = [];
    let carritoId = null;

    if (carritoError && carritoError.code !== 'PGRST116') {
      console.error('Error obteniendo carrito:', carritoError);
      return res.status(500).json({
        error: 'Error al obtener carrito',
        message: 'No se pudo obtener el carrito'
      });
    }

    if (carritoActual) {
      carritoId = carritoActual.id;
      try {
        if (typeof carritoActual.carrito === 'string') {
          items = JSON.parse(carritoActual.carrito);
        } else {
          items = carritoActual.carrito || [];
        }
      } catch (e) {
        console.error('Error parseando carrito:', e);
        items = [];
      }
    }

    // Buscar si el producto ya existe en el carrito
    const existingIndex = items.findIndex(item => item.id === productoId);

    if (existingIndex !== -1) {
      // Actualizar cantidad del producto existente
      items[existingIndex].cantidad = (items[existingIndex].cantidad || 0) + cantidad;
    } else {
      // Agregar nuevo producto al carrito
      items.push({
        id: producto.id,
        nombre: producto.nombre,
        precio: producto.precio,
        cantidad: cantidad,
        negocio_id: producto.restaurante_id,
        opciones: opciones || {}
      });
    }

    // Guardar carrito actualizado
    const carritoData = {
      email: userEmail,
      carrito: items,
      updated_at: new Date().toISOString()
    };

    if (carritoId) {
      // Actualizar carrito existente
      const { error: updateError } = await supabase
        .from('carritos')
        .update(carritoData)
        .eq('id', carritoId);

      if (updateError) {
        console.error('Error actualizando carrito:', updateError);
        return res.status(500).json({
          error: 'Error al actualizar carrito',
          message: 'No se pudo actualizar el carrito'
        });
      }
    } else {
      // Crear nuevo carrito
      const { error: insertError } = await supabase
        .from('carritos')
        .insert(carritoData);

      if (insertError) {
        console.error('Error creando carrito:', insertError);
        return res.status(500).json({
          error: 'Error al crear carrito',
          message: 'No se pudo crear el carrito'
        });
      }
    }

    res.json({
      success: true,
      message: 'Producto agregado al carrito',
      data: items
    });

  } catch (error) {
    console.error('Error agregando al carrito:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al agregar producto al carrito'
    });
  }
});

// PUT /api/carrito/actualizar - Actualizar cantidad de un item
router.put('/actualizar', authenticateToken, async (req, res) => {
  try {
    const { userEmail, itemId, cantidad } = req.body;

    // Verificar que el usuario autenticado es el propietario del carrito
    if (req.user.email !== userEmail && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para modificar este carrito'
      });
    }

    // Obtener el carrito actual
    const { data: carritoActual, error: carritoError } = await supabase
      .from('carritos')
      .select('id, carrito')
      .eq('email', userEmail)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single();

    if (carritoError || !carritoActual) {
      return res.status(404).json({
        error: 'Carrito no encontrado',
        message: 'No se encontró el carrito'
      });
    }

    let items = [];
    try {
      if (typeof carritoActual.carrito === 'string') {
        items = JSON.parse(carritoActual.carrito);
      } else {
        items = carritoActual.carrito || [];
      }
    } catch (e) {
      console.error('Error parseando carrito:', e);
      return res.status(500).json({
        error: 'Error al procesar carrito',
        message: 'Error al procesar el carrito'
      });
    }

    // Buscar y actualizar el item
    const itemIndex = items.findIndex(item => item.id === itemId);
    if (itemIndex === -1) {
      return res.status(404).json({
        error: 'Item no encontrado',
        message: 'El item especificado no existe en el carrito'
      });
    }

    items[itemIndex].cantidad = cantidad;

    // Guardar carrito actualizado
    const { error: updateError } = await supabase
      .from('carritos')
      .update({
        carrito: items,
        updated_at: new Date().toISOString()
      })
      .eq('id', carritoActual.id);

    if (updateError) {
      console.error('Error actualizando carrito:', updateError);
      return res.status(500).json({
        error: 'Error al actualizar carrito',
        message: 'No se pudo actualizar el carrito'
      });
    }

    res.json({
      success: true,
      message: 'Cantidad actualizada',
      data: items
    });

  } catch (error) {
    console.error('Error actualizando carrito:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al actualizar el carrito'
    });
  }
});

// DELETE /api/carrito/eliminar - Eliminar item del carrito
router.delete('/eliminar', authenticateToken, async (req, res) => {
  try {
    const { userEmail, itemId } = req.body;

    // Verificar que el usuario autenticado es el propietario del carrito
    if (req.user.email !== userEmail && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para modificar este carrito'
      });
    }

    // Obtener el carrito actual
    const { data: carritoActual, error: carritoError } = await supabase
      .from('carritos')
      .select('id, carrito')
      .eq('email', userEmail)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single();

    if (carritoError || !carritoActual) {
      return res.status(404).json({
        error: 'Carrito no encontrado',
        message: 'No se encontró el carrito'
      });
    }

    let items = [];
    try {
      if (typeof carritoActual.carrito === 'string') {
        items = JSON.parse(carritoActual.carrito);
      } else {
        items = carritoActual.carrito || [];
      }
    } catch (e) {
      console.error('Error parseando carrito:', e);
      return res.status(500).json({
        error: 'Error al procesar carrito',
        message: 'Error al procesar el carrito'
      });
    }

    // Filtrar el item a eliminar
    const filteredItems = items.filter(item => item.id !== itemId);

    // Guardar carrito actualizado
    const { error: updateError } = await supabase
      .from('carritos')
      .update({
        carrito: filteredItems,
        updated_at: new Date().toISOString()
      })
      .eq('id', carritoActual.id);

    if (updateError) {
      console.error('Error actualizando carrito:', updateError);
      return res.status(500).json({
        error: 'Error al actualizar carrito',
        message: 'No se pudo actualizar el carrito'
      });
    }

    res.json({
      success: true,
      message: 'Item eliminado del carrito',
      data: filteredItems
    });

  } catch (error) {
    console.error('Error eliminando del carrito:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al eliminar item del carrito'
    });
  }
});

// DELETE /api/carrito/limpiar/:userEmail - Limpiar carrito completo
router.delete('/limpiar/:userEmail', authenticateToken, async (req, res) => {
  try {
    const { userEmail } = req.params;

    // Verificar que el usuario autenticado es el propietario del carrito
    if (req.user.email !== userEmail && req.user.rol !== 'admin') {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para modificar este carrito'
      });
    }

    // Eliminar todos los carritos del usuario
    const { error } = await supabase
      .from('carritos')
      .delete()
      .eq('email', userEmail);

    if (error) {
      console.error('Error limpiando carrito:', error);
      return res.status(500).json({
        error: 'Error al limpiar carrito',
        message: 'No se pudo limpiar el carrito'
      });
    }

    res.json({
      success: true,
      message: 'Carrito limpiado exitosamente',
      data: []
    });

  } catch (error) {
    console.error('Error limpiando carrito:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al limpiar el carrito'
    });
  }
});

module.exports = router; 