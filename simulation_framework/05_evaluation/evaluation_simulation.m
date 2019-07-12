%% I. Initialisierung

close all
clear
clc

% Note: You can plot many more things, see fun_sim_VTMS_type_x to comment
% in those plots. Here, you find the most relevant stuff.

%% II. Select and load the relevant data

% Select all simulations you want to plot

load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
Evaluation{1} = Output;

% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{2} = Output;
% 
% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{3} = Output;
% 
% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{4} = Output;
% 
% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{5} = Output;
% 
% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{6} = Output;
% 
% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{7} = Output;
% 
% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{8} = Output;
% 
% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{9} = Output;
% 
% load (['190704_1742_VW_eGolf_FastCharging_VTMS7_20_Celsius','.mat'])
% Evaluation{10} = Output;


%% III. Select the components

% Select all components you are interested in

battery_system = 1;
Fluid_battery_system = 1;

electric_machine = 1;
Fluid_electric_machine = 1;

power_electronics = 1;
Fluid_power_electronics = 1;

charger = 1;
Fluid_charger = 1;

Fluid_radiator = 1;

PCM = 1;

%--------------------------------------------------------------------------
% Darstellung der Temperatur des battery_systems
%--------------------------------------------------------------------------

if battery_system
    figure
    for i=1:length(Evaluation)
        plot(Evaluation{i}.battery_system.Time,Evaluation{i}.battery_system.T-273.15);
        hold on;
    end
    
    leg = legend;
    leg.Location = 'northwest';
    for i=1:length(Evaluation)
        leg.String{i}=[Evaluation{i}.vehicle_name,' ',Evaluation{i}.load_cycle_name,' ', Evaluation{i}.VTMS_name,' ',num2str(Evaluation{i}.T_ambient-273.15),' °C'];
    end
    
    grid on;
    axis tight;
    title('Temperature of battery system');
    xlabel('Time in s');
    ylabel('Temperature in °C');
end

%--------------------------------------------------------------------------
% Plot temperature of electric machine
%--------------------------------------------------------------------------

if electric_machine
    figure
    for i=1:length(Evaluation)
        plot(Evaluation{i}.electric_machine.Time,Evaluation{i}.electric_machine.T_emachine-273.15);
        hold on;
    end
    
    leg = legend;
    leg.Location = 'northwest';
    for i=1:length(Evaluation)
        leg.String{i}=[Evaluation{i}.vehicle_name,' ',Evaluation{i}.load_cycle_name,' ', Evaluation{i}.VTMS_name,' ',num2str(Evaluation{i}.T_ambient-273.15),' °C'];
    end
    
    grid on;
    axis tight;
    title('Temperature of electric machine');
    xlabel('Time in s');
    ylabel('Temperature in °C');
end

%--------------------------------------------------------------------------
% Plot temperature of power electronics
%--------------------------------------------------------------------------

if power_electronics
    figure
    for i=1:length(Evaluation)
        plot(Evaluation{i}.power_electronics.Time,Evaluation{i}.power_electronics.T_j_K-273.15);
        hold on;
    end
    
    leg = legend;
    leg.Location = 'northwest';
    for i=1:length(Evaluation)
        leg.String{i}=[Evaluation{i}.vehicle_name,' ',Evaluation{i}.load_cycle_name,' ', Evaluation{i}.VTMS_name,' ',num2str(Evaluation{i}.T_ambient-273.15),' °C'];
    end

    grid on;
    axis tight;
    title('Temperature of MOSFET substrate of power electronics');
    xlabel('Time in s');
    ylabel('Temperature in °C');
    
    figure
    for i=1:length(Evaluation)
        plot(Evaluation{i}.power_electronics.Time,Evaluation{i}.power_electronics.T_c_K-273.15);
        hold on;
    end
    
    leg = legend;
    leg.Location = 'northwest';
    for i=1:length(Evaluation)
        leg.String{i}=[Evaluation{i}.vehicle_name,' ',Evaluation{i}.load_cycle_name,' ', Evaluation{i}.VTMS_name,' ',num2str(Evaluation{i}.T_ambient-273.15),' °C'];
    end

    grid on;
    axis tight;
    title('Temperature of MOSFET case of power electronics');
    xlabel('Time in s');
    ylabel('Temperature in °C');
end

%--------------------------------------------------------------------------
% Plot temperature of charger
%--------------------------------------------------------------------------

if charger
    figure
    for i=1:length(Evaluation)
        plot(Evaluation{i}.charger.Time,Evaluation{i}.charger.T-273.15);
        hold on;
    end
    
    leg = legend;
    leg.Location = 'northwest';
    for i=1:length(Evaluation)
        leg.String{i}=[Evaluation{i}.vehicle_name,' ',Evaluation{i}.load_cycle_name,' ', Evaluation{i}.VTMS_name,' ',num2str(Evaluation{i}.T_ambient-273.15),' °C'];
    end
      
    grid on;
    axis tight;
    title('Temperature of charger');
    xlabel('Time in s');
    ylabel('Temperature in °C');
end

%--------------------------------------------------------------------------
% Plot temperature of PCM
%--------------------------------------------------------------------------

if PCM
    figure
    for i=1:length(Evaluation)
        if isfield(Evaluation{i},'PCM_1')==1
            plot(Evaluation{i}.PCM_1.Time,Evaluation{i}.PCM_1.T-273.15);
        end
        hold on;
    end
    
    leg = legend;
    leg.Location = 'northwest';
    leg.String = {};
    j=1;
    for i=1:length(Evaluation)
        if isfield(Evaluation{i},'PCM_1')==1
            leg.String{j}=[Evaluation{i}.vehicle_name,' ',Evaluation{i}.load_cycle_name,' ', Evaluation{i}.VTMS_name,' ',num2str(Evaluation{i}.T_ambient-273.15),' °C'];
            j=j+1;
        end
    end
    
    grid on;
    axis tight;
    title(['Temperature of PCM']);
    xlabel('Time in s');
    ylabel('Temperature in °C');
end


%--------------------------------------------------------------------------
% Plot temperature of coolant in the battery system
%--------------------------------------------------------------------------
if Fluid_battery_system
    figure
    for i=1:length(Evaluation)
        if isfield(Evaluation{i},'Fluid_battery_system')==1
            plot(Evaluation{i}.Fluid_battery_system.Time,Evaluation{i}.Fluid_battery_system.T_middle-273.15);
        end
        hold on;
    end
    
    leg = legend;
    leg.Location = 'northwest';
    leg.String = {};
    j=1;
    for i=1:length(Evaluation)
        if isfield(Evaluation{i},'Fluid_battery_system')==1
            leg.String{j}=[Evaluation{i}.vehicle_name,' ',Evaluation{i}.load_cycle_name,' ', Evaluation{i}.VTMS_name,' ',num2str(Evaluation{i}.T_ambient-273.15),' °C'];
            j=j+1;
        end
    end
    
    grid on;
    axis tight;
    title(['Temperatur der Kühlflüssigkeit im Strömungsgebiet des battery_systems']);
    xlabel('Time in s');
    ylabel('Temperature in °C');
end

% if exist('Fluid_electric_machine_Output')==1
%    for i=1:(size(fieldnames(Fluid_electric_machine_Output),1)/2)
%        figure
%        plot(Fluid_electric_machine_Output.(['T_FinitesVolumen_electric_machine_',num2str(i),'___K_']).Time,Fluid_electric_machine_Output.(['T_FinitesVolumen_electric_machine_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_electric_machine_Output.(['T_FinitesVolumen_electric_machine_',num2str(i),'___K_']).Time,Fluid_electric_machine_Output.(['T_FinitesVolumen_electric_machine_',num2str(i),'___K_']).Data(:,Fluid_electric_machine(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_electric_machine_Output.(['T_FinitesVolumen_electric_machine_',num2str(i),'___K_']).Time,Fluid_electric_machine_Output.(['T_FinitesVolumen_electric_machine_',num2str(i),'___K_']).Data(:,Fluid_electric_machine(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kühlflüssigkeit im Strömungsgebiet der ',num2str(i),'. E-Maschine']);
%        xlabel('Time in s');
%        ylabel('Temperature in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% 
% 
% if exist('Fluid_charger_Output')==1
%    for i=1:(size(fieldnames(Fluid_charger_Output),1)/2)
%        figure
%        plot(Fluid_charger_Output.(['T_FinitesVolumen_charger_',num2str(i),'___K_']).Time,Fluid_charger_Output.(['T_FinitesVolumen_charger_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_charger_Output.(['T_FinitesVolumen_charger_',num2str(i),'___K_']).Time,Fluid_charger_Output.(['T_FinitesVolumen_charger_',num2str(i),'___K_']).Data(:,Fluid_charger(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_charger_Output.(['T_FinitesVolumen_charger_',num2str(i),'___K_']).Time,Fluid_charger_Output.(['T_FinitesVolumen_charger_',num2str(i),'___K_']).Data(:,Fluid_charger(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kuehlfluessigkeit im ',num2str(i),'. charger']);
%        xlabel('Time in s');
%        ylabel('Temperature in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% if exist('Fluid_PCM_Output')==1
%    for i=1:(size(fieldnames(Fluid_PCM_Output),1)/2)
%        figure
%        plot(Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Time,Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Time,Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Data(:,Fluid_PCM(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Time,Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Data(:,Fluid_PCM(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kuehlfluessigkeit im ',num2str(i),'. PCM']);
%        xlabel('Time in s');
%        ylabel('Temperature in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% if exist('Fluid_Peltier_Output')==1
%    for i=1:(size(fieldnames(Fluid_Peltier_Output),1)/2)
%        figure
%        plot(Fluid_Peltier_Output.(['T_FinitesVolumen_Peltier_',num2str(i),'___K_']).Time,Fluid_Peltier_Output.(['T_FinitesVolumen_Peltier_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_Peltier_Output.(['T_FinitesVolumen_Peltier_',num2str(i),'___K_']).Time,Fluid_Peltier_Output.(['T_FinitesVolumen_Peltier_',num2str(i),'___K_']).Data(:,Fluid_Peltier(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_Peltier_Output.(['T_FinitesVolumen_Peltier_',num2str(i),'___K_']).Time,Fluid_Peltier_Output.(['T_FinitesVolumen_Peltier_',num2str(i),'___K_']).Data(:,Fluid_Peltier(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kuehlfluessigkeit im ',num2str(i),'. Peltier']);
%        xlabel('Time in s');
%        ylabel('Temperature in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% 
% 
% %--------------------------------------------------------------------------
% % Plot vehicle speed
% %--------------------------------------------------------------------------
% 
% figure
% plot([v_Fahrzeug.Time;t_Simulation],[v_Fahrzeug.Data(:);0]);
% grid on;
% axis tight;
% title('Fahrzeuggeschwindigkeit');
% xlabel('Time in s');
% ylabel('Geschwindigkeit in km/h');
% 
% 
% %--------------------------------------------------------------------------
% % Plot power at wheel, transmission, electric machine and power electronics
% %--------------------------------------------------------------------------
% 
% if exist('Rad_Output')==1
%    figure
%    plot(Rad_Output.P_Rad__W_.Time,Rad_Output.P_Rad__W_.Data(:)/1000);
%    grid on;
%    axis tight;
%    title('Leistungsanforderung an die Räder');
%    xlabel('Time in s');
%    ylabel('Leistung in kW');
% end
% 
% if exist('Getriebe_Output')==1
%    figure
%    plot(Getriebe_Output.P_electric_machine__W_.Time,Getriebe_Output.P_electric_machine__W_.Data(:)/1000);
%    grid on;
%    axis tight;
%    title('Leistungsanforderung an die 1. E-Maschine');
%    xlabel('Time in s');
%    ylabel('Leistung in kW');
% end
% 
% if exist('electric_machine_Output')==1
%    figure
%    plot(electric_machine_Output.P_power_electronics__W_.Time,electric_machine_Output.P_power_electronics__W_.Data(:)/1000);
%    grid on;
%    axis tight;
%    title('Leistungsanforderung an die 1. power_electronics');
%    xlabel('Time in s');
%    ylabel('Leistung in kW');
% end
% 
% if exist('power_electronics_Output')==1
%    figure
%    plot(power_electronics_Output.P_battery_system_Fahrbetrieb__W_.Time,(power_electronics_Output.P_battery_system_Fahrbetrieb__W_.Data(:)+P_Nebenverbraucher)/1000);
%    grid on;
%    axis tight;
%    title('Leistungsanforderung an das 1. battery_system');
%    xlabel('Time in s');
%    ylabel('Leistung in kW');
% end
% 
% %--------------------------------------------------------------------------
% % Plot RPM and torque of electric machine
% %--------------------------------------------------------------------------
% 
% if exist('Getriebe_Output')==1
%    figure
%    plot(Getriebe_Output.n_electric_machine__min__1_.Time,Getriebe_Output.n_electric_machine__min__1_.Data(:));
%    grid on;
%    axis tight;
%    title('Drehzahl der 1. E-Maschine');
%    xlabel('Time in s');
%    ylabel('Drehzahl in 1/min');
% 
%    figure
%    plot(Getriebe_Output.M_electric_machine__Nm_.Time,Getriebe_Output.M_electric_machine__Nm_.Data(:));
%    grid on;
%    axis tight;
%    title('Drehmoment der 1. E-Maschine');
%    xlabel('Time in s');
%    ylabel('Moment in Nm');
% end
% 
% %--------------------------------------------------------------------------
% % Plot dynamic voltage, current and state-of-charge of battery system
% %-------------------------------------------------------------------------
% 
% if exist('battery_system_Output')==1
%    figure
%    plot(battery_system_Output.U_battery_system__V_.Time,battery_system_Output.U_battery_system__V_.Data(:));
%    grid on;
%    axis tight;
%    title('Klemmenspannung des 1. battery_systems');
%    xlabel('Time in s');
%    ylabel('Spannung in V');
% 
%    figure
%    plot(battery_system_Output.I_battery_system__A_.Time,battery_system_Output.I_battery_system__A_.Data(:));
%    grid on;
%    axis tight;
%    title('Strombelastung des 1. battery_systems');
%    xlabel('Time in s');
%    ylabel('Strom in A');
% 
%    figure
%    plot(battery_system_Output.SOC_battery_system____.Time,battery_system_Output.SOC_battery_system____.Data(:)*100);
%    grid on;
%    axis tight;
%    title('SOC des 1. battery_systems');
%    xlabel('Time in s');
%    ylabel('SOC in %');
% end
