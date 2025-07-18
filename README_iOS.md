# Configuración iOS - App Móvil Multirol

## 📱 **Estado actual: Configurado para iOS**

La aplicación está configurada para funcionar en iOS con las siguientes características:

### ✅ **Funcionalidades habilitadas:**
- ✅ Firebase Firestore (base de datos)
- ✅ Firebase Auth (autenticación)
- ✅ Notificaciones locales nativas
- ✅ Permisos de ubicación
- ✅ Google Maps
- ✅ Navegación con GoRouter
- ✅ Gestión de estado con Provider

### 🔧 **Configuración realizada:**

#### 1. **Info.plist actualizado**
- Permisos de notificaciones locales
- Permisos de ubicación
- Modos de fondo para notificaciones

#### 2. **AppDelegate.swift configurado**
- Inicialización de Firebase
- Configuración de notificaciones
- Manejo de notificaciones en primer plano

#### 3. **Podfile optimizado**
- iOS 14.0 como versión mínima
- Configuración de permisos
- Compatibilidad con dependencias

#### 4. **GoogleService-Info.plist**
- Configuración de Firebase para iOS
- Proyecto: `abonosapp-6507a`

## 🚀 **Para compilar en iOS:**

### **Requisitos:**
- macOS con Xcode 14+
- iOS 14.0+ como target
- Dispositivo físico o simulador iOS

### **Comandos:**
```bash
# Instalar dependencias
flutter pub get

# Instalar pods de iOS
cd ios
pod install
cd ..

# Compilar para iOS
flutter build ios --release

# O para desarrollo
flutter run
```

### **Para distribuir:**
```bash
# Crear archivo IPA
flutter build ipa --release
```

## ⚠️ **Notas importantes:**

1. **Firebase**: La app usa el proyecto `abonosapp-6507a` para iOS
2. **Bundle ID**: `com.example.movil` (cambiar para producción)
3. **Permisos**: Se solicitan automáticamente al iniciar la app
4. **Notificaciones**: Funcionan en primer plano y segundo plano

## 🔍 **Solución de problemas:**

### **Error de pods:**
```bash
cd ios
pod deintegrate
pod install
```

### **Error de certificados:**
- Configurar certificados en Xcode
- Verificar Bundle ID en Apple Developer

### **Error de Firebase:**
- Verificar `GoogleService-Info.plist` en Xcode
- Asegurar que esté incluido en el target

## 📋 **Próximos pasos para producción:**

1. Cambiar Bundle ID a uno único
2. Configurar certificados de distribución
3. Actualizar `GoogleService-Info.plist` con proyecto de producción
4. Configurar App Store Connect
5. Probar en dispositivos físicos

---

**Estado: ✅ Listo para desarrollo y pruebas en iOS** 