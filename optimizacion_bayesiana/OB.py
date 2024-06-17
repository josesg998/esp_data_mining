import pandas as pd
from hyperopt import fmin, tpe, STATUS_OK, Trials
from sklearn.metrics import roc_auc_score
from xgboost import DMatrix, train
from config import config
import numpy as np
import os
import pickle

os.chdir('buckets/b1')

def OB():
    # create folder logs and trials if they don't exist
    if not os.path.exists('logs'):
        os.makedirs('logs')
    if not os.path.exists('trials'):
        os.makedirs('trials')    
    
    #eleccion de modelo
    model = input('Elegir modelo (RF o XGB): ')
    model = model.upper()
    
    # se toma información del modelo desde el config file
    config_ML = config(model)

    series_CV      = config_ML['CV']
    data           = config_ML['input']
    space          = config_ML[model]['space']
    clf            = config_ML[model]['model']
    output         = config_ML[model]['output']
    trials_path    = config_ML[model]['trials']
    iteraciones    = config_ML['iteraciones']
    
    log = []

    # se toma archivo pickle, si no existe se crea desde el csv generado en el script de R
    df = pd.read_csv(data)
    

    # drop non numeric columns for df pandas dataframe
    df = df.select_dtypes(include=['number'])
    df = df[df.columns[~df.columns.str.startswith('e_')]]

    X = df.drop('coup', axis=1)
    y = df.set_index('year')['coup']
    # X.fillna(0, inplace=True)


    def block_time_series_CV(X, y, clf,series_CV=series_CV,model='RF'):

        # se hace block-time series cv a partir del config file
        scores = []
        for fold in series_CV:                
            
            inicio_train = fold['train'][0]
            fin_train    = fold['train'][1]
            inicio_val   = fold['val'][0]
            fin_val      = fold['val'][1]
            
            X_train = X[X['year'].between(inicio_train, fin_train)]
            X_val   = X[X['year'].between(inicio_val, fin_val)]
            y_train = y[(y.index>=inicio_train)&(y.index<=fin_train)]
            y_val  =  y[(y.index>=inicio_val)  &(y.index<=fin_val)]
            
            if model=='XGB':
                dtrain = DMatrix(X_train,label=y_train)
                dtest = DMatrix(X_val,label=y_val)
                
                bst = train(clf, dtrain)
                
                y_pred = bst.predict(dtest)
            else:
                clf.fit(X_train, y_train)
                y_pred = clf.predict(X_val)
            score = roc_auc_score(y_val, y_pred)
            scores.append(score)
        
            mean_score = sum(scores) / len(scores)
        return mean_score

    # Define the objective function
    def objective(params):
        '''funcion objetivo a minimizar por la optimización bayesiana'''
        clf.set_params(**params,random_state=42)
        time = pd.Timestamp.now()
        mean_score = block_time_series_CV(X, y, clf)        
        minutes = (pd.Timestamp.now()-time).seconds/60
        
        params['score'] = mean_score
        params['minutes'] = round(minutes,2)
        
        log.append(params)
        
        pd.DataFrame(log).to_csv(output, index=True,sep='\t',index_label='iteration')
        
        return {'loss': -mean_score, 'status': STATUS_OK}

    # si hay un archivo con el historial de bayesianas se carga, si no se crea un trials vacío
    if os.path.exists(trials_path):
        print("Historial de bayesiana encontrado! Cargando...\n")
        trials = pickle.load(open(trials_path, "rb"))
        # se import log file
        log = list(pd.read_csv(output, sep='\t').drop(columns='iteration').to_dict(orient='records'))
    else:
        trials = Trials()
    
    # se ejecuta optimización bayesiana
    fmin(fn=objective, space=space, algo=tpe.suggest, max_evals=iteraciones, trials=trials, 
         rstate=np.random.default_rng(42),trials_save_file=trials_path)
    
    print("Fin de la Bayesiana!")
    
if __name__ == "__main__":
    OB()
