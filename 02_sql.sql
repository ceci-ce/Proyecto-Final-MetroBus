-- ============================================================
-- METROBUS ANALYTICS
-- PROYECTO FINAL - MASTER EN DATA ANALYTICS
-- ============================================================
--
-- FASE 2 - MODELO RELACIONAL Y SQL
--
-- Gestor de base de datos: MySQL
-- Herramienta: MySQL Workbench
--
-- Objetivo:
-- Crear el modelo relacional de MetroBus a partir de los
-- 9 archivos CSV analizados durante la Fase 1.
--
-- Tablas:
--   - 3 tablas de hechos
--   - 6 tablas de dimensiones
--
-- ============================================================



-- ============================================================
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ============================================================

-- Se elimina la base de datos únicamente si ya existía.
-- Esto permite ejecutar nuevamente el script desde cero.

DROP DATABASE IF EXISTS metrobus_analytics;

CREATE DATABASE metrobus_analytics;

USE metrobus_analytics;

-- ============================================================
-- 2. CREACIÓN DE LAS TABLAS DE DIMENSIONES
-- ============================================================


-- ------------------------------------------------------------
-- 2.1. DIM_DEPOT
-- ------------------------------------------------------------
-- Contiene información sobre las tres cocheras de MetroBus.
-- ------------------------------------------------------------

CREATE TABLE dim_depot (
    depot_id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    barrio VARCHAR(100),
    latitud DECIMAL(9,6),
    longitud DECIMAL(9,6),
    capacidad_vehiculos INT
);

-- ------------------------------------------------------------
-- 2.2. DIM_LINEA
-- ------------------------------------------------------------
-- Contiene información descriptiva de las líneas de autobús.
-- ------------------------------------------------------------

CREATE TABLE dim_linea (
    linea_id INT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50),
    km_recorrido DECIMAL(6,2),
    n_paradas INT,
    frecuencia_min INT
);

-- ------------------------------------------------------------
-- 2.3. DIM_VEHICULO
-- ------------------------------------------------------------
-- Contiene información de los vehículos de la flota.
-- ------------------------------------------------------------

CREATE TABLE dim_vehiculo (
    vehiculo_id INT PRIMARY KEY,
    matricula VARCHAR(20) NOT NULL,
    modelo VARCHAR(100),
    combustible VARCHAR(30),
    capacidad_sentados INT,
    capacidad_total INT,
    anno_fabricacion INT,
    anno_incorporacion INT,
    km_totales INT,
    depot_id INT,
    emisiones_co2_gkm INT,
    en_servicio BOOLEAN
);

-- ------------------------------------------------------------
-- 2.4. DIM_CONDUCTOR
-- ------------------------------------------------------------
-- Contiene información de los conductores.
-- ------------------------------------------------------------

CREATE TABLE dim_conductor (
    conductor_id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    anno_incorporacion INT,
    antiguedad_anos DECIMAL(5,1),
    turno_habitual VARCHAR(50),
    depot_id INT,
    formacion VARCHAR(100),
    licencia_tipo VARCHAR(50),
    activo BOOLEAN,
    ausencias_2024 INT
);

-- ------------------------------------------------------------
-- 2.5. DIM_PARADA
-- ------------------------------------------------------------
-- Contiene información de las paradas de MetroBus.
-- ------------------------------------------------------------

CREATE TABLE dim_parada (
    parada_id INT PRIMARY KEY,
    nombre_parada VARCHAR(150) NOT NULL,
    barrio VARCHAR(100),
    tipo VARCHAR(50),
    latitud DECIMAL(9,6),
    longitud DECIMAL(9,6),
    accesible_silla VARCHAR(20),
    marquesina BOOLEAN,
    panel_informacion BOOLEAN,
    activa BOOLEAN
);

-- ------------------------------------------------------------
-- 2.6. DIM_TARIFA
-- ------------------------------------------------------------
-- Contiene información de los títulos y tarifas.
-- ------------------------------------------------------------

CREATE TABLE dim_tarifa (
    tarifa_id INT PRIMARY KEY,
    tipo_titulo VARCHAR(100) NOT NULL,
    categoria VARCHAR(100),
    precio_eur DECIMAL(8,2),
    es_abono BOOLEAN,
    bonificado BOOLEAN
);

-- ============================================================
-- 3. CREACIÓN DE LAS TABLAS DE HECHOS
-- ============================================================


-- ------------------------------------------------------------
-- 3.1. FACT_VIAJES
-- ------------------------------------------------------------
-- Contiene un registro por cada expedición de autobús.
--
-- En el EDA se detectó que:
--   - fecha estaba almacenada como object en pandas.
--   - las horas también estaban almacenadas como object.
--
-- En el modelo SQL se convierten a DATE y TIME respectivamente.
-- ------------------------------------------------------------

CREATE TABLE fact_viajes (
    viaje_id INT PRIMARY KEY,

    linea_id INT NOT NULL,
    vehiculo_id INT NOT NULL,
    conductor_id INT NOT NULL,

    parada_origen_id INT NOT NULL,
    parada_destino_id INT NOT NULL,

    fecha DATE NOT NULL,

    anno INT NOT NULL,
    mes INT NOT NULL,
    dia_semana VARCHAR(20),

    es_festivo BOOLEAN,
    franja_horaria VARCHAR(50),

    hora_salida_prog TIME,
    hora_salida_real TIME,
    hora_llegada_real TIME,

    retraso_salida_min INT,
    duracion_real_min INT,

    pasajeros_subidos DECIMAL(8,2),
    ocupacion_pct DECIMAL(6,3),

    km_programados DECIMAL(6,2),
    km_recorridos DECIMAL(6,2),

    viaje_completado BOOLEAN,

    consumo DECIMAL(8,2),

    tarifa_predominante_id INT
);

-- ------------------------------------------------------------
-- 3.2. FACT_INCIDENCIAS
-- ------------------------------------------------------------
-- Contiene las incidencias registradas durante la operación.
-- ------------------------------------------------------------

CREATE TABLE fact_incidencias (
    incidencia_id INT PRIMARY KEY,

    viaje_id INT NOT NULL,
    vehiculo_id INT NOT NULL,
    conductor_id INT NOT NULL,
    linea_id INT NOT NULL,

    fecha DATE NOT NULL,

    anno INT NOT NULL,
    mes INT NOT NULL,

    hora_incidencia TIME,

    tipo_incidencia VARCHAR(100),
    categoria VARCHAR(100),
    severidad VARCHAR(50),

    requiere_retirada BOOLEAN,

    duracion_resolucion_min INT,

    vehiculo_sustituto BOOLEAN,

    coste_estimado_eur DECIMAL(10,2)
);

-- ------------------------------------------------------------
-- 3.3. FACT_MANTENIMIENTO
-- ------------------------------------------------------------
-- Contiene el historial de intervenciones realizadas
-- sobre los vehículos.
-- ------------------------------------------------------------

CREATE TABLE fact_mantenimiento (
    mantenimiento_id INT PRIMARY KEY,

    vehiculo_id INT NOT NULL,
    depot_id INT NOT NULL,

    fecha_entrada DATE,
    fecha_salida DATE,

    anno INT NOT NULL,
    mes INT NOT NULL,

    tipo_mantenimiento VARCHAR(100),
    categoria VARCHAR(100),

    es_correctivo BOOLEAN,

    dias_fuera_servicio INT,
    km_en_revision INT,

    coste_eur DECIMAL(10,2),

    proveedor VARCHAR(150),

    garantia_meses INT
);

-- ============================================================
-- 4. CLAVES FORÁNEAS
-- ============================================================
--
-- Las claves foráneas garantizan la integridad referencial
-- entre las tablas del modelo.
--
-- Se crean después de todas las tablas para evitar problemas
-- de dependencia entre tablas.
-- ============================================================

-- ------------------------------------------------------------
-- 4.1. DIM_VEHICULO -> DIM_DEPOT
-- ------------------------------------------------------------

ALTER TABLE dim_vehiculo
ADD CONSTRAINT fk_vehiculo_depot
FOREIGN KEY (depot_id)
REFERENCES dim_depot(depot_id);

-- ------------------------------------------------------------
-- 4.2. DIM_CONDUCTOR -> DIM_DEPOT
-- ------------------------------------------------------------

ALTER TABLE dim_conductor
ADD CONSTRAINT fk_conductor_depot
FOREIGN KEY (depot_id)
REFERENCES dim_depot(depot_id);

-- ------------------------------------------------------------
-- 4.3. FACT_VIAJES -> DIM_LINEA
-- ------------------------------------------------------------

ALTER TABLE fact_viajes
ADD CONSTRAINT fk_viaje_linea
FOREIGN KEY (linea_id)
REFERENCES dim_linea(linea_id);

-- ------------------------------------------------------------
-- 4.4. FACT_VIAJES -> DIM_VEHICULO
-- ------------------------------------------------------------

ALTER TABLE fact_viajes
ADD CONSTRAINT fk_viaje_vehiculo
FOREIGN KEY (vehiculo_id)
REFERENCES dim_vehiculo(vehiculo_id);

-- ------------------------------------------------------------
-- 4.5. FACT_VIAJES -> DIM_CONDUCTOR
-- ------------------------------------------------------------

ALTER TABLE fact_viajes
ADD CONSTRAINT fk_viaje_conductor
FOREIGN KEY (conductor_id)
REFERENCES dim_conductor(conductor_id);

-- ------------------------------------------------------------
-- 4.6. FACT_VIAJES -> DIM_PARADA (ORIGEN)
-- ------------------------------------------------------------

ALTER TABLE fact_viajes
ADD CONSTRAINT fk_viaje_parada_origen
FOREIGN KEY (parada_origen_id)
REFERENCES dim_parada(parada_id);

-- ------------------------------------------------------------
-- 4.7. FACT_VIAJES -> DIM_PARADA (DESTINO)
-- ------------------------------------------------------------

ALTER TABLE fact_viajes
ADD CONSTRAINT fk_viaje_parada_destino
FOREIGN KEY (parada_destino_id)
REFERENCES dim_parada(parada_id);

-- ------------------------------------------------------------
-- 4.8. FACT_VIAJES -> DIM_TARIFA
-- ------------------------------------------------------------

ALTER TABLE fact_viajes
ADD CONSTRAINT fk_viaje_tarifa
FOREIGN KEY (tarifa_predominante_id)
REFERENCES dim_tarifa(tarifa_id);

-- ------------------------------------------------------------
-- 4.9. FACT_INCIDENCIAS -> FACT_VIAJES
-- ------------------------------------------------------------

ALTER TABLE fact_incidencias
ADD CONSTRAINT fk_incidencia_viaje
FOREIGN KEY (viaje_id)
REFERENCES fact_viajes(viaje_id);

-- ------------------------------------------------------------
-- 4.10. FACT_INCIDENCIAS -> DIM_VEHICULO
-- ------------------------------------------------------------

ALTER TABLE fact_incidencias
ADD CONSTRAINT fk_incidencia_vehiculo
FOREIGN KEY (vehiculo_id)
REFERENCES dim_vehiculo(vehiculo_id);

-- ------------------------------------------------------------
-- 4.11. FACT_INCIDENCIAS -> DIM_CONDUCTOR
-- ------------------------------------------------------------

ALTER TABLE fact_incidencias
ADD CONSTRAINT fk_incidencia_conductor
FOREIGN KEY (conductor_id)
REFERENCES dim_conductor(conductor_id);

-- ------------------------------------------------------------
-- 4.12. FACT_INCIDENCIAS -> DIM_LINEA
-- ------------------------------------------------------------

ALTER TABLE fact_incidencias
ADD CONSTRAINT fk_incidencia_linea
FOREIGN KEY (linea_id)
REFERENCES dim_linea(linea_id);

-- ------------------------------------------------------------
-- 4.13. FACT_MANTENIMIENTO -> DIM_VEHICULO
-- ------------------------------------------------------------

ALTER TABLE fact_mantenimiento
ADD CONSTRAINT fk_mantenimiento_vehiculo
FOREIGN KEY (vehiculo_id)
REFERENCES dim_vehiculo(vehiculo_id);

-- ------------------------------------------------------------
-- 4.14. FACT_MANTENIMIENTO -> DIM_DEPOT
-- ------------------------------------------------------------

ALTER TABLE fact_mantenimiento
ADD CONSTRAINT fk_mantenimiento_depot
FOREIGN KEY (depot_id)
REFERENCES dim_depot(depot_id);

-- ============================================================
-- 5. RESTRICCIONES DE CALIDAD Y REGLAS DE NEGOCIO
-- ============================================================
--
-- Se añaden restricciones para impedir valores claramente
-- incompatibles con las reglas básicas del negocio.
--
-- Los problemas detectados durante el EDA que requieren
-- transformación, como -99 en retrasos o Diesel/diesel,
-- se tratarán durante la fase de limpieza y carga.
-- ============================================================

-- ------------------------------------------------------------
-- 5.1. La capacidad total no puede ser inferior a la capacidad
-- de asientos.
-- ------------------------------------------------------------

ALTER TABLE dim_vehiculo
ADD CONSTRAINT chk_capacidad_vehiculo
CHECK (capacidad_total >= capacidad_sentados);

-- ------------------------------------------------------------
-- 5.2. La frecuencia programada debe ser positiva.
-- ------------------------------------------------------------

ALTER TABLE dim_linea
ADD CONSTRAINT chk_frecuencia_linea
CHECK (frecuencia_min > 0);

-- ------------------------------------------------------------
-- 5.3. La ocupación debe estar entre 0 y 1.
-- ------------------------------------------------------------

ALTER TABLE fact_viajes
ADD CONSTRAINT chk_ocupacion
CHECK (
    ocupacion_pct >= 0
    AND ocupacion_pct <= 1
);

-- ------------------------------------------------------------
-- 5.4. Los kilómetros no pueden ser negativos.
-- ------------------------------------------------------------

ALTER TABLE fact_viajes
ADD CONSTRAINT chk_km_programados
CHECK (km_programados >= 0);

ALTER TABLE fact_viajes
ADD CONSTRAINT chk_km_recorridos
CHECK (km_recorridos >= 0);

-- ------------------------------------------------------------
-- 5.5. Los costes de incidencias no pueden ser negativos.
-- ------------------------------------------------------------

ALTER TABLE fact_incidencias
ADD CONSTRAINT chk_coste_incidencia
CHECK (coste_estimado_eur >= 0);

-- ------------------------------------------------------------
-- 5.6. Los costes de mantenimiento no pueden ser negativos.
-- ------------------------------------------------------------

ALTER TABLE fact_mantenimiento
ADD CONSTRAINT chk_coste_mantenimiento
CHECK (coste_eur >= 0);

-- ------------------------------------------------------------
-- 5.7. Los días fuera de servicio no pueden ser negativos.
-- ------------------------------------------------------------

ALTER TABLE fact_mantenimiento
ADD CONSTRAINT chk_dias_fuera_servicio
CHECK (dias_fuera_servicio >= 0);

-- ============================================================
-- 6. COMPROBACIÓN DE LA ESTRUCTURA
-- ============================================================
--
-- Estas consultas permiten comprobar que las tablas se han
-- creado correctamente.
-- ============================================================


-- Mostrar las tablas creadas.

SHOW TABLES;



-- Mostrar la estructura de fact_viajes.

DESCRIBE fact_viajes;



-- Mostrar la estructura de fact_incidencias.

DESCRIBE fact_incidencias;



-- Mostrar la estructura de fact_mantenimiento.

DESCRIBE fact_mantenimiento;



-- Mostrar la estructura de las dimensiones.

DESCRIBE dim_linea;

DESCRIBE dim_vehiculo;

DESCRIBE dim_conductor;

DESCRIBE dim_parada;

DESCRIBE dim_tarifa;

DESCRIBE dim_depot;

-- ============================================================
-- 7. CARGA DE DATOS
-- ============================================================
--
-- Los datos originales proceden de 9 archivos CSV.
--
-- La carga se realiza respetando el orden de las dependencias
-- entre tablas:
--
-- 1. dim_depot
-- 2. dim_linea
-- 3. dim_vehiculo
-- 4. dim_conductor
-- 5. dim_parada
-- 6. dim_tarifa
-- 7. fact_viajes
-- 8. fact_incidencias
-- 9. fact_mantenimiento
--
-- Primero se cargan las dimensiones y posteriormente las
-- tablas de hechos.
-- ============================================================



-- ============================================================
-- 8. COMPROBACIONES POSTERIORES A LA CARGA
-- ============================================================
--
-- Estas consultas se ejecutarán después de cargar los CSV.
-- Permiten comprobar que el número de registros coincide
-- con el dataset original.
-- ============================================================


-- Número esperado de viajes: 50.000

SELECT COUNT(*) AS total_viajes
FROM fact_viajes;



-- Número esperado de incidencias: 4.000

SELECT COUNT(*) AS total_incidencias
FROM fact_incidencias;



-- Número esperado de mantenimientos: 876

SELECT COUNT(*) AS total_mantenimientos
FROM fact_mantenimiento;



-- Número esperado de líneas: 10

SELECT COUNT(*) AS total_lineas
FROM dim_linea;



-- Número esperado de vehículos: 45

SELECT COUNT(*) AS total_vehiculos
FROM dim_vehiculo;



-- Número esperado de conductores: 30

SELECT COUNT(*) AS total_conductores
FROM dim_conductor;



-- Número esperado de paradas: 120

SELECT COUNT(*) AS total_paradas
FROM dim_parada;



-- Número esperado de tarifas: 9

SELECT COUNT(*) AS total_tarifas
FROM dim_tarifa;



-- Número esperado de cocheras: 3

SELECT COUNT(*) AS total_cocheras
FROM dim_depot;

-- Comprobar los primeros registros de viajes
SELECT *
FROM fact_viajes
LIMIT 10;

-- Comprobar que las fechas se han almacenado como DATE
SELECT
    viaje_id,
    fecha,
    hora_salida_prog,
    hora_salida_real,
    hora_llegada_real
FROM fact_viajes
LIMIT 10;

-- Comprobar que el valor -99 ya no existe
SELECT
    retraso_salida_min,
    COUNT(*) AS cantidad
FROM fact_viajes
GROUP BY retraso_salida_min
ORDER BY retraso_salida_min;

-- Comprobar los valores de combustible
SELECT
    combustible,
    COUNT(*) AS cantidad
FROM dim_vehiculo
GROUP BY combustible;

-- Comprobar la normalización de los días de la semana
SELECT
    dia_semana,
    COUNT(*) AS cantidad
FROM fact_viajes
GROUP BY dia_semana
ORDER BY dia_semana;

-- ============================================================
-- 9. CONSULTAS DE NEGOCIO
-- ============================================================
--
-- Las siguientes consultas responden a preguntas relevantes
-- para la toma de decisiones de MetroBus.

-- ============================================================
-- Se utilizan JOIN, funciones de agregación, GROUP BY,
-- CASE y CTE para demostrar diferentes técnicas SQL.
-- ============================================================


-- ============================================================
-- 9.1. ¿Qué líneas presentan un mayor retraso medio?
-- ============================================================

-- 
-- Se excluyen los valores NULL de retraso.
-- Se relacionan los viajes con la dimensión de líneas para
-- obtener el código y nombre de cada línea.
-- ============================================================

SELECT
	l.linea_id,
    l.codigo,
    l.nombre,
    COUNT(v.viaje_id) AS total_viajes,
    ROUND(AVG(v.retraso_salida_min), 2) AS retraso_medio_min
FROM fact_viajes v
INNER JOIN dim_linea l
	ON v.linea_id = l.linea_id
WHERE v.retraso_salida_min IS NOT NULL
GROUP BY
	l.linea_id,
    l.codigo,
    l.nombre
ORDER BY retraso_medio_min DESC;    

-- 
-- Se analiza el retraso medio por línea. Para ello se relaciona la 
-- tabla de hechos fact_viajes con dim_linea mediante linea_id, 
-- se excluyen los retrasos nulos, se agrupa por línea y se calcula tanto 
-- el número de viajes como el retraso medio. Finalmente se ordena 
-- las líneas de mayor a menor retraso.
-- ============================================================

-- ============================================================
-- 9.2. ¿Qué franjas horarias concentran más pasajeros?
-- ============================================================

-- 
-- Permite identificar los periodos de mayor demanda.
-- ============================================================

SELECT
	franja_horaria,
	COUNT(*) AS total_viajes,
	ROUND(SUM(pasajeros_subidos), 0) AS pasajeros_totales,
	ROUND(AVG(pasajeros_subidos), 2) AS pasajeros_medios
FROM fact_viajes
GROUP BY franja_horaria
ORDER BY pasajeros_totales DESC;

-- 
-- Se analiza la demanda de pasajeros por franja horaria.
-- Para ello se agrupan los viajes de fact_viajes por franja
-- horaria y se calcula el número total de viajes, los pasajeros
-- totales y el número medio de pasajeros por viaje.
-- Finalmente se ordenan las franjas de mayor a menor número
-- de pasajeros totales para identificar los periodos de mayor demanda.
-- ============================================================

-- ============================================================
-- 9.3. ¿Qué vehículos presentan mayor ocupación media?
-- ============================================================

-- 
-- Se combina la tabla de viajes con la dimensión de vehículos
-- para analizar la ocupación según el vehículo.
-- ============================================================

SELECT
	v.vehiculo_id,
    ve.modelo,
    ve.combustible,
    ve.capacidad_total,
    ROUND(AVG(v.ocupacion_pct) * 100, 2) AS ocupacion_media_pct,
    COUNT(v.viaje_id) AS total_viajes
FROM fact_viajes v
INNER JOIN dim_vehiculo ve
	ON v.vehiculo_id = ve.vehiculo_id
GROUP BY 
	v.vehiculo_id,
    ve.modelo,
    ve.combustible,
    ve.capacidad_total
ORDER BY ocupacion_media_pct DESC;    

-- 
-- Se analiza la ocupación media por vehículo. Para ello se
-- relaciona la tabla de hechos fact_viajes con la dimensión
-- dim_vehiculo mediante vehiculo_id, obteniendo información
-- adicional sobre el modelo, combustible y capacidad del vehículo.
-- Se calcula la ocupación media y el número total de viajes
-- realizados por cada vehículo. Finalmente se ordenan los
-- vehículos de mayor a menor ocupación media.
-- ============================================================

-- ============================================================
-- 9.4. ¿Qué tipo de combustible está asociado a un menor
--      consumo medio?
-- ============================================================

-- 
-- Permite comparar el comportamiento de los diferentes tipos
-- de combustible de la flota.
-- ============================================================

SELECT
    ve.combustible,
    COUNT(v.viaje_id) AS total_viajes,
    ROUND(AVG(v.consumo), 2) AS consumo_medio,
    ROUND(SUM(v.consumo), 2) AS consumo_total
FROM fact_viajes v
INNER JOIN dim_vehiculo ve
    ON v.vehiculo_id = ve.vehiculo_id
WHERE v.consumo IS NOT NULL
	AND ve.combustible IS NOT NULL
GROUP BY ve.combustible
ORDER BY consumo_medio ASC;

-- 
-- Se analiza el consumo medio de los viajes según el tipo de
-- combustible. Para ello se relaciona fact_viajes con
-- dim_vehiculo mediante vehiculo_id y se excluyen los viajes
-- que no tienen consumo o tipo de combustible informado.
-- Se calcula el número de viajes, el consumo medio y el consumo
-- total para cada tipo de combustible. Finalmente se ordenan
-- los resultados de menor a mayor consumo medio para identificar
-- los tipos de combustible asociados a un menor consumo.
-- ============================================================

-- ============================================================
-- COMPROBACIÓN DE CALIDAD DE DATOS
-- ============================================================
-- Se comprueban los vehículos que no tienen informado
-- el tipo de combustible.
-- ============================================================

SELECT
    ve.vehiculo_id,
    ve.modelo,
    COUNT(v.viaje_id) AS total_viajes
FROM fact_viajes v
INNER JOIN dim_vehiculo ve
    ON v.vehiculo_id = ve.vehiculo_id
WHERE ve.combustible IS NULL
GROUP BY
    ve.vehiculo_id,
    ve.modelo;
    
--    
-- Se detectó un vehículo sin tipo de combustible informado 
-- (vehiculo_id = 32), asociado a 1.190 viajes. Dado que no 
-- existe información suficiente para determinar el combustible 
-- de forma fiable, se mantiene el valor NULL y se excluyen 
-- estos registros del análisis comparativo por tipo de combustible.
-- ============================================================

-- ============================================================
-- 9.5. ¿Qué líneas presentan mayor número de incidencias?
-- ============================================================
--
-- Se relacionan las incidencias con las líneas para detectar
-- aquellas con mayor frecuencia de incidencias.
-- ============================================================

SELECT
    l.linea_id,
    l.codigo,
    l.nombre,
    COUNT(i.incidencia_id) AS total_incidencias

FROM fact_incidencias i

INNER JOIN dim_linea l
    ON i.linea_id = l.linea_id

GROUP BY
    l.linea_id,
    l.codigo,
    l.nombre

ORDER BY total_incidencias DESC;


--
-- Se analiza el número de incidencias por línea. Para ello se
-- relaciona la tabla de hechos fact_incidencias con dim_linea
-- mediante linea_id, obteniendo el código y nombre de cada línea.
-- Se calcula el número total de incidencias de cada línea y se
-- ordenan los resultados de mayor a menor número de incidencias.
-- ============================================================

-- ============================================================
-- 9.6. ¿Qué vehículos tienen mayor coste de mantenimiento?
-- ============================================================
--
-- Permite identificar vehículos que pueden requerir una
-- revisión de su rentabilidad o sustitución.
-- ============================================================

SELECT
    ve.vehiculo_id,
    ve.modelo,
    ve.combustible,
    COUNT(m.mantenimiento_id) AS intervenciones,
    ROUND(SUM(m.coste_eur), 2) AS coste_mantenimiento_total,
    ROUND(AVG(m.coste_eur), 2) AS coste_medio_intervencion
FROM fact_mantenimiento m
INNER JOIN dim_vehiculo ve
    ON m.vehiculo_id = ve.vehiculo_id
GROUP BY
    ve.vehiculo_id,
    ve.modelo,
    ve.combustible
ORDER BY coste_mantenimiento_total DESC;

--
-- Se analiza el coste de mantenimiento acumulado por vehículo.
-- Para ello se relaciona fact_mantenimiento con dim_vehiculo
-- mediante vehiculo_id, obteniendo información adicional sobre
-- el modelo y el tipo de combustible.
-- Se calcula el número de intervenciones, el coste total de
-- mantenimiento y el coste medio por intervención para cada
-- vehículo. Finalmente se ordenan los resultados de mayor a
-- menor coste total de mantenimiento.
-- ============================================================

-- ============================================================
-- 9.7. ¿Cuál es el porcentaje de viajes completados por línea?
-- ============================================================
--
-- Permite detectar líneas con una menor tasa de cumplimiento
-- del servicio.
-- ============================================================

SELECT
    l.codigo,
    l.nombre,
    COUNT(v.viaje_id) AS total_viajes,

    SUM(
        CASE
            WHEN v.viaje_completado = TRUE THEN 1
            ELSE 0
        END
    ) AS viajes_completados,

    ROUND(
        100 * SUM(
            CASE
                WHEN v.viaje_completado = TRUE THEN 1
                ELSE 0
            END
        ) / COUNT(v.viaje_id),
        2
    ) AS porcentaje_completado

FROM fact_viajes v

INNER JOIN dim_linea l
    ON v.linea_id = l.linea_id

GROUP BY
    l.codigo,
    l.nombre

ORDER BY porcentaje_completado ASC;

--
-- Se analiza la tasa de cumplimiento de los viajes por línea.
-- Para ello se relaciona fact_viajes con dim_linea mediante
-- linea_id, obteniendo el código y nombre de cada línea.
-- Se calcula el número total de viajes y, mediante CASE y SUM,
-- el número de viajes completados. A partir de estos valores
-- se obtiene el porcentaje de viajes completados para cada línea.
-- Finalmente se ordenan los resultados de menor a mayor
-- porcentaje de cumplimiento para identificar las líneas con
-- menor tasa de servicio completado.
-- ============================================================

-- ============================================================
-- 9.8. ¿Qué vehículos combinan mayor coste de mantenimiento
--      y mayor número de incidencias?
-- ============================================================
--
-- Se utiliza una CTE para combinar dos indicadores de riesgo
-- operativo:
--
--   - número de incidencias
--   - coste total de mantenimiento
--
-- El objetivo es identificar vehículos que podrían requerir
-- una revisión específica.
-- ============================================================

WITH incidencias_vehiculo AS (

    SELECT
        vehiculo_id,
        COUNT(*) AS total_incidencias
    FROM fact_incidencias
    GROUP BY vehiculo_id

),

mantenimiento_vehiculo AS (

    SELECT
        vehiculo_id,
        SUM(coste_eur) AS coste_mantenimiento
    FROM fact_mantenimiento
    GROUP BY vehiculo_id

)

SELECT
    ve.vehiculo_id,
    ve.modelo,
    ve.combustible,

    COALESCE(i.total_incidencias, 0)
        AS total_incidencias,

    ROUND(
        COALESCE(m.coste_mantenimiento, 0),
        2
    ) AS coste_mantenimiento

FROM dim_vehiculo ve

LEFT JOIN incidencias_vehiculo i
    ON ve.vehiculo_id = i.vehiculo_id

LEFT JOIN mantenimiento_vehiculo m
    ON ve.vehiculo_id = m.vehiculo_id

ORDER BY
    total_incidencias DESC,
    coste_mantenimiento DESC;
    
--
-- Se identifican los vehículos que podrían requerir una revisión
-- específica combinando información de incidencias y mantenimiento.
-- Para ello se crean dos consultas temporales (CTE): una que
-- resume el número de incidencias por vehículo y otra que calcula
-- el coste total de mantenimiento por vehículo.
-- Posteriormente, ambas se relacionan con dim_vehiculo mediante
-- vehiculo_id utilizando LEFT JOIN, de forma que se mantengan
-- todos los vehículos de la flota, incluso aquellos sin incidencias
-- o sin registros de mantenimiento. Los valores NULL se sustituyen
-- por cero mediante COALESCE. Finalmente, los vehículos se ordenan
-- de mayor a menor número de incidencias y, en caso de empate,
-- de mayor a menor coste de mantenimiento.
-- ============================================================    

