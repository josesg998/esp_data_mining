def config(modelo):
    diccionario = {}
    
    if modelo=='RF': # Random Forest
        from sklearn.ensemble import RandomForestClassifier      
        diccionario['modelo'] = RandomForestClassifier(n_jobs=-1,
                                     n_estimators=1000,
                                     max_depth=8,
                                     max_features=0.535263,
                                     random_state=42)
        diccionario['output'] = 'random_forest.pkl'
        
        return diccionario
    
    elif modelo=='XGB': #XGBBoost
        from xgboost import XGBClassifier
        diccionario['modelo'] = XGBClassifier(n_estimators=1000,
                            learning_rate=0.238914349636628,
                            reg_lambda=0.4425001945646789,
                            use_label_encoder=False,
                            random_state=42)
        diccionario['output'] = 'xgboost.pkl'
        
        return diccionario
    
    else:
        print("No tenemos ese modelo en el diccionario")
