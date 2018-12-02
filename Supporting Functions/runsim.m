function [max_vals, flightdata, forces, Roc, Eng, exec_time] = runsim(Conditions, Eng, Roc, Recovery)
%RUNSIM Summary of this function goes here
%   Tamb:               ambient temperature (K)
%   Pamb:               ambient pressure (Pa)
%   MR:                 mixture (OF) ratio
%   expansion_ratio:    Nozzle expansion ratio (Ae/At)
%   chamber_pressure:   Chamber total pressure (psia)
%% Liquid Rocket Script with Simulink
% Model LRSim1D
%clc,clear

format shortG

% Coolprop reference
% http://www.coolprop.org/coolprop/wrappers/MATLAB/index.html#matlab

%% Initial Rocket Parameters
% General Constans and Assumptions
g = 9.81; % m/s2
m2f = 3.28084; % convert meters to feet
psi2pa = 6894.76; % convert psi to Pa
lb2kg = 0.453592; % convert lbs to kg
lb2N = 4.448; % convert lbs to N
in2m = 0.0254; % convert in to m

Roc.Cd = csvread('CdvsM_RASAERO.csv')';
Roc.Cd(2, :) = Roc.Cd(2, :) + Roc.Cd_adjust * ones(size(Roc.Cd(2, :)));

%%Read in thrust curve
%Must populate Eng.thrustcurve with properties:
%   - thrustcurve: nx2 matrix, with times (s) in the first column and thrust
%   (N) in the second
%   - minitial: wet motor mass (kg)
%   - mfinal: post-burn motor mass (kg)
%   - burntime: motor burn time (s)

Eng.thrustcurve = getmotorbyname(Eng.name);
Eng.thrustcurve.thrustcurve = Eng.thrustcurve.thrustcurve * (1 + Eng.impulse_adjust);

% Wet Mass and More Derived Performance
Roc.mwet = Eng.thrustcurve.minitial + Roc.minert; % Wet mass of rocket [kg]

Roc.Mprop = Eng.thrustcurve.mprop / Roc.mwet; % Propellant mass ratio

Roc.A = pi * Roc.d^2 / 4;

% For convenience with parachutes
Recovery.mainCdA = Recovery.mainCd * Recovery.mainarea;
Recovery.drogueCdA = Recovery.drogueCd * Recovery.droguearea;
Recovery.apogeetime = 0;

%% Simulation Section
options = simset('SrcWorkspace','current');

if ~isfield(Conditions, 'tend')
    tend = 300; % End time of sim in seconds
else
    tend = Conditions.tend;
end

tic % Record sim computation time
    load_system('LR_Traject_Sim.slx');
    simOut = sim('LR_Traject_Sim.slx', [], options);
    Flight.max.alt = max(flightdata(:,4))*m2f; % [ft]
    Flight.max.mach = max(flightdata(:,5)); % V/a
    Flight.max.accel = max(flightdata(:,2))/g; % [g]
    Flight.max.Q = max(forces(:,2))*0.2248; % Drag force[lb]
    Flight.max.load = max(forces(:,2)+forces(:,3))*0.2248; % Compressive load [lb]
    Flight.max.thrust = max(forces(:,3))*0.2248; % Thrust force[lb]
    Flight.max.impulse = max(flightdata(:, 6)); % [N*s]
    Flight.max.Isp = Flight.max.impulse / ((max(forces(:, 1)) - min(forces(:, 1))) * g);
    Flight.max.drift = max(abs(flightdata(:, 11))) * m2f;
    Flight.max.groundhitvelocity = abs(flightdata(end, 8)) * m2f;
    temp = find(~flightdata(5:end, 3));
    max_vals = Flight.max;

exec_time = toc;

end
