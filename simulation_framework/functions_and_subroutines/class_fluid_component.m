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
         % -> Nur f�r Fluid_Waermetauscher ben�tigt -> Diese Eigenschaft bei der Definition anderer Fluid_Komponenten nicht verwenden
         Art_Waermetauscher=0;                                              % Art des W�rmetauschers: 1 = Gleichstromw�rmetauscher, -1 = Gegenstromw�rmetauscher, 0 = Bei der jeweiligen Komponente, in dem sich das Fluid befindet, handelt es sich nicht um einen W�rmetauscher
         % -> F�r alle Fluid_Komponenten ben�tigt
         Nr_Kuehlkreislauf=0;                                               % Nummer des K�hlkreislaufs, zu dem das Fluid in der jeweiligen Komponente geh�rt
         l_Kuehlfluessigkeit=0;                                             % L�nge des K�hlfl�ssigkeitsstroms in der jeweiligen Komponente in m -> muss ein Vielfaches von l_FinitesVolumen sein
         A_Kuehlfluessigkeit=0;                                             % Querschnittsfl�che der K�hlfl�ssigkeit in der jeweiligen Komponente in m^2
         T_Kuehlfluessigkeit_init=0;                                        % Initialtemperatur der K�hlfl�ssigkeit in der jeweiligen Komponente in K
         T_FinitesVolumen_init=0;                                           % Initialtemperaturen der finiten Volumen des Fluids in der jeweiligen Komponente in K -> wird als Vektor ben�tigt
         R_FinitesVolumen=0;                                                % W�rmeleitwiderstand eines finiten Volumens des Fluids in der jeweiligen Komponente in K/W
         m_FinitesVolumen=0;                                                % Masse eines finiten Volumens des Fluids in der jeweiligen Komponente in kg
         C_FinitesVolumen=0;                                                % W�rmekapazit�t eines finiten Volumens des Fluids in der jeweiligen Komponente in J/K
         b_FinitesVolumen=0;                                                % Gr��e b f�r ein finites Volumen des Fluids in der jeweiligen Komponente in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Sch�tz "Thermische Modellierung und Optimierung elektrischer Antriebsstr�nge"
         end
end