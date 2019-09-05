%% Info

% This framework simulates different VTMS architectures using different
% vehicles, driving cycles and ambient temperatures as input.

% For further information refer to https://github.com/TUMFTM/sim_VTMS


%% Initialising

% Close parallel pool
poolobj = gcp('nocreate');
delete(poolobj);

% Clear variables and close everything
clear
close all
clc

% Close all open Simulink systems
bdclose('all')  % Warning: All unsaved changes are discarded!

% Add folders to path
addpath 01_vehicles 02_driving_cycles 03_VTMS_architectures 04_simulation_results...
    05_evaluation functions_and_subroutines coolprop



%% Definitions

% Selection of vehicles, load cycles and VTMS architectures to simulate.
% Possible values: 1 = will be simulated, 0 = won't be simulated


% Select vehicles. We regard different vehicle classes. The specifications
% of the individual classes are based on different reference vehicles

%                        | VEHICLE CLASS                      | REFERENCE

veh_class_1 = 0;         % Subcompact:                          Renault Twizy
veh_class_2 = 1;         % Compact:                             BMW i3
veh_class_3 = 1;         % Lower middle classe:                 Volkswagen eGolf
veh_class_4 = 1;         % upper middle class/upper class:      Tesla Model 3


% Select load cycle. This implies a specfic vehicle speed trajectory and/or
% a charging current.

sim_load_cycle_1   = 1;
load_cycle_1_name  = 'WLTP';

sim_load_cycle_2   = 1;
load_cycle_2_name  = 'CADCMotorway';

sim_load_cycle_3   = 0;
load_cycle_3_name  = 'FastCharging';

sim_load_cycle_4   = 1;
load_cycle_4_name  = 'a_max';

sim_load_cycle_5   = 1;
load_cycle_5_name  = 'MotorwayFastCharge';


% Selection of BTMS architecture

sim_VTMS_type_1 = 1;
VTMS_type_1_name = 'VTMS1';

sim_VTMS_type_2 = 1;
VTMS_type_2_name = 'VTMS2';

sim_VTMS_type_3 = 1;
VTMS_type_3_name = 'VTMS3';

sim_VTMS_type_4 = 1;
VTMS_type_4_name = 'VTMS4';

sim_VTMS_type_5 = 1;
VTMS_type_5_name = 'VTMS5';

sim_VTMS_type_6 = 1;
VTMS_type_6_name = 'VTMS6';

sim_VTMS_type_7 = 1;
VTMS_type_7_name = 'VTMS7';


% Select one or more ambient temperatures (in K!) at which the simulation will be carried out.

T_ambient = 253.15 : 10 : 313.15;   % -20°C to 40°C in 10°C steps



%% Some more definitions

SoC_Bat_init = 0.4;             % Initial battery state-of-charge (Range: 0-1)

P_charge = 150;                 % Charging power in kW


% Load standard driving cycles

driving_cycles = load(fullfile(pwd, '\02_driving_cycles', 'drivingcycles')); 



%% Load general VTMS parameters

run('general_VTMS_parameters');



%% Create config arrays

% Put the selection in an array for better handling within the for loops.

vehicle_selection    = [veh_class_1, veh_class_2, veh_class_3, veh_class_4];

load_cycle_selection = [sim_load_cycle_1, sim_load_cycle_2, sim_load_cycle_3, sim_load_cycle_4, sim_load_cycle_5];
load_cycle_names     = {load_cycle_1_name, load_cycle_2_name, load_cycle_3_name, load_cycle_4_name, load_cycle_5_name};

VTMS_type_selection  = [sim_VTMS_type_1, sim_VTMS_type_2, sim_VTMS_type_3, sim_VTMS_type_4, sim_VTMS_type_5, sim_VTMS_type_6, sim_VTMS_type_7];
VTMS_type_names      = {VTMS_type_1_name, VTMS_type_2_name, VTMS_type_3_name, VTMS_type_4_name, VTMS_type_5_name, VTMS_type_6_name, VTMS_type_7_name};



%% Set up the simulations

% This section creates the input for all simulations that will be carried
% out according to the parameterization above.

date = datetime('now','Format','yyMMdd_HHmm');          % Save date and time of simulation start

sim_index = 0;                                          % Simulation index

Simulation = cell(1);                                   % Create empty structure

for ii = 1:length(T_ambient)                            % Iterate through the ambient temperatures
    
    T_ambient_loop = T_ambient(ii);                     % Get ambient temperature of current interation
    
    T_init = T_ambient_loop;                            % Initial component temperature = ambient temperature
    
    for jj = 1:length(vehicle_selection)                % Iterate through the vehicles. Load vehicle depending on iteration.
        if (jj==1)&&(vehicle_selection(jj))
            vehicle = Renault_Twizy();
        end
        if (jj==2)&&(vehicle_selection(jj))
            vehicle = BMW_i3();
        end
        if (jj==3)&&(vehicle_selection(jj))
            vehicle = VW_eGolf();
        end
        if (jj==4)&&(vehicle_selection(jj))
            vehicle = Tesla_Model3();
        end
        vehicle.SOC_init = SoC_Bat_init;                % Set inital state-of-charge depending on the selection
        
        if vehicle_selection(jj)              
            
            for kk = 1:length(load_cycle_selection)                  % Iterate through the different load cycles.
                if (kk == 1) && (load_cycle_selection(kk))
                    load_cycle = driving_cycles.WLTP_Class3;
                    charging_info = calc_charger_control(load_cycle,0);
                    load_cycle_name = load_cycle_names{kk};
                
                elseif (kk == 2) && (load_cycle_selection(kk))
                    load_cycle = driving_cycles.ArtMw130;
                    charging_info = calc_charger_control(load_cycle,0);
                    load_cycle_name = load_cycle_names{kk};
                
                elseif (kk == 3) && (load_cycle_selection(kk))
                    load(fullfile(pwd,'\02_driving_cycles','cycle_fast_charging.mat')); 
                    load_cycle = Schnellladen;
                    charging_info = calc_charger_control(load_cycle,1);
                    load_cycle_name = load_cycle_names{kk};
                
                elseif (kk == 4) && (load_cycle_selection(kk))
                    load(fullfile(pwd,'\02_driving_cycles','cycle_a_max.mat'));       
                    load_cycle = Zyklus_aMax{jj};
                    charging_info = calc_charger_control(load_cycle,0);
                    load_cycle_name = load_cycle_names{kk};
                
                elseif (kk == 5) && (load_cycle_selection(kk))
                    load(fullfile(pwd,'\02_driving_cycles','ArtMw130_charge_timeseries.mat')); 
                    load_cycle = ArtMw130_charge.v_Fahrzeug;
                    charging_info = ArtMw130_charge.laden;
                    load_cycle_name = load_cycle_names{kk};
                end
                
                if load_cycle_selection(kk)
                    
                    for ll = 1:length(VTMS_type_selection)           % Iterate through the different VTMS architectures
                        
                        if VTMS_type_selection(ll)
                        	sim_index = sim_index+1;                 % Iterate simulation counter
                            Fluid = Fluid_data{ll};                  % Get fluid data
                            VTMS_name = VTMS_type_names{ll};         % Get name of VTMS configuration
                            
                            % Create 'simulation' structure. This will be used as simulation input in the next step
                            Simulation = assign_Parameter(Simulation, sim_index, vehicle, load_cycle, charging_info, P_charge, load_cycle_name, Fluid, VTMS_name, T_ambient_loop, T_init);
                        end
                    end
                end
            end
        end
    end
end



%% Carry out the simulation

% Clear persistent variables (first-run indicator) in functions

clear fun_sim_VTMS_type_1 fun_sim_VTMS_type_2 fun_sim_VTMS_type_3 fun_sim_VTMS_type_4 fun_sim_VTMS_type_5 fun_sim_VTMS_type_6 fun_sim_VTMS_type_7                       

%parpool(4)                         % Option: Set up a parallel pool parallel simulation on all cores

Output = cell(1,sim_index);         % Create empty outout array

for ii = 1:sim_index                % Iterate through the configs. NOTE: Change this to parfor if you want to use parallel computing!
    
    if strcmp(Simulation{ii}.VTMS_name, VTMS_type_1_name)
        Output{ii}=fun_sim_VTMS_type_1(Simulation{ii}.vehicle, Simulation{ii}.load_cycle, Simulation{ii}.charging_info, Simulation{ii}.P_charge, Simulation{ii}.Fluid, Simulation{ii}.T_ambient, Simulation{ii}.T_init, Simulation{ii}.VTMS_name);
    
    elseif strcmp(Simulation{ii}.VTMS_name, VTMS_type_2_name)
        Output{ii}=fun_sim_VTMS_type_2(Simulation{ii}.vehicle, Simulation{ii}.load_cycle, Simulation{ii}.charging_info, Simulation{ii}.P_charge, Simulation{ii}.Fluid, Simulation{ii}.T_ambient, Simulation{ii}.T_init, Simulation{ii}.VTMS_name);
    
    elseif strcmp(Simulation{ii}.VTMS_name, VTMS_type_3_name)
        Output{ii}=fun_sim_VTMS_type_3(Simulation{ii}.vehicle, Simulation{ii}.load_cycle, Simulation{ii}.charging_info, Simulation{ii}.P_charge, Simulation{ii}.Fluid, Simulation{ii}.T_ambient, Simulation{ii}.T_init, Simulation{ii}.VTMS_name);
    
    elseif strcmp(Simulation{ii}.VTMS_name, VTMS_type_4_name)
        Output{ii}=fun_sim_VTMS_type_4(Simulation{ii}.vehicle, Simulation{ii}.load_cycle, Simulation{ii}.charging_info, Simulation{ii}.P_charge, Simulation{ii}.Fluid, Simulation{ii}.T_ambient, Simulation{ii}.T_init, Simulation{ii}.VTMS_name);
    
    elseif strcmp(Simulation{ii}.VTMS_name, VTMS_type_5_name)
        Output{ii}=fun_sim_VTMS_type_5(Simulation{ii}.vehicle, Simulation{ii}.load_cycle, Simulation{ii}.charging_info, Simulation{ii}.P_charge, Simulation{ii}.Fluid, Simulation{ii}.T_ambient, Simulation{ii}.T_init, Simulation{ii}.VTMS_name);
    
    elseif strcmp(Simulation{ii}.VTMS_name, VTMS_type_6_name)
        Output{ii}=fun_sim_VTMS_type_6(Simulation{ii}.vehicle, Simulation{ii}.load_cycle, Simulation{ii}.charging_info, Simulation{ii}.P_charge, Simulation{ii}.Fluid, Simulation{ii}.T_ambient, Simulation{ii}.T_init, Simulation{ii}.VTMS_name);

    elseif strcmp(Simulation{ii}.VTMS_name, VTMS_type_7_name)
        Output{ii}=fun_sim_VTMS_type_7(Simulation{ii}.vehicle, Simulation{ii}.load_cycle, Simulation{ii}.charging_info, Simulation{ii}.P_charge, Simulation{ii}.Fluid, Simulation{ii}.T_ambient, Simulation{ii}.T_init, Simulation{ii}.VTMS_name);
    end
    
    Temp = Simulation{ii}.T_ambient - 273.15;    % K --> °C
    filename = [char(date), '_', Simulation{ii}.vehicle_name, '_',Simulation{ii}.load_cycle_name, '_',Simulation{ii}.VTMS_name, '_', num2str(Temp), '_Celsius'];
    Output{ii}.Output.vehicle_name = Simulation{ii}.vehicle_name;
    Output{ii}.Output.load_cycle_name = Simulation{ii}.load_cycle_name;
    Output{ii}.Output.VTMS_name = Simulation{ii}.VTMS_name;
    Output{ii}.Output.T_ambient = Simulation{ii}.T_ambient;
     
    parsave(filename, Output{ii}, '\04_simulation_results');      % Save simulation results.

    fprintf('Simulation %i of %i completed.', ii, sim_index);
end

clearvars -except Simulation Output

fprintf('\nSimulation finished.\n');
