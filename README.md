# Predicción de golpes de Estado en el siglo xxi

## Introducción

El objetivo de este trabajo es reproducir el artículo realizado por Cebotari et al 
(2024) para el Fondo Monetario Internacional (FMI) en el año 2024. En el mismo,
se entrenaron algoritmos de aprendizaje automático para predecir la presencia de golpes
de estado en los años 2020 a 2022 en todos los países del mundo. Este trabajo busca
reproducir la metodología utilizada pero utilizando un conjunto de datos distinto para su
entrenamiento, específicamente la base de datos de Varieties of Democracy (V-Dem) 
(Cebtari et al. 2024). Una vez realizado el entrenamiento, se 
busca comparar la performance de los algoritmos entrenados con los utilizados por el artículo
de Cebotari et al (2024), evaluando si se logró alcanzar el mismo nivel de predicción. 
Adicionalmente, este trabajo busca tener una noción acabada de las variables más importantes 
que los algoritmos utilizan para la predicción de la variable objetivo, de manera de tener
una noción del poder predictivo de variables exclusivamente políticas e institucionales para 
la predicción de golpes de Estado.

## Reproducción del trabajo

Para la reproducción del trabajo, se utilizó el lenguaje de programación R en su versión 4.3.1 y 
se utilizó la versión 3.12 de Python, con los módulos y librerías que se detallan en el archivo
`requirements.txt`. A continuación mostramos los pasos para replicar el trabajo:

1. Los datos se obtienen con el archivo `get_data.R`, para eso son necesarias las librerías
data.table (para importar los datos y procesarlos), devtools y vdemdata (para obtener los datos de V-Dem
desde su librería de R).

2. La optimización bayesiana se realiza con el archivo `optimizacion_bayesiana/OB.py`, el cual es configurado
con el archivo `optimizacion_bayesiana/config.py`.

3. Una vez obtenidos los hiperparámetros óptimos, cargarlos en `entrenamiento_final/config.py` y correr el script
`entrenamiento_final/train.py`, lo cual devolverá los modelos finales entrenados en formato pkl.

Adicionalmente, están los scripts `EDA.R` y `entrenamiento_final/analisis_final.ipynb` que realizan un análisis exploratorio
en el primer caso, y un análisis de los modelos entrenados y sus valores Shapley en el segundo caso.

Por último, en la carpeta entregas figura el trabajo realizado en formato .tex y su correspondiente .pdf, así como las imágenes,
bibliografía y plantilla utilizada.

