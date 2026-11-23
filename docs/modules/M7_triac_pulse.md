# M7 — TRIAC Pulse

**Proyecto:** ELDI-Dimmer-FPGA  
**Actualización documental:** 23 de noviembre de 2026  
**RTL:** `rtl/modules/triac_pulse.v`  
**Estado:** RTL y pruebas disponibles; no hay resultados de ejecución, síntesis, implementación ni temporización conservados para este módulo.

## 1. Propósito del módulo

M7 genera la orden digital `gate_pulse` que se entrega a la salida de la FPGA después de que M6 solicita un disparo. También informa a M6, mediante `pulse_done`, que la secuencia de pulso terminó.

## 2. Función dentro de la arquitectura

M6 entrega `triac_pulse_start` a M7. M7 genera `gate_pulse`, que `top_dimmer` expone hacia M8, y devuelve `pulse_done` a M6. El módulo no proporciona aislamiento eléctrico ni control directo de un TRIAC de potencia.

## 3. Entradas y salidas

| Puerto | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk` | Entrada | 1 | Reloj del sistema. |
| `rst` | Entrada | 1 | Reset síncrono activo alto. |
| `pulse_start` | Entrada | 1 | Solicitud de inicio de pulso proveniente de M6. |
| `gate_pulse` | Salida | 1 | Orden digital de disparo hacia M8. |
| `pulse_done` | Salida | 1 | Notificación de finalización de un ciclo. |

El parámetro `PULSE_WIDTH_CYCLES` es de 32 bits y tiene valor por defecto `1000` en el RTL.

## 4. Funcionamiento implementado

M7 utiliza los estados `IDLE`, `PULSE_ACTIVE` y `PULSE_DONE`. En `IDLE`, una solicitud `pulse_start` inicia el pulso. En `PULSE_ACTIVE`, un contador ascendente controla la duración; `gate_pulse` permanece activo mientras la FSM está en ese estado. Al alcanzar el ancho parametrizado, la FSM entra en `PULSE_DONE`, donde `pulse_done` es activo durante un ciclo antes de regresar a `IDLE`.

El reset cancela el pulso y devuelve la FSM al estado inactivo. Las solicitudes que ocurren mientras `PULSE_ACTIVE` está activo no producen un segundo pulso en paralelo.

## 5. Dependencias e interfaces

- Solicitud de pulso: M6 `dimmer_fsm`.
- Notificación de fin: M7 entrega `pulse_done` a M6.
- Salida digital: `gate_pulse` se conecta al puerto del top y a la interfaz externa M8.
- La duración apropiada para la etapa externa no se determina mediante esta implementación RTL.

## 6. RTL disponible

- `rtl/modules/triac_pulse.v`

## 7. Testbenches disponibles

- Unitario: `sim/unit/tb_triac_pulse.v`, con un ancho de prueba parametrizado de cinco ciclos.
- Integración M4–M7: `sim/integration/tb_integration_m4_m7.v`.
- Integración indirecta mediante el top: `sim/integration/tb_top_dimmer.v`.

Los archivos incluyen comprobaciones propuestas para reset, inicio, duración de pulso, solicitudes durante actividad, `pulse_done`, segundo pulso y reset durante un pulso. No se registra en esta ficha una ejecución real de esos casos.

## 8. Resultados documentados

No se conservan logs, ondas, reportes de síntesis, implementación, temporización ni pruebas físicas específicos de M7. En particular, no existe evidencia documentada que relacione el ancho de pulso por defecto con una interfaz M8 concreta.

## 9. Limitaciones y trabajo pendiente

- Ejecutar y preservar resultados de las pruebas unitarias e integradas.
- Verificar la duración del pulso en función de la interfaz externa que se documente para M8.
- Analizar síntesis, restricciones y temporización en el diseño integrado.
- Validar la salida digital y el aislamiento de la etapa externa antes de conectar cargas de CA.
