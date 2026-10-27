# Arquitectura general del sistema ELDI Dimmer

**Proyecto:** Control de potencia mediante FPGA Digilent Nexys 4 DDR  
**Documento de referencia:** Arquitectura general del sistema, 27 de octubre de 2026  
**Estado:** Arquitectura conceptual en proceso de validación.

## 1. Introducción

El proyecto ELDI Dimmer consiste en diseñar un sistema de control de potencia para una bombilla de corriente alterna mediante regulación por ángulo de fase, utilizando una FPGA Digilent Nexys 4 DDR.

La arquitectura separa la adquisición del ajuste del usuario, la detección del cruce por cero, el cálculo y la temporización del retardo, la coordinación mediante una máquina de estados y la generación de la orden digital de disparo.

Cada bloque tendrá una responsabilidad definida, interfaces identificables y un procedimiento de verificación independiente antes de integrarse en el sistema completo.

## 2. Objetivo funcional

El sistema debe interpretar el ajuste de un potenciómetro y utilizarlo para definir un retardo respecto a un evento de cruce por cero de la señal de corriente alterna.

Una vez transcurrido ese retardo, la FPGA genera un pulso digital que se entrega a una interfaz externa de disparo optoaislada. Esta interfaz controla el TRIAC de la etapa de potencia, que regula la energía entregada a la bombilla.

La FPGA se encarga del procesamiento digital y de la temporización. La adaptación eléctrica y el aislamiento entre la lógica de baja tensión y la etapa de potencia corresponden a la interfaz externa.

## 3. Alcance de este documento

Este documento describe la arquitectura funcional, las responsabilidades de los módulos, sus principales interfaces y los aspectos pendientes de validación.

No constituye un esquema eléctrico definitivo ni una autorización para conectar la FPGA directamente a la red eléctrica.

Los parámetros y las decisiones que todavía no se hayan verificado se identificarán expresamente como pendientes, para evitar tratarlos como definitivos antes de contar con la documentación técnica y las pruebas correspondientes.
## 4. Vista general de la arquitectura

La arquitectura contiene dos ramas de entrada independientes que convergen en la lógica de control.

### 4.1. Rama de ajuste

**Flujo:** Potenciómetro → XADC → `xadc_interface` (M1) → `control_mapper` (M3) → `delay_target`.

Esta rama adquiere el ajuste del usuario mediante el convertidor analógico-digital XADC de la FPGA y transforma la muestra obtenida en un valor de retardo para el control de fase.

### 4.2. Rama de sincronización

**Flujo:** Detector externo de cruce por cero → `zero_cross_sync` (M2) → `zero_cross_detect` (M4) → `zc_event`.

Esta rama recibe la señal digital del detector externo, la sincroniza con el reloj de la FPGA y genera un evento que sirve como referencia temporal para iniciar el control de fase.

### 4.3. Temporización y coordinación

La máquina de estados `dimmer_fsm` (M6) coordina el funcionamiento del sistema. Recibe el evento de cruce por cero y ordena al temporizador `phase_timer` (M5) contar los ciclos correspondientes al retardo establecido.

Cuando termina la temporización, la máquina de estados ordena al generador `triac_pulse` (M7) producir el pulso digital de disparo.

### 4.4. Salida hacia la etapa de potencia

La señal `gate_pulse` se lleva a una salida física de la FPGA mediante la interfaz digital de salida (M8). Después se entrega a una interfaz externa optoaislada compatible con el circuito de disparo del TRIAC.

La FPGA no debe conectarse directamente a la red eléctrica ni a la etapa de potencia.

### 4.5. Integración del sistema

El módulo superior `dimmer_top` instancia e interconecta los módulos de la arquitectura. También integra las señales de reloj, reinicio, las interfaces físicas y las conexiones requeridas por la IP del XADC.

La ubicación definitiva de los registros internos y algunos parámetros de las interfaces se determinará durante el diseño detallado de los módulos.
## 5. Filosofía de diseño

La arquitectura se organiza siguiendo los siguientes criterios:

### 5.1. Separación de responsabilidades

Cada módulo realiza una función principal y expone señales de interfaz explícitas. Esta organización facilita comprender, implementar, probar y corregir cada parte sin tener que modificar todo el sistema.

### 5.2. Sincronización de entradas asíncronas

La señal externa de cruce por cero se sincroniza con el reloj de la FPGA antes de ser procesada por la lógica secuencial. La arquitectura propone una estructura de dos flip-flops en cascada para reducir el riesgo de que la metastabilidad afecte al resto del sistema.

### 5.3. Control basado en eventos

El evento de cruce por cero proporciona la referencia temporal para iniciar la temporización de fase. El retardo se mide mediante ciclos del reloj de la FPGA.

### 5.4. Comportamiento seguro

Durante el reinicio y cuando no existe una secuencia válida de control, la salida de disparo debe permanecer inactiva. La máquina de estados coordina la temporización y el pulso para evitar disparos sin un evento válido.

### 5.5. Separación entre lógica y potencia

La FPGA genera una orden digital de baja tensión. Una interfaz externa adecuada debe proporcionar el aislamiento y la adaptación eléctrica necesarios para conectar el control digital con la etapa de potencia.

### 5.6. Verificación incremental

Cada módulo debe verificarse individualmente antes de integrarlo con los demás. Una vez comprobados los bloques por separado, se realizarán pruebas de integración para evaluar el comportamiento del sistema completo.

### 5.7. Decisiones pendientes de validación

Los parámetros que dependan de componentes, configuraciones de IP, restricciones físicas o pruebas experimentales se mantendrán como provisionales hasta contar con evidencia suficiente para confirmarlos.
## 6. Módulos de la arquitectura

La arquitectura define ocho módulos funcionales y un módulo superior de integración.

| Identificador | Módulo | Responsabilidad principal |
|---|---|---|
| M1 | `xadc_interface` | Obtener muestras digitales del potenciómetro mediante la interfaz del XADC. |
| M2 | `zero_cross_sync` | Sincronizar la señal externa de cruce por cero con el reloj de la FPGA. |
| M3 | `control_mapper` | Convertir la muestra del potenciómetro en el valor de retardo `delay_target`. |
| M4 | `zero_cross_detect` | Detectar el evento de cruce por cero y generar `zc_event`. |
| M5 | `phase_timer` | Contar los ciclos de reloj correspondientes al retardo y generar `timer_done`. |
| M6 | `dimmer_fsm` | Coordinar la secuencia de detección, temporización y disparo mediante una máquina de estados. |
| M7 | `triac_pulse` | Generar el pulso digital de disparo con una duración definida. |
| M8 | Interfaz digital de salida | Llevar la señal `gate_pulse` al puerto físico de salida de la FPGA. |
| — | `dimmer_top` | Instanciar e interconectar los módulos, el reloj, el reinicio y las interfaces necesarias. |

### 6.1. Criterio de implementación

Cada módulo tendrá una descripción detallada antes de su implementación. Esa descripción deberá establecer:

- Función y justificación del módulo.
- Entradas y salidas, incluyendo sus nombres y anchuras.
- Comportamiento esperado y condiciones límite.
- Relación con los demás módulos.
- Pruebas necesarias para verificar su funcionamiento.

### 6.2. Estado de implementación

Los módulos de esta tabla representan la arquitectura definida en el documento de referencia. Su inclusión en la arquitectura no significa que estén implementados ni verificados en Verilog.

Las interfaces, los parámetros y los comportamientos que el documento identifica como pendientes deberán resolverse antes de considerar definitivo el diseño de cada módulo.
## 7. Interfaces principales

Las siguientes señales representan las interfaces funcionales previstas entre los módulos. Las anchuras marcadas como provisionales deberán confirmarse durante el diseño detallado.

| Señal | Origen → destino | Anchura prevista | Función |
|---|---|---|---|
| `pot_sample` | M1 → M3 | 12 bits, provisional | Muestra digital del potenciómetro. |
| `sample_valid` | M1 → M3 | 1 bit | Indica que hay una muestra disponible. |
| `delay_target` | M3 → M5 | 20 bits, provisional | Número objetivo de ciclos para la temporización. |
| `zc_in` | Detector externo → M2 | 1 bit | Señal digital asíncrona de cruce por cero. |
| `zc_sync` | M2 → M4 | 1 bit | Señal de cruce por cero sincronizada. |
| `zc_event` | M4 → M6 | 1 bit | Evento detectado de cruce por cero. |
| `timer_start` | M6 → M5 | 1 bit | Orden de inicio de la temporización. |
| `timer_clear` | M6 → M5 | 1 bit | Orden de cancelación o reinicio del conteo. |
| `timer_done` | M5 → M6 | 1 bit | Indica que terminó la temporización. |
| `pulse_start` | M6 → M7 | 1 bit | Orden de inicio del pulso de disparo. |
| `pulse_done` | M7 → M6 | 1 bit | Indica que terminó el pulso. |
| `gate_pulse` | M7/M8 → interfaz externa | 1 bit | Orden digital de disparo. |
| `clk` | Reloj → lógica secuencial | 1 bit | Reloj de referencia previsto de 100 MHz. |
| `rst` | Reinicio → módulos | 1 bit | Reinicio de estados y contadores. |

La interfaz analógica `pot_voltage` conecta el potenciómetro con la entrada del XADC. Su pin, rango admisible y acondicionamiento eléctrico deberán validarse antes de conectar la señal físicamente.
## 8. Aspectos pendientes de definición y validación

La arquitectura está definida a nivel conceptual, pero los siguientes puntos deben resolverse antes de considerar definitivo el diseño.

| Tema | Aspecto pendiente |
|---|---|
| XADC | Confirmar canal, pin, rango de tensión, configuración de la IP, bits útiles y protocolo de lectura. |
| Detector de cruce por cero | Definir el circuito externo, los niveles lógicos, la forma de onda, la polaridad y el aislamiento. |
| Detección del evento | Determinar qué flancos se detectarán y si es necesario rechazar transiciones espurias. |
| Mapeo del potenciómetro | Definir los límites de `delay_target`, su resolución y el tratamiento de muestras inválidas. |
| Temporizador | Establecer el conteo exacto de ciclos, el comportamiento con retardo cero y las prioridades de inicio y cancelación. |
| Máquina de estados | Definir las transiciones, las salidas por estado y el comportamiento ante eventos inesperados o simultáneos. |
| Pulso de disparo | Determinar su duración según la interfaz externa y el TRIAC seleccionados. |
| Etapa de potencia | Validar la interfaz optoaislada, el TRIAC, la bombilla y las protecciones correspondientes. |
| Pines y restricciones | Confirmar los pines físicos, el reloj, las polaridades y las restricciones del archivo `.xdc`. |
| Reinicio | Confirmar el pin, la polaridad del botón y la compatibilidad con la configuración del XADC. |
| Verificación | Definir y ejecutar las simulaciones individuales y de integración antes de las pruebas físicas. |

### 8.1. Criterio para cerrar una decisión

Un punto pendiente solo se considerará definido cuando exista una justificación técnica suficiente y, cuando corresponda, evidencia procedente de documentación del fabricante, configuración de Vivado, simulaciones o pruebas controladas.

### 8.2. Seguridad

La FPGA debe permanecer eléctricamente separada de la etapa de potencia mediante una interfaz de aislamiento adecuada. La señal digital `gate_pulse` no proporciona aislamiento por sí misma.

El montaje y las pruebas de la etapa conectada a la red de corriente alterna deben realizarse con las protecciones adecuadas y bajo supervisión cualificada.