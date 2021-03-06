function [data] = CEA_Rocket_Heat(ox,fuel,pct_psi,O_F,epsilon,Tox,Tf)

reactants =   [                                           ...
             CEA.Reactant(fuel,                           ...
                     'Type','Fuel',                     ...
                     'T',DimVar(Tf,'K'),             ...         
                     'Q',DimVar(1,'kg'))                ...
            CEA.Reactant(ox,                            ...
                    'Type','ox',                        ...
                    'T',DimVar(Tox,'K'),              ...         
                    'Q',DimVar(1,'kg'))                 ...
            ];     
        

data =  CEA.Run(reactants,                                ...
        'ProblemType','Rocket',                         ...
        'Flow','eq',                                 ...
        'Pc',DimVar(pct_psi,'psi'),                           ...
        'OF',O_F,'supar',epsilon,                                         ...
        'Outputs',{'rho','son','pran','cp','mw','vis','gam'});
