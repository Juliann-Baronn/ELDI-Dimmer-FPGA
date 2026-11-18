# M4 — Zero-Cross Event Detector

**Proyecto:** ELDI-Dimmer-FPGA
**Fecha de actualización:** 18 de noviembre de 2026
**Módulo RTL:** `zero_cross_detect`
**Estado:** Implementado y verificado mediante simulación conductual registrada; análisis temporal y validación física pendientes.

## 1. Propósito

M4 recibe la señal sincronizada `zc_sync` desde M2 y genera `zc_event`, un pulso de un ciclo de reloj. Detecta únicamente un flanco ascendente válido después de haber observado un nivel bajo; no sincroniza entradas asíncronas ni temporiza el retardo de fase.

## 2. Interfaz

| Puerto | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk` | Entrada | 1 | Reloj común de 100 MHz. |
| `rst` | Entrada | 1 | Reset síncrono activo alto. |
| `zc_sync` | Entrada | 1 | Señal sincronizada por M2. |
| `zc_event` | Salida | 1 | Pulso registrado de un ciclo ante un ascenso válido. |

## 3. Comportamiento implementado

Durante reset, `zc_prev`, `armed` y `zc_event` se limpian. Fuera de reset, `zc_event` se limpia por defecto en cada flanco de reloj.

1. Al observar `zc_sync = 0`, M4 se arma y registra `zc_prev = 0`.
2. Si posteriormente observa `zc_sync = 1` con `armed = 1` y `zc_prev = 0`, genera `zc_event = 1` durante ese ciclo.
3. El nivel alto sostenido no genera eventos repetidos; el detector requiere observar bajo para volver a armarse.

La condición de armado evita un evento artificial cuando `zc_sync` ya está alto al liberar el reset.

## 4. Archivos relacionados

| Tipo | Archivo |
|---|---|
| RTL | `rtl/modules/zero_cross_detect.v` |
| Testbench unitario | `sim/unit/tb_zero_cross_detect.v` |
| Integración | `sim/integration/tb_zero_cross_chain.v` |
| Módulo anterior | `rtl/modules/zero_cross_sync.v` |

## 5. Evidencia registrada

La bitácora de M4 registra **16 comprobaciones unitarias correctas**. Incluyen reset, liberación con entrada alta, armado al observar bajo, primer y segundo flanco ascendente, duración de un ciclo, ausencia de eventos repetidos, flanco descendente y rearme tras reset.

Para la cadena M2–M4, la bitácora registra una simulación conductual del 17 de noviembre de 2026 con **32 comprobaciones y 0 errores**. El resultado cubre la propagación por las dos etapas de M2 y la emisión posterior de `zc_event` por M4.

Estos son resultados registrados previamente; esta actualización no ejecuta de nuevo las simulaciones.

## 6. Límites y pendientes

- La polaridad y forma de onda del detector externo aún deben confirmarse en hardware.
- La simulación no valida aislamiento, circuito de detección ni comportamiento ante señales físicas espurias.
- Faltan síntesis standalone, análisis temporal post-implementación y validación física documentada.
- La latencia conjunta de M2 y M4 debe incorporarse al presupuesto temporal del dimmer completo.

## 7. Estado resumido

| Actividad | Estado |
|---|---|
| RTL y detección de flanco ascendente armado | Implementados |
| Testbench unitario | Resultado registrado: 16 comprobaciones correctas |
| Integración conductual M2–M4 | Resultado registrado: 32 comprobaciones, 0 errores |
| Síntesis y timing integrado | Pendientes |
| Prueba física | Pendiente |
