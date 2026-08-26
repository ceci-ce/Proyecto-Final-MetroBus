# Gobierno del dato — MetroBus Analytics

Este documento recoge las principales decisiones de gobierno y calidad del dato aplicadas en el proyecto **MetroBus Analytics**.

El objetivo es garantizar que los datos utilizados para el análisis y el cuadro de mando sean comprensibles, trazables y coherentes con las reglas de negocio definidas.

---

# 1. Diccionario de datos

## 1.1. `fact_viajes`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `viaje_id` | INT | Identificador único del viaje | > 0 | Clave primaria |
| `linea_id` | INT | Línea utilizada | 1–10 | FK a `dim_linea` |
| `vehiculo_id` | INT | Vehículo utilizado | > 0 | FK a `dim_vehiculo` |
| `conductor_id` | INT | Conductor asignado | > 0 | FK a `dim_conductor` |
| `parada_origen_id` | INT | Parada de origen | > 0 | FK a `dim_parada` |
| `parada_destino_id` | INT | Parada de destino | > 0 | FK a `dim_parada` |
| `fecha` | DATE | Fecha del viaje | 2022–2024 | En origen aparece como texto |
| `anno` | INT | Año del viaje | 2022–2024 | Coherente con `fecha` |
| `mes` | INT | Mes del viaje | 1–12 | Coherente con `fecha` |
| `dia_semana` | VARCHAR | Día de la semana | Lunes–Domingo | Existían valores en mayúsculas |
| `es_festivo` | BOOLEAN | Indica si el día es festivo | TRUE/FALSE | Sin incidencias relevantes |
| `franja_horaria` | VARCHAR | Franja horaria | Valores definidos por negocio | Sin incidencias relevantes |
| `hora_salida_prog` | TIME | Hora programada de salida | 00:00–23:59 | En origen aparece como texto |
| `hora_salida_real` | TIME | Hora real de salida | 00:00–23:59 | En origen aparece como texto |
| `hora_llegada_real` | TIME | Hora real de llegada | 00:00–23:59 | En origen aparece como texto |
| `retraso_salida_min` | INT | Diferencia entre salida real y programada | Valores negativos o positivos | `-99` identificado como código sospechoso |
| `duracion_real_min` | INT | Duración real del viaje | > 0 | Sin valores fuera de rango |
| `pasajeros_subidos` | DECIMAL | Número de pasajeros que subieron | ≥ 0 | Presenta valores nulos |
| `ocupacion_pct` | DECIMAL | Porcentaje de ocupación | 0–1 | Coherente con pasajeros/capacidad |
| `km_programados` | DECIMAL | Kilómetros previstos | > 0 | Sin anomalías relevantes |
| `km_recorridos` | DECIMAL | Kilómetros realizados | > 0 | Sin anomalías relevantes |
| `viaje_completado` | BOOLEAN | Indica si el viaje finalizó | TRUE/FALSE | 973 viajes no completados |
| `consumo` | DECIMAL | Consumo registrado | ≥ 0 | Presenta valores nulos |
| `tarifa_predominante_id` | INT | Tarifa predominante del viaje | > 0 | FK a `dim_tarifa` |

---

## 1.2. `fact_incidencias`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `incidencia_id` | INT | Identificador de la incidencia | > 0 | Clave primaria |
| `viaje_id` | INT | Viaje asociado | > 0 | FK a `fact_viajes` |
| `vehiculo_id` | INT | Vehículo implicado | > 0 | FK a `dim_vehiculo` |
| `conductor_id` | INT | Conductor implicado | > 0 | FK a `dim_conductor` |
| `linea_id` | INT | Línea afectada | 1–10 | FK a `dim_linea` |
| `fecha` | DATE | Fecha de la incidencia | 2022–2024 | En origen aparece como texto |
| `anno` | INT | Año | 2022–2024 | Coherente con fecha |
| `mes` | INT | Mes | 1–12 | Coherente con fecha |
| `hora_incidencia` | TIME | Hora de la incidencia | 00:00–23:59 | En origen aparece como texto |
| `tipo_incidencia` | VARCHAR | Tipo de incidencia | Categorías definidas | — |
| `categoria` | VARCHAR | Categoría | Valores definidos | — |
| `severidad` | VARCHAR | Nivel de gravedad | Valores definidos | — |
| `requiere_retirada` | BOOLEAN | Indica si requiere retirada | TRUE/FALSE | — |
| `duracion_resolucion_min` | INT | Duración de la resolución | ≥ 0 | — |
| `vehiculo_sustituto` | BOOLEAN | Indica si hubo vehículo sustituto | TRUE/FALSE | — |
| `coste_estimado_eur` | DECIMAL | Coste estimado de la incidencia | ≥ 0 | — |

---

## 1.3. `fact_mantenimiento`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `mantenimiento_id` | INT | Identificador del mantenimiento | > 0 | Clave primaria |
| `vehiculo_id` | INT | Vehículo intervenido | > 0 | FK a `dim_vehiculo` |
| `depot_id` | INT | Cochera responsable | > 0 | FK a `dim_depot` |
| `fecha_entrada` | DATE | Fecha de entrada | 2022–2024 | En origen aparece como texto |
| `fecha_salida` | DATE | Fecha de salida | ≥ fecha de entrada | — |
| `anno` | INT | Año | 2022–2024 | — |
| `mes` | INT | Mes | 1–12 | — |
| `tipo_mantenimiento` | VARCHAR | Tipo de intervención | Categorías definidas | — |
| `categoria` | VARCHAR | Categoría | Valores definidos | — |
| `es_correctivo` | BOOLEAN | Indica si es correctivo | TRUE/FALSE | — |
| `dias_fuera_servicio` | INT | Días fuera de servicio | ≥ 0 | — |
| `km_en_revision` | INT | Kilómetros en la revisión | ≥ 0 | — |
| `coste_eur` | DECIMAL | Coste del mantenimiento | ≥ 0 | Se detectaron costes negativos |
| `proveedor` | VARCHAR | Proveedor del servicio | Texto | — |
| `garantia_meses` | INT | Duración de la garantía | ≥ 0 | — |

---

## 1.4. `dim_linea`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `linea_id` | INT | Identificador de la línea | > 0 | Clave primaria |
| `codigo` | VARCHAR | Código de línea | Único | — |
| `nombre` | VARCHAR | Nombre de la línea | Texto | — |
| `tipo` | VARCHAR | Tipo de línea | Urbano / Interurbano / Nocturno | — |
| `km_recorrido` | DECIMAL | Longitud del recorrido | > 0 | — |
| `n_paradas` | INT | Número de paradas | > 0 | — |
| `frecuencia_min` | INT | Frecuencia programada | > 0 | — |

---

## 1.5. `dim_vehiculo`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `vehiculo_id` | INT | Identificador del vehículo | > 0 | Clave primaria |
| `matricula` | VARCHAR | Matrícula | Única | — |
| `modelo` | VARCHAR | Modelo del vehículo | Texto | — |
| `combustible` | VARCHAR | Tipo de combustible | Diesel / Electrico / Hibrido | Se detectó `Diesel` / `diesel` |
| `capacidad_sentados` | INT | Número de plazas sentadas | ≥ 0 | — |
| `capacidad_total` | INT | Capacidad total | > 0 | — |
| `anno_fabricacion` | INT | Año de fabricación | Año razonable | — |
| `anno_incorporacion` | INT | Año de incorporación | ≥ año de fabricación | — |
| `km_totales` | INT | Kilómetros acumulados | ≥ 0 | — |
| `depot_id` | INT | Cochera asignada | > 0 | FK a `dim_depot` |
| `emisiones_co2_gkm` | INT | Emisiones de CO₂ por km | ≥ 0 | — |
| `en_servicio` | BOOLEAN | Indica si está en servicio | TRUE/FALSE | — |

---

## 1.6. `dim_conductor`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `conductor_id` | INT | Identificador del conductor | > 0 | Clave primaria |
| `nombre` | VARCHAR | Nombre del conductor | Texto | — |
| `anno_incorporacion` | INT | Año de incorporación | Año razonable | — |
| `antiguedad_anos` | DECIMAL | Antigüedad del conductor | ≥ 0 | Presenta un valor nulo |
| `turno_habitual` | VARCHAR | Turno habitual | `Manana (06-14h)`, `Tarde (14-22h)`, `Noche (22-06h)`, `Partido` | Se detectó el valor `manana` como inconsistencia de formato. Se normaliza a `Manana (06-14h)`. El turno `Partido` se mantiene como categoría válida, ya que el dataset no proporciona los intervalos horarios concretos. |
| `depot_id` | INT | Cochera asignada | > 0 | FK a `dim_depot` |
| `formacion` | VARCHAR | Formación recibida | Categorías definidas | — |
| `licencia_tipo` | VARCHAR | Tipo de licencia | Categorías definidas | — |
| `activo` | BOOLEAN | Indica si está activo | TRUE/FALSE | 28 activos y 2 inactivos |
| `ausencias_2024` | INT | Ausencias durante 2024 | ≥ 0 | — |

---

## 1.7. `dim_parada`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `parada_id` | INT | Identificador de la parada | > 0 | Clave primaria |
| `nombre_parada` | VARCHAR | Nombre de la parada | Texto | — |
| `barrio` | VARCHAR | Barrio | Texto, con nomenclatura normalizada | Se normalizaron los valores BARRIO NORTE → Barrio Norte y centro → Centro |
| `tipo` | VARCHAR | Tipo de parada | Categorías definidas | — |
| `latitud` | DECIMAL | Latitud geográfica | Rango geográfico válido | — |
| `longitud` | DECIMAL | Longitud geográfica | Rango geográfico válido | — |
| `accesible_silla` | VARCHAR | Accesibilidad para silla de ruedas | Valores definidos | — |
| `marquesina` | BOOLEAN | Dispone de marquesina | TRUE/FALSE | — |
| `panel_informacion` | BOOLEAN | Dispone de panel informativo | TRUE/FALSE | — |
| `activa` | BOOLEAN | Indica si está activa | TRUE/FALSE | — |

---

## 1.8. `dim_tarifa`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `tarifa_id` | INT | Identificador de la tarifa | > 0 | Clave primaria |
| `tipo_titulo` | VARCHAR | Tipo de título de transporte | Categorías definidas | — |
| `categoria` | VARCHAR | Categoría tarifaria | Valores definidos | — |
| `precio_eur` | DECIMAL | Precio del título | ≥ 0 | — |
| `es_abono` | BOOLEAN | Indica si es un abono | TRUE/FALSE | — |
| `bonificado` | BOOLEAN | Indica si está bonificado | TRUE/FALSE | — |

---

## 1.9. `dim_depot`

| Campo | Tipo de dato | Descripción | Valores válidos / rango esperado | Observaciones de calidad |
|---|---|---|---|---|
| `depot_id` | INT | Identificador de la cochera | > 0 | Clave primaria |
| `nombre` | VARCHAR | Nombre de la cochera | Texto | — |
| `barrio` | VARCHAR | Barrio donde se encuentra | Texto | — |
| `latitud` | DECIMAL | Latitud geográfica | Rango geográfico válido | — |
| `longitud` | DECIMAL | Longitud geográfica | Rango geográfico válido | — |
| `capacidad_vehiculos` | INT | Capacidad de vehículos | > 0 | — |

---

# 3. Registro de decisiones de calidad — Data Quality Log

Durante el análisis exploratorio se identificaron diferentes problemas de calidad. Las decisiones aplicadas se resumen en la siguiente tabla.

| Tabla | Campo | Tipo de problema | Frecuencia | Decisión tomada | Justificación |
|---|---|---|---:|---|---|
| `fact_viajes` | `pasajeros_subidos` | Valores nulos | 40 | Mantener como `NULL` | No se puede determinar el valor real sin introducir información inventada |
| `fact_viajes` | `consumo` | Valores nulos | 1.065 | Mantener como `NULL` | Se conserva la ausencia de medición |
| `fact_viajes` | `retraso_salida_min` | Código anómalo `-99` | 80 | Transformar a `NULL` | `-99` no representa un retraso operativo válido |
| `fact_viajes` | `dia_semana` | Inconsistencia de formato | 30 | Normalizar el formato | Evita duplicidades al agrupar por día |
| `fact_viajes` | `fecha` | Tipo de dato incorrecto | 50.000 | Convertir a `DATE` | Permite realizar correctamente los análisis temporales |
| `dim_parada`  | `barrio` | Inconsistencia en la capitalización de valores categóricos | 2 | Normalizar los valores `BARRIO NORTE` → `Barrio Norte` y `centro` → `Centro` | Unificar la nomenclatura de los barrios para evitar categorías duplicadas y garantizar la consistencia del dato en consultas y visualizaciones.
| `dim_vehiculo` | `combustible` | Inconsistencia categórica | 1 | Normalizar `diesel` a `Diesel` | Evita considerar la misma categoría como dos valores diferentes |
| dim_conductor | turno_habitual | Inconsistencia de formato/categoría | 1 | Normalizar `manana` a `Manana (06-14h)` | Ambos valores representan el mismo turno. La normalización evita duplicar categorías en los análisis y visualizaciones. |
| `fact_mantenimiento` | `coste_eur` | Valores negativos | 25 | Transformar a `NULL` | Un coste negativo incumple la regla de negocio `coste_eur >= 0` |
| `fact_viajes` | `pasajeros_subidos` / `capacidad_total` | Incoherencia de capacidad | 0 | No modificar | No existen viajes con pasajeros por encima de la capacidad |
| Todas | Claves foráneas | Integridad referencial | 0 huérfanos | No modificar | Todas las referencias entre tablas son válidas |

> **Nota:** Los valores `-1`, `-2` y `-3` de `retraso_salida_min` se mantienen porque pueden representar salidas ligeramente adelantadas. El valor `-99` se trata como un código especial de dato desconocido.

---

# 4. Definición formal de KPIs

Los siguientes indicadores serán utilizados posteriormente en el cuadro de mando de MetroBus.

## KPI 1 — Retraso medio de salida

**Fórmula:**

```text
AVG(retraso_salida_min)
```
**Fuente de datos:** fact_viajes.retraso_salida_min

**Criterios de exclusión:** valores NULL y registros con retraso_salida_min = -99.

**Interpretación:** mide el retraso medio de las expediciones respecto a la hora de salida programada.

**Responsable de validación:** Responsable de Operaciones.

## KPI 2 — Porcentaje de viajes completados

**Fórmula:**

```text
(Viajes completados / Total de viajes) × 100
```
**Fuente:** fact_viajes.viaje_completado

**Criterios de exclusión:** ninguno.

**Interpretación:** mide el nivel de cumplimiento del servicio programado.

**Responsable de validación:** Responsable de Operaciones.

## KPI 3 — Ocupación media

**Fórmula:**

```text
AVG(ocupacion_pct) × 100
```
**Fuente:** fact_viajes.ocupacion_pct

**Criterios de exclusión:** valores NULL.

**Interpretación:** mide el nivel medio de utilización de la capacidad de los vehículos.

**Responsable de validación:** Responsable de Planificación.

## KPI 4 — Número de incidencias

**Fórmula:**

```text
COUNT(incidencia_id)
```
**Fuente:** fact_incidencias.incidencia_id

**Criterios de exclusión:** ninguno.

**Interpretación:** cuantifica las incidencias registradas durante la operación.

**Responsable de validación:** Responsable de Operaciones y Mantenimiento.

## KPI 5 — Coste total de mantenimiento

**Fórmula:**

```text
SUM(coste_eur)
```
**Fuente:** fact_mantenimiento.coste_eur

**Criterios de exclusión:** valores NULL.

**Interpretación:** representa el coste acumulado de las intervenciones de mantenimiento.

**Responsable de validación:** Responsable de Mantenimiento y Finanzas.

## KPI 6 — Consumo medio

**Fórmula:**

```text
AVG(consumo)
```
**Fuente:** fact_viajes.consumo

**Criterios de exclusión:** valores NULL.

**Interpretación:** permite evaluar y comparar la eficiencia de la flota.

**Responsable de validación:** Responsable de Flota.

## KPI 7 — Coste medio de mantenimiento por intervención

**Fórmula:**

```text
SUM(coste_eur) / COUNT(mantenimiento_id)
```
**Fuente:** fact_mantenimiento.coste_eur y fact_mantenimiento.mantenimiento_id

**Criterios de exclusión:** intervenciones cuyo coste sea NULL.

**Interpretación:** permite conocer el coste medio de las intervenciones de mantenimiento.

**Responsable de validación:** Responsable de Mantenimiento.

# 5. Criterios generales de calidad

Durante el proyecto se aplican los siguientes principios:

- No se sustituyen valores ausentes por valores inventados.
- Los códigos anómalos se documentan antes de transformarlos.
- Las categorías se normalizan para evitar duplicidades semánticas.
- Las claves primarias deben ser únicas.
- Las claves foráneas deben mantener la integridad referencial.
- Las reglas de negocio prevalecen sobre la detección estadística de outliers.
- Las transformaciones realizadas durante el proceso ETL deben ser reproducibles.
- Las métricas utilizadas en el dashboard deben seguir las definiciones establecidas en este documento.

# 6. Resumen

La fase de gobierno del dato permite documentar la estructura del modelo, los principales problemas de calidad encontrados y las decisiones tomadas durante la preparación de los datos.

El resultado establece una base común para la construcción del cuadro de mando y facilita la trazabilidad de las métricas utilizadas en el análisis.
