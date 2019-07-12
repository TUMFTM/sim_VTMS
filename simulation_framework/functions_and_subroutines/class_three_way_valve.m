%% Info

% Create 'three_way_valve' class


%% classdef

classdef class_three_way_valve
         properties
         Nr_Kuehlkreislauf=0;                                               % Nummer des Kühlkreislaufs, zu dem das jeweilige Dreiwegeventil gehört
         Ventil_nach=0;                                                     % Name von Fluid_Komponente innerhalb des entsprechenden Kühlkreislaufs, nach der sich das jeweilige Dreiwegeventil befindet bzw. nach der die Aufzweigung stattfindet
         Vereinigung_vor=0;                                                 % Name von Fluid_Komponente innerhalb des entsprechenden Kühlkreislaufs, vor der die Vereinigung der durch das jeweilige Dreiwegeventil aufgezweigten Pfade stattfindet
         Knoten_Hauptpfad={};                                               % Cell Array mit den Namen der Knoten, die sich im Hauptpfad des jeweiligen Dreiwegeventils befinden zwischen Ventil_nach und Vereinigung_vor
         Knoten_Nebenpfad={};                                               % Cell Array mit den Namen der Knoten, die sich im Nebenpfad des jeweiligen Dreiwegeventils befinden zwischen Ventil_nach und Vereinigung_vor
         % -> Für den Steuerungsfall benötigt, dass Dreiwegeventile gesteuert sind (Steuerung_Ventil = 1)
         Zustand_Ventil_Break_T_FinitesVolumen_Ventil_nach=0;               % Der Zustand des jeweiligen Dreiwegeventils ist abh. von der Temperatur des n. finiten Volumens des Fluids in der Fluid_Komponente, die bei Ventil_nach festgelegt ist
         Zustand_Ventil_Table=0;                                            % Der Zustand des jeweiligen Dreiwegeventils in Abh. von der Temperatur des n. finiten Volumens des Fluids in der Fluid_Komponente, die bei Ventil_nach festgelegt ist
         % -> Für den Steuerungsfall benötigt, dass Dreiwegeventile ungesteuert sind (Steuerung_Ventil = 0)
         Zustand_Ventil=0;                                                  % Zustand des jeweiligen Dreiwegeventil -> Spalte 1 = Zeit, Spalte 2 = Zustand des entsprechenden Dreiwegeventil
         end
end