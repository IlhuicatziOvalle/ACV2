# Guía de herramientas y conceptos

Este documento explica las herramientas del proyecto y la responsabilidad de
cada una. Es material de referencia opcional: quienes ya conocen el stack
pueden consultar directamente [Versiones del stack](versiones_del_stack.md) y
[Preparación del entorno](preparacion_del_entorno.md).

## Distribución del código

### Flutter y Dart

La interfaz, navegación, estado, base de datos, contactos, historial,
configuración, flujo FAST y coordinación de servicios están principalmente en
`lib/`. Flutter compila Dart para cada plataforma; no convierte el código Dart
en Kotlin o Swift.

### Android nativo

El código Kotlin de `android/app/src/main/kotlin/` integra CameraX, MediaPipe,
Vosk, llamadas, SMS, el widget de pantalla de inicio y el host Android.

### iOS nativo

El código Swift de `ios/Runner/` integra AVFoundation, MediaPipe, Speech
Framework, llamadas, SMS, ubicación y el host iOS.

Las carpetas `android/` e `ios/` no duplican toda la aplicación. Son proyectos
host que contienen configuración, permisos, firma e integraciones específicas
de cada sistema operativo.

## Flujo de compilación

### Capa compartida

```text
.fvmrc -> FVM selecciona Flutter 3.47.5
             |
             v
pubspec.yaml -> pub resuelve paquetes -> pubspec.lock
             |
             v
      Dart + Flutter compilan lib/ y assets
             |
             v
       salida Android o salida iOS
```

### Android

```text
flutter build
  -> Gradle Wrapper selecciona Gradle 9.3.1
  -> Gradle carga AGP 9.1 y Kotlin 2.4
  -> JDK 17 ejecuta Gradle y genera bytecode 17
  -> Android SDK 36 y Build Tools empaquetan la app
  -> NDK compila/enlaza bibliotecas nativas cuando son necesarias
  -> se produce un APK instalable o un AAB para Google Play
```

### iOS

```text
bundle install -> Gemfile fija CocoaPods 1.17
bundle exec pod install -> Podfile/Podfile.lock integran dependencias nativas
flutter build ios/ipa -> Xcode + Swift + iOS SDK compilan y enlazan la app
                     -> se produce una app/IPA que debe firmarse
```

### Comunicación con funciones nativas

```text
Pantalla Flutter (Dart)
  -> servicio Dart
  -> contrato generado por Pigeon
  -> implementación Kotlin o Swift
  -> API del sistema o biblioteca nativa
  -> resultado tipado de regreso a Dart
```

El contrato fuente de Pigeon es `pigeons/fast_api.dart`. Sus salidas generadas
en Dart, Kotlin y Swift deben regenerarse juntas y no editarse manualmente.

## Flutter y administración del proyecto

| Herramienta | Qué es | Uso en Alerta ACV |
| --- | --- | --- |
| Flutter SDK | Framework y conjunto de comandos multiplataforma | Construye la UI, incorpora el motor Flutter y coordina los builds móviles |
| Dart SDK | Lenguaje, compilador y herramientas incluidas con Flutter | Compila `lib/`, analiza el código y ejecuta pruebas |
| Flutter Engine | Motor nativo que dibuja la UI y ejecuta el código compilado | Mantiene una interfaz compartida en Android e iOS |
| DevTools | Suite de inspección y perfilado | Depura widgets, memoria, CPU, red y rendimiento |
| FVM | Gestor de versiones de Flutter por proyecto | Lee `.fvmrc` y selecciona Flutter 3.47.5 sin depender de la instalación global |
| `pub` | Gestor de paquetes de Dart | Resuelve `pubspec.yaml` y produce `pubspec.lock` |
| `pubspec.yaml` | Manifiesto principal de Flutter | Declara Dart, dependencias, assets y opciones de generación |
| `pubspec.lock` | Resolución exacta de paquetes | Reproduce las mismas dependencias directas y transitivas |
| `flutter analyze` | Analizador estático | Detecta errores y usos inseguros sin ejecutar la app |
| `flutter test` | Ejecutor de pruebas | Comprueba el comportamiento cubierto por pruebas automatizadas |

FVM es una ayuda de desarrollo, no una dependencia de la aplicación en
ejecución. Se puede trabajar sin FVM si se instala exactamente la versión de
Flutter definida en [Versiones del stack](versiones_del_stack.md).

## Android

| Herramienta o concepto | Qué es | Uso en Alerta ACV |
| --- | --- | --- |
| Android Studio | IDE oficial de Android | Instala SDKs, administra emuladores y permite depurar Kotlin/Gradle |
| Android SDK | APIs y herramientas para crear aplicaciones Android | Aporta la plataforma de compilación, empaquetado y depuración |
| Nivel de API | Número que identifica un contrato de Android | Expresa compatibilidad mínima, API de compilación y comportamiento objetivo |
| `minSdk` 24 | Nivel mínimo donde la app puede instalarse | Excluye dispositivos anteriores a API 24 |
| `compileSdk` 36 | Nivel de API usado por el compilador | Permite compilar código y plugins contra Android API 36 |
| `targetSdk` 36 | Nivel para el que la app declara estar adaptada | Activa las reglas de compatibilidad correspondientes y cumple el objetivo de publicación |
| Android API 36 | Conjunto de APIs identificado por el nivel 36 | Se usa como `compileSdk` y `targetSdk`; no es el Android mínimo |
| Build Tools | Empaquetadores, procesadores de recursos y firmadores | Transforman recursos y bytecode en APK/AAB |
| Command-line Tools | Herramientas de administración del SDK | Proporcionan `sdkmanager` y gestión de licencias |
| Platform Tools / ADB | Herramientas para comunicarse con dispositivos | Instalan apps, muestran dispositivos y permiten consultar logs |
| JDK | Kit de desarrollo de Java | Ejecuta Gradle y compila Java/Kotlin |
| Gradle | Motor de automatización | Coordina dependencias, compilación, recursos, variantes, firma y empaquetado |
| Gradle Wrapper | Scripts y JAR versionados con el proyecto | Descargan y ejecutan la versión correcta de Gradle |
| Android Gradle Plugin (AGP) | Plugin oficial de Android para Gradle | Configura SDKs, manifiestos, recursos, variantes y artefactos |
| Kotlin | Lenguaje del host Android | Implementa las integraciones nativas de la aplicación |
| Kotlin Gradle Plugin | Integración del compilador Kotlin con Gradle | Configura y compila el código Kotlin |
| AndroidX | Bibliotecas modernas de compatibilidad | Proporciona componentes usados por la app y los plugins Flutter |
| Jetifier | Conversor de bibliotecas `android.support` antiguas a AndroidX | No está activo porque las dependencias actuales ya usan AndroidX |
| NDK | Kit para compilar C/C++ | Compila o enlaza bibliotecas nativas requeridas por dependencias |
| Android Manifest | Declaración de identidad y capacidades | Registra componentes, permisos, filtros y metadatos de la app |
| APK | Paquete instalable | Se utiliza en desarrollo, pruebas y distribución directa controlada |
| AAB | Android App Bundle | Se publica en Google Play para generar APK optimizados |
| Keystore | Identidad criptográfica de firma | Permite publicar actualizaciones reconocidas como la misma aplicación |

Los tres niveles de SDK responden preguntas diferentes: `minSdk` indica dónde
puede instalarse, `compileSdk` contra qué API se compila y `targetSdk` para qué
reglas del sistema está preparada.

### Bibliotecas Android

| Biblioteca | Uso en Alerta ACV | Motivo |
| --- | --- | --- |
| CameraX | Administra la cámara y entrega frames | Simplifica el ciclo de vida y compatibilidad de cámara |
| MediaPipe Tasks Vision | Ejecuta Face Landmarker y Pose Landmarker | Obtiene señales para las pruebas de cara y brazos |
| Vosk | Reconoce voz localmente | Transcribe la frase FAST sin conexión |
| JNA | Comunica Java con código nativo | Es una dependencia técnica de Vosk |
| AppCompat / ConstraintLayout | Compatibilidad y vistas Android | Dan soporte a componentes nativos y al widget de inicio |

## iOS

| Herramienta o concepto | Qué es | Uso en Alerta ACV |
| --- | --- | --- |
| Xcode | IDE y toolchain oficial de Apple | Compila, enlaza, firma, prueba y distribuye la app iOS |
| iOS SDK | Frameworks y herramientas de una versión de iOS | Proporciona las APIs del sistema usadas durante la compilación |
| Deployment target | Versión mínima de iOS | Define dónde se puede instalar y qué APIs requieren comprobación |
| Swift language mode | Reglas del lenguaje usadas por el compilador | Mantiene el código nativo en modo Swift 5 |
| CocoaPods | Gestor de dependencias nativas | Descarga e integra los pods de Flutter y MediaPipe |
| Bundler | Gestor de gemas Ruby | Ejecuta la versión de CocoaPods definida en `Gemfile` |
| `Podfile` | Receta de CocoaPods | Declara plataforma, targets y configuración de pods |
| `Podfile.lock` | Resolución exacta de pods | Reproduce las mismas dependencias nativas |
| `.xcworkspace` | Espacio de trabajo de Runner y Pods | Es el archivo que se abre en Xcode después de `pod install` |
| Firma y provisioning profile | Identidad y autorización de Apple | Permiten instalar en iPhone y publicar en App Store |
| IPA | Paquete distribuible iOS | Se entrega a TestFlight, App Store o un canal autorizado |

### Frameworks iOS

| Framework | Uso en Alerta ACV | Motivo |
| --- | --- | --- |
| AVFoundation | Captura cámara y audio | Proporciona frames y audio a los pasos FAST |
| MediaPipe Tasks Vision | Detecta cara y pose | Mantiene el análisis visual equivalente a Android |
| Speech Framework | Transcribe voz mediante APIs de Apple | Implementa el paso de habla solicitando procesamiento local |
| CoreLocation | Obtiene ubicación | Añade coordenadas al mensaje de emergencia cuando están disponibles |
| MessageUI | Presenta la interfaz de mensajes | Permite que la persona revise y confirme el SMS |

## Paquetes y arquitectura compartida

| Herramienta o paquete | Uso en Alerta ACV | Motivo |
| --- | --- | --- |
| Pigeon | Genera contratos tipados en Dart, Kotlin y Swift | Reduce errores al cruzar el puente Flutter-nativo |
| Riverpod | Administra estado y dependencias | Comparte estado de forma predecible entre pantallas y servicios |
| GoRouter | Declara navegación y rutas | Centraliza destinos y transiciones |
| sqflite / SQLite | Base de datos relacional local | Conserva el historial FAST sin internet |
| SharedPreferences | Almacenamiento clave-valor | Guarda preferencias no sensibles |
| Flutter Secure Storage | Almacenamiento protegido por el sistema | Está declarado, pero no tiene llamadas directas desde `lib/`; su necesidad debe revisarse antes de retirarlo |
| `permission_handler` | Consulta y solicita permisos | Unifica permisos de cámara, micrófono, contactos y ubicación |
| `geolocator` | Obtiene coordenadas y estado de ubicación | Alimenta el enlace de ubicación del SMS |
| `url_launcher` | Abre URLs y esquemas del sistema | Inicia llamadas, mensajería o enlaces cuando corresponde |
| `flutter_tts` | Convierte texto a voz | Lee instrucciones y apoya accesibilidad |
| `flutter_contacts` | Accede a contactos con permiso | Permite elegir contactos de emergencia |
| `home_widget` | Comunica Flutter con widgets nativos | Expone un acceso rápido desde la pantalla de inicio |
| `path_provider` | Localiza directorios privados | Proporciona una ruta estable para la base de datos |
| `flutter_localizations` e `intl` | Traducción y formato regional | Adaptan mensajes, fechas y números al idioma |
| `cupertino_icons` | Fuente de iconos de estilo iOS | Está disponible como recurso; no hay uso directo actual en `lib/` |
| `flutter_native_splash` | Generador de pantalla de arranque | Muestra el logotipo antes de que Flutter termine de iniciar |
| `flutter_lints` | Reglas recomendadas de análisis | Mantiene criterios estáticos comunes |

Las versiones exactas se consultan en `pubspec.lock`, `ios/Podfile.lock` y
[Versiones del stack](versiones_del_stack.md).
