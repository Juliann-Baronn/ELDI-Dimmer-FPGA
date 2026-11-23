# M8 — External Isolated Trigger

**Proyecto:** ELDI-Dimmer-FPGA  
**Actualización documental:** 23 de noviembre de 2026  
**Estado:** Interfaz externa de hardware; no existe módulo RTL, testbench de hardware ni evidencia de montaje en el repositorio.

## 1. Propósito del módulo

M8 representa la interfaz externa entre la salida digital `gate_pulse` de la FPGA y una eventual etapa de disparo y potencia de CA. Su función arquitectónica es mantener separada la lógica de baja tensión de la circuitería que pudiera manejar la carga.

## 2. Función dentro de la arquitectura

`top_dimmer` entrega `gate_pulse`, generado por M7, a un puerto de salida de la FPGA. `constraints/top_dimmer.xdc` asigna ese puerto al pin D18, identificado como JA2. A partir de ese punto, la adaptación eléctrica, el aislamiento, el disparo y la etapa de potencia pertenecen a M8 y están fuera del RTL.

## 3. Entradas y salidas

| Interfaz | Dirección respecto de M8 | Ancho | Descripción |
|---|---|---:|---|
| `gate_pulse` | Entrada | 1 | Orden digital procedente de M7 y expuesta por `top_dimmer`. |
| Interfaz hacia potencia | Salida | No documentado | Señal o red eléctrica resultante hacia una etapa externa; su topología no está definida en el repositorio. |

## 4. Funcionamiento implementado

No hay funcionamiento de M8 implementado en Verilog. El comportamiento implementado dentro de la FPGA se limita a generar y exponer `gate_pulse`; no implementa aislamiento, adaptación de nivel, control de compuerta, conmutación de CA ni protecciones eléctricas.

## 5. Dependencias e interfaces

- Origen digital: M7 `triac_pulse` a través de `top_dimmer`.
- Asignación física documentada: `constraints/top_dimmer.xdc`, salida `gate_pulse` en D18/JA2.
- Dependencia externa: un diseño de interfaz aislada y de potencia que no está almacenado en el repositorio.

## 6. RTL disponible

No existe RTL específico para M8. `rtl/top/top_dimmer.v` sólo expone la señal digital que debe entregar a la interfaz externa.

## 7. Testbenches disponibles

No existe testbench específico de la interfaz física M8. `sim/integration/tb_top_dimmer.v` observa una salida digital del top, pero no modela ni verifica aislamiento, componentes, red de CA ni comportamiento de potencia.

## 8. Resultados documentados

No se conservan esquemáticos, lista de materiales, hojas de datos, capturas de osciloscopio, resultados de simulación eléctrica, pruebas de aislamiento ni pruebas físicas de M8.

MOC3021M y BTA16-600B se identifican como componentes de interés para esta etapa externa, pero no hay información técnica respaldada sobre ellos dentro del repositorio. Por ello, este documento no afirma pinout, valores eléctricos, modo de disparo, conexión, compatibilidad ni rendimiento de dichos componentes.

## 9. Limitaciones y trabajo pendiente

- Incorporar documentación técnica verificable de los componentes seleccionados antes de definir la interfaz.
- Elaborar y revisar el esquema eléctrico, la adaptación de niveles, el aislamiento, las protecciones y la conexión de potencia.
- Definir condiciones de prueba seguras y obtener evidencia física antes de conectar una carga de CA.
- Verificar que el ancho de `gate_pulse` y la polaridad de la señal sean compatibles con la interfaz externa finalmente documentada.
