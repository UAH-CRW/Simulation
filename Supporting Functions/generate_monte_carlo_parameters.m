function [this_run_atm_conditions, this_run_engine_params, this_run_rocket_params, this_run_recovery_params, variedtable] = generate_monte_carlo_parameters(atm_conditions, engine_params, rocket_params, recovery_params)
%GENERATE_MONTE_CARLO_PARAMETERS Summary of this function goes here
%   Detailed explanation goes here

this_run_atm_conditions = [];
this_run_prop_params = [];
this_run_engine_params = [];
this_run_rocket_params = [];
this_run_recovery_params = [];

fields = fieldnames(atm_conditions);
variedtable = [];
for i = 1:numel(fields)
    if ( length(atm_conditions.(fields{i})) == 1)
        this_run_atm_conditions.(fields{i}) = atm_conditions.(fields{i});
    elseif ( length(atm_conditions.(fields{i})) == 2)
        this_run_atm_conditions.(fields{i}) = normrnd(atm_conditions.(fields{i})(1),atm_conditions.(fields{i})(2));
        variedtable = [variedtable; [{fields{i}}, this_run_atm_conditions.(fields{i})]];
    end
end

fields = fieldnames(engine_params);
for i = 1:numel(fields)
    if ( length(engine_params.(fields{i})) == 1 || ischar(engine_params.(fields{i})))
        this_run_engine_params.(fields{i}) = engine_params.(fields{i});
    elseif ( length(engine_params.(fields{i})) == 2)
        this_run_engine_params.(fields{i}) = normrnd(engine_params.(fields{i})(1),engine_params.(fields{i})(2));
        variedtable = [variedtable; [{fields{i}}, this_run_engine_params.(fields{i})]];
    end
end


fields = fieldnames(rocket_params);
for i = 1:numel(fields)
    if ( length(rocket_params.(fields{i})) == 1)
        this_run_rocket_params.(fields{i}) = rocket_params.(fields{i});
    elseif ( length(rocket_params.(fields{i})) == 2)
        this_run_rocket_params.(fields{i}) = normrnd(rocket_params.(fields{i})(1),rocket_params.(fields{i})(2));
        variedtable = [variedtable; [{fields{i}}, this_run_rocket_params.(fields{i})]];
    end
end

fields = fieldnames(recovery_params);
for i = 1:numel(fields)
    if ( length(recovery_params.(fields{i})) == 1)
        this_run_recovery_params.(fields{i}) = recovery_params.(fields{i});
    elseif ( length(recovery_params.(fields{i})) == 2)
        this_run_recovery_params.(fields{i}) = normrnd(recovery_params.(fields{i})(1), recovery_params.(fields{i})(2));
        variedtable = [variedtable; [{fields{i}}, this_run_recovery_params.(fields{i})]];
    end
end

end

