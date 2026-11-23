# Arquitectura general del sistema ELDI Dimmer

**Proyecto:** Control de potencia mediante FPGA Digilent Nexys 4 DDR  
**Actualización:** 23 de noviembre de 2026  
**Estado:** Arquitectura documentada a partir del RTL y de los testbenches disponibles. La documentación no declara validación completa, cierre temporal ni funcionamiento de la etapa de potencia.

## 1. Objetivo y frontera del sistema

ELDI Dimmer implementa en FPGA la secuencia digital necesaria para controlar el ángulo de fase de una carga de corriente alterna. La FPGA adquiere la posición de un potenciómetro mediante el XADC, recibe una referencia externa de cruce por cero, calcula un retardo y genera una salida digital de disparo.

La frontera de la FPGA termina en `gate_pulse`. La adaptación eléctrica, el aislamiento y la conmutación de potencia corresponden a M8, una interfaz externa que no se describe mediante RTL en este repositorio.

## 2. Diagrama funcional

```text
                           ┌──────────────── FPGA: top_dimmer ────────────────┐
                           │                                                     │
Potenciómetro ─ VAUX3 ───► │ M1 xadc_interface                                  │
                           │       │ pot_sample[11:0], sample_valid             │
                           │       ▼                                             │
                           │ M3 pot_to_delay ── delay_target[19:0] ──────┐      │
                           │                                               ▼      │
Detector externo ─ zc_in ► │ M2 zero_cross_sync → M4 zero_cross_detect → M6     │
de cruce por cero          │          zc_sync            zc_event         │     │
                           │                                                     │
                           │                         M5 phase_timer ◄────┘     │
                           │                              │ timer_done           │
                           │                              ▼                      │
                           │                         M6 dimmer_fsm               │
                           │                         │ timer_start, timer_clear  │
                           │                         │ triac_pulse_start         │
                           │                         ▼                           │
                           │                     M7 triac_pulse                  │
                           │                         │ gate_pulse                │
                           └─────────────────────────┼───────────────────────────┘
                                                     ▼
                              M8: interfaz externa optoaislada y etapa de potencia
```

## 3. Módulos implementados en RTL

| ID | Módulo | Archivo | Responsabilidad observada en el RTL |
|---|---|---|---|
| M1 | `xadc_interface` | `rtl/modules/xadc_interface.v` | Solicita una lectura DRP del XADC y entrega `pot_sample[11:0]` con `sample_valid`. Instancia la IP externa `xadc_wiz_1`. |
| M2 | `zero_cross_sync` | `rtl/modules/zero_cross_sync.v` | Sincroniza `zc_in` mediante dos registros marcados como `ASYNC_REG`. |
| M3 | `pot_to_delay` | `rtl/modules/pot_to_delay.v` | Convierte una muestra de 12 bits en `delay_target[19:0]` con parámetros `D_MIN` y `D_MAX`; el RTL actual implementa etapas registradas para el cálculo. |
| M4 | `zero_cross_detect` | `rtl/modules/zero_cross_detect.v` | Genera un pulso `zc_event` de un ciclo ante un flanco ascendente armado después de observar nivel bajo. |
| M5 | `phase_timer` | `rtl/modules/phase_timer.v` | Captura el retardo al detectar inicio, cuenta hacia cero y emite `timer_done`; `timer_clear` tiene prioridad. |
| M6 | `dimmer_fsm` | `rtl/modules/dimmer_fsm.v` | Coordina inicio, cancelación y finalización del temporizador, así como la solicitud de pulso a M7. |
| M7 | `triac_pulse` | `rtl/modules/triac_pulse.v` | Genera `gate_pulse` de ancho parametrizable y emite `pulse_done` durante un ciclo al finalizar. |

`rtl/top/top_dimmer.v` instancia M1–M7, invierte `CPU_RESETN` para generar el reset interno activo alto y expone los puertos `clk`, `CPU_RESETN`, `zc_in`, `vauxp3`, `vauxn3` y `gate_pulse`.

## 4. Conexiones y responsabilidades

### 4.1 Rama de ajuste

M1 recibe las entradas analógicas auxiliares `vauxp3` y `vauxn3`. El control digital usa una FSM con los estados `IDLE`, `REQ`, `WAIT` y `REARM`; solicita la dirección DRP `7'h13`, captura `do_out[15:4]` y emite `sample_valid` junto con la muestra retenida.

M3 recibe `pot_sample` y `sample_valid`. Sus parámetros por defecto son `D_MIN = 10000` y `D_MAX = 800000`; el resultado es un retardo de 20 bits que M5 captura al aceptar el inicio de una temporización.

### 4.2 Rama de sincronización

M2 recibe `zc_in`, una señal externa que puede ser asíncrona respecto a `clk`, y entrega `zc_sync` después de dos etapas de registro. M4 observa `zc_sync`, requiere haber visto un nivel bajo para armarse y genera `zc_event` durante un ciclo cuando detecta el ascenso posterior.

### 4.3 Temporización y coordinación

M6 permanece inicialmente a la espera de `zc_event`. Tras un evento, solicita el inicio de M5. Si aparece un nuevo `zc_event` mientras espera `timer_done`, M6 solicita la limpieza de M5 y reinicia la secuencia. Cuando M5 indica `timer_done`, M6 solicita a M7 un pulso digital. Durante la secuencia de pulso, M6 puede retener un nuevo cruce para iniciar una operación posterior después de `pulse_done`.

M5 detecta el flanco ascendente de `timer_start`, captura `delay_target` y activa una cuenta regresiva. Para `delay_target = 0`, establece `timer_done` en la aceptación del inicio; para cuentas activas, lo establece al alcanzar el último ciclo. M7 acepta `triac_pulse_start` en estado inactivo, activa `gate_pulse` durante `PULSE_WIDTH_CYCLES` y emite `pulse_done` al completar el pulso.

## 5. M8: interfaz externa de aislamiento y potencia

M8 no tiene RTL ni testbench propio en el repositorio. Su entrada funcional es la señal digital `gate_pulse` producida por M7 y expuesta por `top_dimmer`. `constraints/top_dimmer.xdc` asigna esa salida al pin D18 (JA2) de la placa.

Los componentes MOC3021M y BTA16-600B se mencionan como elementos de interés para la etapa externa, pero el repositorio no contiene hojas de datos, esquemáticos, lista de materiales ni cálculos eléctricos que permitan documentar sus valores, pines, umbrales, topología de conexión o adecuación al montaje. Por ello, esta arquitectura no afirma una conexión específica ni especificaciones técnicas de dichos componentes.

## 6. Restricciones y señales físicas disponibles

El top integrado cuenta con `constraints/top_dimmer.xdc`, que declara el reloj de 100 MHz, `CPU_RESETN`, VAUX3, la entrada `zc_in` y la salida `gate_pulse`. Los XDC de M2 y M4 contienen un reloj de referencia de 10 ns. La existencia de estos archivos no demuestra que se hayan aplicado en una implementación ni que hayan cerrado temporización.

## 7. Evidencia y límites de validación

Existen resultados históricos documentados para M1–M4 y para la integración M2–M4. También existen RTL y testbenches para M5–M7, integraciones adicionales y el top integrado. Esta documentación no reporta una nueva ejecución de esos testbenches ni resultados de síntesis, implementación, temporización o hardware para la versión integrada.

La reproducción completa depende de la IP `xadc_wiz_1` y, para el estímulo analógico descrito en la documentación de M1, de `design.txt`; ninguno está presente en el repositorio. Tampoco se conservan un proyecto Vivado, scripts de reconstrucción o artefactos de ejecución.
