import pandas as pd
from hyperopt import fmin, tpe, STATUS_OK, Trials
from sklearn.metrics import roc_auc_score
from xgboost import DMatrix, train
from config import config

def OB(model):
    # Define the space over which to search
    config_ML = config()

    series_CV = config_ML['CV']
    model     = config_ML[model]
    space     = model['space']
    clf       = model['model']
    output    = model['output']

    log = []


    # df = pd.read_csv('../data/vdem_coup.csv',parse_dates=True,keep_date_col=True)
    df = pd.read_pickle('../data/vdem_coup.pkg')

    # drop non numeric columns for df pandas dataframe
    df = df.select_dtypes(include=['number'])

    X = df.drop('coup', axis=1)
    y = df.set_index('year')['coup']
    X.fillna(0, inplace=True)


    def block_time_series_CV(X, y, clf,series_CV=series_CV,model='RF'):

        # Perform block time-series cross-validation
        scores = []
        for n in range(1,6):                
            
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
    def objective(params,clf=clf,log=log,output=output):
        
        clf.set_params(**params,random_state=42)
            
        mean_score = block_time_series_CV(X, y, clf)        
        
        params['score'] = mean_score
        
        log.append(params)
        
        pd.DataFrame(log).to_csv(output, index=True,sep='\t',index_label='iteration')
        
        return {'loss': -mean_score, 'status': STATUS_OK}


    # Run the optimizer
    trials = Trials()
    best = fmin(fn=objective, space=space, algo=tpe.suggest, max_evals=10, trials=trials)