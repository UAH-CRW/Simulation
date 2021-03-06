function dim = get_sim_dimensions(atm_conditions, prop_params, engine_params, rocket_params, avionics_params)
% Given a set of input parameters where n parameters are set to 'Range of 
% Values', return the dimensions associated with an n-dimensional matrix
% that holds every permutation of the simulation
dim = [];
fields = fieldnames(atm_conditions);
for i = 1:numel(fields)
    if ( length(atm_conditions.(fields{i})) == 3)
        param = atm_conditions.(fields{i});
        dim = [dim (param(3) - param(1))/param(2)];
    end
end

fields = fieldnames(engine_params);
for i = 1:numel(fields)
    if (length(engine_params.(fields{i})) == 3)
        param = engine_params.(fields{i});
        dim = [dim (param(3) - param(1))/param(2)];
    end
end


fields = fieldnames(rocket_params);
for i = 1:numel(fields)
    if ( length(rocket_params.(fields{i})) == 3)
        param = rocket_params.(fields{i});
        dim = [dim (param(3) - param(1))/param(2)];
    end
end

dim = round(dim);
end

