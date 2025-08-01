# Backend Integration - Configuración

## 🔧 Configuración del Backend

### 1. Variables de Entorno

Copia el archivo `backend/env.example` a `backend/.env` y configura las variables:

```bash
# En el directorio backend
cp env.example .env
```

Edita el archivo `.env` con tus credenciales reales:

```env
# Configuración de la base de datos
SUPABASE_URL=tu_url_de_supabase
SUPABASE_ANON_KEY=tu_clave_anonima_de_supabase

# Configuración de JWT
JWT_SECRET=tu_jwt_secret_muy_seguro

# Configuración de Twilio
TWILIO_ACCOUNT_SID=tu_account_sid_de_twilio
TWILIO_AUTH_TOKEN=tu_auth_token_de_twilio
TWILIO_SERVICE_SID=tu_service_sid_de_twilio

# Configuración del servidor
PORT=3000
NODE_ENV=development
```

### 2. Instalación de Dependencias

```bash
cd backend
npm install
```

### 3. Iniciar el Servidor

```bash
npm start
```

El servidor estará disponible en `http://localhost:3000`

## 🔒 Seguridad

- ✅ Las credenciales de Twilio están en variables de entorno
- ✅ JWT secret configurado
- ✅ Rate limiting activado
- ✅ CORS configurado
- ✅ Helmet para seguridad HTTP

## 📡 Endpoints Disponibles

### Autenticación
- `POST /api/auth/login` - Login de usuario
- `POST /api/auth/register` - Registro de usuario
- `POST /api/auth/check-email` - Verificar email existente
- `GET /api/auth/me` - Obtener información del usuario

### Twilio
- `POST /api/twilio/send-code` - Enviar código SMS
- `POST /api/twilio/verify-code` - Verificar código SMS

### Otros
- `GET /api/negocios` - Obtener negocios
- `GET /api/productos` - Obtener productos
- `GET /api/pedidos` - Obtener pedidos
- `GET /api/direcciones` - Obtener direcciones
- `GET /api/carrito` - Obtener carrito

## 🚀 Desarrollo

Para desarrollo local, asegúrate de:

1. Tener Node.js instalado
2. Configurar las variables de entorno
3. Tener acceso a Supabase
4. Tener una cuenta de Twilio (para SMS)

## 📝 Notas

- Las credenciales de Twilio están protegidas en variables de entorno
- El sistema usa JWT para autenticación
- Todas las operaciones pasan por el backend
- Twilio requiere números verificados en cuentas de prueba 