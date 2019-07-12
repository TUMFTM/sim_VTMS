function [Charge] = calc_charger_control(cycle, state)

%% Info

% Create 'Charge' Structure


%% Assignments

Charge = timeseries;
Charge.Time = cycle.Time;
Charge.Data(1:length(Charge.Time),1)=state;


end

