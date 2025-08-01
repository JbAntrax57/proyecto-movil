const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const morgan = require('morgan');
require('dotenv').config();

// Importar rutas
const authRoutes = require('./routes/auth');
const twilioRoutes = require('./routes/twilio');
const negociosRoutes = require('./routes/negocios');
const productosRoutes = require('./routes/productos');
const pedidosRoutes = require('./routes/pedidos');
const direccionesRoutes = require('./routes/direcciones');
const carritoRoutes = require('./routes/carrito');
const sistemaPuntosRoutes = require('./routes/sistema-puntos');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración de seguridad
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// Configuración de CORS
const corsOptions = {
  origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : ['http://localhost:3000', 'http://localhost:8080'],
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutos
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // máximo 100 requests por ventana
  message: {
    error: 'Demasiadas peticiones desde esta IP, intenta de nuevo más tarde.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Middleware
app.use(compression());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rutas
app.use('/api/auth', authRoutes);
app.use('/api/twilio', twilioRoutes);
app.use('/api/negocios', negociosRoutes);
app.use('/api/productos', productosRoutes);
app.use('/api/pedidos', pedidosRoutes);
app.use('/api/direcciones', direccionesRoutes);
app.use('/api/carrito', carritoRoutes);
app.use('/api/sistema-puntos', sistemaPuntosRoutes);

// Ruta de salud
app.get('/', (req, res) => {
  res.json({
    message: 'API Backend para App Móvil',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      negocios: '/api/negocios',
      productos: '/api/productos',
      pedidos: '/api/pedidos',
      direcciones: '/api/direcciones',
      carrito: '/api/carrito'
    }
  });
});

// Ruta de salud específica
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Middleware de manejo de errores
app.use((err, req, res, next) => {
  console.error('Error no manejado:', err);
  
  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'development' ? err.message : 'Algo salió mal';
  
  res.status(statusCode).json({
    error: 'Error interno del servidor',
    message: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Middleware para rutas no encontradas
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Ruta no encontrada',
    message: `La ruta ${req.originalUrl} no existe`
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
  console.log(`🔒 Modo: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📡 Endpoints disponibles:`);
  console.log(`   - GET  /health`);
  console.log(`   - GET  /api/negocios`);
  console.log(`   - GET  /api/productos`);
  console.log(`   - GET  /api/pedidos`);
  console.log(`   - GET  /api/direcciones`);
  console.log(`   - GET  /api/carrito`);
  console.log(`⚠️  DESARROLLO: Credenciales hardcodeadas activas`);
});

module.exports = app; 