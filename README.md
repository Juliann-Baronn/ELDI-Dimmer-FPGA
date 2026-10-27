
# ELDI-Dimmer-FPGA

## Descripción

Proyecto académico de Electrónica Digital para diseñar e implementar un dimmer de control de potencia mediante una FPGA Digilent Nexys 4 DDR.

El sistema busca regular la potencia entregada a una carga de corriente alterna mediante control por ángulo de fase, utilizando detección de cruce por cero, temporización digital y una interfaz de disparo con aislamiento.

## Objetivos del repositorio

- Documentar la arquitectura y las decisiones de diseño.
- Desarrollar los módulos digitales en Verilog.
- Verificar el comportamiento mediante simulaciones y pruebas.
- Organizar las restricciones y los recursos necesarios para la FPGA.
- Registrar los aportes relevantes de inteligencia artificial durante el desarrollo.

## Organización

- `docs/`: arquitectura, documentación de módulos, decisiones y registro de avances.
- `docs/ai/`: registro resumido de los aportes importantes de inteligencia artificial.
- `rtl/`: código Verilog del sistema y sus módulos.
- `sim/`: bancos de prueba y simulaciones.
- `constraints/`: restricciones de implementación de la FPGA.
- `verification/`: evidencias y resultados de verificación.
- `hardware/`: documentación del montaje y de las interfaces físicas.

## Estado del proyecto

**Fase actual:** preparación del repositorio y organización inicial.

La arquitectura y las interfaces se irán consolidando a medida que se revisen y validen las decisiones de diseño.

## Seguridad

El circuito de potencia de corriente alterna debe mantener aislamiento adecuado respecto a la FPGA. Las pruebas con tensión de red requieren montaje protegido y supervisión de laboratorio.
