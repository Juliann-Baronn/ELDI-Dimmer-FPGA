
# M1 — XADC Interface

**Proyecto:** ELDI-Dimmer-FPGA  
**Fecha del avance:** 3 de noviembre de 2026  
**Estado:** Diseño revisado; preparación para implementación RTL.  
**Módulo:** `xadc_interface`  
**Plataforma:** Digilent Nexys 4 DDR — Artix-7  
**Herramienta:** Vivado 2026.1  

## 1. Objetivo del módulo

El módulo `xadc_interface` (M1) proporciona la interfaz entre el XADC Wizard generado en Vivado y la lógica digital del sistema.

Su función es obtener las muestras digitalizadas del potenciómetro y entregarlas al módulo M3 mediante las señales `pot_sample` y `sample_valid`.

## 2. Trabajo realizado

Durante esta etapa se revisó la configuración real del XADC Wizard generado en Vivado. Se inspeccionaron:

- Los puertos disponibles en la instancia `xadc_wiz_1`.
- El template de instanciación generado por Vivado.
- El archivo envolvente `xadc_wiz_1.v`.
- La configuración y versión de la IP.
- Las conexiones del canal auxiliar VAUX3.
- La interfaz DRP utilizada para consultar los resultados de conversión.
- Las señales de control y estado disponibles.

**Importante:** todavía no se ha implementado `xadc_interface.v`, no se ha construido su testbench y no se ha realizado una simulación funcional de M1.

## 3. Decisiones confirmadas

| Elemento | Decisión |
|---|---|
| Módulo | `xadc_interface` |
| FPGA | Nexys 4 DDR — Artix-7 |
| Reloj del sistema | 100 MHz |
| IP del convertidor | `xadc_wiz_1` |
| Versión de IP | XADC Wizard 3.3, revisión 15 |
| Interfaz de acceso | DRP |
| Entrada analógica | VAUX3 |
| Señales analógicas | `vauxp3`, `vauxn3` |
| Dirección del registro | `7'h13` |
| Tipo de operación | Lectura (`DWE = 0`) |
| Datos útiles | 12 bits en `DO[15:4]` |
| Salida hacia M3 | `pot_sample[11:0]` |
| Indicador de muestra | `sample_valid` |
| Retención | Conservar la última muestra válida hasta recibir otra lectura válida |

## 4. Comportamiento de las muestras

Cuando se completa una lectura válida:

1. Se captura `do_out[15:4]` en `pot_sample`.
2. Se genera un pulso de un ciclo de reloj en `sample_valid`.
3. En los ciclos posteriores, `sample_valid` vuelve a cero.
4. `pot_sample` conserva su valor hasta recibir una nueva lectura válida.

La inicialización del registro durante el reset se definirá en la implementación.

## 5. Protocolo DRP

De acuerdo con UG480:

- `DEN` debe activarse durante un único ciclo de DCLK.
- `DWE = 0` selecciona una operación de lectura.
- `DADDR` contiene la dirección del registro consultado.
- `DO` se captura cuando `DRDY` indica que los datos están disponibles.
- No se inicia una nueva transacción hasta que `DRDY` vuelva a cero.

## 6. Organización de control propuesta

Se plantea una máquina de estados de cuatro estados:

| Estado | Función |
|---|---|
| `IDLE` | Esperar la condición de inicio de lectura. |
| `REQ` | Generar la solicitud DRP de un ciclo. |
| `WAIT` | Esperar la respuesta `DRDY`. |
| `REARM` | Esperar que `DRDY` vuelva a cero antes de permitir otra lectura. |

La captura de datos y la activación de `sample_valid` se realizarán cuando la FSM esté en `WAIT` y `DRDY` esté activo.

Esta organización es una propuesta pendiente de consolidación mediante revisión RTL y simulación.

## 7. Temporización propuesta

Se plantea utilizar un contador de 17 bits para generar un intervalo de 1 ms con un reloj de 100 MHz.

- Frecuencia: 100 MHz.
- Periodo de reloj: 10 ns.
- Ciclos correspondientes a 1 ms: 100 000.
- Conteo propuesto: de 0 a 99 999.

La relación exacta entre este intervalo y las solicitudes, capturas y transacciones DRP deberá definirse durante la implementación.

## 8. Reset

Se debe distinguir entre:

- `rst`: reset de la lógica propia de M1, propuesto síncrono y activo en alto.
- `reset_in`: reset de la IP XADC, conectado respetando las características de la primitiva.

La documentación UG480 identifica el reset del XADC como activo en alto y asíncrono. No se debe modificar el comportamiento interno de la IP generada por Vivado.

## 9. Aspectos pendientes

1. Consolidar las transiciones y ecuaciones de la FSM.
2. Definir la temporización exacta entre solicitudes DRP y el intervalo entre muestras.
3. Definir la secuencia de liberación del reset durante la integración.
4. Confirmar la correspondencia definitiva de los puertos externos con M3.
5. Implementar y revisar el RTL.
6. Construir el testbench y ejecutar la simulación.
7. Validar el comportamiento con la IP XADC y el potenciómetro.

## 10. Plan de verificación

### Etapa 1 — Revisión RTL

- Comprobar que `DEN` dura un ciclo.
- Verificar `DWE = 0`.
- Verificar `DADDR = 7'h13`.
- Confirmar que la captura depende de `DRDY`.
- Comprobar el rearme antes de una nueva solicitud.

### Etapa 2 — Registro de muestra

- Confirmar la captura de los 12 bits correctos.
- Confirmar la retención del último valor válido.
- Confirmar que `sample_valid` dura un ciclo.
- Comprobar el comportamiento durante reset.

### Etapa 3 — Temporización

- Comprobar el contador de 1 ms.
- Verificar la secuencia de solicitudes y respuestas DRP.
- Comprobar que no se generen solicitudes repetidas durante una transacción activa.

### Etapa 4 — Simulación

- Ejecutar el testbench.
- Probar diferentes respuestas de `DRDY`.
- Comprobar reset y retención de datos.
- Revisar las formas de onda.

### Etapa 5 — Prueba física

- Integrar la IP XADC generada por Vivado.
- Programar la Nexys 4 DDR.
- Variar el potenciómetro.
- Comprobar que `pot_sample` cambia de acuerdo con la entrada analógica.

## 11. Estado del módulo

| Actividad | Estado |
|---|---|
| Inspección de la IP XADC | Completada |
| Identificación de puertos DRP | Completada |
| Identificación de VAUX3 | Completada |
| Revisión del protocolo DRP | Completada |
| Definición de retención de muestra | Confirmada |
| Definición de `sample_valid` | Confirmada |
| Diseño detallado de FSM | Pendiente |
| Implementación RTL | Pendiente |
| Testbench | Pendiente |
| Simulación | Pendiente |
| Prueba física | Pendiente |

## 12. Conclusión

M1 cuenta con una base técnica revisada y con el comportamiento de retención de muestras definido. El siguiente paso es consolidar su contrato de interfaz y construir la implementación RTL en Verilog, sin modificar la IP generada por Vivado.

La integración con M3 se realizará después de verificar individualmente el funcionamiento de M1.
