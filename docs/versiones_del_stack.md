# Versiones del stack

Última revisión: 2026-10-01

Estado: línea base adoptada para Android e iOS.

Este documento es la fuente de verdad para las versiones del toolchain. Para
instalarlo, consulta [Preparación del entorno](preparacion_del_entorno.md). Si algún
término no resulta familiar, consulta la [Guía de herramientas](guia_de_herramientas.md).

## Alcance

- Obtener builds reproducibles entre desarrolladores y CI.
- Cumplir los requisitos vigentes de Google Play y App Store.
- Separar actualizaciones del toolchain, paquetes y comportamiento funcional.

El producto soportado es móvil. Web, Windows, macOS y Linux desktop no forman
parte del alcance.

## Versiones fijadas

| Componente | Versión |
| --- | --- |
| Flutter | 3.47.5, canal `stable` |
| Dart | 3.13.4, incluido en Flutter |
| DevTools | 2.60.0 |
| Restricción Dart del proyecto | `>=3.13.0 <4.0.0` |
| JDK usado por Flutter y Gradle | 17 |
| Java/Kotlin bytecode | 17 |
| Android mínimo | API 24 |
| Android `compileSdk` | API 36 |
| Android `targetSdk` | API 36 |
| Android Build Tools | 36.0.0 |
| Android NDK | 28.2.13676358 |
| Android Gradle Plugin | 9.1.0 |
| Gradle Wrapper | 9.3.1 |
| Kotlin Gradle Plugin | 2.4.0 |
| iOS mínimo | 15.0 |
| Xcode | 26.x estable |
| iOS SDK | 26 o posterior |
| Swift language mode | 5.0 |
| CocoaPods | 1.17.0 |

Flutter 3.47 fija `minSdk 24`, `compileSdk 36`, `targetSdk 36` y NDK
28.2.13676358. El proyecto utiliza esos valores mediante
`flutter.minSdkVersion`, `flutter.compileSdkVersion`,
`flutter.targetSdkVersion` y `flutter.ndkVersion`.

## Criterios de selección

### Flutter y Dart

Flutter 3.47.5 es la revisión estable adoptada e incluye Dart 3.13.4. Dart no
se instala ni actualiza por separado: se usa el SDK incluido con Flutter.

Flutter 3.47 soporta Android 24 o posterior e iOS 15 o posterior. Estos son los
mínimos que el proyecto mantiene y valida.

### Android

Google Play exige `targetSdk 36` para aplicaciones nuevas y actualizaciones
desde el 31 de agosto de 2026. AGP 9.1, Gradle 9.3.1 y Kotlin 2.4 forman la
combinación adoptada con Flutter 3.47.5.

Gradle se ejecuta con JDK 17. El JDK global de cada equipo puede ser diferente,
siempre que Flutter y Gradle utilicen JDK 17 para este proyecto.

### iOS

El deployment target es iOS 15 tanto en el Podfile como en el proyecto Xcode.
Las entregas a App Store Connect se compilan con Xcode 26 y un SDK de iOS 26 o
posterior.

El código se conserva en modo de lenguaje Swift 5. Una migración a Swift 6 debe
realizarse y validarse como un cambio independiente.

## Dependencias funcionales fijadas

| Dependencia | Versión resuelta |
| --- | --- |
| MediaPipe Tasks Vision | 0.10.14 |
| CameraX | 1.3.4 |
| Vosk Android | 0.3.47 |
| JNA Android | 5.13.0 |
| Pigeon | 22.7.4 |
| Riverpod | 2.6.1 |
| GoRouter | 14.8.1 |

Las versiones completas de dependencias directas y transitivas se consultan en
`pubspec.lock` y `ios/Podfile.lock`.

## Archivos que fijan el entorno

| Archivo | Responsabilidad |
| --- | --- |
| `.fvmrc` | Flutter 3.47.5 para equipos que usan FVM |
| `.java-version` | JDK 17 para gestores compatibles |
| `Gemfile` | CocoaPods 1.17.0 en macOS |
| `pubspec.yaml` | Rango de Dart y dependencias directas |
| `pubspec.lock` | Dependencias Dart resueltas |
| `android/settings.gradle.kts` | Versiones de AGP y Kotlin |
| `android/gradle/wrapper/` | Distribución de Gradle 9.3.1 |
| `android/gradle.properties` | Opciones globales del build Android |
| `ios/Podfile` y `Podfile.lock` | Plataforma y dependencias nativas iOS |

El Gradle Wrapper se versiona completo: `gradlew`, `gradlew.bat`,
`gradle-wrapper.jar` y `gradle-wrapper.properties`.

## Compatibilidad conocida

AGP 9 incorpora soporte Kotlin integrado. `flutter_contacts`, `flutter_tts` y
`home_widget` todavía aplican el Kotlin Gradle Plugin anterior. Por ello se
mantienen temporalmente `android.builtInKotlin=false` y
`android.newDsl=false`.

Estas opciones se retirarán en AGP 10. Antes de adoptar esa versión se deben
actualizar o reemplazar los plugins afectados.

## Política de actualización

1. Mantener Flutter dentro de la serie fijada durante un ciclo de trabajo.
2. Aplicar primero revisiones patch y repetir la verificación completa.
3. Migrar Flutter, AGP, Gradle, Kotlin o Swift en cambios independientes.
4. Actualizar paquetes Dart por grupos pequeños y con pruebas.
5. Regenerar Pigeon de forma aislada y revisar Dart, Kotlin y Swift juntos.
6. Actualizar MediaPipe o los modelos con pruebas comparativas en ambas plataformas.
7. Actualizar este documento al cambiar cualquier versión fijada.

## Referencias oficiales

- [Flutter SDK archive](https://docs.flutter.dev/install/archive)
- [Plataformas soportadas por Flutter](https://docs.flutter.dev/reference/supported-platforms)
- [Migración de Flutter a AGP 9](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)
- [Requisitos de target API de Google Play](https://developer.android.com/google/play/requirements/target-sdk)
- [Compatibilidad de AGP 9.1](https://developer.android.com/build/releases/agp-9-1-0-release-notes)
- [Versiones de Java para Android](https://developer.android.com/build/jdks)
- [Requisitos de App Store Connect](https://developer.apple.com/news/upcoming-requirements/)
- [Releases de CocoaPods](https://github.com/CocoaPods/CocoaPods/releases)
