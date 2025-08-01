const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'tu_jwt_secret_muy_seguro_aqui_para_desarrollo';

// Middleware para verificar token JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      error: 'Token requerido',
      message: 'Se requiere un token de autenticación'
    });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({
        error: 'Token inválido',
        message: 'El token proporcionado no es válido'
      });
    }
    req.user = user;
    next();
  });
};

// Middleware para verificar roles específicos
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'No autenticado',
        message: 'Se requiere autenticación'
      });
    }

    if (!roles.includes(req.user.rol)) {
      return res.status(403).json({
        error: 'Acceso denegado',
        message: 'No tienes permisos para realizar esta acción'
      });
    }

    next();
  };
};

module.exports = {
  authenticateToken,
  requireRole,
  JWT_SECRET
}; 