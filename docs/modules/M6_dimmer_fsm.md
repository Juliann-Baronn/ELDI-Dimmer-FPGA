# M6 — Dimmer FSM

**Proyecto:** ELDI-Dimmer-FPGA  
**Actualización documental:** 23 de noviembre de 2026  
**RTL:** `rtl/modules/dimmer_fsm.v`  
**Estado:** RTL y pruebas disponibles; no hay resultados de ejecución, síntesis, implementación ni temporización conservados para este módulo.

## 1. Propósito del módulo

M6 coordina la secuencia digital entre el evento de cruce por cero, la temporización de fase y la generación del pulso de disparo. No adquiere el potenciómetro, no sincroniza la entrada externa y no conmuta la etapa de potencia.

## 2. Función dentro de la arquitectura

M6 recibe `zc_event` de M4, `timer_done` de M5 y `pulse_done` de M7. Produce `timer_start` y `timer_clear` para M5, además de `triac_pulse_start` para M7. El módulo se integra en `rtl/top/top_dimmer.v`.

## 3. Entradas y salidas

| Puerto | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk` | Entrada | 1 | Reloj del sistema. |
| `rst` | Entrada | 1 | Reset síncrono activo alto. |
| `zc_event` | Entrada | 1 | Evento de cruce por cero generado por M4. |
| `timer_done` | Entrada | 1 | Finalización de la cuenta de M5. |
| `pulse_done` | Entrada | 1 | Finalización del pulso de M7. |
| `timer_start` | Salida | 1 | Solicitud de inicio para M5. |
| `timer_clear` | Salida | 1 | Solicitud de cancelación para M5. |
| `triac_pulse_start` | Salida | 1 | Solicitud de generación de pulso para M7. |

## 4. Funcionamiento implementado

La FSM define los estados `WAIT_ZC`, `START_TIMER`, `WAIT_TIMER`, `CLEAR_TIMER`, `FIRE_TRIAC` y `WAIT_PULSE`. En reset vuelve a `WAIT_ZC` y mantiene las salidas de control inactivas.

Al recibir `zc_event`, M6 pasa por `START_TIMER` y activa `timer_start`. Mientras espera `timer_done`, un nuevo `zc_event` tiene prioridad: M6 entra en `CLEAR_TIMER`, activa `timer_clear` y vuelve a solicitar una temporización. Cuando recibe `timer_done`, M6 entra en `FIRE_TRIAC` y emite `triac_pulse_start` durante ese estado.

Durante `FIRE_TRIAC` y `WAIT_PULSE`, un evento de cruce puede guardarse en `pending_zc`. Cuando M7 informa `pulse_done`, M6 inicia una nueva temporización si hay un evento pendiente o si el evento coincide con esa finalización; en caso contrario regresa a la espera de cruce.

## 5. Dependencias e interfaces

- Evento de entrada: M4 `zero_cross_detect`.
- Temporizador controlado: M5 `phase_timer`.
- Generador de pulso controlado: M7 `triac_pulse`.
- M6 no se conecta directamente a M1, M2, M3 ni a la interfaz M8.

## 6. RTL disponible

- `rtl/modules/dimmer_fsm.v`

## 7. Testbenches disponibles

- Unitario: `sim/unit/tb_dimmer_fsm.v`.
- Integración M4–M7: `sim/integration/tb_integration_m4_m7.v`.
- Integración indirecta mediante el top: `sim/integration/tb_top_dimmer.v`.

El testbench unitario contiene casos para reset, inicio de M5, prioridad de un nuevo cruce durante temporización, cruce durante el pulso, evento pendiente y coincidencia entre cruce y `pulse_done`. Los casos descritos son pruebas disponibles, no resultados documentados.

## 8. Resultados documentados

No se conservan resultados de simulación, síntesis, implementación, temporización ni pruebas físicas específicos de M6. Esta ficha no atribuye una ejecución satisfactoria a los testbenches disponibles.

## 9. Limitaciones y trabajo pendiente

- Ejecutar y archivar evidencia de las pruebas unitarias e integradas para la versión que se evalúe.
- Revisar la interacción temporal integrada con M4, M5 y M7.
- Analizar síntesis, restricciones y cierre temporal del top.
- Validar el comportamiento ante la señal de cruce por cero y la interfaz externa bajo condiciones controladas.
