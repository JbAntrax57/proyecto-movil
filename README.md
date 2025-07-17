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

## Verifica que estés en la carpeta correcta

Antes de ejecutar la app, asegúrate de estar en la carpeta del proyecto Flutter. Puedes hacerlo con los siguientes comandos:

1. Verifica tu ubicación actual:
   ```bash
   pwd
   ```
   Esto debe mostrar una ruta similar a:
   `/Users/carloslopez/Downloads/movil/movil`

2. Lista los archivos y carpetas en tu ubicación:
   ```bash
   ls
   ```
   Debes ver archivos como `pubspec.yaml` y la carpeta `lib`.

3. Si no estás en la carpeta correcta, navega hasta ella:
   ```bash
   cd /Users/carloslopez/Downloads/movil/movil
   ```

## Ejecutar en iOS (simulador)

**IMPORTANTE: Primero debes abrir el simulador de iOS**
1. Abre el simulador:
   ```bash
   open -a Simulator
   ```
   O desde Xcode: "Xcode" → "Open Developer Tool → Simulator"

2. En el simulador, ve a Device → "iOS" y selecciona un iPhone

3. Asegúrate de que el dispositivo esté disponible:
   ```bash
   flutter devices
   ```
4. Ejecuta la app:
   ```bash
   flutter run -d ios
   ```

Esto abrirá la app en el simulador de iOS.

## Recargar la app sin cerrar el emulador (Hot Reload y Hot Restart)

Cuando tengas la app corriendo en el emulador y realices cambios en el código, puedes ver los cambios reflejados rápidamente sin cerrar ni reiniciar el emulador:

- Presiona la tecla **r** en la terminal donde corre Flutter para hacer un **hot reload** (recarga rápida, mantiene el estado de la app).
- Presiona la tecla **R** (mayúscula) para hacer un **hot restart** (recarga completa, reinicia el estado de la app).

Esto te permite desarrollar de forma mucho más ágil y ver los cambios al instante.

## Código base (movil/lib/main.dart)

El archivo `movil/lib/main.dart` contiene un ejemplo simple para probar que todo funciona.

---

Si tienes algún error, revisa que Xcode y CocoaPods estén correctamente instalados y actualizados.

## Subir el proyecto a GitHub

1. Asegúrate de estar en la carpeta del proyecto:
   ```bash
   cd /Users/carloslopez/Downloads/movil/movil
   ```

2. Verifica el estado de los archivos:
   ```bash
   git status
   ```

3. Agrega los archivos modificados:
   ```bash
   git add .
   ```

4. Haz un commit con un mensaje descriptivo:
   ```bash
   git commit -m "Funcionalidad: contador, imagen, y detección de sistema operativo"
   ```

5. Sube los cambios al repositorio remoto:
   - Si ya tienes el repositorio conectado:
     ```bash
     git push
     ```
   - Si aún no lo has conectado, sigue estos pasos (solo la primera vez):
     ```bash
     git remote add origin https://github.com/TU_USUARIO/NOMBRE_DEL_REPO.git
     git branch -M main
     git push -u origin main
     ```
   (Reemplaza TU_USUARIO y NOMBRE_DEL_REPO por los tuyos)

## Instalación de dependencias y ejecución

1. Cuando agregues o cambies dependencias en `pubspec.yaml`, ejecuta:
   ```bash
   flutter pub get
   ```

2. Si tu terminal no reconoce el comando flutter, ejecuta:
   ```bash
   source ~/.zshrc
   flutter --version
   ```
   Así te aseguras de que Flutter esté disponible en la terminal.

3. Navega a la carpeta del proyecto:
   ```bash
   cd /Users/carloslopez/Downloads/movil/movil
   ```

4. Ejecuta la app en iOS:
   ```bash
   flutter run -d ios
   ```
