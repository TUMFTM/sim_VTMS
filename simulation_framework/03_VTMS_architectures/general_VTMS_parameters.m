%% Info

% Set up all parameters for the different VTMS components in this script.

% Notes: 

% - Vehicle specific parameters are set up in the functions representing the vehicles in '01_vehicles'
% - Individual VTMS parameters are set up in the simulation functions itself in '03_VTMS architectures'

% Why the separation: This offers the possiblity to reuse parameters for different VTMS architectures.


%% III. Parameter für Kühlkreislauf 1

Fluid_data = cell(1,7);

if sim_VTMS_type_1
    Fluid_data{1}.PV_Kuehlkreislauf_Break_T = [273.15+10;273.15+35];                    % Control of volume flow, Breakpoints: Temperatures in K
    Fluid_data{1}.PV_Kuehlkreislauf_Table = [500/(3.6e6);2000/(3.6e6)];                 % Control of volume flow, Table data: Volume flow in m^3/s. Linear interpolation between the breakpoints, clipping of last value outside of breakpoints.
    
    Fluid_data{1}.Ladegeraet.l_Kuehlfluessigkeit = 0.3;                                 % Length of coolant flow inside the charger in m -> must be a mulitplicative of l_FinitesVolumen
    Fluid_data{1}.Ladegeraet.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                      % Cross section of coolant flow inside the charger in m^2
    
    Fluid_data{1}.Leistungselektronik.l_Kuehlfluessigkeit = 0.32;                       % Length of coolant flow inside the power electronics in m -> must be a mulitplicative of l_FinitesVolumen
    Fluid_data{1}.Leistungselektronik.A_Kuehlfluessigkeit = 0.01*0.2;                   % Cross section of coolant flow inside the power electronics in m^2
    
    Fluid_data{1}.EMaschine.l_Kuehlfluessigkeit = 1;                                    % Length of coolant flow inside the electric machine in m -> must be a mulitplicative of l_FinitesVolumen
    Fluid_data{1}.EMaschine.A_Kuehlfluessigkeit = 0.01*0.3;                             % Cross section of coolant flow inside the electric machine in m^2
    
    Fluid_data{1}.Kuehler.l_Kuehlfluessigkeit = 0.7;                                    % Length of coolant flow inside the radiator in m -> must be a mulitplicative of l_FinitesVolumen
    Fluid_data{1}.Kuehler.A_Kuehlfluessigkeit = 0.0015*0.014*108;                       % Cross section of coolant flow inside the radiator in m^2
    Fluid_data{1}.Kuehler.UA_Kuehler_Fluid_Table_1 = [10,40;20,80];                     % (:,:,1) Heat transfer capacity of the radiator depended on volume flow of coolant, and air speed through the cooler by means of the radiator fan and the vehicle speed in W/K
    Fluid_data{1}.Kuehler.UA_Kuehler_Fluid_Table_2 = [10,40;20,80];                     % (:,:,2) Heat transfer capacity of the radiator depended on volume flow of coolant, and air speed through the cooler by means of the radiator fan and the vehicle speed in W/K
    
    Fluid_data{1}.Schlauch.l_Kuehlfluessigkeit = 0.3;                                   % Length of coolant flow inside the of one pipe between two components in m -> must be a mulitplicative of l_FinitesVolumen
    Fluid_data{1}.Schlauch.A_Kuehlfluessigkeit = 0.019^2/4*pi;                          % Cross section of coolant flow inside the piping in m^2
end
%% III. Parameter für Kühlkreislauf 2
if sim_VTMS_type_2
    Fluid_data{2}.PV_Kuehlkreislauf_Break_T = [273.15+10;273.15+35];                    % Control of volume flow, Breakpoints: Temperatures in K
    Fluid_data{2}.PV_Kuehlkreislauf_Table = [500/(3.6e6);2000/(3.6e6)];                 % Control of volume flow, Table data: Volume flow in m^3/s. Linear interpolation between the breakpoints, clipping of last value outside of breakpoints.
   
    Fluid_data{2}.Batteriepack.l_Kuehlfluessigkeit = 3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Batteriepacks in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{2}.Batteriepack.A_Kuehlfluessigkeit = 0.01*0.1;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in m^2
    
    Fluid_data{2}.Ladegeraet.l_Kuehlfluessigkeit = 0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Ladegeräts in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{2}.Ladegeraet.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                      % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Ladegeräts in m^2
    
    Fluid_data{2}.Leistungselektronik.l_Kuehlfluessigkeit = 0.32;                       % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der Leistungselektronik in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{2}.Leistungselektronik.A_Kuehlfluessigkeit = 0.01*0.2;                   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in m^2
    
    Fluid_data{2}.EMaschine.l_Kuehlfluessigkeit = 1;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der E-Maschine in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{2}.EMaschine.A_Kuehlfluessigkeit = 0.01*0.3;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der E-Maschine in m^2
    
    Fluid_data{2}.Kuehler.l_Kuehlfluessigkeit = 0.7;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{2}.Kuehler.A_Kuehlfluessigkeit = 0.0015*0.014*108;                       % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{2}.Kuehler.UA_Kuehler_Fluid_Table_1 = [10,40;20,80];                     % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{2}.Kuehler.UA_Kuehler_Fluid_Table_2 = [10,40;20,80];                     % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    
    Fluid_data{2}.Schlauch.l_Kuehlfluessigkeit = 0.3;                                   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{2}.Schlauch.A_Kuehlfluessigkeit = 0.019^2/4*pi;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2  
end
%% III. Parameter für Kühlkreislauf 3
if sim_VTMS_type_3
    Fluid_data{3}.PV_Kuehlkreislauf_Break_T = [273.15+10;273.15+35];                    % Control of volume flow, Breakpoints: Temperatures in K
    Fluid_data{3}.PV_Kuehlkreislauf_Table = [500/(3.6e6);2000/(3.6e6)];                 % Control of volume flow, Table data: Volume flow in m^3/s. Linear interpolation between the breakpoints, clipping of last value outside of breakpoints.
    
    Fluid_data{3}.Ladegeraet.l_Kuehlfluessigkeit = 0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Ladegeräts in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{3}.Ladegeraet.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                      % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Ladegeräts in m^2
    
    Fluid_data{3}.Leistungselektronik.l_Kuehlfluessigkeit = 0.32;                       % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der Leistungselektronik in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{3}.Leistungselektronik.A_Kuehlfluessigkeit = 0.01*0.2;                   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in m^2
    
    Fluid_data{3}.EMaschine.l_Kuehlfluessigkeit = 1;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der E-Maschine in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{3}.EMaschine.A_Kuehlfluessigkeit = 0.01*0.3;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der E-Maschine in m^2
    
    Fluid_data{3}.Kuehler_1.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{3}.Kuehler_1.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{3}.Kuehler_1.UA_Kuehler_Fluid_Table_1 = [10,40;20,80];                   % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{3}.Kuehler_1.UA_Kuehler_Fluid_Table_2 = [10,40;20,80];                   % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
        
    Fluid_data{3}.Batteriepack.l_Kuehlfluessigkeit = 3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Batteriepacks in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{3}.Batteriepack.A_Kuehlfluessigkeit = 0.01*0.1;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in m^2
    
    Fluid_data{3}.Kuehler_2.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{3}.Kuehler_2.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{3}.Kuehler_2.UA_Kuehler_Fluid_Table_1 = [10,40;20,80]*10;                % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{3}.Kuehler_2.UA_Kuehler_Fluid_Table_2 = [10,40;20,80]*10;                % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
        
    Fluid_data{3}.Schlauch.l_Kuehlfluessigkeit = 0.3;                                   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{3}.Schlauch.A_Kuehlfluessigkeit = 0.019^2/4*pi;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
end
%% III. Parameter für Kühlkreislauf 4
if sim_VTMS_type_4
    Fluid_data{4}.PV_Kuehlkreislauf_Break_T = [273.15+10;273.15+35];                    % Control of volume flow, Breakpoints: Temperatures in K
    Fluid_data{4}.PV_Kuehlkreislauf_Table = [500/(3.6e6);2000/(3.6e6)];                 % Control of volume flow, Table data: Volume flow in m^3/s. Linear interpolation between the breakpoints, clipping of last value outside of breakpoints.
    
    Fluid_data{4}.Ladegeraet.l_Kuehlfluessigkeit = 0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Ladegeräts in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{4}.Ladegeraet.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                      % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Ladegeräts in m^2
    
    Fluid_data{4}.Leistungselektronik.l_Kuehlfluessigkeit = 0.32;                       % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der Leistungselektronik in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{4}.Leistungselektronik.A_Kuehlfluessigkeit = 0.01*0.2;                   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in m^2
    
    Fluid_data{4}.EMaschine.l_Kuehlfluessigkeit = 1;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der E-Maschine in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{4}.EMaschine.A_Kuehlfluessigkeit = 0.01*0.3;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der E-Maschine in m^2
    
    Fluid_data{4}.Kuehler_1.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{4}.Kuehler_1.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{4}.Kuehler_1.UA_Kuehler_Fluid_Table_1 = [10,40;20,80];                   % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{4}.Kuehler_1.UA_Kuehler_Fluid_Table_2 = [10,40;20,80];                   % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
        
    Fluid_data{4}.Batteriepack.l_Kuehlfluessigkeit = 3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Batteriepacks in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{4}.Batteriepack.A_Kuehlfluessigkeit = 0.01*0.1;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in m^2
    
    Fluid_data{4}.Kuehler_2.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{4}.Kuehler_2.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{4}.Kuehler_2.UA_Kuehler_Fluid_Table_1 = [10,40;20,80]*10;                % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{4}.Kuehler_2.UA_Kuehler_Fluid_Table_2 = [10,40;20,80]*10;                % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    
    Fluid_data{4}.PCM.l_Kuehlfluessigkeit = 0.3;                                        % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des PCM in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{4}.PCM.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des PCM in m^2
    Fluid_data{4}.PCM.unterer_Grenzwert_Phasenwechsel = 273.15+30.1;                    % unterer Grenzwert des Phasenuebergangs
    Fluid_data{4}.PCM.oberer_Grenzwert_Phasenwechsel = 273.15+35;                       % oberer Grenzwert des Phasenuebergangs
    Fluid_data{4}.PCM.UA_PCM_Umgebung_Table = [1;50];                                   % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{4}.PCM.UA_PCM_Kuehlfluessigkeit_Table = [15;100]*10;                     % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des thermischen Speichers (PCM) in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K
    Fluid_data{4}.PCM.m_PCM = 5; %6.648;                                                % Masse des thermischen Speichers (PCM) in kg
    Fluid_data{4}.PCM.c_PCM = 2000;                                                     % Spezifische Waermekapazitaet thermischen Speichers (PCM) J/(kg*K) 
    
    Fluid_data{4}.Schlauch.l_Kuehlfluessigkeit = 0.3;                                   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{4}.Schlauch.A_Kuehlfluessigkeit = 0.019^2/4*pi;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
end
%% III. Parameter für Kühlkreislauf 5
if sim_VTMS_type_5
    Fluid_data{5}.PV_Kuehlkreislauf_Break_T = [273.15+10;273.15+35];                    % Control of volume flow, Breakpoints: Temperatures in K
    Fluid_data{5}.PV_Kuehlkreislauf_Table = [500/(3.6e6);2000/(3.6e6)];                 % Control of volume flow, Table data: Volume flow in m^3/s. Linear interpolation between the breakpoints, clipping of last value outside of breakpoints.
    
    Fluid_data{5}.Ladegeraet.l_Kuehlfluessigkeit = 0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Ladegeräts in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.Ladegeraet.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                      % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Ladegeräts in m^2
    
    Fluid_data{5}.Leistungselektronik.l_Kuehlfluessigkeit = 0.32;                       % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der Leistungselektronik in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.Leistungselektronik.A_Kuehlfluessigkeit = 0.01*0.2;                   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in m^2
    
    Fluid_data{5}.EMaschine.l_Kuehlfluessigkeit = 1;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der E-Maschine in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.EMaschine.A_Kuehlfluessigkeit = 0.01*0.3;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der E-Maschine in m^2
    
    Fluid_data{5}.Waermetauscher_1.l_Kuehlfluessigkeit = 0.5;                           % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Wärmetauschers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.Waermetauscher_1.A_Kuehlfluessigkeit = 0.01^2/4*pi*20;                % Querschnittsfläche der Kühlflüssigkeit im 1. Strömungsgebiet des Wärmetauschers in m^2
    Fluid_data{5}.Waermetauscher_2.A_Kuehlfluessigkeit = ((0.015^2/4*pi)-(0.01^2/4*pi))*20;     % Querschnittsfläche der Kühlflüssigkeit im 2. Strömungsgebiet des Wärmetauschers in m^2
    Fluid_data{5}.Waermetauscher.UA_Waermetauscher_Fluid_Table = [1.5,3;3,6]*10;        % Die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der gesamten Kühlflüssigkeit im 1. bzw. 2. Strömungsgebiet des Wärmetauschers in Abh. von den Volumenströmen der zwei Kühlflüssigkeiten in W/K
    
    Fluid_data{5}.Kuehler_1.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.Kuehler_1.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{5}.Kuehler_1.UA_Kuehler_Fluid_Table_1 = [10,40;20,80];                   % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{5}.Kuehler_1.UA_Kuehler_Fluid_Table_2 = [10,40;20,80];                   % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
        
    Fluid_data{5}.Batteriepack.l_Kuehlfluessigkeit = 3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Batteriepacks in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.Batteriepack.A_Kuehlfluessigkeit = 0.01*0.1;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in m^2
    
    Fluid_data{5}.Kuehler_2.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.Kuehler_2.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{5}.Kuehler_2.UA_Kuehler_Fluid_Table_1 = [10,40;20,80]*10;                % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{5}.Kuehler_2.UA_Kuehler_Fluid_Table_2 = [10,40;20,80]*10;                % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    
    Fluid_data{5}.PCM.l_Kuehlfluessigkeit = 0.3;                                        % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des PCM in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.PCM.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des PCM in m^2
    Fluid_data{5}.PCM.unterer_Grenzwert_Phasenwechsel = 273.15+25.1;                    % unterer Grenzwert des Phasenuebergangs
    Fluid_data{5}.PCM.oberer_Grenzwert_Phasenwechsel = 273.15+30;                       % oberer Grenzwert des Phasenuebergangs
    Fluid_data{5}.PCM.UA_PCM_Umgebung_Table = [1;50];                                   % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{5}.PCM.UA_PCM_Kuehlfluessigkeit_Table = [1350;9000];  %[15;100];         % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des thermischen Speichers (PCM) in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K
    Fluid_data{5}.PCM.m_PCM = 5; %6.648;                                                % Masse des thermischen Speichers (PCM) in kg
    Fluid_data{5}.PCM.c_PCM = 2000;                                                     % Spezifische Waermekapazitaet thermischen Speichers (PCM) J/(kg*K) 
   
    Fluid_data{5}.Schlauch.l_Kuehlfluessigkeit = 0.3;                                   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{5}.Schlauch.A_Kuehlfluessigkeit = 0.019^2/4*pi;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
end
%% III. Parameter für Kühlkreislauf 6
if sim_VTMS_type_6
    Fluid_data{6}.PV_Kuehlkreislauf_Break_T = [273.15+10;273.15+35];                    % Control of volume flow, Breakpoints: Temperatures in K
    Fluid_data{6}.PV_Kuehlkreislauf_Table = [500/(3.6e6);2000/(3.6e6)];                 % Control of volume flow, Table data: Volume flow in m^3/s. Linear interpolation between the breakpoints, clipping of last value outside of breakpoints.
    
    Fluid_data{6}.Ladegeraet.l_Kuehlfluessigkeit = 0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Ladegeräts in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.Ladegeraet.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                      % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Ladegeräts in m^2
    
    Fluid_data{6}.Leistungselektronik.l_Kuehlfluessigkeit = 0.32;                       % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der Leistungselektronik in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.Leistungselektronik.A_Kuehlfluessigkeit = 0.01*0.2;                   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in m^2
    
    Fluid_data{6}.EMaschine.l_Kuehlfluessigkeit = 1;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der E-Maschine in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.EMaschine.A_Kuehlfluessigkeit = 0.01*0.3;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der E-Maschine in m^2
    
    Fluid_data{6}.Waermetauscher_1.l_Kuehlfluessigkeit = 0.5;                           % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Wärmetauschers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.Waermetauscher_1.A_Kuehlfluessigkeit = 0.01^2/4*pi*20;                % Querschnittsfläche der Kühlflüssigkeit im 1. Strömungsgebiet des Wärmetauschers in m^2
    Fluid_data{6}.Waermetauscher_2.A_Kuehlfluessigkeit = ((0.015^2/4*pi)-(0.01^2/4*pi))*20;     % Querschnittsfläche der Kühlflüssigkeit im 2. Strömungsgebiet des Wärmetauschers in m^2
    Fluid_data{6}.Waermetauscher.UA_Waermetauscher_Fluid_Table = [1.5,3;3,6]*10;        % Die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der gesamten Kühlflüssigkeit im 1. bzw. 2. Strömungsgebiet des Wärmetauschers in Abh. von den Volumenströmen der zwei Kühlflüssigkeiten in W/K
    
    Fluid_data{6}.Kuehler_1.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.Kuehler_1.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{6}.Kuehler_1.UA_Kuehler_Fluid_Table_1 = [10,40;20,80];                   % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{6}.Kuehler_1.UA_Kuehler_Fluid_Table_2 = [10,40;20,80];                   % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
        
    Fluid_data{6}.Batteriepack.l_Kuehlfluessigkeit = 3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Batteriepacks in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.Batteriepack.A_Kuehlfluessigkeit = 0.01*0.1;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in m^2
    
    Fluid_data{6}.Kuehler_2.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.Kuehler_2.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{6}.Kuehler_2.UA_Kuehler_Fluid_Table_1 = [10,40;20,80]*10;                % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{6}.Kuehler_2.UA_Kuehler_Fluid_Table_2 = [10,40;20,80]*10;                % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
   
    Fluid_data{6}.PCM.l_Kuehlfluessigkeit = 0.3;                                        % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des PCM in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.PCM.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des PCM in m^2
    Fluid_data{6}.PCM.unterer_Grenzwert_Phasenwechsel = 273.15+30.1;                    % unterer Grenzwert des Phasenuebergangs
    Fluid_data{6}.PCM.oberer_Grenzwert_Phasenwechsel = 273.15+35;                       % oberer Grenzwert des Phasenuebergangs
    Fluid_data{6}.PCM.UA_PCM_Umgebung_Table = [1;50];                                   % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{6}.PCM.UA_PCM_Kuehlfluessigkeit_Table = [15;100]*10;                     % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des thermischen Speichers (PCM) in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K
    Fluid_data{6}.PCM.m_PCM = 5; %6.648;                                                % Masse des thermischen Speichers (PCM) in kg
    Fluid_data{6}.PCM.c_PCM = 2000;                                                     % Spezifische Waermekapazitaet thermischen Speichers (PCM) J/(kg*K) 
   
    Fluid_data{6}.Schlauch.l_Kuehlfluessigkeit = 0.3;                                   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{6}.Schlauch.A_Kuehlfluessigkeit = 0.019^2/4*pi;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
end
%% III. Parameter für Kühlkreislauf 7
if sim_VTMS_type_7
    Fluid_data{7}.PV_Kuehlkreislauf_Break_T = [273.15+10;273.15+35];                    % Control of volume flow, Breakpoints: Temperatures in K
    Fluid_data{7}.PV_Kuehlkreislauf_Table = [500/(3.6e6);2000/(3.6e6)];                 % Control of volume flow, Table data: Volume flow in m^3/s. Linear interpolation between the breakpoints, clipping of last value outside of breakpoints.
    
    Fluid_data{7}.Ladegeraet.l_Kuehlfluessigkeit = 0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Ladegeräts in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.Ladegeraet.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                      % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Ladegeräts in m^2
    
    Fluid_data{7}.Leistungselektronik.l_Kuehlfluessigkeit = 0.32;                       % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der Leistungselektronik in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.Leistungselektronik.A_Kuehlfluessigkeit = 0.01*0.2;                   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in m^2
    
    Fluid_data{7}.EMaschine.l_Kuehlfluessigkeit = 1;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der E-Maschine in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.EMaschine.A_Kuehlfluessigkeit = 0.01*0.3;                             % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der E-Maschine in m^2
    
    Fluid_data{7}.Waermetauscher_11.l_Kuehlfluessigkeit = 0.5;                          % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Wärmetauschers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.Waermetauscher_11.A_Kuehlfluessigkeit = 0.01^2/4*pi*20;               % Querschnittsfläche der Kühlflüssigkeit im 1. Strömungsgebiet des Wärmetauschers in m^2
    Fluid_data{7}.Waermetauscher_12.A_Kuehlfluessigkeit = ((0.015^2/4*pi)-(0.01^2/4*pi))*20; % Querschnittsfläche der Kühlflüssigkeit im 2. Strömungsgebiet des Wärmetauschers in m^2
    Fluid_data{7}.Waermetauscher_1.UA_Waermetauscher_Fluid_Table = [1.5,3;3,6]*10;      % Die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der gesamten Kühlflüssigkeit im 1. bzw. 2. Strömungsgebiet des Wärmetauschers in Abh. von den Volumenströmen der zwei Kühlflüssigkeiten in W/K
    
    Fluid_data{7}.Waermetauscher_21.l_Kuehlfluessigkeit = 0.5;                          % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Wärmetauschers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.Waermetauscher_21.A_Kuehlfluessigkeit = 0.01^2/4*pi*20;               % Querschnittsfläche der Kühlflüssigkeit im 1. Strömungsgebiet des Wärmetauschers in m^2
    Fluid_data{7}.Waermetauscher_22.A_Kuehlfluessigkeit = ((0.015^2/4*pi)-(0.01^2/4*pi))*20;    % Querschnittsfläche der Kühlflüssigkeit im 2. Strömungsgebiet des Wärmetauschers in m^2
    Fluid_data{7}.Waermetauscher_2.UA_Waermetauscher_Fluid_Table = [1.5,3;3,6]*10;      % Die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der gesamten Kühlflüssigkeit im 1. bzw. 2. Strömungsgebiet des Wärmetauschers in Abh. von den Volumenströmen der zwei Kühlflüssigkeiten in W/K
    
    Fluid_data{7}.Kuehler_1.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.Kuehler_1.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{7}.Kuehler_1.UA_Kuehler_Fluid_Table_1 = [10,40;20,80];                   % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{7}.Kuehler_1.UA_Kuehler_Fluid_Table_2 = [10,40;20,80];                   % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
        
    Fluid_data{7}.Batteriepack.l_Kuehlfluessigkeit = 3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Batteriepacks in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.Batteriepack.A_Kuehlfluessigkeit = 0.01*0.1;                          % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in m^2
    
    Fluid_data{7}.Kuehler_2.l_Kuehlfluessigkeit = 0.7;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.Kuehler_2.A_Kuehlfluessigkeit = 0.0015*0.014*108;                     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
    Fluid_data{7}.Kuehler_2.UA_Kuehler_Fluid_Table_1 = [10,40;20,80]*10;                % (:,:,1) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{7}.Kuehler_2.UA_Kuehler_Fluid_Table_2 = [10,40;20,80]*10;                % (:,:,2) Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
   
    Fluid_data{7}.PCM.l_Kuehlfluessigkeit = 0.3;                                      % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des PCM in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.PCM.A_Kuehlfluessigkeit = 2*0.019^2/4*pi;                           % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des PCM in m^2
    Fluid_data{7}.PCM.unterer_Grenzwert_Phasenwechsel = 273.15+5.05;                  % unterer Grenzwert des Phasenuebergangs
    Fluid_data{7}.PCM.oberer_Grenzwert_Phasenwechsel = 273.15+30;                     % oberer Grenzwert des Phasenuebergangs
    Fluid_data{7}.PCM.UA_PCM_Umgebung_Table = [1;50];                                 % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K
    Fluid_data{7}.PCM.UA_PCM_Kuehlfluessigkeit_Table = [1350;9000];  %[15;100];       % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des thermischen Speichers (PCM) in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K
    Fluid_data{7}.PCM.m_PCM = 5; %6.648;                                              % Masse des thermischen Speichers (PCM) in kg
    Fluid_data{7}.PCM.c_PCM = 2000;                                                   % Spezifische Waermekapazitaet thermischen Speichers (PCM) J/(kg*K) 
   
    Fluid_data{7}.Schlauch.l_Kuehlfluessigkeit = 0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
    Fluid_data{7}.Schlauch.A_Kuehlfluessigkeit = 0.019^2/4*pi;                        % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
end