# Guía de Ajuste de Sensibilidad (Face Test)

Este documento describe las variables clave en `FaceActivity.kt` que controlan la sensibilidad del algoritmo de detección de asimetría facial.

Ubicación del archivo: `android/app/src/main/kotlin/com/example/alerta_acv/FaceActivity.kt`

## Variables de Configuración

### 1. Suavizado (EMA)
Controla qué tan rápido reacciona el algoritmo a los cambios en la expresión facial.

```kotlin
private val alpha = 0.2f
```
- **Valor actual:** `0.2`
- **Efecto:**
    - **Mayor (ej. 0.5):** Más reactivo, pero más ruidoso (puede dar falsos positivos por movimientos rápidos).
    - **Menor (ej. 0.1):** Más suave y estable, pero tarda más en detectar la sonrisa.

### 2. Umbral de Activación (Sonrisa)
Define qué tan fuerte debe sonreír el usuario para que el análisis comience.

```kotlin
val isSmiling = maxSmile >= 0.30f
```
- **Valor actual:** `0.30` (30% de intensidad de sonrisa)
- **Ajuste:**
    - **Bajar (ej. 0.20):** Detecta sonrisas más sutiles. Útil si a los pacientes les cuesta mover la cara.
    - **Subir (ej. 0.50):** Requiere una sonrisa muy marcada. Evita analizar cuando el usuario solo está hablando.

### 3. Umbrales de Asimetría
Definen cuándo una sonrisa se considera "Asimétrica" (Riesgo).

**Condición de Simetría (Sano):**
```kotlin
val symmetric = (smileLeftSmoothed > 0.28 && smileRightSmoothed > 0.28 && delta < 0.12)
```

#### A. Intensidad Mínima (`0.28`)
- **Descripción:** Ambos lados deben superar este valor para considerarse una sonrisa "completa" y sana.
- **Ajuste:**
    - **Bajar (ej. 0.20):** Hace el modelo **menos sensible** a la debilidad leve. Acepta sonrisas más débiles como "sanas".
    - **Subir (ej. 0.35):** Hace el modelo **más estricto**. Requiere fuerza en ambos lados.

#### B. Diferencia Máxima (`delta < 0.12`)
- **Descripción:** La diferencia entre el lado izquierdo y derecho no debe superar este valor (12%).
- **Ajuste:**
    - **Bajar (ej. 0.08):** Modelo **muy estricto**. Cualquier pequeña diferencia marcará "Riesgo".
    - **Subir (ej. 0.20):** Modelo **más permisivo**. Permite más asimetría natural antes de marcar "Riesgo".

### 4. Ventana de Votación
Para evitar errores por un solo frame, analizamos una secuencia.

```kotlin
private val votingWindowSize = 20
// ...
val isAsymmetric = asymmetricVotes >= 12
```

- **`votingWindowSize` (20):** Número de frames a analizar (aprox. 1 segundo).
- **Umbral de Votos (12):** Cantidad de frames "Asimétricos" necesarios para dar positivo.
- **Ajuste:**
    - **Bajar umbral (ej. 10/20):** Más sensible a detectar asimetría.
    - **Subir umbral (ej. 15/20):** Requiere que la asimetría sea muy constante.

## Resumen para Ajuste Rápido

| Objetivo | Acción Recomendada |
| :--- | :--- |
| **Hacerlo MÁS SENSIBLE** (Detectar más casos leves) | Bajar `0.28` a `0.20` y Bajar `delta` a `0.10`. |
| **Hacerlo MENOS SENSIBLE** (Evitar falsos positivos) | Subir `delta` a `0.15` o `0.18`. |
| **Detectar sonrisas más débiles** | Bajar umbral de activación `0.30` a `0.20`. |
