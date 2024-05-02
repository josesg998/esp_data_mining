from hyperopt import hp

def config(modelo):    
    diccionario = {
        'iteraciones': 100,
        'CV':  [
        {'train':(1970,2009),'val':(2010,2011)},
        {'train':(1970,2011),'val':(2012,2013)},
        {'train':(1970,2013),'val':(2014,2015)},
        {'train':(1970,2015),'val':(2016,2017)},
        {'train':(1970,2017),'val':(2018,2019)}],
        'input':'data/vdem_coup_ML.pkl'
    }
    
    if modelo=='RF': # Random Forest
        from sklearn.ensemble import RandomForestClassifier        
        diccionario[modelo] =  {
            'model':RandomForestClassifier(n_jobs=-1),
            'output':'optimizacion_bayesiana/logs/OB_random_forest_log.csv',
            'space':{
                'n_estimators':1000,
                'max_depth':    hp.uniformint('max_depth', 1, 15),
                'max_features':hp.uniform('max_features', 0.1, 1.0),
                },
            'trials':'optimizacion_bayesiana/trials/trials_RF.pkl'
        }
        return diccionario
    
    elif modelo=='XGB': #XGBBoost
        from xgboost import XGBClassifier
        diccionario[modelo] = {
            'model':XGBClassifier(),
            'output':'optimizacion_bayesiana/logs/OB_XGB_log.csv',
            'space':{
                'n_estimators':1000,
                'reg_lambda': hp.uniform('reg_lambda', 0.1, 10),
                'learning_rate': hp.uniform('learning_rate', 0.01, 0.3),
                },
            'trials':'optimizacion_bayesiana/trials/trials_XGB.pkl'
        }
        return diccionario
    
    else:
        print("No tenemos ese modelo en el diccionario")