
# ELDI-Dimmer-FPGA

Proyecto académico de Electrónica Digital para implementar un dimmer de corriente alterna por control de ángulo de fase sobre una **Digilent Nexys 4 DDR** (Artix-7). La FPGA adquiere el ajuste del potenciómetro, sincroniza el cruce por cero y, tras completar la lógica de temporización y disparo, deberá controlar una interfaz externa aislada hacia el TRIAC.

## Herramientas y alcance

El RTL está escrito en Verilog y los avances se han documentado con Vivado 2026.1 y XSim. La FPGA procesa lógica de baja tensión; no se conecta directamente a la red eléctrica. Cualquier prueba de potencia requiere aislamiento, montaje protegido y supervisión de laboratorio.

## Estructura

- `rtl/modules/`: módulos Verilog reutilizables.
- `rtl/top/`: módulos superiores de prueba e integración.
- `sim/unit/`: testbenches unitarios.
- `sim/integration/`: testbenches de integración.
- `constraints/`: restricciones para objetivos específicos de implementación.
- `docs/`: arquitectura, documentación técnica, bitácora del proyecto y registro de IA.
- `verification/`: evidencias y resultados de verificación.
- `hardware/`: documentación del montaje y de interfaces físicas.

## Estado de módulos

| Módulo | Estado actual |
|---|---|
| M1 `xadc_interface` | RTL implementado; una prueba básica en placa registró variación de LED al mover el potenciómetro. Caracterización e integración M1–M3 pendientes. |
| M2 `zero_cross_sync` | RTL implementado; resultado unitario registrado de 13 comprobaciones correctas. |
| M3 `pot_to_delay` | RTL implementado con salida de 20 bits; resultados registrados de 15 comprobaciones correctas y síntesis standalone. |
| M4 `zero_cross_detect` | RTL implementado; resultado unitario registrado de 16 comprobaciones correctas. |
| Integración M2–M4 | Resultado conductual registrado: 32 comprobaciones y 0 errores. |
| M5 `phase_timer` | Testbench en desarrollo; RTL aún no disponible. |
| M6–M8 y `dimmer_top` | Pendientes de implementación e integración. |

Los resultados registrados no sustituyen la verificación integrada ni las pruebas físicas pendientes. No se ejecutan simulaciones automáticamente al clonar este repositorio.

## Documentación técnica

- [Arquitectura general](docs/architecture/arquitectura_general.md)
- [Registro de avances](docs/project_log.md)
- [M1 — XADC Interface](docs/modules/M1_xadc_interface.md)
- [M2 — Zero-Cross Synchronizer](docs/modules/M2_zero_cross_sync.md)
- [M3 — Potentiometer-to-Delay Mapper](docs/modules/M3_pot_to_delay.md)
- [M4 — Zero-Cross Event Detector](docs/modules/M4_zero_cross_detect.md)

## Restricciones e IP

`xadc_test.xdc` y `m3_timing.xdc` corresponden a objetivos distintos; no deben tratarse como un único conjunto de restricciones sin revisar el reloj y los pines definidos por cada flujo. M1 requiere la configuración reproducible de la IP `xadc_wiz_1`; sus productos generados de Vivado no forman parte del RTL fuente.
