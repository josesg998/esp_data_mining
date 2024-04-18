import pandas as pd
from hyperopt import fmin, tpe, STATUS_OK, Trials
from sklearn.metrics import roc_auc_score
from xgboost import DMatrix, train
from config import config
import numpy as np
import os
import pickle

def OB():
    
    model = input('Elegir modelo (RF o XGB): ')
    model = model.upper()
    # Define the space over which to search
    config_ML = config(model)

    series_CV = config_ML['CV']
    data      = config_ML['input']
    space     = config_ML[model]['space']
    clf       = config_ML[model]['model']
    output    = config_ML[model]['output']
    trials_path    = config_ML[model]['trials']
    
    # # Check if the log file exists
    # if os.path.exists(output):
    #     # Load the log from the file
    #     log = list(pd.read_csv(output, sep='\t'))
    #     print(log)
    # else:
    # Create a new log if no log file exists
    log = []

    try:
        # df = pd.read_csv('../data/vdem_coup.csv',parse_dates=True,keep_date_col=True)
        df = pd.read_pickle(data)
    except:
        print('No hay archivo pickle, se cargará el archivo csv y se guardará el pickle para futuras ocasiones')
        data_csv = data.split('.')[0]+'.csv'
        df = pd.read_csv(data_csv,parse_dates=True,keep_date_col=True,low_memory=False)
        df.to_pickle(data)

    # drop non numeric columns for df pandas dataframe
    df = df.select_dtypes(include=['number'])

    X = df.drop('coup', axis=1)
    y = df.set_index('year')['coup']
    X.fillna(0, inplace=True)


    def block_time_series_CV(X, y, clf,series_CV=series_CV,model='RF'):

        # Perform block time-series cross-validation
        scores = []
        for n in range(5):                
            
            inicio_train = series_CV[n]['train'][0]
            fin_train    = series_CV[n]['train'][1]
            inicio_val   = series_CV[n]['val'][0]
            fin_val      = series_CV[n]['val'][1]
            
            X_train = X[X['year'].between(inicio_train, fin_train)]
            X_val   = X[X['year'].between(inicio_val, fin_val)]
            y_train = y[(y.index>=inicio_train)&(y.index<=fin_train)]
            y_val  =  y[(y.index>=inicio_val)  &(y.index<=fin_val)]
            
            if model=='XGB':
                dtrain = DMatrix(X_train,label=y_train)
                dtest = DMatrix(X_val,label=y_val)
                
                bst = train(clf, dtrain, num_boost_round=10) # TODO
                
                y_pred = bst.predict(dtest)
            else:
                clf.fit(X_train, y_train)
                y_pred = clf.predict(X_val)
            score = roc_auc_score(y_val, y_pred)
            scores.append(score)
        
            mean_score = sum(scores) / len(scores)
        return -mean_score

    # Define the objective function
    def objective(params):
        
        clf.set_params(**params,random_state=42)
            
        mean_score = block_time_series_CV(X, y, clf)        
        
        params['score'] = mean_score
        
        log.append(params)
        
        pd.DataFrame(log).to_csv(output, index=True,sep='\t',index_label='iteration')
        
        return {'loss': -mean_score, 'status': STATUS_OK}


    # Run the optimizer
    if os.path.exists(trials_path):
        print("Historial de bayesiana encontrado! Cargando...\n")
        trials = pickle.load(open(trials_path, "rb"))
        # import log file and transform it into a list consisted of dictionaries
        log = list(pd.read_csv(output, sep='\t').drop(columns='iteration').to_dict(orient='records'))
    else:
        trials = Trials()
    fmin(fn=objective, space=space, algo=tpe.suggest, max_evals=10, trials=trials, rstate=np.random.default_rng(42),trials_save_file=trials_path)
    
    print("Fin de la Bayesiana!")
    
if __name__ == "__main__":
    OB()