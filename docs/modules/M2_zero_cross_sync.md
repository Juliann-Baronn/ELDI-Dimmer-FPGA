# M2 — Zero-Cross Synchronizer

**Proyecto:** ELDI-Dimmer-FPGA
**Fecha de actualización:** 18 de noviembre de 2026
**Módulo RTL:** `zero_cross_sync`
**Estado:** Implementado y verificado mediante simulación conductual registrada; validación física, síntesis y timing integrado pendientes.

## 1. Propósito

M2 recibe `zc_in`, una señal procedente del detector externo de cruce por cero que puede cambiar de forma asíncrona respecto al reloj de la FPGA. Su única responsabilidad es entregar `zc_sync`, una versión registrada y sincronizada para la lógica posterior. La detección del evento corresponde a M4.

El flujo de esta etapa es:

```text
zc_in → sync_ff1 → sync_ff2 → zc_sync
```

## 2. Interfaz y comportamiento

| Puerto | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk` | Entrada | 1 | Reloj común de 100 MHz. |
| `rst` | Entrada | 1 | Reset síncrono activo alto. |
| `zc_in` | Entrada | 1 | Entrada asíncrona del detector externo. |
| `zc_sync` | Salida | 1 | Salida de la segunda etapa del sincronizador. |

El RTL implementa dos registros en cascada, `sync_ff1` y `sync_ff2`, ambos marcados con `ASYNC_REG = "TRUE"`. Durante reset ambos se limpian a cero. Fuera de reset, el primer registro captura `zc_in` y el segundo captura el valor anterior del primero; por ello la cadena añade dos etapas de registro antes de que M4 observe el nivel sincronizado.

## 3. Archivos relacionados

| Tipo | Archivo |
|---|---|
| RTL | `rtl/modules/zero_cross_sync.v` |
| Testbench unitario | `sim/unit/tb_zero_cross_sync.v` |
| Integración | `sim/integration/tb_zero_cross_chain.v` |
| Módulo posterior | `rtl/modules/zero_cross_detect.v` |

## 4. Evidencia registrada

La bitácora técnica de M2 registra que el testbench unitario reportó **13 comprobaciones correctas**. Los casos cubren reset, propagación de flancos de subida y bajada por ambas etapas, nivel alto sostenido, pulso corto y reset durante funcionamiento.

También registra una simulación conductual de la cadena M2–M4, ejecutada el 17 de noviembre de 2026, con **32 comprobaciones y 0 errores**. El testbench conecta `zc_in → zc_sync → zc_event` y comprueba la latencia de sincronización, la generación del evento en M4, flancos sucesivos y recuperación tras reset.

Estos resultados son evidencia registrada en las bitácoras y se preservan sin afirmar una nueva ejecución durante esta actualización documental.

## 5. Límites de la evidencia

- El sincronizador reduce el riesgo de propagar metastabilidad; no garantiza que un pulso externo demasiado corto sea muestreado.
- La simulación conductual no valida la polaridad, el aislamiento ni la forma de onda del detector físico de cruce por cero.
- No hay síntesis standalone, análisis temporal post-implementación ni prueba física documentados para M2.

## 6. Pendientes

1. Revisar síntesis y preservación del atributo `ASYNC_REG`.
2. Revisar CDC y timing dentro del diseño integrado.
3. Validar el detector externo aislado y el ancho mínimo de pulso en condiciones de laboratorio.

## 7. Estado resumido

| Actividad | Estado |
|---|---|
| RTL y contrato de interfaz | Implementados |
| Testbench unitario | Resultado registrado: 13 comprobaciones correctas |
| Integración conductual M2–M4 | Resultado registrado: 32 comprobaciones, 0 errores |
| Síntesis y timing integrado | Pendientes |
| Prueba física | Pendiente |
