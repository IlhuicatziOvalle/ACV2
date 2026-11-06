# Registro de cambios de configuración

Fecha de la línea base: 2026-09-30

Este documento registra la migración que estableció el stack descrito en
[Versiones del stack](versiones_del_stack.md). Su función es permitir auditoría y
explicar por qué existe cada cambio; no es una guía de instalación.

## Toolchain de validación

Los siguientes cambios se realizaron en el equipo utilizado para validar la
migración. No viajan en Git; deben reproducirse siguiendo
[Preparación del entorno](preparacion_del_entorno.md).

| Elemento | Estado anterior | Línea base | Función | Motivo |
| --- | --- | --- | --- | --- |
| Flutter | 3.47.2 | 3.47.5 `stable` | Framework, compilador y comandos de build | Adoptar una revisión patch exacta y reproducible |
| Dart | 3.13.2 | 3.13.4 | Compila y analiza el código de `lib/` | Se actualiza como parte del SDK de Flutter |
| JDK de Flutter | 17 | 17 confirmado | Ejecuta Gradle y compila Java/Kotlin | Garantizar una versión compatible con AGP 9.1 |
| Android Command-line Tools | No disponibles | Instaladas | Administran componentes y licencias del Android SDK | Permitir configuración y validación desde la terminal |
| Licencias Android | Pendientes | Aceptadas | Habilitan el uso local de componentes del SDK | Evitar bloqueos de compilación |
| Componentes Android | Sin verificación integral | Platform 36, Build Tools 36.0.0 y NDK 28.2.13676358 | Compilan y empaquetan Android | Coincidir con la línea base del proyecto |

## Archivos editados o agregados manualmente

| Archivo | Estado anterior | Cambio | Qué hace | Motivo |
| --- | --- | --- | --- | --- |
| `.fvmrc` | No existía | Fija Flutter 3.47.5 | Permite que FVM seleccione el Flutter del proyecto | Evitar diferencias entre equipos |
| `.java-version` | No existía | Declara JDK 17 | Informa la versión a gestores compatibles | Hacer visible el JDK requerido |
| `Gemfile` | No existía | Fija CocoaPods 1.17.0 | Permite instalar CocoaPods mediante Bundler | Reproducir la integración iOS y CI |
| `pubspec.yaml` | Dart `^3.9.2` | Dart `>=3.13.0 <4.0.0` | Define SDK compatible y dependencias directas | Alinear el proyecto con Dart 3.13 sin aceptar Dart 4 automáticamente |
| `android/settings.gradle.kts` | AGP 8.9.1 y Kotlin 2.1.0 | AGP 9.1.0 y Kotlin 2.4.0 | Declara plugins del build Android | Adoptar la combinación de Flutter 3.47.5 |
| `android/app/build.gradle.kts` | Plugin Kotlin explícito y bytecode 11 | Plugin directo retirado, DSL moderna y bytecode 17 | Configura SDK, compiladores, variantes y firma | Adaptar el módulo a Flutter 3.47/AGP 9 y JDK 17 |
| `android/gradle.properties` | Jetifier activo | Jetifier retirado y flags temporales de compatibilidad AGP 9 | Define opciones globales de Gradle/Android | El grafo usa AndroidX; algunos plugins aún necesitan el modo Kotlin anterior |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.12 | Gradle 9.3.1, validación de URL y timeout | Selecciona la distribución de Gradle | Cumplir la compatibilidad de AGP 9.1 |
| Gradle Wrapper | Scripts/JAR ausentes o ignorados | `gradlew`, `gradlew.bat` y `gradle-wrapper.jar` versionados | Ejecuta la versión de Gradle del proyecto | Permitir builds desde un clon nuevo sin Gradle global |
| `android/.gitignore` | Ignoraba partes del wrapper | Excepciones retiradas | Controla archivos Android versionados | Incluir el wrapper completo |
| `ios/Runner.xcodeproj/project.pbxproj` | iOS 13 en Debug, Profile y Release | iOS 15 en las tres configuraciones | Define el deployment target | Coincidir con Flutter 3.47 y `ios/Podfile` |
| `README.md` | Requisitos anteriores o genéricos | Requisitos vigentes y acceso a `docs/` | Presenta el proyecto y orienta al equipo | Evitar instalaciones incompatibles |
| `docs/` | Sin guía del toolchain | Documentación técnica separada por tema | Conserva versiones, setup, conceptos y este registro | Facilitar incorporación y mantenimiento |

## Archivos regenerados

| Archivo | Resultado | Función | Motivo del cambio |
| --- | --- | --- | --- |
| `pubspec.lock` | Resuelto nuevamente con Dart 3.13 | Fija paquetes directos y transitivos | `flutter pub get` seleccionó revisiones compatibles con las restricciones existentes |
| `linux/flutter/generated_plugins.cmake` | Registro de `jni` actualizado | Registra plugins del build Linux | Salida automática de Flutter; Linux no es plataforma soportada |
| `windows/flutter/generated_plugins.cmake` | Registro de `jni` actualizado | Registra plugins del build Windows | Salida automática de Flutter; Windows no es plataforma soportada |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | Registro antiguo de `path_provider` retirado | Registra plugins macOS | Salida automática según el lockfile; macOS no es plataforma soportada |
| `lib/l10n/app_localizations_es.dart` | Formato normalizado | Contiene localizaciones generadas | Salida del generador de localización de Flutter |

Los archivos generados no se editan manualmente. Si una salida es incorrecta,
se modifica su fuente y se vuelve a ejecutar el generador correspondiente.

## Ajustes de código requeridos por el analizador

| Archivo | Cambio | Función | Motivo |
| --- | --- | --- | --- |
| `lib/features/fast/pages/decision_page.dart` | Comprobación de `mounted` y contexto sin sombrear | Evita usar `BuildContext` cuando la pantalla ya no está montada | Corregir una advertencia de ciclo de vida asíncrono |
| `lib/services/device/floating_911_button.dart` | Comprobación equivalente y contexto renombrado | Protege las acciones asíncronas del botón 911 | Corregir una advertencia de ciclo de vida asíncrono |
| `lib/services/device/widget_service.dart` | Constante privada sin uso retirada | Coordina el widget nativo | Mantener el análisis sin hallazgos |

`analysis_options.yaml` no fue modificado como parte de esta migración. La
lógica FAST, los permisos y las APIs funcionales de los paquetes tampoco se
refactorizaron en esta fase.

## Resultado de la verificación

| Comprobación | Resultado al 2026-09-30 |
| --- | --- |
| `flutter doctor` para Flutter | Correcto |
| `flutter doctor` para Android | Correcto; licencias aceptadas |
| `flutter analyze` | Sin hallazgos |
| `flutter test` | 1 prueba aprobada |
| APK debug | Generado correctamente |
| APK release | Generado correctamente, 154.2 MB |
| AAB release | Generado correctamente, 123.0 MB; firma debug temporal |
| Build iOS | Pendiente de macOS/Xcode |
| Pruebas en dispositivos físicos | Pendientes |

## Pendientes posteriores a la configuración

- Definir el application ID definitivo en lugar de `com.example.alerta_acv`.
- Crear y proteger el keystore Android de producción.
- Configurar firma Release sin guardar secretos en Git.
- Validar compilación, firma y ejecución iOS en macOS y iPhone físico.
- Probar cámara, voz, llamadas, SMS y widgets en dispositivos físicos.
- Aumentar la cobertura automatizada más allá de la apertura de la pantalla principal.
