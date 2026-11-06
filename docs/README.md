# Documentación técnica

Esta carpeta reúne la documentación del entorno y del stack de Alerta ACV.
Cada documento responde una necesidad distinta para que no sea obligatorio leer
todo el material antes de trabajar.

## Documentos

| Necesidad | Documento |
| --- | --- |
| Consultar las versiones vigentes | [Versiones del stack](versiones_del_stack.md) |
| Preparar o verificar una computadora | [Preparación del entorno](preparacion_del_entorno.md) |
| Entender qué hace cada herramienta | [Guía de herramientas](guia_de_herramientas.md) |
| Auditar por qué se modificó la configuración | [Registro de cambios de configuración](cambios_de_configuracion.md) |
| Conocer el producto y la estructura del código | [README principal](../README.md) |

## Guías especializadas

| Tema | Documento |
| --- | --- |
| Face Landmarker en Android | [Integración de Face Landmarker](guia_face_landmarker.md) |
| Sensibilidad de la prueba facial | [Parámetros de Face](guia_face_parametros_.md) |
| Pose Landmarker en Android | [Integración de Pose Landmarker en Android](guia_pose_landmarker.md) |
| Pose Landmarker en iOS | [Integración de Pose Landmarker en iOS](guia_pose_landmarker_ios.md) |

## Rutas de lectura

### Incorporación rápida

1. Revisar las [versiones vigentes](versiones_del_stack.md).
2. Seguir la [preparación del entorno](preparacion_del_entorno.md).
3. Ejecutar las verificaciones indicadas antes de desarrollar.

### Primera experiencia con Flutter o desarrollo móvil

1. Leer la [guía de herramientas](guia_de_herramientas.md).
2. Revisar las [versiones vigentes](versiones_del_stack.md).
3. Seguir la [preparación del entorno](preparacion_del_entorno.md).

### Mantenimiento del toolchain

1. Consultar la política en [Versiones del stack](versiones_del_stack.md).
2. Comparar el cambio con el
   [registro de configuración](cambios_de_configuracion.md).
3. Ejecutar la verificación completa en Android y iOS.

## Mantenimiento de estos documentos

- Actualizar `versiones_del_stack.md` cuando cambie una versión fijada.
- Actualizar `preparacion_del_entorno.md` cuando cambien los requisitos de instalación.
- Agregar una entrada a `cambios_de_configuracion.md` cuando se migre el toolchain.
- Actualizar `guia_de_herramientas.md` cuando se incorpore o retire una herramienta.
- Evitar instrucciones que dependan de una computadora particular o de contexto no registrado.
