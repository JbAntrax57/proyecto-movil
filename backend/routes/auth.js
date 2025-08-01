const express = require('express');
const { supabase } = require('../config/supabase');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const router = express.Router();

// Función para hashear contraseña con SHA-256
function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

// POST /api/auth/login - Login de usuario
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        error: 'Datos incompletos',
        message: 'Email y contraseña son requeridos'
      });
    }

    console.log('🔐 POST /api/auth/login - Intentando login para:', email);

    // Buscar usuario en la base de datos
    const { data: userData, error } = await supabase
      .from('usuarios')
      .select('*')
      .eq('email', email)
      .eq('password', hashPassword(password))
      .single();

    if (error || !userData) {
      console.log('❌ POST /api/auth/login - Login fallido para:', email);
      return res.status(401).json({
        error: 'Credenciales inválidas',
        message: 'Email o contraseña incorrectos'
      });
    }

    console.log('✅ POST /api/auth/login - Login exitoso para:', email, 'Rol:', userData.rol);

    // Generar token JWT
    const token = jwt.sign(
      {
        id: userData.user_id || userData.id,
        email: userData.email,
        rol: userData.rol,
        restaurante_id: userData.restaurante_id
      },
      process.env.JWT_SECRET || 'tu_jwt_secret_muy_seguro_aqui_para_desarrollo',
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      message: 'Login exitoso',
      data: {
        token,
        user: {
          id: userData.user_id || userData.id,
          email: userData.email,
          rol: userData.rol,
          restaurante_id: userData.restaurante_id,
          nombre: userData.name
        }
      }
    });

  } catch (error) {
    console.error('❌ Error en login:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar el login'
    });
  }
});

// POST /api/auth/register - Registro de usuario
router.post('/register', async (req, res) => {
  try {
    const { email, password, nombre, rol = 'cliente', telefono, direccion } = req.body;

    if (!email || !password || !nombre) {
      return res.status(400).json({
        error: 'Datos incompletos',
        message: 'Email, contraseña y nombre son requeridos'
      });
    }

    console.log('🔐 POST /api/auth/register - Intentando registro para:', email);

    // Verificar si el usuario ya existe
    const { data: existingUser } = await supabase
      .from('usuarios')
      .select('id')
      .eq('email', email)
      .single();

    if (existingUser) {
      return res.status(409).json({
        error: 'Usuario ya existe',
        message: 'Ya existe un usuario con este email'
      });
    }

    // Crear nuevo usuario
    const userData = {
      email,
      password: hashPassword(password),
      name: nombre,
      rol,
      created_at: new Date().toISOString(),
      phone_verified: true
    };

    // Agregar campos opcionales si están presentes
    if (telefono) {
      userData.telephone = telefono;
    }
    if (direccion) {
      userData.direccion = direccion;
    }

    const { data: newUser, error } = await supabase
      .from('usuarios')
      .insert(userData)
      .select()
      .single();

    if (error) {
      console.error('❌ Error creando usuario:', error);
      return res.status(500).json({
        error: 'Error al crear usuario',
        message: 'No se pudo crear el usuario'
      });
    }

    console.log('✅ POST /api/auth/register - Registro exitoso para:', email);

    // Generar token JWT
    const token = jwt.sign(
      {
        id: newUser.user_id || newUser.id,
        email: newUser.email,
        rol: newUser.rol
      },
      process.env.JWT_SECRET || 'tu_jwt_secret_muy_seguro_aqui_para_desarrollo',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'Usuario registrado exitosamente',
      data: {
        token,
        user: {
          id: newUser.user_id || newUser.id,
          email: newUser.email,
          rol: newUser.rol,
          nombre: newUser.name,
          telefono: newUser.telephone,
          direccion: newUser.direccion
        }
      }
    });

  } catch (error) {
    console.error('❌ Error en registro:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al procesar el registro'
    });
  }
});

// GET /api/auth/me - Obtener información del usuario actual
router.get('/me', async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        error: 'Token requerido',
        message: 'Se requiere un token de autenticación'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'tu_jwt_secret_muy_seguro_aqui_para_desarrollo');
    
    // Obtener información actualizada del usuario
    const { data: userData, error } = await supabase
      .from('usuarios')
      .select('*')
      .eq('user_id', decoded.id)
      .single();

    if (error || !userData) {
      return res.status(404).json({
        error: 'Usuario no encontrado',
        message: 'El usuario no existe'
      });
    }

    res.json({
      success: true,
      data: {
        id: userData.user_id || userData.id,
        email: userData.email,
        rol: userData.rol,
        restaurante_id: userData.restaurante_id,
        nombre: userData.name
      }
    });

  } catch (error) {
    console.error('❌ Error obteniendo información del usuario:', error);
    res.status(401).json({
      error: 'Token inválido',
      message: 'El token proporcionado no es válido'
    });
  }
});

// POST /api/auth/check-email - Verificar si un email ya existe
router.post('/check-email', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: 'Email requerido',
        message: 'Debe proporcionar un email'
      });
    }

    console.log('🔐 POST /api/auth/check-email - Verificando email:', email);

    // Buscar usuario en la base de datos
    const { data: userData, error } = await supabase
      .from('usuarios')
      .select('id')
      .eq('email', email)
      .single();

    const exists = !error && userData;

    console.log('🔐 POST /api/auth/check-email - Email existe:', exists);

    res.json({
      success: true,
      exists: exists
    });

  } catch (error) {
    console.error('❌ Error verificando email:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: 'Error al verificar el email'
    });
  }
});

module.exports = router; 