function ret = sim_output_gen(Excel, flightdata, forces, max, Eng, Roc)
% Write the simulation and simulation input parameters described by
% flightdata, forces, propinfo, max, Prop, Eng, and Roc into the current
% active Excel sheet
Excel.Range('A1:N1').Select();
Excel.Selection.Value = {'Time (s)', 'Acceleration (m/s)', 'Velocity (m/s)',...
    'Altitude (m)', 'Mach Number', 'Total Delivered Impulse (N*s)', 'Y Acceleration (m/s^2)', 'Y Velocity (m/s',...
    'X Acceleration (m/s^2)', 'X Velocity (m/s)', 'X Position (m)', 'Angle (°)', 'Free-stream pressure (Pa)', 'Air density (kg/m3)'};
[rows, ~] = size(flightdata);
Excel.Range(sprintf('A2:N%i', rows)).Select();
Excel.Selection.Value = num2cell(flightdata);

Excel.Range('O1:Q1').Select();
Excel.Selection.Value = {'Mass (kg)', 'Drag (N)', 'Thrust (N)'};
[rows, ~] = size(forces);
Excel.Range(sprintf('O2:Q%i', rows)).Select();
Excel.Selection.Value = num2cell(forces);

% Insert results
begin_col = 19;
[~, plusc] = insert_struct_into_excel(max, 'Maximums', Excel, [1, begin_col]);
begin_col = begin_col + plusc + 2;
[~, plusc] = insert_struct_into_excel(Eng, 'Engine', Excel, [1, begin_col]);
begin_col = begin_col + plusc + 2;
[~, plusc] = insert_struct_into_excel(Roc, 'Rocket', Excel, [1, begin_col]);
ret = 0;
end