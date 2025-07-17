# Proyecto Flutter: movil

Este proyecto es una base mínima creada con Flutter para probar en iOS.

## Requisitos previos

1. **Flutter SDK**
   - Descárgalo desde [flutter.dev](https://docs.flutter.dev/get-started/install/macos)
   - Descomprime y agrega Flutter a tu PATH:
     ```bash
     export PATH="$PATH:/ruta/a/flutter/bin"
     ```
   - Verifica la instalación:
     ```bash
     flutter --version
     ```

2. **Xcode** (desde la App Store)
   - Necesario para compilar y correr en iOS.
   - Abre Xcode una vez instalado y acepta los términos.
   - Instala las Command Line Tools:
     ```bash
     xcode-select --install
     ```

3. **CocoaPods** (si no lo tienes, sigue las instrucciones del README de React Native)

## Crear el proyecto (ya hecho si tienes esta carpeta)

```bash
flutter create movil
```

## Ejecutar en iOS (simulador)

**IMPORTANTE: Primero debes abrir el simulador de iOS**
1. Abre el simulador:
   ```bash
   open -a Simulator
   ```
   O desde Xcode: "Xcode" → "Open Developer Tool → Simulator"

2. En el simulador, ve a Device →iOS" y selecciona un iPhone

3. Asegúrate de que el dispositivo esté disponible:
   ```bash
   flutter devices
   ```
4. Ejecuta la app:
   ```bash
   cd movil
   flutter run -d ios
   ```

Esto abrirá la app en el simulador de iOS.

## Código base (movil/lib/main.dart)

El archivo `movil/lib/main.dart` contiene un ejemplo simple para probar que todo funciona.

---

Si tienes algún error, revisa que Xcode y CocoaPods estén correctamente instalados y actualizados. 