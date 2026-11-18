# M3 — Potentiometer-to-Delay Mapper

**Proyecto:** ELDI-Dimmer-FPGA
**Fecha de actualización:** 18 de noviembre de 2026
**Módulo RTL:** `pot_to_delay`
**Estado:** RTL, simulación funcional registrada y síntesis standalone documentados; timing e integración con M1 y M5 pendientes.

## 1. Propósito

M3 convierte la muestra de 12 bits producida por M1 en `delay_target`, un retardo de 20 bits medido en ciclos de reloj. No detecta cruces por cero ni genera el pulso de disparo; entrega la consigna que M5 deberá capturar al iniciar una temporización.

```text
pot_sample[11:0], sample_valid → pot_to_delay → delay_target[19:0]
```

## 2. Interfaz

| Puerto | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk` | Entrada | 1 | Reloj común de 100 MHz. |
| `rst` | Entrada | 1 | Reset síncrono activo alto. |
| `pot_sample` | Entrada | 12 | Muestra digital de M1, entre 0 y 4095. |
| `sample_valid` | Entrada | 1 | Pulso que habilita una actualización de la consigna. |
| `delay_target` | Salida | 20 | Retardo objetivo en ciclos de reloj. |

## 3. Mapeo implementado

El RTL usa los parámetros acordados `D_MIN = 10000` y `D_MAX = 800000`, con `SPAN = 790000`. El mapeo es inverso: una lectura baja retrasa más el disparo y una lectura alta lo adelanta.

\[
Q = \left\lfloor\frac{P \cdot 790000 + 2047}{4095}\right\rfloor,
\qquad delay\_target = 800000 - Q
\]

| `pot_sample` | `delay_target` esperado |
|---:|---:|
| 0 | 800000 |
| 1 | 799807 |
| 1024 | 602452 |
| 2048 | 404904 |
| 3072 | 207355 |
| 4094 | 10193 |
| 4095 | 10000 |

Durante reset la salida toma `D_MAX`; sin `sample_valid` conserva la última consigna. El RTL incluye comprobaciones de simulación para impedir `D_MAX < D_MIN` y detectar desbordamiento de la aritmética de 32 bits. No se mantiene como requisito vigente una restricción fija como `D_MAX <= 830564`, porque no corresponde al RTL actual.

## 4. Archivos relacionados

| Tipo | Archivo |
|---|---|
| RTL | `rtl/modules/pot_to_delay.v` |
| Testbench unitario | `sim/unit/tb_pot_to_delay.v` |
| Restricción temporal de referencia | `constraints/m3_timing.xdc` |

## 5. Evidencia registrada

La bitácora de M3 registra que el testbench, con los parámetros actuales, obtuvo **15 comprobaciones correctas y 0 errores**. Cubre reset y prioridad, extremos, valores intermedios, retención sin `sample_valid`, muestras consecutivas y actualización posterior al reset.

También registra síntesis standalone en Vivado 2026.1 para `xc7a100tcsg324-1`: 240 Slice LUTs, 20 registros, un DSP48E1, 35 I/O y un BUFGCTRL; no se reportaron latches. Esta síntesis no equivale a cierre temporal del sistema integrado.

## 6. Pendientes y dependencias

- Revisar el timing de la revisión actual y sus restricciones efectivas.
- Validar el enlace M1–M3 con muestras XADC útiles en la integración.
- Incorporar y verificar M5: debe capturar `delay_target` al aceptar `timer_start`, de modo que cambios posteriores del potenciómetro no alteren una cuenta activa.
- Confirmar la temporización global con M4, M5, M6 y la etapa de salida.

## 7. Estado resumido

| Actividad | Estado |
|---|---|
| RTL y parámetros definitivos | Implementados |
| Simulación unitaria | Resultado registrado: 15 comprobaciones correctas |
| Síntesis standalone | Completada y documentada |
| Timing de esta revisión | Pendiente |
| Integración M1–M3 y M3–M5 | Pendiente |
