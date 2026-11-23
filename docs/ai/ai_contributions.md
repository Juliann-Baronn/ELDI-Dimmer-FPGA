
# Registro de uso de inteligencia artificial

**Proyecto:** ELDI-Dimmer-FPGA  
**Actualización de cierre documental:** 23 de noviembre de 2026

## Propósito y alcance

Este documento registra de manera transparente el uso de herramientas de inteligencia artificial (IA) como apoyo durante el desarrollo del proyecto ELDI Dimmer. La IA se utilizó como recurso de orientación técnica, explicación y elaboración de propuestas; no se presenta como autora autónoma del proyecto ni como sustituto del trabajo de ingeniería realizado por sus integrantes.

Las contribuciones descritas en este registro no constituyen, por sí mismas, evidencia de que el RTL, los testbenches, las restricciones, la síntesis, la implementación o las pruebas físicas hayan sido ejecutados satisfactoriamente. Esa evidencia debe conservarse y evaluarse por separado.

## Registro histórico

Las siguientes entradas conservan el contexto de las actividades documentales registradas durante el avance inicial del proyecto. Describen contribuciones puntuales de esas fechas y no limitan el alcance del acompañamiento técnico de IA descrito en la actualización de cierre.

| Utilización de IA | Trabajo de los integrantes | Resultado | Verificación y límites |
|---|---|---|---|
| Apoyo en la organización y documentación del avance M1 — XADC Interface (3 de noviembre de 2026). | La inspección de Vivado y las decisiones técnicas sobre XADC, DRP, VAUX3, señales e implementación fueron realizadas por el estudiante. | Documentación de M1, actualización del registro de avances y reflejo de las decisiones confirmadas en la arquitectura. | Los integrantes revisan los documentos y validan las decisiones técnicas; el registro no demuestra por sí solo RTL, simulación ni prueba física. |
| Apoyo en la organización y documentación del diseño de la FSM de M1 (3 de noviembre de 2026). | El diseño de la FSM y las decisiones técnicas fueron realizados y aprobados por el estudiante; la IA apoyó en organizar su documentación. | Incorporación de estados, codificación, transiciones, señales de control, relación temporal y plan de verificación en los documentos del proyecto. | La documentación requiere revisión final de los integrantes. Esta entrada histórica no atribuye a la IA resultados de implementación o validación funcional. |
| Apoyo en la organización y documentación del avance de M1 (10 de noviembre de 2026). | La implementación RTL, las decisiones técnicas, la configuración, el testbench, las pruebas y los resultados fueron realizados u observados por el estudiante. | Organización de la información suministrada en la documentación de M1, arquitectura general y registro de avances. | No se atribuyen a la IA resultados de simulación o hardware. Las evidencias originales deben conservarse y revisarse. |
| Apoyo en la consolidación documental de los avances M1–M5 (18 de noviembre de 2026). | Las bitácoras, resultados reportados, decisiones técnicas, RTL, testbenches y restricciones fueron aportados o validados por el estudiante. | Actualización de la documentación de M1, creación de fichas para M2–M4, actualización de arquitectura, README y registro de avances; se diferenciaron resultados registrados de trabajo pendiente. | La IA no ejecutó simulaciones, síntesis ni pruebas físicas. Los integrantes deben revisar la redacción y conservar la evidencia original. |

## Actualización de cierre documental — 23 de noviembre de 2026

Durante el desarrollo completo del proyecto, las herramientas de IA también se emplearon como apoyo técnico y académico en las siguientes actividades:

| Área de apoyo | Alcance de la asistencia de IA | Límite de la contribución |
|---|---|---|
| Desarrollo de código | Orientación para construir módulos en Verilog, explicar su funcionamiento, estructurar la lógica y comprender las interfaces entre módulos. | Las decisiones de diseño y el código incorporado deben ser revisados, comprendidos y asumidos por los integrantes. |
| Elaboración de testbenches | Apoyo en el diseño y construcción de pruebas unitarias y de integración orientadas a comprobar el comportamiento esperado de los módulos. | La presencia de un testbench no demuestra que se haya ejecutado ni que haya finalizado sin errores. |
| Depuración y solución de errores | Asistencia en el análisis de errores de compilación, problemas de simulación, inconsistencias lógicas y comportamientos inesperados; propuesta de posibles soluciones y explicación de su razonamiento. | Las propuestas de IA requieren revisión técnica antes de adoptarse y no sustituyen la depuración ni la validación realizadas por los integrantes. |
| Documentación técnica | Apoyo en la redacción y organización de fichas de módulos, arquitectura general, interfaces, bitácoras y explicaciones del código. | La documentación debe mantenerse coherente con los archivos fuente y con la evidencia disponible. |
| Organización del repositorio | Orientación para definir la estructura de carpetas, organizar archivos, documentar dependencias y preparar el repositorio para la entrega. | La estructura final y los archivos incorporados son responsabilidad de los integrantes del proyecto. |
| Acompañamiento técnico y académico | Explicación de conceptos de FPGA, Verilog, temporización, sincronización, máquinas de estados, interfaces y otros temas relacionados, para apoyar la comprensión de las decisiones de diseño. | La comprensión, aplicación y evaluación de esos conceptos corresponde a los integrantes. |

## Responsabilidad de los integrantes

- Los integrantes del proyecto son responsables del diseño, las decisiones de ingeniería, la implementación incorporada y el resultado final.
- El código y las propuestas desarrolladas con asistencia de IA deben ser revisados y comprendidos por los integrantes antes de utilizarse en el proyecto.
- La IA funciona como herramienta de apoyo y no sustituye la revisión técnica, las pruebas, la síntesis, la implementación ni la validación experimental.
- La inclusión de un testbench en el repositorio no demuestra que haya sido ejecutado satisfactoriamente.
- Los resultados de simulación, síntesis, implementación, temporización y pruebas físicas deben estar respaldados por evidencia real, trazable y correspondiente a la versión evaluada.

## Criterio de trazabilidad

El uso de IA debe registrarse cuando haya contribuido de forma relevante a una decisión, una explicación, una propuesta de código, una estrategia de prueba, una actividad de depuración o la organización del proyecto. Este registro no asigna porcentajes de contribución ni reemplaza la trazabilidad técnica de cambios, resultados y evidencias experimentales.
