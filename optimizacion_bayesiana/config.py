from sklearn.ensemble import RandomForestClassifier
from hyperopt import hp
from xgboost import XGBClassifier

def config():
    return {
        # Random Forest
        'RF': {
            'model':RandomForestClassifier(),
            'output':'logs/OB_random_forest_log.csv',
            'space':{
                'n_estimators':5,
                'max_depth':    hp.uniformint('max_depth', 1, 4),
                'max_features': hp.choice('max_features', [ 'sqrt', 'log2']),
                'criterion':    hp.choice('criterion', ['gini', 'entropy'])
                }
        },

        'XGB':{
            'model':XGBClassifier(),
            'output':'logs/OB_XGB_log.csv',
            'space':{
                'n_estimators':5,                
                'max_depth':    hp.uniformint('max_depth', 1, 4)
                }
        }, # Block Time Series Cross Validation
        
        'CV':  {
        1: {'train':(1970,2009),'val':(2010,2011)},
        2: {'train':(1970,2011),'val':(2012,2013)},
        3: {'train':(1970,2013),'val':(2014,2015)},
        4: {'train':(1970,2015),'val':(2016,2017)},
        5: {'train':(1970,2017),'val':(2018,2019)}
        }
    }