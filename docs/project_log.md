# Registro de avances del proyecto

## 27 de octubre de 2026

- Se creó el repositorio privado `ELDI-Dimmer-FPGA` en GitHub.
- Se organizó la estructura inicial para la documentación, el código RTL, las simulaciones, las restricciones y la verificación.
- Se preparó el README con la descripción y los objetivos generales del proyecto.
- Se estableció un registro resumido de los aportes relevantes de inteligencia artificial.
- **Estado:** organización inicial del repositorio; la arquitectura y los módulos digitales se desarrollarán y verificarán progresivamente.

## 3 de noviembre de 2026 — Avance M1: XADC Interface

- Se revisó la configuración de la IP XADC Wizard 3.3, revisión 15, generada en Vivado 2026.1.
- Se identificó el canal auxiliar VAUX3 (`vauxp3`, `vauxn3`) y la interfaz DRP para consultar las conversiones.
- Se confirmaron la dirección de lectura `7'h13`, `DWE = 0` y la extracción de los 12 bits útiles desde `DO[15:4]`.
- Se definieron las salidas hacia M3: `pot_sample[11:0]`, que conserva la última muestra válida, y `sample_valid`, un pulso de un ciclo.
- Se propuso una FSM de cuatro estados (`IDLE`, `REQ`, `WAIT` y `REARM`) y un contador de 17 bits para el intervalo de 1 ms a 100 MHz (conteo de 0 a 99 999). En el momento de ese registro, la codificación y las transiciones detalladas todavía estaban pendientes; se aprobaron en el avance documentado abajo.
- **Estado:** revisión de la IP y definición inicial del comportamiento de M1 completadas. La implementación RTL, el testbench, la simulación y la validación física siguen pendientes.

## 3 de noviembre de 2026 — Diseño de la FSM de M1

- Se aprobó para servir de referencia a la implementación RTL el diseño de la FSM de M1 con cuatro estados (`IDLE=00`, `REQ=01`, `WAIT=10`, `REARM=11`), ecuaciones de próximo estado, tabla de transiciones, control DRP y condición de captura. Desde `IDLE`, la transición a `REQ` requiere `tick_1ms=1` y `drdy_out=0`.
- Se documentaron la habilitación del temporizador durante la espera en `IDLE` con `drdy_out` bajo, el rearme mediante `drdy_out`, el reset de la lógica de control y el plan de verificación.
- **Estado:** diseño documentado y aprobado para implementación; la implementación RTL, el testbench, la simulación y la validación física siguen pendientes. La FSM aún no está verificada funcionalmente.
