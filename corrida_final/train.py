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
df = pd.read_pickle('data/vdem_coup_ML.pkl')

# drop non numeric columns for df pandas dataframe
df = df.select_dtypes(include=['number'])

df = df[df.columns[~df.columns.str.startswith('e_')]]

X = df.drop('coup', axis=1)
y = df.set_index('year')['coup']

for year in range(2020,end+1):
    clf            = config_ML['modelo']
    print("Entrenando para el año "+str(year))
    if not os.path.exists('modelos/'+str(year)):
        os.mkdir('modelos/'+str(year))

    X_train = X[X['year']<year]
    y_train = y[y.index<year]

    # %%
    clf.fit(X_train, y_train)
    with open('modelos/'+str(year)+'/'+output, 'wb') as f:
        pickle.dump(clf, f)
    print('Entrenamiento finalizado para el año '+str(year))
print("Todos los entrenamientos finalizados")