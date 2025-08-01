const express = require('express');
const { supabase } = require('../config/supabase');

const router = express.Router();

// GET /api/sistema-puntos/:duenoId - Obtener configuración de puntos del dueño
router.get('/:duenoId', async (req, res) => {
  try {
    const { duenoId } = req.params;
    
    const { data, error } = await supabase
      .from('sistema_puntos')
      .select('puntos_por_pedido, puntos_disponibles, total_asignado')
      .eq('dueno_id', duenoId)
      .single();

    if (error) {
      console.error('Error obteniendo puntos del dueño:', error);
      return res.status(500).json({
        error: 'Error al obtener puntos del dueño',
        message: 'No se pudo obtener la información de puntos'
      });
    }

    res.json({
      success: true,
      data: data || {
        puntos_por_pedido: 2,
        puntos_disponibles: 0,
        total_asignado: 0
      }
    });

  } catch (error) {
    console.error('Error en sistema de puntos:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar la solicitud de puntos'
    });
  }
});

module.exports = router; 