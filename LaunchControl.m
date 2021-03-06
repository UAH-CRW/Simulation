%% Liquid Rocket Script with Simulink
% Model LRSim1D
clc,clear
startup % run startup script for CEA and Coolprop


%runsim() % Uses default parameters
%Changes temperature (K), pressure (Pa), MR, area ratio, and chamber
%pressure (psi)

%READ THESE IN FROM EXCEL LATER

%warning('off','all')

%% Simulation Conditions
atm_conditions = [];
atmoptions = readtable('simconfig.xlsm', 'Sheet', 'Simulation Conditions');

atm_conditions.pamb = param_from_table(atmoptions, 'Ambient pressure', 1);

atm_conditions.Tamb = param_from_table(atmoptions, 'Ambient temperature', 1);

atm_conditions.launchaltitude = param_from_table(atmoptions, 'Launch Altitude', 1);

monte_carlo_iterations = param_from_table(atmoptions, '# of Monte Carlo runs', 1);

atm_conditions.rail_length = param_from_table(atmoptions, 'Rail length (effective)', 1);

atm_conditions.launch_angle = deg2rad(param_from_table(atmoptions, 'Launch angle', 1));

atm_conditions.windspeed = param_from_table(atmoptions, 'Windspeed', 1);

%% Rocket Options
rocket_params = [];
engine_params = [];
rocketoptions = readtable('simconfig.xlsm', 'Sheet', 'Vehicle');
rocket_params.minert = param_from_table(rocketoptions, 'Total inert mass', 1);
rocket_params.d = param_from_table(rocketoptions, 'Largest circular diameter', 1);
rocket_params.Cd_adjust = param_from_table(rocketoptions, 'Rocket Cd adjustment', 1);

for i = 1:height(rocketoptions)
    if strcmp(table2cell(rocketoptions(i, 1)), 'Motor')
        name = table2cell(rocketoptions(i, 2));
        engine_params.name = name{1};
    end
end

engine_params.impulse_adjust = param_from_table(rocketoptions, 'Motor impulse adjustment', 1);

%% Recovery system options
recovery_params = [];
recoveryoptions = readtable('simconfig.xlsm', 'Sheet', 'Recovery');

recovery_params.droguedeployoffset = param_from_table(recoveryoptions, 'Drogue deployment time', 1);
recovery_params.maindeployaltitude = param_from_table(recoveryoptions, 'Main deployment altitude', 1);
recovery_params.mainCd = param_from_table(recoveryoptions, 'Main chute Cd', 1);
recovery_params.drogueCd = param_from_table(recoveryoptions, 'Drogue chute Cd', 1);
recovery_params.mainarea = param_from_table(recoveryoptions, 'Main chute area', 1);
recovery_params.droguearea = param_from_table(recoveryoptions, 'Drogue chute area', 1);

%% Mode Detection

% 1 is single
% 2 is monte carlo
% 3 is range
mode = detect_value_types(atm_conditions, engine_params, rocket_params, recovery_params);

%% Simulation Execution
results = [];


startup % run startup script for CEA and Coolprop
if (mode == 1)
    [keyinfo, flightdata, forces, Roc, Eng] = runsim(atm_conditions, engine_params, rocket_params, recovery_params);
elseif (mode == 2)
    
    fieldrecord = cell([monte_carlo_iterations, 1]);
    fullsims = cell([monte_carlo_iterations, 1]);
    
    exec_times = [0];
    for runNum = 1:monte_carlo_iterations
        fprintf('\n\nOn iteration %.0f of %.0f  ( %.1f%% )', runNum, monte_carlo_iterations, runNum/monte_carlo_iterations*100);
        
        iterations_remaining = monte_carlo_iterations - runNum;
        time_remaining = iterations_remaining * mean(exec_times);
        
        
        curr_time = clock;
        curr_hr = curr_time(4); curr_min = curr_time(5); curr_s = curr_time(6);
        
        finish_hr = floor(curr_hr + time_remaining / (60.0 * 60.0));
        finish_min = floor(curr_min + mod(time_remaining / 60.0,60));
        finish_s = floor(curr_s +  mod(time_remaining,60));
        
        finish_min = finish_min + finish_s/60;
        finish_hr = finish_hr + finish_min/60;
        
        finish_s = floor(mod(finish_s,60));
        finish_min = floor(mod(finish_min,60));
        finish_hr = floor(mod(finish_hr,24));
        
        fprintf('\nEstimated Time Remaining: %4.0f : %02.0f : %02.0f', floor(time_remaining / (60.0 * 60.0)), floor(mod(time_remaining / 60.0,60)), floor(mod(time_remaining,60)));
        fprintf('\nApproximate Time Elapsed: %4.0f : %02.0f : %02.0f', floor(sum(exec_times) / (60.0 * 60.0)), floor(mod(sum(exec_times) / 60.0,60)), floor(mod(sum(exec_times),60)));
        fprintf('\nExtrapolated Finish Time: %4.0f : %02.0f : %02.0f', finish_hr, finish_min, finish_s);
        
        [this_run_atm_conditions, this_run_engine_params, this_run_rocket_params, this_run_recovery_params, varied_fields] = generate_monte_carlo_parameters(atm_conditions, engine_params, rocket_params, recovery_params);
        
        [keyinfo, flightdata, forces, Roc, Eng, exec_time] = runsim(this_run_atm_conditions, this_run_engine_params, this_run_rocket_params, this_run_recovery_params);
        
        exec_times(runNum) = exec_time * 1.125; % Multiply by 1.125 so the time estimate is conservative and we don't end up trying to make a graph out of the data in 7 minutes before a poster is due when we thought we'd have an hour
        
        fieldrecord(runNum) = {varied_fields};
        data.flightdata = flightdata;
        data.keyinfo = keyinfo;
        data.forces = forces;
        data.Roc = Roc;
        data.Eng = Eng;
        fullsims{runNum} = data;
        %FIXME: currently defaulting to mass fraction of 0
        results(runNum,:) = [keyinfo.alt, keyinfo.mach, keyinfo.accel, keyinfo.Q, keyinfo.load, keyinfo.thrust, this_run_rocket_params.minert, 0 / (0 + this_run_rocket_params.minert)];
    end
elseif (mode == 3)
    % Return [2, 5, 10] if the first parameter has 2 values, the next
    % has 5, and the 3rd has 10. Preserving order is obviously rather
    % important here
    dimensions = get_sim_dimensions(atm_conditions, engine_params, rocket_params, recovery_params);
    dimensions = dimensions + 1;
    
    fprintf('\nDimension Sizes:');
    disp(dimensions);
    
    for i = 1:numel(dimensions)
        if(dimensions(i) <= 1)
            error('The %s range of values parameter has one or fewer items. Decrease the step size for the parameter.',num2ordinal(i));
        end
    end
    
    input_counts = ones([1,length(dimensions)]);
    
    input_counts(end) = 0;
    
    fieldrecord = cell([prod(dimensions), 1]);
    fullsims = cell([prod(dimensions), 1]);
    
    exec_times = [0];
    
    for i = 1:prod(dimensions)
        input_counts(end) = input_counts(end) + 1;
        for j = numel(input_counts):-1:2
            if (input_counts(j) > dimensions(j))
                input_counts(j) = 1;
                input_counts(j-1) = input_counts(j-1) + 1;
            end
        end
        
        input_coefficients = (input_counts-1) ./ (dimensions-1);
        
        fprintf('\n\nOn iteration %.0f of %.0f  ( %.1f%% )', i, prod(dimensions), i/prod(dimensions)*100);
        
        iterations_remaining = prod(dimensions) - i;
        time_remaining = iterations_remaining * mean(exec_times);
        
        
        curr_time = clock;
        curr_hr = curr_time(4); curr_min = curr_time(5); curr_s = curr_time(6);
        
        finish_hr = floor(curr_hr + time_remaining / (60.0 * 60.0));
        finish_min = floor(curr_min + mod(time_remaining / 60.0,60));
        finish_s = floor(curr_s +  mod(time_remaining,60));
        
        finish_min = finish_min + finish_s/60;
        finish_hr = finish_hr + finish_min/60;
        
        finish_s = floor(mod(finish_s,60));
        finish_min = floor(mod(finish_min,60));
        finish_hr = floor(mod(finish_hr,24));
        
        fprintf('\nEstimated Time Remaining: %4.0f : %02.0f : %02.0f', floor(time_remaining / (60.0 * 60.0)), floor(mod(time_remaining / 60.0,60)), floor(mod(time_remaining,60)));
        fprintf('\nApproximate Time Elapsed: %4.0f : %02.0f : %02.0f', floor(sum(exec_times) / (60.0 * 60.0)), floor(mod(sum(exec_times) / 60.0,60)), floor(mod(sum(exec_times),60)));
        fprintf('\nExtrapolated Finish Time: %4.0f : %02.0f : %02.0f', finish_hr, finish_min, finish_s);
        
        [this_run_atm_conditions, this_run_engine_params, this_run_rocket_params, this_run_recovery_params, varied_fields] = generate_range_of_values_parameters(atm_conditions, engine_params, rocket_params, recovery_params, input_coefficients);
        
        [keyinfo, flightdata, forces, Roc, Eng, exec_time] = runsim(this_run_atm_conditions, this_run_engine_params, this_run_rocket_params, this_run_recovery_params);
        
        exec_times(i) = exec_time * 1.125;
        
        fieldrecord(i) = {varied_fields};
        data.flightdata = flightdata;
        data.keyinfo = keyinfo;
        data.forces = forces;
        data.Roc = Roc;
        data.Eng = Eng;
        fullsims{i} = data;
        results(i,:) = [keyinfo.alt, keyinfo.mach, keyinfo.accel, keyinfo.Q, keyinfo.load, keyinfo.thrust, this_run_rocket_params.minert, 0 / (0 + this_run_rocket_params.minert)];
        
    end
    
    
end

fprintf('\n\nDone Simulating!\n\n');


%% Output

% From https://www.mathworks.com/matlabcentral/answers/2603-add-a-new-excel-sheet-from-matlab
% Connect to Excel
Excel = actxserver('excel.application');
% Get Workbook object
fname = ['Output/sim ' datestr(now(), 'yyyy-mm-dd-HH-MM') '.xlsx'];
% https://www.mathworks.com/matlabcentral/answers/94822-are-there-any-examples-that-show-how-to-use-the-activex-automation-interface-to-connect-matlab-to-ex
Workbooks = Excel.Workbooks;
WB = invoke(Workbooks, 'Add');
% WB = Excel.Workbooks.New(fullfile(pwd, fname), 0, false);
Excel.Visible = true;
% Get Worksheets object
WS = WB.Worksheets;

if (mode == 1)
    % Add after the last sheet
    WS.Add([], WS.Item(WS.Count));
    WS.Item(WS.Count).Name = 'Output';
    % Delete default sheets
    while WS.Count > 1
        WB.Sheets.Item(WS.Count - 1).Delete();
    end
    
    % https://stackoverflow.com/questions/7636567/write-information-into-excel-after-each-loop
    WB.Sheets.Item(WS.Count).Activate();
    sim_output_gen(Excel, flightdata, forces, keyinfo, Eng, Roc);
    
elseif (mode == 2 || mode == 3)
    if(mode == 2)
        iteration_count = monte_carlo_iterations;
    else
        iteration_count = prod(dimensions);
    end
    
    WS.Add([], WS.Item(WS.Count));
    WS.Item(WS.Count).Name = 'Summary';
    % Delete default sheets
    while WS.Count > 1
        WB.Sheets.Item(WS.Count - 1).Delete();
    end
    WB.Sheets.Item(WS.Count).Activate();
    
    tablestart = 5;
    Excel.Range(sprintf('A%i:A%i', tablestart + 2, iteration_count + 6)).Select();
    its = 1:iteration_count;
    Excel.Selection.Value = its';
    
    % Insert input values
    [num_varied_parameters, ~] = size(fieldrecord{1});
    for i = 1:num_varied_parameters
        cur_record = fieldrecord{1};
        Excel.Range(sprintf('%s%i', alphabetnumbers(i + 1), tablestart)).Select();
        Excel.Selection.Value = 'Input';
        Excel.Range(sprintf('%s%i', alphabetnumbers(i + 1), tablestart + 1)).Select();
        Excel.Selection.Value = cur_record(i, 1);
        for j = 1:iteration_count
            Excel.Range(sprintf('%s%i', alphabetnumbers(i + 1), j + tablestart + 1)).Select();
            cur_record = fieldrecord{j};
            Excel.Selection.Value = cur_record(i, 2);
        end
    end
    
    output_headers = {'Apogee (ft)', 'Mach Number', 'Acceleration (G)', 'Drag (lbf)',...
        'Load (lbf)', 'Thrust (lbf)', 'Dry Mass (kg)', 'Mass Fraction'};
    Excel.Range(sprintf('%s%i:%s%i', alphabetnumbers(num_varied_parameters + 2),...
        tablestart + 1, alphabetnumbers(num_varied_parameters + 1 + length(output_headers)), tablestart + 1)).Select();
    Excel.Selection.Value = output_headers;
    %Insert output values
    for j = 1:length(output_headers)
        for i = 1:iteration_count
            Excel.Range(sprintf('%s%i', alphabetnumbers(num_varied_parameters + 2 + j - 1), i + tablestart + 1)).Select();
            Excel.Selection.Value = results(i, j);
        end
    end
    
    apogees = results(:,1);
    binstep = (max(apogees) - min(apogees)) / (iteration_count / 3);
    bins = (min(apogees) * 0.99):binstep:(max(apogees) * 1.01);
    [counts] = histc(apogees, bins);
    % Each entry in counts is the number of values between the
    % corresponding entry in bins and the subsequent entry in bins. This
    % means that the last entry in counts will always be zero
    counts = counts(1:end-1);
    
    % Output into Excel will contain the average bin value instead of the
    % endpoints of the bin, for easier plotting. Bin size is readily
    % calculated from the spacing between two bins
    % https://www.mathworks.com/matlabcentral/answers/89845-how-do-i-create-a-vector-of-the-average-of-consecutive-elements-of-another-vector-without-using-a-l#answer_99279
    excel_bins = mean([bins(1:end-1); bins(2:end)])';
    
    Excel.Range(sprintf('%s%i:%s%i', alphabetnumbers(num_varied_parameters ...
        + length(output_headers) + 5), tablestart + 1, ...
        alphabetnumbers(num_varied_parameters + length(output_headers) + 5),...
        tablestart + length(bins) - 1)).Select();
    Excel.Selection.Value = excel_bins;
    Excel.Range(sprintf('%s%i:%s%i', alphabetnumbers(num_varied_parameters ...
        + length(output_headers) + 6), tablestart + 1, ...
        alphabetnumbers(num_varied_parameters + length(output_headers) + 6),...
        tablestart + length(bins) - 1)).Select();
    Excel.Selection.Value = counts;
    
    for i = 1:iteration_count
        WS.Add([], WS.Item(WS.Count));
        WS.Item(WS.Count).Name = sprintf('Run #%i', i);
        WB.Sheets.Item(WS.Count).Activate();
        this_sim = fullsims(i);
        this_sim = this_sim{:};
        sim_output_gen(Excel, this_sim.flightdata, this_sim.forces,...
            this_sim.keyinfo, this_sim.Eng, this_sim.Roc);
    end
    
    results = sortrows(results);
    
elseif mode == 3
    
end

% Save
%SaveAs(Excel, 'Output/test.xlsx');
invoke(WB, 'SaveAs', fullfile(pwd, fname));
WB.Saved = 1;
%WB.Save(); %As('Output/test.xlsx');
% Quit Excel
Excel.Quit();