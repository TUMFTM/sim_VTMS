function [Parameter]  =  Tesla_Model3()

%% Info

% This function is used to set up the vehicle parameters for the
% longitudinal dynamics simulation and the thermal properties of the
% powertrain components. 

% Since the goal of the simulation framework is to compare different
% vehicle CATHEGORIES the parameter set is based on the named vehicle but
% is by no means identical. This applies in particular to the component
% parameters!

Parameter.name  =  'Tesla_Model3';                                         % Vehicle name


%% I. Parameters for vehicle and electric powertrain

% Vehicle

Parameter.r_dynamisch = 0.3362;                                     % dynamic wheel radius in m
Parameter.rho_Luft = 1.2;                                           % air density in kg/m^3 (-> value used: standard conditions for 20°C)
Parameter.A_Stirn = 2.28;                                           % vehicle front surface in m^2
Parameter.c_W = 0.23;                                               % drag coefficient
Parameter.m_Fahrzeug = 1860;                                        % vehicle mass in kg
Parameter.e_Fahrzeug = 1;                                           % Rotational inertia factor
Parameter.m_Zuladung = 0;                                           % additional load in in kg
Parameter.f_R = 0.0161;                                             % rolling resistance coefficient
Parameter.v_max = 261;                                              % max. speed in km/h

Parameter.P_Nebenverbraucher = 0;                                   % Constant load from auxiliary energy users in vehicle in W


% Transmission

Parameter.i_Getriebe = 9.036;                                       % total transmission ratio between electric machine and wheels


% Electric Machine

load('Efficiency_map_EM_Tesla_Model3.mat');                         % efficiency map of electric machine
Parameter.eta_EMaschine_Break_M = KennfeldMaschine.M;               % influence on electric machine efficiency from torque in Nm
Parameter.eta_EMaschine_Break_n = KennfeldMaschine.n;               % influence on electric machine efficiency from rpm in 1/min
Parameter.eta_EMaschine_Table = KennfeldMaschine.etages;            % breakpoints for torque and rpm efficiencies
Parameter.eta_EMaschine_Volllast = 0.97;                            % power factor of electric machine
Parameter.m_EMaschine = 46.5;                                       % mass of electric machine in kg
Parameter.m_Getriebe = 23.25;                                       % mass of transmission in kg


% Power electronics

Parameter.n_MOSFET = 134;                                           % number of MOSFETS in power electronics. This is a model assumption to get the heat dissipation right and comparable between the different vehicles.
load('Efficiency_map_power_electronics.mat');                       % efficiency map of power electronics
Parameter.eta_Leistungselektronik_Break_M = eta_LE100_break_M;      % influence on power electronics efficiency from electric machine torque in Nm
Parameter.eta_Leistungselektronik_Break_n = eta_LE100_break_n;      % influence on power electronics efficiency from electric machine rpm in 1/min
Parameter.eta_Leistungselektronik_Table = eta_LE100_Kennfeld;       % breakpoints for torque and rpm efficiencies
Parameter.eta_Leistungselektronik_Volllast = 0.96;                  % power factor of power electronics


% Battery System

% Note: We built an arbitrary battery system since we want to use the same
% cell for all vehicles to achieve better comparabilty. Therefore the cell
% parameters and interconnection specified here DO NOT represent the state
% in the real vehicles!

Parameter.p_Zelle = 73;                                             % Number of cells connected in parallel inside the battery system
Parameter.s_Zelle = 96;                                             % Number of cells connected in serial inside the batter system
Parameter.SOC_init = 0.99;                                          % Initial state-of-charge of the battery system
Parameter.m_Zelle = 0.048;                                          % Mass of individual cell in kg

Parameter.n_Zelle = Parameter.p_Zelle*Parameter.s_Zelle;            % Total number of cells in the battery system

load('BatData_NCR18650PF');                                         % Load cell parameters. Assumption: Cell used is a Panasonic NCR-18659OF


% Charger

load('charger_parameters.mat');                                     % parameters of charger
Parameter.m_Ladegeraet = 8;                                         % mass of charger in kg

%% II. Parameters for component heat transfer capacities (UA)

% Note: We don't want so simulation the components in great detail since we
% assume the components as lumped-masses. Therefore we don't consider the
% exact inner geometrie of the components.

% We therefore consider the product of specific heat transfer coefficent
% and the heat transferring surface as one value 'UA' in W/K. This value
% can be found experimentally.


% UA electric machine

Parameter.UA_EMaschine_Umgebung_Table = ([0.03;228.19]*1.26);       % Heat transfer capacity of the electric machine to the ambient temperature subject to the vehicle speed in W/K
Parameter.UA_Getriebe_Umgebung_Table = ([1.6;305.7]*1.26);          % Heat transfer capacity of the transmission to the ambient temperature subject to the vehicle speed in W/K
Parameter.UA_EMaschine_Fluid_Table = ([7.5;15]*1.24);               % Heat transfer capacity of the electric machine to the coolant subject to the volume flow inside the coolant cycles in W/K


% UA power electronics

Parameter.UA_c_Umgebung_Table = ([11.5;12.8]*1.26);                 % Heat transfer capacity of the power electronics to the ambient temperature subject to the vehicle speed in W/K in W/K
Parameter.UA_c_Fluid_Table = ([4.25;8.5]*1.24);                     % Heat transfer capacity of the power electronics to the coolant subject to the volume flow inside the coolant cycles in W/K


% UA battery system

Parameter.UA_Batteriepack_Umgebung_Table = ([1;270]*3.5);           % Heat transfer capacity of the battery system to the ambient temperature subject to the vehicle speed in W/K
Parameter.UA_Batteriepack_Fluid_Table = ([15;30]*3.5*10);           % Heat transfer capacity of the electric machine to the coolant subject to the volume flow inside the coolant cycles in W/K

% UA charger

Parameter.UA_Ladegeraet_Umgebung_Table = [1;50];                    % Heat transfer capacity of the charger to the ambient temperature subject to the vehicle speed in W/K
Parameter.UA_Ladegeraet_Fluid_Table = [15;100];                     % Heat transfer capacity of the charger to the coolant subject to the volume flow inside the coolant cycles in W/K

end

