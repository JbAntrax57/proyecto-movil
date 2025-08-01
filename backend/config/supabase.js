const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://yyjpkxrjwhaueanbteua.supabase.co';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5anBreHJqd2hhdWVhbmJ0ZXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyODUxODUsImV4cCI6MjA2Nzg2MTE4NX0.AqvEVE8Nln4qSIu-Tu0aNpwgK5at7i34vaSyaz9PWJE';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5anBreHJqd2hhdWVhbmJ0ZXVhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjI4NTE4NSwiZXhwIjoyMDY3ODYxMTg1fQ.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8';

// Cliente con permisos de anónimo (para operaciones básicas)
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Cliente con permisos de servicio (para operaciones administrativas)
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

module.exports = {
  supabase,
  supabaseAdmin,
  supabaseUrl,
  supabaseAnonKey,
  supabaseServiceKey
}; 