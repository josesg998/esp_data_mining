# %%
import pandas as pd
from config import config
import pickle
import os

# %%
#eleccion de modelo
model = input('Elegir modelo (RF o XGB): ')
model = model.upper()
end = input('Elegir año de fin de corte: ')
end = int(end)

# se toma información del modelo desde el config file
config_ML = config(model)
output         = config_ML['output']

# %%

# se toma archivo pickle, si no existe se crea desde el csv generado en el script de R
df = pd.read_csv('data/vdem_coup_ML.csv')

# drop non numeric columns for df pandas dataframe
df = df.select_dtypes(include=['number'])

df = df[df['year']>=1970]

df = df[df.columns[~df.columns.str.startswith('e_')]]

X = df.drop('coup', axis=1)
y = df.set_index('year')['coup']

clf            = config_ML['modelo']

X_train = X[X['year']<2020]
y_train = y[y.index  <2020]

# %%
clf.fit(X_train, y_train)
with open('modelos/'+output, 'wb') as f:
    pickle.dump(clf, f)
print("Entrenamiento finalizado")