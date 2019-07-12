function [Simulation] = assign_Parameter(Simulation, h, vehicle, load_cycle, charging_info, P_charge, load_cycle_name, Fluid, VTMS_name, T_ambient, T_init)

%% Info

% This function assigns the individual Parameters to the 'Simulation'
% structure used as Input to the VTMS simulation.


%% Assignments

Simulation{h}.vehicle           = vehicle;
Simulation{h}.vehicle_name      = vehicle.name;
Simulation{h}.load_cycle        = load_cycle;
Simulation{h}.charging_info     = charging_info;
Simulation{h}.load_cycle_name   = load_cycle_name;
Simulation{h}.Fluid             = Fluid;
Simulation{h}.VTMS_name         = VTMS_name;
Simulation{h}.T_ambient         = T_ambient;
Simulation{h}.T_init            = T_init;
Simulation{h}.P_charge          = P_charge;

end

