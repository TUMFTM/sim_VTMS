%% Info

% Create 'fluid_component' class.

% This class is used to describe all components that interact with the
% fluid cycles.

% Possible fluid_components:

%     | NAME                         | DESCRIPTION        
%
%     Fluid_Kuehler                   Cooler/external Radiator
%     Fluid_Waermetauscher            Heat exchanger
%     Fluid_EMaschine                 Electric machine
%     Fluid_Leistungselektronik       Power electronics
%     Fluid_Batteriepack              Battery system
%     Fluid_Schlauch                  Coolant piping


%% classdef

classdef class_fluid_component
         properties
         % -> Nur für Fluid_Waermetauscher benötigt -> Diese Eigenschaft bei der Definition anderer Fluid_Komponenten nicht verwenden
         Art_Waermetauscher=0;                                              % Art des Wärmetauschers: 1 = Gleichstromwärmetauscher, -1 = Gegenstromwärmetauscher, 0 = Bei der jeweiligen Komponente, in dem sich das Fluid befindet, handelt es sich nicht um einen Wärmetauscher
         % -> Für alle Fluid_Komponenten benötigt
         Nr_Kuehlkreislauf=0;                                               % Nummer des Kühlkreislaufs, zu dem das Fluid in der jeweiligen Komponente gehört
         l_Kuehlfluessigkeit=0;                                             % Länge des Kühlflüssigkeitsstroms in der jeweiligen Komponente in m -> muss ein Vielfaches von l_FinitesVolumen sein
         A_Kuehlfluessigkeit=0;                                             % Querschnittsfläche der Kühlflüssigkeit in der jeweiligen Komponente in m^2
         T_Kuehlfluessigkeit_init=0;                                        % Initialtemperatur der Kühlflüssigkeit in der jeweiligen Komponente in K
         T_FinitesVolumen_init=0;                                           % Initialtemperaturen der finiten Volumen des Fluids in der jeweiligen Komponente in K -> wird als Vektor benötigt
         R_FinitesVolumen=0;                                                % Wärmeleitwiderstand eines finiten Volumens des Fluids in der jeweiligen Komponente in K/W
         m_FinitesVolumen=0;                                                % Masse eines finiten Volumens des Fluids in der jeweiligen Komponente in kg
         C_FinitesVolumen=0;                                                % Wärmekapazität eines finiten Volumens des Fluids in der jeweiligen Komponente in J/K
         b_FinitesVolumen=0;                                                % Größe b für ein finites Volumen des Fluids in der jeweiligen Komponente in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
         end
end