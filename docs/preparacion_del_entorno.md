# Preparación del entorno de desarrollo

Esta guía permite preparar una computadora para desarrollar Alerta ACV. Las
versiones exactas se mantienen en [Versiones del stack](versiones_del_stack.md).

## Requisitos comunes

- Git.
- Flutter 3.47.5 con Dart 3.13.4.
- JDK 17.
- Un editor compatible con Flutter y Dart.
- Acceso a un dispositivo físico para validar las integraciones nativas.

FVM es el mecanismo recomendado para seleccionar Flutter por proyecto. No es
obligatorio si el equipo ya tiene instalada exactamente la versión indicada.

## Obtener el proyecto

```bash
git clone https://github.com/AlertaACV/alerta_acv.git
cd alerta_acv
```

Con FVM:

```bash
fvm install
fvm flutter --version
fvm flutter pub get
```

Sin FVM:

```bash
flutter --version
flutter pub get
```

El resultado debe mostrar Flutter 3.47.5 y Dart 3.13.4.

## Android

### Componentes requeridos

- Android SDK Platform 36.
- Android SDK Build Tools 36.0.0.
- Android SDK Command-line Tools.
- Android SDK Platform Tools.
- Android NDK 28.2.13676358.
- JDK 17.

Los componentes pueden instalarse desde Android Studio o mediante
`sdkmanager`. Android Studio es recomendable para administrar emuladores y
depurar, pero no reemplaza las versiones definidas en el repositorio.

### Configurar el JDK

Cuando se usa Flutter directamente:

```bash
flutter config --jdk-dir=/ruta/al/jdk-17
```

Cuando se usa FVM:

```bash
fvm flutter config --jdk-dir=/ruta/al/jdk-17
```

La ruta debe apuntar a la instalación real de JDK 17. El valor de
`.java-version` también puede ser leído automáticamente por gestores como jenv
o mise.

### Licencias y diagnóstico

```bash
flutter doctor --android-licenses
flutter doctor -v
```

Con FVM, sustituir `flutter` por `fvm flutter`. La sección Android debe quedar
sin errores. El aviso de Chrome no bloquea el proyecto porque Web no es una
plataforma soportada.

### Verificar Gradle

La terminal debe usar JDK 17 antes de ejecutar:

```bash
./android/gradlew --version
```

El resultado debe informar Gradle 9.3.1 y una JVM 17.

## iOS

El desarrollo iOS requiere macOS y una versión compatible de Xcode 26.x.

### Componentes requeridos

- Xcode 26.x con iOS SDK 26 o posterior.
- Herramientas de línea de comandos de Xcode.
- Ruby y Bundler.
- CocoaPods 1.17.0, instalado mediante el `Gemfile`.
- Cuenta y configuración de firma de Apple para dispositivos y distribución.

### Preparar Xcode

```bash
sudo xcodebuild -license
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Instalar dependencias nativas

Desde la raíz del repositorio:

```bash
bundle install
cd ios
bundle exec pod install
cd ..
```

Después de instalar los pods, abrir `ios/Runner.xcworkspace` cuando sea
necesario trabajar directamente en Xcode.

### Verificar iOS

```bash
flutter doctor -v
flutter build ios --debug --no-codesign
flutter build ipa
```

Con FVM, sustituir `flutter` por `fvm flutter`. La generación del IPA requiere
una configuración de firma válida. La compilación y ejecución iOS no pueden
validarse desde Linux o Windows.

## Verificación antes de integrar cambios

Ejecutar desde la raíz:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

En equipos con FVM se utiliza `fvm flutter` en cada comando. Los cambios que
afecten iOS también deben pasar:

```bash
flutter build ios --debug --no-codesign
```

Las funciones de cámara, micrófono, voz, ubicación, llamadas, SMS y widgets
deben probarse en dispositivos físicos; una compilación correcta no valida su
comportamiento ni los permisos del sistema.

## Consideraciones de Release

El build Android de verificación usa temporalmente la clave de depuración. No
debe publicarse hasta completar lo siguiente:

- Definir el application ID definitivo.
- Crear y proteger el keystore de producción.
- Configurar la firma Release sin guardar secretos en Git.
- Generar y probar el AAB firmado.

Para iOS se deben configurar el bundle identifier, certificados y provisioning
profiles del equipo antes de distribuir mediante TestFlight o App Store.

## Diagnóstico inicial

Si el build no coincide entre equipos, comprobar en este orden:

1. `flutter --version` o `fvm flutter --version`.
2. `flutter doctor -v` y el JDK seleccionado.
3. `./android/gradlew --version` para Android.
4. `bundle exec pod --version` y `xcodebuild -version` para iOS.
5. Que `pubspec.lock` y `ios/Podfile.lock` no tengan cambios inesperados.
6. Las advertencias de compatibilidad descritas en
   [Versiones del stack](versiones_del_stack.md).
