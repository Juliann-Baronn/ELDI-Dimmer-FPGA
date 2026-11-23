# ELDI-Dimmer-FPGA

Proyecto académico de Electrónica Digital para implementar sobre una Digilent Nexys 4 DDR la lógica de un dimmer de corriente alterna por control de ángulo de fase. La FPGA adquiere un ajuste analógico, sincroniza una referencia externa de cruce por cero, calcula un retardo y genera una orden digital de disparo. La adaptación eléctrica y la potencia pertenecen a una interfaz externa aislada, no al RTL.

## Alcance y seguridad

La Nexys 4 DDR procesa señales de baja tensión. No debe conectarse directamente a la red eléctrica ni a la etapa de potencia. La interfaz M8, sus protecciones, aislamiento, montaje y pruebas con CA requieren diseño y validación independientes bajo condiciones de laboratorio adecuadas.

## Plataforma y herramientas

- **Plataforma objetivo:** Digilent Nexys 4 DDR con FPGA Artix-7.
- **RTL:** Verilog.
- **Reloj de referencia documentado:** 100 MHz.
- **Herramientas referenciadas en la documentación existente:** Vivado 2026.1 y XSim.
- **Conversión analógica:** IP XADC Wizard `xadc_wiz_1`, requerida por M1 y no incluida como fuente regenerable en este repositorio.

## Arquitectura M1–M8

```text
Potenciómetro → M1 xadc_interface → M3 pot_to_delay → M5 phase_timer
                                                     ▲         │ timer_done
Detector externo → M2 zero_cross_sync → M4 zero_cross_detect → M6 dimmer_fsm
                                                              │ triac_pulse_start
                                                              ▼
                                                        M7 triac_pulse
                                                              │ gate_pulse
                                                              ▼
                                             M8 interfaz externa aislada
                                             (fuera de la FPGA)
```

`rtl/top/top_dimmer.v` instancia M1–M7. M8 no es un módulo RTL: comienza en el puerto físico `gate_pulse` y corresponde a la interfaz externa de aislamiento y potencia.

## Estado de implementación y evidencia

La existencia de RTL o de un testbench no constituye una validación completa. “Resultado documentado” se refiere únicamente a evidencia registrada; esta actualización no ejecuta simulaciones, síntesis, implementación ni pruebas físicas.

| Módulo | Implementación y pruebas disponibles | Resultados documentados | Estado actual |
|---|---|---|---|
| M1 `xadc_interface` | RTL, `top_xadc_test.v` y `tb_xadc_interface.v`. | La ficha M1 registra una prueba básica con LEDs y métricas temporales del top de prueba; no están los reportes originales. | Control digital e integración de IP presentes; caracterización, simulación autochecking e integración completa pendientes. |
| M2 `zero_cross_sync` | RTL, testbench unitario y prueba M2–M4. | Se registran históricamente 13 comprobaciones unitarias y 32 comprobaciones M2–M4 sin errores. | Sin síntesis, timing integrado ni validación física documentados. |
| M3 `pot_to_delay` | RTL actual, testbench unitario e integración M3–M5. | La ficha M3 conserva 15 comprobaciones y una síntesis standalone como resultados históricos; no hay reporte fuente para la revisión actual. | Timing e integración completa pendientes. |
| M4 `zero_cross_detect` | RTL, testbench unitario y prueba M2–M4. | Se registran históricamente 16 comprobaciones unitarias y 32 comprobaciones M2–M4 sin errores. | Sin síntesis, timing integrado ni validación física documentados. |
| M5 `phase_timer` | RTL, testbench unitario e integración M3–M5. | No hay resultado de ejecución, síntesis o implementación conservado. | Implementación y pruebas disponibles; evidencia de ejecución pendiente. |
| M6 `dimmer_fsm` | RTL, testbench unitario e integración M4–M7. | No hay resultado de ejecución, síntesis o implementación conservado. | Implementación y pruebas disponibles; evidencia de ejecución pendiente. |
| M7 `triac_pulse` | RTL, testbench unitario, integración M4–M7 y top. | No hay resultado de ejecución, síntesis o implementación conservado. | Implementación y pruebas disponibles; evidencia de ejecución pendiente. |
| M8 interfaz externa | `gate_pulse` se expone en `top_dimmer` y tiene asignación de pin. | No hay esquemático, hoja de datos, prueba de hardware ni resultado conservado. | Hardware externo pendiente de documentación y validación. |

## Estructura del repositorio

```text
rtl/
  modules/       M1–M7 en Verilog
  top/           top_xadc_test y top_dimmer
  ip/            reservado para IP; actualmente no contiene xadc_wiz_1
sim/
  unit/          testbenches unitarios
  integration/   testbenches de integración y del top
constraints/     XDC de objetivos unitarios, prueba XADC y top integrado
docs/
  architecture/  arquitectura del sistema
  modules/       fichas M1–M8
  ai/            trazabilidad de contribuciones de IA
verification/
  results/       reservado para evidencia; actualmente sin resultados generados
hardware/        reservado para documentación de la interfaz física; actualmente sin archivos
```

## Restricciones disponibles

- `constraints/xadc_test.xdc`: objetivo `top_xadc_test`, reloj, reset, LEDs y VAUX3.
- `constraints/m2_timing.xdc`, `m3_timing.xdc` y `m4_timing.xdc`: restricciones temporales de referencia para objetivos unitarios.
- `constraints/top_dimmer.xdc`: reloj, reset, VAUX3, entrada `zc_in`, salida `gate_pulse` y excepciones declaradas para las entradas asíncronas del top integrado.

Estos conjuntos corresponden a objetivos distintos. Debe seleccionarse y revisarse el XDC aplicable al top elegido; no deben combinarse automáticamente.

## Reproducción en Vivado

### Material disponible

1. Crear un proyecto Vivado para la Nexys 4 DDR usando la configuración de dispositivo o placa confirmada por el entorno de laboratorio.
2. Añadir los fuentes de `rtl/modules/` y el top que se quiera evaluar: `top_xadc_test` o `top_dimmer`.
3. Añadir exclusivamente el XDC correspondiente al top elegido.
4. Para análisis de testbench, añadir el RTL dependiente y el archivo de `sim/unit/` o `sim/integration/` seleccionado.

### Dependencias y limitaciones

- No hay archivo `.xpr` ni script TCL que reconstruya el proyecto Vivado.
- M1 instancia `xadc_wiz_1`; el envolvente, la configuración de IP y sus productos generados no están en el repositorio. Deben conservarse o regenerarse desde una configuración validada antes de elaborar cualquier diseño que incluya M1.
- La documentación de M1 referencia `design.txt` para estímulo analógico de simulación, pero ese archivo tampoco está incluido.
- No se conservan bitstreams, checkpoints, ondas, logs, reportes de síntesis, implementación o temporización para la versión integrada.
- La disponibilidad de un testbench describe una prueba preparada, no una ejecución satisfactoria.

## Documentación técnica

- [Arquitectura general](docs/architecture/arquitectura_general.md)
- [Bitácora del proyecto](docs/project_log.md)
- [M1 — XADC Interface](docs/modules/M1_xadc_interface.md)
- [M2 — Zero-Cross Synchronizer](docs/modules/M2_zero_cross_sync.md)
- [M3 — Potentiometer-to-Delay Mapper](docs/modules/M3_pot_to_delay.md)
- [M4 — Zero-Cross Event Detector](docs/modules/M4_zero_cross_detect.md)
- [M5 — Phase Timer](docs/modules/M5_phase_timer.md)
- [M6 — Dimmer FSM](docs/modules/M6_dimmer_fsm.md)
- [M7 — TRIAC Pulse](docs/modules/M7_triac_pulse.md)
- [M8 — External Isolated Trigger](docs/modules/M8_external_isolated_trigger.md)
