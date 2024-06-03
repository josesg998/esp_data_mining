# %%
import pandas as pd
from config import config
import pickle

# %%
#eleccion de modelo
model = input('Elegir modelo (RF o XGB): ')
model = model.upper()

# se toma información del modelo desde el config file
config_ML = config(model)
clf            = config_ML['modelo']
output         = config_ML['output']

# %%

# se toma archivo pickle, si no existe se crea desde el csv generado en el script de R
df = pd.read_pickle('data/vdem_coup_ML.pkl')

# drop non numeric columns for df pandas dataframe
df = df.select_dtypes(include=['number'])

df = df.columns[~df.columns.str.startswith('e_')]

X = df.drop('coup', axis=1)
y = df.set_index('year')['coup']

X_train = X[X['year']<2020]
y_train = y[y.index<2020]

# %%
clf.fit(X_train, y_train)
with open(output, 'wb') as f:
    pickle.dump(clf, f)
print('Entrenamiento finalizado')