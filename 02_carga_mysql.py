# ============================================================
# METROBUS ANALYTICS
# Carga de datos en MySQL
# ============================================================
#
# Este script:
# 1. Lee los 9 archivos CSV.
# 2. Realiza las transformaciones necesarias para MySQL.
# 3. Inserta los datos en la base de datos.
# 4. Comprueba el número de registros cargados.
#
# ============================================================


import pandas as pd
import mysql.connector
from pathlib import Path


# ============================================================
# 1. CONFIGURACIÓN
# ============================================================

# Carpeta donde se encuentran los archivos CSV.
RUTA_DATOS = Path("data")


# Configuración de conexión con MySQL.
conexion = mysql.connector.connect(
    host="localhost",
    user="root",
    password="NNNN690@@37/",
    database="metrobus_analytics"
)

cursor = conexion.cursor()

print("Conexión con MySQL establecida correctamente.")


# ============================================================
# 2. LECTURA DE LOS ARCHIVOS CSV
# ============================================================

print("\nLeyendo archivos CSV...")


dim_depot = pd.read_csv(
    RUTA_DATOS / "dim_depot.csv"
)

dim_linea = pd.read_csv(
    RUTA_DATOS / "dim_linea.csv"
)

dim_vehiculo = pd.read_csv(
    RUTA_DATOS / "dim_vehiculo.csv"
)

dim_conductor = pd.read_csv(
    RUTA_DATOS / "dim_conductor.csv"
)

dim_parada = pd.read_csv(
    RUTA_DATOS / "dim_parada.csv"
)

dim_tarifa = pd.read_csv(
    RUTA_DATOS / "dim_tarifa.csv"
)

fact_viajes = pd.read_csv(
    RUTA_DATOS / "fact_viajes.csv"
)

fact_incidencias = pd.read_csv(
    RUTA_DATOS / "fact_incidencias.csv"
)

fact_mantenimiento = pd.read_csv(
    RUTA_DATOS / "fact_mantenimiento.csv"
)


print("Archivos CSV cargados correctamente.")


# ============================================================
# 3. TRANSFORMACIÓN DE FECHAS Y HORAS
# ============================================================
#
# En el EDA se detectó que pandas había interpretado estas
# columnas como object.
#
# Para MySQL las se transforman a formatos DATE y TIME.
# ============================================================


# ------------------------------------------------------------
# FACT_VIAJES
# ------------------------------------------------------------

fact_viajes["fecha"] = pd.to_datetime(
    fact_viajes["fecha"],
    errors="coerce"
).dt.date


fact_viajes["hora_salida_prog"] = pd.to_datetime(
    fact_viajes["hora_salida_prog"],
    format="%H:%M",
    errors="coerce"
).dt.time


fact_viajes["hora_salida_real"] = pd.to_datetime(
    fact_viajes["hora_salida_real"],
    format="%H:%M",
    errors="coerce"
).dt.time


fact_viajes["hora_llegada_real"] = pd.to_datetime(
    fact_viajes["hora_llegada_real"],
    format="%H:%M",
    errors="coerce"
).dt.time


# ------------------------------------------------------------
# FACT_INCIDENCIAS
# ------------------------------------------------------------

fact_incidencias["fecha"] = pd.to_datetime(
    fact_incidencias["fecha"],
    errors="coerce"
).dt.date


fact_incidencias["hora_incidencia"] = pd.to_datetime(
    fact_incidencias["hora_incidencia"],
    format="%H:%M",
    errors="coerce"
).dt.time


# ------------------------------------------------------------
# FACT_MANTENIMIENTO
# ------------------------------------------------------------

fact_mantenimiento["fecha_entrada"] = pd.to_datetime(
    fact_mantenimiento["fecha_entrada"],
    errors="coerce"
).dt.date


fact_mantenimiento["fecha_salida"] = pd.to_datetime(
    fact_mantenimiento["fecha_salida"],
    errors="coerce"
).dt.date


print("Fechas y horas transformadas correctamente.")


# ============================================================
# 4. NORMALIZACIÓN DE VALORES CATEGÓRICOS
# ============================================================
#
# Durante el EDA se detectaron inconsistencias de escritura.
# ============================================================


# ------------------------------------------------------------
# 4.1. Normalización del combustible
# ------------------------------------------------------------

dim_vehiculo["combustible"] = (
    dim_vehiculo["combustible"]
    .replace({
        "diesel": "Diesel"
    })
)


# ------------------------------------------------------------
# 4.2. Normalización del día de la semana
# ------------------------------------------------------------
#
# En el EDA se detectaron valores como:
#
# Monday
# MONDAY
# Friday
# FRIDAY
#
# Se normalizan utilizando formato capitalizado.
# ------------------------------------------------------------

fact_viajes["dia_semana"] = (
    fact_viajes["dia_semana"]
    .str.strip()
    .str.capitalize()
)


print("Valores categóricos normalizados.")


# ============================================================
# 5. TRATAMIENTO DEL VALOR -99 EN LOS RETRASOS
# ============================================================
#
# Durante el EDA se detectaron 80 registros con -99.
#
# Este valor se considera un código especial y no un retraso
# real de 99 minutos.
#
# Se transforma a NaN para representar un valor desconocido.
# ============================================================

fact_viajes["retraso_salida_min"] = (
    fact_viajes["retraso_salida_min"]
    .replace(-99, pd.NA)
)


print(
    "Valor -99 de retraso transformado a valor nulo."
)


# ============================================================
# TRATAMIENTO DE COSTES DE MANTENIMIENTO NEGATIVOS
# ============================================================
#
# Durante el análisis exploratorio se detectaron 25 registros
# con costes de mantenimiento negativos.
#
# Según la regla de negocio definida en MySQL:
#
#     coste_eur >= 0
#
# un coste negativo no es válido.
#
# No se convierten los valores a positivos porque no podemos
# asegurar que el signo sea simplemente un error.
#
# Se convierten a NULL para no inventar un valor y mantener
# la trazabilidad de la incidencia de calidad.
# ============================================================

costes_negativos = (
    fact_mantenimiento["coste_eur"] < 0
).sum()

fact_mantenimiento.loc[
    fact_mantenimiento["coste_eur"] < 0,
    "coste_eur"
] = pd.NA

print(
    f"Costes de mantenimiento negativos tratados: "
    f"{costes_negativos}"
)


# ============================================================
# 6. PREPARACIÓN DE VALORES NULOS
# ============================================================
#
# MySQL utiliza NULL para representar valores desconocidos.
# Pandas utiliza NaN / NA.
#
# Se convierten los valores ausentes a None para que el conector
# de MySQL los inserte como NULL.
# ============================================================

datasets = {
    "dim_depot": dim_depot,
    "dim_linea": dim_linea,
    "dim_vehiculo": dim_vehiculo,
    "dim_conductor": dim_conductor,
    "dim_parada": dim_parada,
    "dim_tarifa": dim_tarifa,
    "fact_viajes": fact_viajes,
    "fact_incidencias": fact_incidencias,
    "fact_mantenimiento": fact_mantenimiento
}


for nombre, df in datasets.items():

    datasets[nombre] = (
        df.astype(object)
        .where(pd.notna(df), None)
    )


print("Valores nulos preparados para MySQL.")


# ============================================================
# 7. FUNCIÓN DE CARGA
# ============================================================

def cargar_dataframe(
    df,
    tabla
):
    """
    Inserta un DataFrame completo en una tabla MySQL.
    """

    columnas = list(df.columns)

    nombres_columnas = ", ".join(
        f"`{columna}`"
        for columna in columnas
    )

    placeholders = ", ".join(
        ["%s"] * len(columnas)
    )

    sql = f"""
        INSERT INTO {tabla}
        ({nombres_columnas})
        VALUES ({placeholders})
    """

    datos = [
        tuple(fila)
        for fila in df.itertuples(index=False, name=None)
    ]

    cursor.executemany(
        sql,
        datos
    )

    conexion.commit()

    print(
        f"{tabla}: {len(datos)} registros cargados."
    )


# ============================================================
# 8. CARGA DE LAS TABLAS
# ============================================================
#
# Las dimensiones se cargan primero porque las tablas de hechos
# dependen de ellas mediante claves foráneas.
# ============================================================


print("\nIniciando carga de datos...")


cargar_dataframe(
    datasets["dim_depot"],
    "dim_depot"
)


cargar_dataframe(
    datasets["dim_linea"],
    "dim_linea"
)


cargar_dataframe(
    datasets["dim_vehiculo"],
    "dim_vehiculo"
)


cargar_dataframe(
    datasets["dim_conductor"],
    "dim_conductor"
)


cargar_dataframe(
    datasets["dim_parada"],
    "dim_parada"
)


cargar_dataframe(
    datasets["dim_tarifa"],
    "dim_tarifa"
)


cargar_dataframe(
    datasets["fact_viajes"],
    "fact_viajes"
)


cargar_dataframe(
    datasets["fact_incidencias"],
    "fact_incidencias"
)


cargar_dataframe(
    datasets["fact_mantenimiento"],
    "fact_mantenimiento"
)


# ============================================================
# 9. CIERRE DE LA CONEXIÓN
# ============================================================

cursor.close()
conexion.close()


print("\n==========================================")
print("Carga de datos finalizada correctamente.")
print("==========================================")