# M5 — Phase Timer

**Proyecto:** ELDI-Dimmer-FPGA  
**Actualización documental:** 23 de noviembre de 2026  
**RTL:** `rtl/modules/phase_timer.v`  
**Estado:** RTL y pruebas disponibles; no hay resultados de ejecución, síntesis, implementación ni temporización conservados para este módulo.

## 1. Propósito del módulo

M5 realiza la temporización entre la aceptación de un cruce por cero y la solicitud de disparo. Recibe un retardo expresado en ciclos de reloj y genera `timer_done` cuando la cuenta correspondiente termina.

## 2. Función dentro de la arquitectura

M3 entrega `delay_target[19:0]` a M5. M6 controla M5 mediante `timer_start` y `timer_clear`; a su vez, M5 entrega `timer_done` a M6. El módulo no detecta cruces por cero ni genera directamente `gate_pulse`.

## 3. Entradas y salidas

| Puerto | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk` | Entrada | 1 | Reloj del sistema. |
| `rst` | Entrada | 1 | Reset síncrono activo alto. |
| `timer_start` | Entrada | 1 | Solicitud de inicio; el RTL detecta su flanco ascendente. |
| `timer_clear` | Entrada | 1 | Cancelación o limpieza del temporizador. |
| `delay_target` | Entrada | 20 | Retardo que se captura al aceptar el inicio. |
| `timer_done` | Salida | 1 | Pulso registrado de finalización. |

## 4. Funcionamiento implementado

El RTL mantiene un contador descendente, una marca interna de actividad y un registro previo de `timer_start`. En reset limpia esos registros y `timer_done`.

Fuera de reset, `timer_done` se lleva a cero por defecto en cada ciclo. `timer_clear` tiene prioridad: cancela una cuenta activa y limpia el contador. Cuando detecta un flanco ascendente de `timer_start` y no hay una cuenta activa, M5 captura `delay_target`. Si el retardo capturado es cero, activa `timer_done` en esa aceptación; si es distinto de cero, inicia la cuenta regresiva. Una cuenta activa termina cuando el contador alcanza uno y entonces se emite el pulso `timer_done`.

## 5. Dependencias e interfaces

- Entrada de consigna: M3 `pot_to_delay` mediante `delay_target`.
- Control: M6 `dimmer_fsm` mediante `timer_start` y `timer_clear`.
- Notificación: M5 entrega `timer_done` a M6.
- El top integrado que conecta estas señales es `rtl/top/top_dimmer.v`.

## 6. RTL disponible

- `rtl/modules/phase_timer.v`

## 7. Testbenches disponibles

- Unitario: `sim/unit/tb_phase_timer.v`.
- Integración M3–M5: `sim/integration/tb_pot_to_delay_phase_timer.v`.
- Integración indirecta mediante M4–M7: `sim/integration/tb_integration_m4_m7.v`.
- Integración indirecta mediante el top: `sim/integration/tb_top_dimmer.v`.

Los archivos de prueba contienen comprobaciones previstas para reset, cuenta regresiva, retardo cero, captura de consigna, cancelación y reinicio. Su presencia no acredita una ejecución satisfactoria.

## 8. Resultados documentados

No se conservan logs, ondas, reportes de síntesis, implementación, temporización ni evidencia de hardware específicos de M5. Esta ficha no declara resultados de simulación.

## 9. Limitaciones y trabajo pendiente

- Ejecutar y preservar evidencia de las pruebas unitarias e integradas correspondientes a la versión evaluada.
- Revisar síntesis, restricciones y temporización dentro del top integrado.
- Validar el presupuesto temporal conjunto con M3, M4, M6 y M7.
- Confirmar el comportamiento del sistema completo frente a la señal física de cruce por cero y la etapa externa M8.
