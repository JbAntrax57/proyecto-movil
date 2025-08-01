const express = require('express');
const axios = require('axios');
const crypto = require('crypto');

const router = express.Router();

// Configuración de Twilio
const TWILIO_CONFIG = {
  accountSid: process.env.TWILIO_ACCOUNT_SID,
  authToken: process.env.TWILIO_AUTH_TOKEN,
  serviceSid: process.env.TWILIO_SERVICE_SID,
  baseUrl: 'https://verify.twilio.com/v2/Services',
};

// Verificar que las credenciales estén configuradas
if (!TWILIO_CONFIG.accountSid || !TWILIO_CONFIG.authToken || !TWILIO_CONFIG.serviceSid) {
  console.error('❌ Error: Credenciales de Twilio no configuradas en variables de entorno');
  console.error('Configura: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_SERVICE_SID');
}

// Función para generar código aleatorio de 6 dígitos
function generateRandomCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Función para formatear número de teléfono
function formatPhoneNumber(phoneNumber) {
  // Si el número no empieza con +, agregar código de país por defecto
  if (!phoneNumber.startsWith('+')) {
    const cleanNumber = phoneNumber.replace(/[\s\-\(\)]/g, '');
    
    // Si empieza con 0, removerlo
    if (cleanNumber.startsWith('0')) {
      return `+52${cleanNumber.substring(1)}`;
    }
    
    // Si empieza con 1, agregar código de país
    if (cleanNumber.startsWith('1')) {
      return `+52${cleanNumber}`;
    }
    
    // Si tiene 10 dígitos, agregar código de país
    if (cleanNumber.length === 10) {
      return `+52${cleanNumber}`;
    }
    
    // Si ya tiene código de país, solo agregar +
    if (cleanNumber.length > 10) {
      return `+${cleanNumber}`;
    }
  }
  
  return phoneNumber;
}

// Función para validar formato de número de teléfono
function isValidPhoneNumber(phoneNumber) {
  const cleanNumber = phoneNumber.replace(/[\s\-\(\)]/g, '');
  const digitsOnly = cleanNumber.replace(/\D/g, '');
  return digitsOnly.length >= 10;
}

// POST /api/twilio/send-code - Enviar código de verificación
router.post('/send-code', async (req, res) => {
  try {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({
        error: 'Número de teléfono requerido',
        message: 'Debe proporcionar un número de teléfono'
      });
    }

    if (!isValidPhoneNumber(phoneNumber)) {
      return res.status(400).json({
        error: 'Número de teléfono inválido',
        message: 'El formato del número de teléfono no es válido'
      });
    }

    const formattedPhone = formatPhoneNumber(phoneNumber);
    const customCode = generateRandomCode();

    console.log('📱 POST /api/twilio/send-code - Enviando código a:', formattedPhone);

    const response = await axios.post(
      `${TWILIO_CONFIG.baseUrl}/${TWILIO_CONFIG.serviceSid}/Verifications`,
      {
        To: formattedPhone,
        Channel: 'sms',
      },
      {
        headers: {
          'Authorization': `Basic ${Buffer.from(`${TWILIO_CONFIG.accountSid}:${TWILIO_CONFIG.authToken}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        transformRequest: (data) => {
          return Object.keys(data)
            .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(data[key])}`)
            .join('&');
        },
      }
    );

    console.log('✅ POST /api/twilio/send-code - Código enviado exitosamente');

    res.json({
      success: true,
      message: 'Código de verificación enviado',
      data: {
        phoneNumber: formattedPhone,
        status: response.data.status,
      }
    });

  } catch (error) {
    console.error('❌ Error enviando código de verificación:', error.response?.data || error.message);
    
    res.status(500).json({
      error: 'Error al enviar código',
      message: 'No se pudo enviar el código de verificación',
      details: error.response?.data || error.message
    });
  }
});

// POST /api/twilio/verify-code - Verificar código
router.post('/verify-code', async (req, res) => {
  try {
    const { phoneNumber, code } = req.body;

    if (!phoneNumber || !code) {
      return res.status(400).json({
        error: 'Datos incompletos',
        message: 'Número de teléfono y código son requeridos'
      });
    }

    const formattedPhone = formatPhoneNumber(phoneNumber);

    console.log('📱 POST /api/twilio/verify-code - Verificando código para:', formattedPhone);

    const response = await axios.post(
      `${TWILIO_CONFIG.baseUrl}/${TWILIO_CONFIG.serviceSid}/VerificationCheck`,
      {
        To: formattedPhone,
        Code: code,
      },
      {
        headers: {
          'Authorization': `Basic ${Buffer.from(`${TWILIO_CONFIG.accountSid}:${TWILIO_CONFIG.authToken}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        transformRequest: (data) => {
          return Object.keys(data)
            .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(data[key])}`)
            .join('&');
        },
      }
    );

    if (response.data.status === 'approved') {
      console.log('✅ POST /api/twilio/verify-code - Código verificado exitosamente');
      
      res.json({
        success: true,
        message: 'Número verificado correctamente',
        data: {
          phoneNumber: formattedPhone,
          status: response.data.status,
        }
      });
    } else {
      console.log('❌ POST /api/twilio/verify-code - Código incorrecto');
      
      res.status(400).json({
        error: 'Código incorrecto',
        message: 'El código de verificación no es válido',
        data: {
          status: response.data.status,
        }
      });
    }

  } catch (error) {
    console.error('❌ Error verificando código:', error.response?.data || error.message);
    
    res.status(500).json({
      error: 'Error al verificar código',
      message: 'No se pudo verificar el código',
      details: error.response?.data || error.message
    });
  }
});

module.exports = router; 