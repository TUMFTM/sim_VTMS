function [OutputData] = fun_sim_VTMS_type_1(vehicle, load_cycle, charging_info, P_charge_in, Fluid, T_ambient_in, T_init_in, VTMS_name)


%% Info

% This function creates and simulates a given VTMS architecture. Refer to the README to see how you define other architectures or change the component parameters.
% 
% The function takes all parameters and creates a simulink model from it which is then used for simulation. This is a nontrivial process, so don't change anything
% from section "II. Fehler beim Setup des Thermomanagementsystemmodells" onwards. All 'fun_sim_VTMS_type_x' use the exact same underlying code and only differ from
% their component parameters and VTMS architecture definitions. 


%% Anmerkung:
% Dies ist eine erweiterte Version des Thermomanagementsystemmodells nach B. Bernhardt "Entwicklung und Auslegung eines innovativen Thermomanagementsystems für Elektrofahrzeuge".
% Dieses Simulationsmodell ist im Rahmen der Arbeit von B. BERNHARDT "Entwicklung und Auslegung eines innovativen Thermomanagementsystems für Elektrofahrzeuge" entstanden,
% es handelt sich dabei nicht um die eigentliche Arbeit. Bei diesem Modell handelt es sich um eine Beta-Version, die getestet wurde, aber weiterhin Fehler enthalten kann.
% Es wurden weitere Komponenten zugefügt und in den durch J. DIRNECKER entwickelten MATLAB-Code eingefügt. Mithilfe dieses Codes ist es möglich ein Kühlkreislaufmodell automatisch
% aufzubauen, zu simulieren und nach der Simulation automatisch in den Ausgangszustand zurückzusetzen.
% Das Simulationsmodell enthält zusätzlich die im  Rahmen der Arbeit von B. BERNHARDT modellierten Komponenten Ladegerät, Phasenwechselmaterial und thermoelektrische
% Wärmepumpe. Es kann ein  Ladegerät und eine thermoelektrische Wärmepumpe Teil des Kühlkreislaufs sein. Die Anzahl an unterschiedlichen Phasenwechselmaterialien ist
% unbegrenzt. Während der Arbeit ist außerdem ein erweitertes Modell des Batteriepacks entstanden, dass Batteriezellen und Batteriegehäuse als zwei unterschiedliche thermische
% Massen modelliert. Dieses Modell ist nicht in diesem Simulationsmodell enthalten.
% Die Komponenten wurden entsprechend des beiliegenden Leitfadens in das Simulationsmodell integriert. Nach dem Schema können auch weitere Komponenten modelliert und in das Simulationsmodell eingefügt werden.


%% I. Setup des Thermomanagementsystemmodells

%% Allgemeine Paramter

%--------------------------------------------------------------------------
% Parameter Modell
%--------------------------------------------------------------------------

Modell='mod_sim_VTMS';                % Specify name of VTMS simulation model
open_system(Modell,'loadonly');       % Load the VTMS simulation model

%--------------------------------------------------------------------------
% Parameter Subsystem "Input"
%--------------------------------------------------------------------------

T_Umgebung = T_ambient_in;
T_init = T_init_in;

P_charge = P_charge_in;
        
% -> Fahrzyklus: 
% -> ArtMw130: Artemis Motorway mit maximaler Fahrzeuggeschwindigkeit = 130 km/h
% -> ArtMw150: Artemis Motorway mit maximaler Fahrzeuggeschwindigkeit = 150 km/h
% -> ArtRoad: Artemis Rural Road
% -> ArtUrban: Artemis Urban
% -> ECE_R15: Urban Driving Cycle (UDC)
% -> EUDC: Extra Urban Driving Cycle
% -> FTP72: Federal Test Procedure 72
% -> FTP75: Federal Test Procedure 75
% -> HWFET: Highway Fuel Economy Test
% -> LA92: California Unified Cycle (UC/UCDS)
% -> LA92_short: Kürzere Version des LA92
% -> NEDC: Neuer europäischer Fahrzyklus (NEFZ)
% -> NYCC: New York City Cycle
% -> SC03: SFTP SC03
% -> US06: SFTP US06
% -> WLTP_Class2: Worldwide Harmonized Light Vehicles Test Procedure Klasse 2
% -> WLTP_Class2_Low: Worldwide Harmonized Light Vehicles Test Procedure Klasse 2 Teil 1
% -> WLTP_Class2_Middle: Worldwide Harmonized Light Vehicles Test Procedure Klasse 2 Teil 2
% -> WLTP_Class2_High: Worldwide Harmonized Light Vehicles Test Procedure Klasse 2 Teil 3
% -> WLTP_Class3: Worldwide Harmonized Light Vehicles Test Procedure Klasse 3

v_Fahrzeug = load_cycle; % Zyklus wird in Hauptskrip definiert, Geschwindigkeitsverlauf des Fahrzyklus in km/h -> Fahrzeuggeschwindigkeit in km/h
v_max = vehicle.v_max;                                                                  % Maximalgeschwindigkeit des Fahrzeugs in km/h
alpha_Strecke = [0,0;v_Fahrzeug.Time(end),0]; %Wird in Hauptscript definiert, Steigung der Strecke in %
Ladevorgang = charging_info;                                                              % Gibt an, ob das Fahrzeug geladen wird

% Die folgenden 3 Parameter nicht verändern!
switch_BP_Zyklus = 0;
v_start = 0;
v_end = 150;

%--------------------------------------------------------------------------
% Parameter Subsystem "Output"
%--------------------------------------------------------------------------

Datenfrequenz_Output_max=1;                                               % Maximale Datenfrequenz der Outputs in 1/s -> Maximale Anzahl an Datenpunkten der Simulationsergebnisse, die mittels "To Workspace"-Blöcken nach Ende der Simulation von Simulink an MATLAB übergeben werden, pro Sekunde
% -> Wegen der Strömungssimulation mittels der Finiten-Volumen-Methode haben die Simulationsergebnisse, die mittels "To Workspace"-Blöcken nach Ende der Simulation von Simulink an MATLAB übergeben werden, große Datenmengen (die Größe der Datenmengen ist abh. von den durch den Anwender festgelegten Parametern)
% -> Diese Simulationsergebnisse werden während der Simulation zuerst in Simulink zwischengespeichert, bevor sie nach Ende der Simulation an MATLAB übergeben werden
% -> Deswegen benötigt Simulink während der Simulation viel Arbeitsspeicher
% -> Es besteht zudem die Möglichkeit, dass die Simulation wegen eines "Out of Memory"-Fehlers abbricht
% -> Um den benötigten Arbeitsspeicher zu reduzieren bzw. um einen "Out of Memory"-Fehler zu verhindern, muss die maximale Anzahl an Datenpunkten der Simulationsergebnisse, die mittels "To Workspace"-Blöcken nach Ende der Simulation von Simulink an MATLAB übergeben werden, pro Sekunde reduziert werden
% -> Datenfrequenz_Output_max legt die maximale Anzahl an Datenpunkten der Simulationsergebnisse, die mittels "To Workspace"-Blöcken nach Ende der Simulation von Simulink an MATLAB übergeben werden, pro Sekunde global für jeden Output fest
% -> Es handelt sich nicht um einen genauen Wert sondern um einen Maximalwert, weil die tatsächliche Anzahl an Datenpunkten der Simulationsergebnisse, die mittels "To Workspace"-Blöcken nach Ende der Simulation von Simulink an MATLAB übergeben werden, pro Sekunde zudem vom Zeitschritt der Simulation abhängt
% -> Es ist zu beachten, dass sich Datenfrequenz_Output_max nur auf die Simulationsergebnisse, die mittels "To Workspace"-Blöcken nach Ende der Simulation von Simulink an MATLAB übergeben werden, bezieht
% -> Das Thermomanagementsystemmodell in Simulink wird unabh. von Datenfrequenz_Output_max zu jedem einzelnen Auswertungszeitpunkt ausgewertet

%--------------------------------------------------------------------------
% Parameter Zeit
%--------------------------------------------------------------------------

t_Simulation=v_Fahrzeug.Time(end)+200;                                      % Simulationszeit in s -> Die Simulationszeit wird abh. von der Dauer des Fahrzyklus bzw. von der Dauer des Geschwindigkeitsverlaufs des Fahrzyklus festgelegt

delta_t_max_Anwender=0.01;                                                  % Durch den Anwender vorgegebener maximaler Zeitschritt der Simulation in s -> Je kleiner der Zeitschritt der Simulation ist, desto besser ist die Ergebnisqualität der Simulation, desto höher ist jedoch der Simulationsaufwand
% -> Für eine numerisch stabile Simulation gibt es noch andere Bedingungen, die den maximalen Zeitschritt der Simulation festlegen
% -> Für jede dieser Bedingungen wird ein maximaler Zeitschritt der Simulation berechnet
% -> Der Zeitschritt der Simulation darf nicht größer sein als der minimale aller vorhandenen maximalen Zeitschritte der Simulation
% -> Aus Gründen des Simulationsaufwands ist ein möglichst großer Zeitschritt der Simualtion von Vorteil 
% -> Deswegen wird für den Zeitschritt der Simualtion zuerst der minimale aller vorhandenen maximalen Zeitschritte der Simulation ausgewählt
% -> Für den letztendlichen Zeitschritt der Simulation wird nur 99,9% des minimalen aller vorhandenen maximalen Zeitschritte der Simulation verwendet, sodass trotz Rundungsfehler bei der Berechnung der maximalen Zeitschritte der Simulation die numerische Stabilität der Simulation in jedem Fall sichergestellt ist 

%% Parameter Subsystem "Fluid"

%--------------------------------------------------------------------------
% Definition grundlegender Parameter
%--------------------------------------------------------------------------

n_Kuehlkreislauf=1;                                                         % Anzahl an Kühlkreisläufen
% -> Falls kein Kühlkreislauf simuliert werden soll, muss n_Kuehlkreislauf trotzdem definiert werden und = 0 festgelegt werden
% -> Alle anderen Parameter, die sich auf Kühlkreisläufe beziehen, können für ein erfolgreiches Durchlaufen der Simulation einfach auskommentiert werden

l_FinitesVolumen=0.005;                                                     % Länge eines finiten Volumens in m

% -> Ein Kühlkreislauf besitzt eine Pumpe, die für den Volumenstrom im Kühlkreislauf sorgt
% -> Eine Pumpe wird als 0D angenommen
% -> Je nachdem wie es der Anwender wünscht, können Pumpen gesteuert oder ungesteuert sein
% -> Dies wird über Steuerung_Pumpe global für alle Pumpen festgelegt
Steuerung_Pumpe=1;                                                          % Steuerung der Pumpen: 1 = Pumpen gesteuert, 0 = Pumpen ungesteuert
% -> Bei einer realen Steuerung existiert eine Totzeit
% -> Totzeit = Zeitspanne zwischen der Signaländerung am Systemeingang und der Signalantwort am Systemausgang
% -> Für das Thermomanagementsystemmodell wird für Steuerung_Pumpe = 1 die Totzeit über Totzeit_Steuerung_Pumpe global für die Steuerung aller Pumpen festgelegt
% -> Da das Thermomanagementsystemmodell zeitdiskret ausgewertet wird, kann es sein, dass die Totzeit der Steuerung der Pumpen nicht exakt eingehalten wird
% -> Dies tritt für den Fall ein, wenn die Totzeit der Steuerung der Pumpen kein Vielfaches vom Zeitschritt der Simulation ist
% -> Für diesen Fall stellt sich die Signalantwort am Systemausgang zum darauffolgenden Auswertungszeitpunkt ein
Totzeit_Steuerung_Pumpe=1;                                                  % Totzeit der Steuerung der Pumpen in s -> Nur benötigt für den Fall Steuerung_Pumpe = 1
% -> Im Thermomanagementsystemmodell wird eine Pumpe nicht modelliert
% -> Im Thermomanagementsystemmodell wird nur der Volumenstrom im Kühlkreislauf, für den eine Pumpe sorgt, benötigt
% -> Steuerung_Pumpe bezieht sich auf die Volumenströme in den Kühlkreisläufen
% -> Im Folgenden werden die Volumenströme in den Kühlkreisläufen festgelegt
% -> Diese müssen nur für den entsprechenden Steuerungsfall bzgl. Steuerung_Pumpe festgelegt werden
% -> Pumpen gesteuert (Steuerung_Pumpe = 1):
% -> Für jeden Kühlkreislauf muss 1 eigener Volumenstrom im Kühlkreislauf festgelegt werden
% -> Der Volumenstrom im Kühlkreislauf ist für 2 Kühlkreisläufe voreingestellt
% -> Falls n Kühlkreisläufe vorhanden sind, müssen n Volumenströme in den Kühlkreisläufen festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: PV_Kuehkreislauf...{i} mit i=1:n
% -> Falls in einem Kühlkreislauf keine Pumpe vorhanden ist, muss der Volumenstrom im Kühlkreislauf trotzdem definiert werden und das Table auf [0;0] festgelegt werden (die Breakpoints müssen trotzdem mit ansteigenden Werten festgelegt sein)
% -> Bei den Lookup Tables wird nicht extrapoliert, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet
% -> Deswegen wird über die Tables der minimal und maximal mögliche Volumenstrom in den Kühlkreisläufen festgelegt
% -> Achtung: Volumenstrom in einem Kühlkreislauf kann nicht < 0 sein bzw. muss >= 0 sein
PV_Kuehlkreislauf_Break_T_Komponente_max{1}=Fluid.PV_Kuehlkreislauf_Break_T;          % Der Volumenstrom im Kühlkreislauf ist abh. von der maximalen Temperatur der zu temperierenden Komponenten in dem entsprechenden Kühlkreislauf in K -> Die zu temperierenden Komponenten in einem Kühlkreislauf können die E-Maschine, die Leistungselektronik und das Batteriepack sein
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_T_Komponente_max
PV_Kuehlkreislauf_Table{1}=Fluid.PV_Kuehlkreislauf_Table;                % Der Volumenstrom im Kühlkreislauf in Abh. von der maximalen Temperatur der zu temperierenden Komponenten in dem entsprechenden Kühlkreislauf in m^3/s -> Die zu temperierenden Komponenten in einem Kühlkreislauf können die E-Maschine, die Leistungselektronik und das Batteriepack sein
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_T_Komponente_max
% -> Pumpen ungesteuert (Steuerung_Pumpe = 0):
% -> Für jeden Kühlkreislauf muss 1 eigener Volumenstrom im Kühlkreislauf festgelegt werden
% -> Der Volumenstrom im Kühlkreislauf ist für 2 Kühlkreisläufe voreingestellt
% -> Falls n Kühlkreisläufe vorhanden sind, müssen n Volumenströme in den Kühlkreisläufen festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: PV_Kuehkreislauf{i} mit i=1:n
% -> Spalte 1 = Zeit, Spalte 2 = Volumenstrom im Kühlkreislauf
% -> Falls in einem Kühlkreislauf keine Pumpe vorhanden ist, muss der Volumenstrom im Kühlkreislauf trotzdem definiert werden und durchgehend auf 0 festgelegt werden
% -> Achtung: Volumenstrom in einem Kühlkreislauf kann nicht < 0 sein bzw. muss >= 0 sein
% PV_Kuehlkreislauf{1}=[0,200/(3.6*10^6);1000,200/(3.6*10^6);1001,2000/(3.6*10^6);t_Simulation,2000/(3.6*10^6)]; % Volumenstrom im Kühlkreislauf in m^3/s -> Spalte 1 = Zeit, Spalte 2 = Volumenstrom im Kühlkreislauf
% PV_Kuehlkreislauf{2}=[0,200/(3.6*10^6);1000,200/(3.6*10^6);1001,2000/(3.6*10^6);t_Simulation,2000/(3.6*10^6)]; % Volumenstrom im Kühlkreislauf in m^3/s -> Spalte 1 = Zeit, Spalte 2 = Volumenstrom im Kühlkreislauf

%--------------------------------------------------------------------------
% Definition der Kühlflüssigkeiten für CoolProp-Datenbank
%--------------------------------------------------------------------------

% -> Die Bestimmung der Stoffwerte der Kühlflüssigkeiten erfolgt mittels der CoolProp-Datenbank
% -> Dafür müssen folgende Parameter der Kühlflüssigkeiten definiert werden: Name_Kuehlfluessigkeit, Anteil_Frostschutzmittel, T_Kuehlfluessigkeit_Referenz, p_Kuehlfluessigkeit_Referenz

% -> Jeder Index von Name_Kuehlfluessigkeit, Anteil_Frostschutzmittel, T_Kuehlfluessigkeit_Referenz und p_Kuehlfluessigkeit_Referenz repräsentiert einen Kühlkreislauf (Index = Nummer Kühlkreislauf)
% -> Es müssen n_Kuehlkreislauf Indizes existieren
% -> Es sind Name_Kuehlfluessigkeit, Anteil_Frostschutzmittel, T_Kuehlfluessigkeit_Referenz und p_Kuehlfluessigkeit_Referenz für 2 Kühlkreisläufe voreingestellt
% -> Falls n Kühkreisläufe vorhanden sind, müssen n Name_Kuehlfluessigkeit, n Anteil_Frostschutzmittel, n T_Kuehlfluessigkeit_Referenz und n p_Kuehlfluessigkeit_Referenz festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: Name_Kuehlfluessigkeit{i}, Anteil_Frostschutzmittel{i}, T_Kuehlfluessigkeit_Referenz{i} und p_Kuehlfluessigkeit_Referenz{i} mit i=1:n

% -> Name Kühlflüssigkeit:
% -> Wasser-Ethylenglykol-Gemisch: MEG (für normales Ethylenglykol), AEG (für ASHRAE, Ethylenglykol), AN (für Antifrogen N, Ethylenglykol), GKN (für Glykosol N, Ethylenglykol), ZM (für Zitrec M, Ethylenglykol), ZMC (für Zitrec MC, Ethylenglykol)
% -> Wasser-Propylenglykol-Gemisch: MPG (für normales Propylenglykol), APG (für ASHRAE, Propylenglykol), AL (für Antifrogen L, Propylenglykol), PKL (für Pekasol L, Propylenglykol), ZFC (für Zitrec FC, Propylenglykol), ZLC (für Zitrec LC, Propylenglykol)
Name_Kuehlfluessigkeit{1}='MEG';                                            % Name der Kühlflüssigkeit
%Name_Kuehlfluessigkeit{2}='MEG';                                            % Name der Kühlflüssigkeit

% -> Anteil Frostschutzmittel:
% -> MEG: Angabe des Massenanteils zwischen 0-60 %
% -> AEG: Angabe des Volumenanteils zwischen 10-60 %
% -> AN: Angabe des Volumenanteils zwischen 10-60 %
% -> GKN: Angabe des Volumenanteils zwischen 10-60 %
% -> ZM: Angabe des Volumenanteils zwischen 0-100 %
% -> ZMC: Angabe des Volumenanteils zwischen 30-70 %
% -> MPG: Angabe des Massenanteils zwischen 0-60 %
% -> APG: Angabe des Volumenanteils zwischen 10-60 %
% -> AL: Angabe des Volumenanteils zwischen 10-60 %
% -> PKL: Angabe des Volumenanteils zwischen 10-60 %
% -> ZFC: Angabe des Volumenanteils zwischen 30-60 %
% -> ZLC: Angabe des Volumenanteils zwischen 30-70 %
Anteil_Frostschutzmittel{1}='50';                                           % Anteil des verwendeten Etyhlenglykols bzw. Propylenglykols (siehe oben) im Wasser-Ethylenglykol-Gemisch bzw. im Wasser-Propylenglykol-Gemisch in %
%Anteil_Frostschutzmittel{2}='50';                                           % Anteil des verwendeten Etyhlenglykols bzw. Propylenglykols (siehe oben) im Wasser-Ethylenglykol-Gemisch bzw. im Wasser-Propylenglykol-Gemisch in %

T_Kuehlfluessigkeit_Referenz(1)=273.15+20;                                  % Referenztemperatur zur Bestimmung relevanter Stoffwerte der Kühlflüssigkeiten mittels der CoolProp-Datenbank in K
%T_Kuehlfluessigkeit_Referenz(2)=273.15+20;                                  % Referenztemperatur zur Bestimmung relevanter Stoffwerte der Kühlflüssigkeiten mittels der CoolProp-Datenbank in K

p_Kuehlfluessigkeit_Referenz(1)=10^5*1;                                     % Referenzdruck zur Bestimmung relevanter Stoffwerte der Kühlflüssigkeiten mittels der CoolProp-Datenbank in Pa
%p_Kuehlfluessigkeit_Referenz(2)=10^5*1;                                     % Referenzdruck zur Bestimmung relevanter Stoffwerte der Kühlflüssigkeiten mittels der CoolProp-Datenbank in Pa

%--------------------------------------------------------------------------
% Definition der Fluid_Komponenten (Fluid_Komponente = Fluid in Komponente)
%--------------------------------------------------------------------------

% -> Für jede einzelne Fluid_Komponente im Thermomanagementsystem muss ein eigenes Objekt mit Klassenzuordnung festgelegt werden
% -> Klasse: Fluid_Komponente
% -> Objektarten: Fluid_Kuehler, Fluid_Waermetauscher, Fluid_EMaschine, Fluid_Leistungselektronik, Fluid_Batteriepack, Fluid_Schlauch
% -> Deswegen können in einem Kühlkreislauf folgende Komponenten existieren: Kühler, Wärmetauscher, E-Maschine, Leistungselektronik, Batteriepack, Schlauch

% -> Definition nur für Fluid_Waermetauscher: Art_Waermetauscher
% -> Definitionen für alle Fluid_Komponenten: Nr_Kuehlkreislauf, l_Kuehlfluessigkeit, A_Kuehlfluessigkeit, T_Kuehlfluessigkeit_init

% -> Für jede mögliche Objektart ist mindestens 1 Objekt voreingestellt 
% -> 1 Komponente beinhaltet 1 Strömungsgebiet bzw. 1 Kühlflüssigkeit (außer Wärmetauscher -> siehe unten)
% -> Bei n gleichen Komponenten müssen n Objekte von der entsprechenden Objektart festgelegt sein (außer Wärmetauscher -> siehe unten) 
% -> Diese müssen aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: Fluid_Komponente(i) mit i=1:n
% -> Ausnahme Wärmetauscher:
% -> 1 Wärmetauscher beinhaltet 2 Strömungsgebiet bzw. 2 Kühlflüssigkeiten, zwischen denen Wärme ausgetauscht wird
% -> Deswegen existieren pro 1 Wärmetauscher 2 Objekte von Fluid_Waermetauscher, die über einen Zeilenindex nummeriert werden (pro 1 Wärmetauscher gibt es den Zeilenindex 1 und 2) 
% -> Bei n Wärmetauscher müssen 2*n Objekte von Fluid_Waermetauscher festgelegt sein
% -> Bei n Wärmetauscher müssen die Objekte von Fluid_Waermetauscher aufsteigend mit einem Spaltenindex nummeriert werden
% -> Nummerierung: Fluid_Waermetauscher(1,i) und Fluid_Waermetauscher(2,i) mit i=1:n

% -> 2 Kühlkreisläufe können mittels eines Wärmetauschers gekoppelt werden
% -> Falls eine voreingestellte Fluid_Komponente im Thermomanagementsystem nicht existiert, muss diese auskommentiert oder gelöscht werden

% -> IN DIESER VERSION DES THERMOMANAGEMENTSYSTEMMODELLS IST DIE ANZAHL BESTIMMTER KOMPONENTEN UND DESWEGEN BESTIMMTER FLUID_KOMPONENTEN IM THERMOMANAGEMENTSYSTEM LIMITIERT:
% -> Kühler: Beliebige Anzahl -> Fluid_Kuehler: Beliebige Anzahl
% -> Wärmetauscher: Beliebige Anzahl -> Fluid_Waermetauscher: Beliebige Anzahl
% -> E-Maschine: Genau 1 -> Fluid_EMaschine: Max. 1
% -> Leistungselektronik: Genau 1 -> Fluid_Leistungselektronik: Max. 1
% -> Batteriepack: Genau 1 -> Fluid_Batteriepack: Max. 1
% -> Ladeeraet: Genau 1 -> Fluid_Ladegeraet: Max. 1
% -> Thermischer Speicher (PCM): Beliebige Anzahl -> Fluid_PCM: Beliebige Anzahl
% -> Thermoelektrische Wärmepumpe (Peltier): Genau 1 -> Fluid_Peliter: Max.1
% -> Schlauch: Beliebige Anzahl -> Fluid_Schlauch: Beliebige Anzahl
% -> Grund dafür ist, dass im verwendeten Antriebsstrangmodell genau mit 1 E-Maschine, 1 Leistungselektronik, 1 Batteriepack, 1 Ladegeraet und 1 Thermoelektrischen Wärmepumpe gerechnet wird 
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 E-Maschine, max. 1 Leistungselektronik, max. 1 Batteriepack, max. 1 Ladegeraet und max. 1 Thermoelektrische Wärmepumpe vorhanden sein

% -> Ein Kühler besteht aus mehreren horinzontalen Kühlrohren
% -> Der Kühlflüssigkeitsstrom im Kühler wird derart modelliert, dass die Kühlflüssigkeit parallel in den Kühlrohren von der einen Seite zur anderen Seite des Kühlers fließt
Fluid_Kuehler(1)=class_fluid_component;                                          % Objektzuordnung zur Klasse
Fluid_Kuehler(1).Nr_Kuehlkreislauf=1;                                       % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Kühlers gehört
Fluid_Kuehler(1).l_Kuehlfluessigkeit=Fluid.Kuehler.l_Kuehlfluessigkeit;     % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Kühlers in m -> muss ein Vielfaches von l_FinitesVolumen sein
Fluid_Kuehler(1).A_Kuehlfluessigkeit=Fluid.Kuehler.A_Kuehlfluessigkeit;     % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Kühlers in m^2
Fluid_Kuehler(1).T_Kuehlfluessigkeit_init=T_init;                        % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Kühlers in K

% -> Es wird ein Doppelrohr-Wärmetauscher modelliert, weil die Bedingung für die Berechnung des Wärmeaustausches im Wärmetauscher ist, dass sich die beiden Kühlflüssigkeitsströme genau gegenüberstehen müssen
% -> Ein Doppelrohr-Wärmetauscher besteht aus mehreren horinzontalen Rohrpaaren
% -> Die Kühlflüssigkeitsströme im Doppelrohr-Wärmetauscher werden derart modelliert, dass die Kühlflüssigkeiten parallel in den Rohrpaaren von der einen Seite zur anderen Seite des Doppelrohr-Wärmetauschers fließen
% Fluid_Waermetauscher(1,1)=Fluid_Komponente;                                 % Objektzuordnung zur Klasse
% Fluid_Waermetauscher(1,1).Art_Waermetauscher=1;                             % Art des Wärmetauschers: 1 = Gleichstromwärmetauscher, -1 = Gegenstromwärmetauscher, 0 = Bei der jeweiligen Komponente, in dem sich das Fluid befindet, handelt es sich nicht um einen Wärmetauscher
% Fluid_Waermetauscher(1,1).Nr_Kuehlkreislauf=1;                              % Nummer des Kühlkreislaufs, zu dem das 1. Strömungsgebiet des Wärmetauschers gehört
% Fluid_Waermetauscher(1,1).l_Kuehlfluessigkeit=0.5;                          % Länge des Kühlflüssigkeitsstroms im 1. Strömungsgebiet des Wärmetauschers in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Waermetauscher(1,1).A_Kuehlfluessigkeit=0.01^2/4*pi*20;               % Querschnittsfläche der Kühlflüssigkeit im 1. Strömungsgebiet des Wärmetauschers in m^2
% Fluid_Waermetauscher(1,1).T_Kuehlfluessigkeit_init=273.15+10;               % Initialtemperatur der Kühlflüssigkeit im 1. Strömungsgebiet des Wärmetauschers in K
% 
% Fluid_Waermetauscher(2,1)=Fluid_Komponente;                                 % Objektzuordnung zur Klasse
% Fluid_Waermetauscher(2,1).Art_Waermetauscher=Fluid_Waermetauscher(1,1).Art_Waermetauscher; % Art des Wärmetauschers: 1 = Gleichstromwärmetauscher, -1 = Gegenstromwärmetauscher, 0 = Bei der jeweiligen Komponente, in dem sich das Fluid befindet, handelt es sich nicht um einen Wärmetauscher
% Fluid_Waermetauscher(2,1).Nr_Kuehlkreislauf=2;                              % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Wärmetauschers gehört
% Fluid_Waermetauscher(2,1).l_Kuehlfluessigkeit=Fluid_Waermetauscher(1,1).l_Kuehlfluessigkeit; % Länge des Kühlflüssigkeitsstroms im 2. Strömungsgebiet des Wärmetauschers in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Waermetauscher(2,1).A_Kuehlfluessigkeit=((0.015^2/4*pi)-(0.01^2/4*pi))*20; % Querschnittsfläche der Kühlflüssigkeit im 2. Strömungsgebiet des Wärmetauschers in m^2
% Fluid_Waermetauscher(2,1).T_Kuehlfluessigkeit_init=273.15+10;               % Initialtemperatur der Kühlflüssigkeit im 2. Strömungsgebiet des Wärmetauschers in K
% -> Fluid_Waermetauscher(1,1) und Fluid_Waermetauscher(2,1) gehören zum gleichen Wärmetauscher 1 (Spalte = 1)
% -> Deswegen muss Art_Waermetauscher identisch sein
% -> Deswegen muss l_Kuehlfluessigkeit identisch sein, dass die Anzahl an finiten Volumen in beiden Strömungsgebieten des Wärmetauschers übereinstimmt und sich somit genau gegenüberstehen -> Bedingung für die Berechnung des Wärmeaustausches im Wärmetauscher

Fluid_EMaschine(1)=class_fluid_component;                                        % Objektzuordnung zur Klasse
Fluid_EMaschine(1).Nr_Kuehlkreislauf=1;                                     % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet der E-Maschine gehört
Fluid_EMaschine(1).l_Kuehlfluessigkeit=Fluid.EMaschine.l_Kuehlfluessigkeit; % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der E-Maschine in m -> muss ein Vielfaches von l_FinitesVolumen sein
Fluid_EMaschine(1).A_Kuehlfluessigkeit=Fluid.EMaschine.A_Kuehlfluessigkeit; % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der E-Maschine in m^2
Fluid_EMaschine(1).T_Kuehlfluessigkeit_init=T_init;                      % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet der E-Maschine in K

Fluid_Leistungselektronik(1)=class_fluid_component;                              % Objektzuordnung zur Klasse
Fluid_Leistungselektronik(1).Nr_Kuehlkreislauf=1;                           % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet der Leistungselektronik gehört
Fluid_Leistungselektronik(1).l_Kuehlfluessigkeit=Fluid.Leistungselektronik.l_Kuehlfluessigkeit; % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet der Leistungselektronik in m -> muss ein Vielfaches von l_FinitesVolumen sein
Fluid_Leistungselektronik(1).A_Kuehlfluessigkeit=Fluid.Leistungselektronik.A_Kuehlfluessigkeit; % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in m^2
Fluid_Leistungselektronik(1).T_Kuehlfluessigkeit_init=T_init;            % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in K

% Fluid_Batteriepack(1)=Fluid_Komponente;                                     % Objektzuordnung zur Klasse
% Fluid_Batteriepack(1).Nr_Kuehlkreislauf=1;                                  % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet im Batteriepacks gehört
% Fluid_Batteriepack(1).l_Kuehlfluessigkeit=Fluid.Batteriepack.l_Kuehlfluessigkeit; % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Batteriepacks in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Batteriepack(1).A_Kuehlfluessigkeit=Fluid.Batteriepack.A_Kuehlfluessigkeit; % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in m^2
% Fluid_Batteriepack(1).T_Kuehlfluessigkeit_init=T_init;                   % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in K

Fluid_Ladegeraet(1)=class_fluid_component;                                       % Objektzuordnung zur Klasse
Fluid_Ladegeraet(1).Nr_Kuehlkreislauf=1;                                    % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet im Ladegerät gehört
Fluid_Ladegeraet(1).l_Kuehlfluessigkeit=Fluid.Ladegeraet.l_Kuehlfluessigkeit; % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Ladegeräts in m -> muss ein Vielfaches von l_FinitesVolumen sein
Fluid_Ladegeraet(1).A_Kuehlfluessigkeit=Fluid.Ladegeraet.A_Kuehlfluessigkeit; % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Ladegeräts in m^2
Fluid_Ladegeraet(1).T_Kuehlfluessigkeit_init=T_init;                     % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Ladegeräts in K

% Fluid_PCM(1)=Fluid_Komponente;                                              % Objektzuordnung zur Klasse
% Fluid_PCM(1).Nr_Kuehlkreislauf=2;                                           % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet im PCM gehört
% Fluid_PCM(1).l_Kuehlfluessigkeit=0.3;                                       % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des PCM in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_PCM(1).A_Kuehlfluessigkeit=2*0.019^2/4*pi;                            % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des PCM in m^2
% Fluid_PCM(1).T_Kuehlfluessigkeit_init=273.15+10;                            % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des PCM in K
% 
% Fluid_Peltier(1)=Fluid_Komponente;                                          % Objektzuordnung zur Klasse
% Fluid_Peltier(1).Nr_Kuehlkreislauf=2;                                       % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet im Peltier-Element gehört
% Fluid_Peltier(1).l_Kuehlfluessigkeit=0.3;                                   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Peltier-Elements in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Peltier(1).A_Kuehlfluessigkeit=2*0.019^2/4*pi;                        % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Peltier-Elements in m^2
% Fluid_Peltier(1).T_Kuehlfluessigkeit_init=273.15+10;                        % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Peltier-Elements in K
% 
Fluid_Schlauch(1)=class_fluid_component;                                         % Objektzuordnung zur Klasse
Fluid_Schlauch(1).Nr_Kuehlkreislauf=1;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
Fluid_Schlauch(1).l_Kuehlfluessigkeit=Fluid.Schlauch.l_Kuehlfluessigkeit;   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
Fluid_Schlauch(1).A_Kuehlfluessigkeit=Fluid.Schlauch.A_Kuehlfluessigkeit;   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
Fluid_Schlauch(1).T_Kuehlfluessigkeit_init=T_init;                          % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K

Fluid_Schlauch(2)=class_fluid_component;                                         % Objektzuordnung zur Klasse
Fluid_Schlauch(2).Nr_Kuehlkreislauf=1;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
Fluid_Schlauch(2).l_Kuehlfluessigkeit=Fluid.Schlauch.l_Kuehlfluessigkeit;   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
Fluid_Schlauch(2).A_Kuehlfluessigkeit=Fluid.Schlauch.A_Kuehlfluessigkeit;   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
Fluid_Schlauch(2).T_Kuehlfluessigkeit_init=T_init;                          % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K

Fluid_Schlauch(3)=class_fluid_component;                                         % Objektzuordnung zur Klasse
Fluid_Schlauch(3).Nr_Kuehlkreislauf=1;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
Fluid_Schlauch(3).l_Kuehlfluessigkeit=Fluid.Schlauch.l_Kuehlfluessigkeit;   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
Fluid_Schlauch(3).A_Kuehlfluessigkeit=Fluid.Schlauch.A_Kuehlfluessigkeit;   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
Fluid_Schlauch(3).T_Kuehlfluessigkeit_init=T_init;                          % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K

Fluid_Schlauch(4)=class_fluid_component;                                         % Objektzuordnung zur Klasse
Fluid_Schlauch(4).Nr_Kuehlkreislauf=1;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
Fluid_Schlauch(4).l_Kuehlfluessigkeit=Fluid.Schlauch.l_Kuehlfluessigkeit;   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
Fluid_Schlauch(4).A_Kuehlfluessigkeit=Fluid.Schlauch.A_Kuehlfluessigkeit;   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
Fluid_Schlauch(4).T_Kuehlfluessigkeit_init=T_init;                          % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K

% Fluid_Schlauch(5)=Fluid_Komponente;                                         % Objektzuordnung zur Klasse
% Fluid_Schlauch(5).Nr_Kuehlkreislauf=1;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
% Fluid_Schlauch(5).l_Kuehlfluessigkeit=Fluid.Schlauch.l_Kuehlfluessigkeit;   % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Schlauch(5).A_Kuehlfluessigkeit=Fluid.Schlauch.A_Kuehlfluessigkeit;   % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
% Fluid_Schlauch(5).T_Kuehlfluessigkeit_init=T_init;                          % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K

% Fluid_Schlauch(6)=Fluid_Komponente;                                         % Objektzuordnung zur Klasse
% Fluid_Schlauch(6).Nr_Kuehlkreislauf=1;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
% Fluid_Schlauch(6).l_Kuehlfluessigkeit=1;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Schlauch(6).A_Kuehlfluessigkeit=0.019^2/4*pi;                         % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
% Fluid_Schlauch(6).T_Kuehlfluessigkeit_init=273.15+10;                       % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K
% 
% Fluid_Schlauch(7)=Fluid_Komponente;                                         % Objektzuordnung zur Klasse
% Fluid_Schlauch(7).Nr_Kuehlkreislauf=1;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
% Fluid_Schlauch(7).l_Kuehlfluessigkeit=1;                                    % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Schlauch(7).A_Kuehlfluessigkeit=0.019^2/4*pi;                         % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
% Fluid_Schlauch(7).T_Kuehlfluessigkeit_init=273.15+10;                       % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K
% 
% Fluid_Schlauch(8)=Fluid_Komponente;                                         % Objektzuordnung zur Klasse
% Fluid_Schlauch(8).Nr_Kuehlkreislauf=2;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
% Fluid_Schlauch(8).l_Kuehlfluessigkeit=0.3;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Schlauch(8).A_Kuehlfluessigkeit=0.019^2/4*pi;                         % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
% Fluid_Schlauch(8).T_Kuehlfluessigkeit_init=273.15+10;                       % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K
% 
% Fluid_Schlauch(9)=Fluid_Komponente;                                         % Objektzuordnung zur Klasse
% Fluid_Schlauch(9).Nr_Kuehlkreislauf=2;                                      % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
% Fluid_Schlauch(9).l_Kuehlfluessigkeit=0.3;                                  % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Schlauch(9).A_Kuehlfluessigkeit=0.019^2/4*pi;                         % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
% Fluid_Schlauch(9).T_Kuehlfluessigkeit_init=273.15+10;                       % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K
% 
% Fluid_Schlauch(10)=Fluid_Komponente;                                        % Objektzuordnung zur Klasse
% Fluid_Schlauch(10).Nr_Kuehlkreislauf=2;                                     % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
% Fluid_Schlauch(10).l_Kuehlfluessigkeit=0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Schlauch(10).A_Kuehlfluessigkeit=0.019^2/4*pi;                        % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
% Fluid_Schlauch(10).T_Kuehlfluessigkeit_init=273.15+10;                      % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K
% 
% Fluid_Schlauch(11)=Fluid_Komponente;                                        % Objektzuordnung zur Klasse
% Fluid_Schlauch(11).Nr_Kuehlkreislauf=2;                                     % Nummer des Kühlkreislaufs, zu dem das Strömungsgebiet des Schlauchs gehört
% Fluid_Schlauch(11).l_Kuehlfluessigkeit=0.3;                                 % Länge des Kühlflüssigkeitsstroms im Strömungsgebiet des Schlauchs in m -> muss ein Vielfaches von l_FinitesVolumen sein
% Fluid_Schlauch(11).A_Kuehlfluessigkeit=0.019^2/4*pi;                        % Querschnittsfläche der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in m^2
% Fluid_Schlauch(11).T_Kuehlfluessigkeit_init=273.15+10;                      % Initialtemperatur der Kühlflüssigkeit im Strömungsgebiet des Schlauchs in K

%--------------------------------------------------------------------------
% Konfiguration der Kühlkreisläufe
%--------------------------------------------------------------------------

% -> Jeder Index von Konfig_Kuehlkreislauf repräsentiert einen Kühlkreislauf (Index = Nummer Kühlkreislauf)
% -> Es müssen n_Kuehlkreislauf Indizes existieren
% -> Es sind 2 Kühlkreisläufe voreingestellt
% -> Falls n Kühlkreisläufe vorhanden sind, müssen n Konfig_Kuehlkreislauf festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: Konfig_Kuehlkreislauf{i} mit i=1:n

% -> WICHTIG: DER HAUPTPFAD EINES DREIWEGEVENTILS MUSS IMMER VOLLSTÄNDIG ALS ERSTES FESTGELEGT WERDEN!
% -> Hauptpfad: Dreiwegeventil wird nicht bestromt bzw. angesteuert -> Zustand_Ventil = 0 -> Kühlflüssigkeit fließt über den Hauptpfad!
% -> Nebenpfad: Dreiwegeventil wird maximal bestromt bzw. angesteuert -> Zustand_Ventil = 1 -> Kühlflüssigkeit fließt über den Nebenpfad!
% -> Zustand_Ventil zwischen 0 und 1 -> Teil der Kühlflüssigkeit fließt über den Hauptpfad und der restliche Teil der Kühlflüssigkeit fließt über den Nebenpfad!

% -> Ein Dreiwegeventil existiert nicht als Fluid_Komponente (wird erst nach Konfig_Kuehlkreislauf festeglegt)
% -> Ein Dreiwegeventil wird als 0D angenommen, d.h. die Kühlflüssigkeit fließt direkt von einer Komponente in die andere
% -> Deswegen wird in Konfig_Kuehlkreislauf ein Dreiwegeventil nicht als eigenes Element aufgenommen
% -> An der Stelle eines Dreiwegeventils muss in Konfig_Kuehlkreislauf eine Aufzweigung konfiguriert werden, d.h. 1 Fluid_Komponente steht mit 2 nachfolgenden Fluid_Komponenten in Kontakt
% -> Die Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade wird derart konfiguriert, dass 2 Fluid_Komponenten mit 1 gleichen nachfolgenden Fluid_Komponente in Kontakt stehen

% -> EINSCHRÄNKUNGEN:
% -> Ein Dreiwegeventil darf nur in Verbindung mit Schläuchen vorkommen -> Vor und nach einem Dreiwegeventil kann nur Fluid_Schlauch sein
% -> Eine Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade soll nur in Verbindung mit Schläuchen vorkommen -> Vor und nach einer Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade soll nur Fluid_Schlauch sein
% -> Es können keine zwei Dreiwegeventile direkt miteinander verbunden werden (aus einem Pfad werden drei Pfade) -> Es muss mindestens ein Fluid_Schlauch egal welcher Länge dazwischen sein
% -> Die zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade müssen sich GEMEINSAM wieder zu einem nachfolgenden Pfad vereinigen -> Nicht möglich: 1. Dreiwegeventil -> dann 2. Dreiwegeventil in einem Pfad des 1. Dreiwegeventils -> dann Vereinigung des Pfades des 1. Dreiwegeventils mit einem Pfad des 2. Dreiwegeventils oder Vereinigung der drei Pfade zu einem Pfad -> Sondern: Zuerst vereinen sich die zwei Pfade des 2. Dreiwegeventils zu einem Pfad (ergibt einen Pfad des 1. Dreiwegeventils) -> Dann vereinen sich die zwei Pfade des 1. Dreiwegeventils zu einem Pfad 

Konfig_Kuehlkreislauf{1}={{'Fluid_Ladegeraet(1)','Fluid_Schlauch(1)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(2)','Fluid_EMaschine(1)','Fluid_Schlauch(3)','Fluid_Kuehler(1)','Fluid_Schlauch(4)'} % Hier müssen die festgelegten Fluid_Komponenten (aus "Definition der Fluid_Komponenten") genannt werden, die in dem jeweiligen Kühlkreislauf vorhanden sind (Angabe Nr_Kuehlkreislauf in der jeweiligen Fluid_Komponente muss mit dem Index von Konfig_Kuehlkreislauf übereinstimmen!) -> Eintrag i in dieser Zeile = Nummer i in den unteren beiden Zeilen  
                          [1,2,3,4,5,6,7,8]                       % Hier werden gerichtete Verbindungen der Fluid_Komponenten und damit die Konfiguration des Kühlkreislaufs definiert -> Eintrag i in dieser Zeile hat mit Eintrag i in unterer Zeile eine gerichtete Verbindung -> Bei einem Dreiwegeventil bzw. bei einer Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade hat ein Eintrag einer Zeile Verbindungen zu zwei Einträgen der anderen Zeile
                          [2,3,4,5,6,7,8,1]};

%Konfig_Kuehlkreislauf{2}={{'Fluid_Waermetauscher(2,1)','Fluid_Schlauch(8)','Fluid_Batteriepack(1)','Fluid_Schlauch(9)','Fluid_PCM(1)','Fluid_Schlauch(10)','Fluid_PCM(2)','Fluid_Schlauch(11)','Fluid_Ladegeraet(1)'} % Hier müssen die festgelegten Fluid_Komponenten (aus "Definition der Fluid_Komponenten") genannt werden, die in dem jeweiligen Kühlkreislauf vorhanden sind (Angabe Nr_Kuehlkreislauf in der jeweiligen Fluid_Komponente muss mit dem Index von Konfig_Kuehlkreislauf übereinstimmen!) -> Eintrag i in dieser Zeile = Nummer i in den unteren beiden Zeilen 
%                           [1,2,3,4,5,6,7,8,9]                                         % Hier werden gerichtete Verbindungen der Fluid_Komponenten und damit die Konfiguration des Kühlkreislaufs definiert -> Eintrag i in dieser Zeile hat mit Eintrag i in unterer Zeile eine gerichtete Verbindung -> Bei einem Dreiwegeventil bzw. bei einer Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade hat ein Eintrag einer Zeile Verbindungen zu zwei Einträgen der anderen Zeile
%                           [2,3,4,5,6,7,8,9,1]};                       
% 


% -> Konfig_Kuehlkreislauf für Thermomanagementsystem des Smart am FTM (auskommentiert):
                      
% Konfig_Kuehlkreislauf{1}={{'Fluid_Kuehler(1)','Fluid_Schlauch(1)','Fluid_Leistungselektronik(1)','Fluid_Schlauch(2)','Fluid_EMaschine(1)','Fluid_Schlauch(3)'} % Hier müssen die festgelegten Fluid_Komponenten (aus "Definition der Fluid_Komponenten") genannt werden, die in dem jeweiligen Kühlkreislauf vorhanden sind (Angabe Nr_Kuehlkreislauf in der jeweiligen Fluid_Komponente muss mit dem Index von Konfig_Kuehlkreislauf übereinstimmen!) -> Eintrag i in dieser Zeile = Nummer i in den unteren beiden Zeilen 
%                           [1,2,3,4,5,6]                                     % Hier werden gerichtete Verbindungen der Fluid_Komponenten und damit die Konfiguration des Kühlkreislaufs definiert -> Eintrag i in dieser Zeile hat mit Eintrag i in unterer Zeile eine gerichtete Verbindung -> Bei einem Dreiwegeventile bzw. einer Vereinigung der durch ein Dreiwegeventil aufgezweigten Pfade hat ein Eintrag einer Zeile Verbindungen zu zwei Einträgen der anderen Zeile
%                           [2,3,4,5,6,1]};
                     
%--------------------------------------------------------------------------
% Erstellung der Graphen der Kühlkreisläufe
%--------------------------------------------------------------------------                        
                        
% -> Die gerichteten Graphen der Kühlkreisläufe werden automatisch aus Konfig_Kuehlkreislauf erstellt
% -> Die gerichteten Graphen der Kühlkreisläufe bestehen aus Knoten, die die Fluid_Komponenten darstellen, und aus gerichteten Kanten, die die gerichteten Verbindungen zwischen Fluid_Komponenten darstellen

for i=1:n_Kuehlkreislauf                                                    
    Graph_Kuehlkreislauf{i}=digraph(Konfig_Kuehlkreislauf{i}{2},Konfig_Kuehlkreislauf{i}{3},[],Konfig_Kuehlkreislauf{i}{1}); %#ok<*SAGROW>
end                        

%--------------------------------------------------------------------------
% Definition der Dreiwegeventile, die durch die Konfiguration der Kühlkreisläufe vorhanden sein müssen
%--------------------------------------------------------------------------

% -> Für jede konfigurierte Aufzweigung in Konfig_Kuehlkreislauf muss ein Dreiwegeventil festgelegt werden
% -> Es ist 1 Dreiwegeventil voreingestellt
% -> Falls n Aufzweigungen in Konfig_Kuehlkreislauf konfiguriert sind, müssen n Dreiwegeventile festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: Ventil(i) mit i=1:n

% -> Definitionen für Dreiwegeventile: Nr_Kuehlkreislauf, Ventil_nach, Vereinigung_vor, Zustand_Ventil_Break_T_FinitesVolumen_Ventil_nach (Definition für Steuerung_Ventil = 1 -> siehe unten), Zustand_Ventil_Table (Definition für Steuerung_Ventil = 1 -> siehe unten), Zustand_Ventil (Definition für Steuerung_Ventil = 0 -> siehe unten)
% -> Nach Ventil_nach befindet sich ein Dreiwegeventil mit einem bestimmten Zustand_Ventil
% -> Vor Vereinigung_vor befindet sich kein Dreiwegeventil mit einem bestimmten Zustand_Ventil, sondern es gilt die Annahme: Vereinigung_vor hat mit jeweils 50% seiner Querschnittsfläche der Kühlflüssigkeit Kontakt zu den beiden Fluid_Komponenten vor Vereinigung_vor
% -> Wegen der 1D-Simulation (und der OD-Annahme eines Dreiwegeventils) wird die Konduktion über ein/e Dreiwegeventil/Aufzweigung bzw. über eine Vereinigung in Simulink immer über die Kontaktquerschnittsfläche von Ventil_nach (1-Zustand_Ventil:Zustand_Ventil) bzw. Vereinigung_vor (0.5:0.5) mit den in Kontakt stehenden Fluid_Komponenten bestimmt
% -> Da ein Dreiwegeventil nur in Verbindung mit Schläuchen vorkommen darf (siehe oben), MUSS Ventil_nach ein Fluid_Schlauch sein 
% -> Da eine Vereinigung nur in Verbindung mit Schläuchen vorkommen soll (siehe oben), soll Vereinigung_vor ein Fluid_Schlauch sein

% -> Zustand_Ventil = 0 -> Dreiwegeventil wird nicht bestromt bzw. angesteuert -> Kühlflüssigkeit fließt über den Hauptpfad des Dreiwegeventils
% -> Zustand_Ventil = 1 -> Dreiwegeventil wird maximal bestromt bzw. angesteuert -> Kühlflüssigkeit fließt über den Nebenpfad des Dreiwegeventils
% -> Zustand_Ventil zwischen 0 und 1 -> Teil der Kühlflüssigkeit fließt über den Hauptpfad des Dreiwegeventils und der restliche Teil der Kühlflüssigkeit fließt über den Nebenpfad des Dreiwegeventils
% -> Im Thermomanagementsystemmodell werden Berechnungen mit Divison durch Zustand_Ventil durchgeführt
% -> Da eine Berechnung mit Division durch 0 nicht möglich ist, wird im Thermomanagementsystemmodell Zustand_Ventil immer zwischen 0.001 und 0.999 skaliert
% -> Damit gibt es keinen Rechenfehler bzw. die Simulation ist stabil, aber es ist immer (auch bei offiziellen Zustand_Ventil = 0 oder 1) zumindest ein minimaler Volumenstrom der Kühlflüssigkeit im Neben- bzw. Hauptpfad eines Dreiwegeventils vorhanden
% -> Folglich wird für das Thermomanagementsystemmodell angenommen, dass ein Dreiwegeventil nicht komplett abdichten kann
% -> Dies kann dadurch validiert werden, dass ein Dreiwegeventil in der Realität in der Regel auch nicht komplett abdichtet

% -> In einem Kühlkreislauf können Dreiwegeventile sein
% -> Ein Dreiwegeventil wird als 0D angenommen
% -> Je nachdem wie es der Anwender wünscht, können Dreiwegeventile gesteuert oder ungesteuert sein
% -> Dies wird über Steuerung_Ventil global für alle Dreiwegeventile festgelegt
Steuerung_Ventil=1;                                                         % Steuerung der Dreiwegeventile: 1 = Dreiwegeventile gesteuert, 0 = Dreiwegeventile ungesteuert
% -> Bei einer realen Steuerung existiert eine Totzeit
% -> Totzeit = Zeitspanne zwischen der Signaländerung am Systemeingang und der Signalantwort am Systemausgang
% -> Für das Thermomanagementsystemmodell wird für Steuerung_Ventil = 1 die Totzeit über Totzeit_Steuerung_Ventil global für die Steuerung aller Dreiwegeventile festgelegt
% -> Da das Thermomanagementsystemmodell zeitdiskret ausgewertet wird, kann es sein, dass die Totzeit der Steuerung der Dreiwegeventile nicht exakt eingehalten wird
% -> Dies tritt für den Fall ein, wenn die Totzeit der Steuerung der Dreiwegeventile kein Vielfaches vom Zeitschritt der Simulation ist
% -> Für diesen Fall stellt sich die Signalantwort am Systemausgang zum darauffolgenden Auswertungszeitpunkt ein
Totzeit_Steuerung_Ventil=1;                                                 % Totzeit der Steuerung der Dreiwegeventile in s -> Nur benötigt für den Fall Steuerung_Ventil = 1
% -> Im Thermomanagementsystemmodell wird ein Dreiwegeventil nicht modelliert
% -> Im Thermomanagementsystemmodell wird der Zustand eines Dreiwegeventils benötigt
% -> Steuerung_Ventil bezieht sich auf den Zustand eines Dreiwegeventils
% -> In der Definition eines Dreiwegeventil wird der Zustand eines Dreiwegeventils festgelegt
% -> Dieser muss nur für den entsprechenden Steuerungsfall bzgl. Steuerung_Ventil festgelegt werden
% -> Achtung: Zustand eines Dreiwegeventils kann nicht < 0 und nicht > 1 sein bzw. muss >= 0 und <= 1 sein

% Ventil(1)=Dreiwegeventil;                                                   % Objektzuordnung zur Klasse
% Ventil(1).Nr_Kuehlkreislauf=1;                                              % Nummer des Kühlkreislaufs, zu dem das Dreiwegeventil gehört
% Ventil(1).Ventil_nach='Fluid_Schlauch(3)';                                  % Name von Fluid_Komponente innerhalb des entsprechenden Kühlkreislaufs, nach der sich das Dreiwegeventil befindet bzw. nach der die Aufzweigung stattfindet 
% Ventil(1).Vereinigung_vor='Fluid_Schlauch(5)';                              % Name von Fluid_Komponente innerhalb des entsprechenden Kühlkreislaufs, vor der die Vereinigung der zwei nach der Aufzweigung durch das Dreiwegeventil resultierenden Pfade stattfindet
% -> Dreiwegeventile gesteuert (Steuerung_Ventil = 1):
% -> Bei den Lookup Tables wird nicht extrapoliert, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet
% -> Deswegen wird über die Tables der minimal und maximal mögliche Zustand der Dreiwegeventile festgelegt
% -> Achtung: Zustand eines Dreiwegeventils kann nicht < 0 und nicht > 1 sein bzw. muss >= 0 und <= 1 sein
% Ventil(1).Zustand_Ventil_Break_T_FinitesVolumen_Ventil_nach=[273.15+25;273.15+30]; % Der Zustand des Dreiwegeventils ist abh. von der Temperatur der Kühlflüssigkeit bzgl. des Knotens des n. finiten Volumens der Fluid_Komponente, die bei Ventil_nach festgelegt ist
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_T_FinitesVolumen_Ventil_nach
% Ventil(1).Zustand_Ventil_Table=[0;1];                                       % Der Zustand des Dreiwegeventils in Abh. von der Temperatur der Kühlflüssigkeit bzgl. des Knotens des n. finiten Volumens der Fluid_Komponente, die bei Ventil_nach festgelegt ist
% -> Dreiwegeventile ungesteuert (Steuerung_Ventil = 0):
% -> Spalte 1 = Zeit, Spalte 2 = Zustand des Dreiwegeventils
% -> Achtung: Zustand eines Dreiwegeventils kann nicht < 0 und nicht > 1 sein bzw. muss >= 0 und <= 1 sein
% Ventil(1).Zustand_Ventil=[0,0;1000,0;1001,1;t_Simulation,1];                % Zustand des Dreiwegeventils -> Spalte 1 = Zeit, Spalte 2 = Zustand des Dreiwegeventils    

%% Parameter Subsystem "Kühler"

% -> Im Thermonagementsystemmodell ist eine beliebige Anzahl an Kühlern möglich

% -> Ein Kühler besitzt keine eigene Temperatur, wird aber als diabat zu seiner Umgebung betrachtet
% -> Es gibt also einen Wärmeaustausch zwischen Umgebungsluft und Kühlflüssigkeit
% -> Für einen Kühler gilt die Annahme, dass dieser im Frontend des Fahrzeugs untergebracht ist
% -> Falls mehrere Kühler simuliert werden sollen, sind alle im Frontend des Fahrzeugs untergebracht
% -> Dadurch wird jeder bei Straßenfahrt simulierte Kühler mit der Luftgeschwindigkeit = v_Fahrzeug angeströmt (relative Luftgeschwindigkeit)
% -> Die tatsächliche Luftgeschwindigkeit durch Wind wird vernachlässigt, weil sie sich in der Realität ständig verändert (Stärke und Richtung) und deswegen schwierig zu bestimmen und folglich zu simulieren ist (sie wird auch bei der Berechnung des Fahrwiderstandes im Antriebsstrangmodell vernachlässigt)
% -> Auf dem Rollenprüfstand wird ein Kühler nicht mit Luftgeschwindigkeit = v_Fahrzeug angeströmt
% -> Der entsprechende Fall (Straßenfahrt oder Rollenprüfstand) muss bei der Abh. der Wärmeübertragungsfähigkeit UA von v_Fahrzeug berücksichtigt werden
% -> Straßenfahrt: UA ist abh. von v_Fahrzeug; Rollenprüfstand: UA ist unabh. von v_Fahrzeug
% -> Ein Kühler besitzt einen Kühlerlüfter, der den Kühler mit seiner Luftgeschwindigkeit anströmt, um die Wärmeübertragungsfähigkeit UA zu verbessern
% -> Die Wärmeübertragungsfähigkeit UA ist zudem abh. vom Volumenstrom der Kühlflüssigkeit
% -> Wärmeübertragungsfähigkeit UA = Wärmedurchgangskoeffizient U * Wärmeübertragungsfläche A

%--------------------------------------------------------------------------
% Definition thermischer Paramater
%--------------------------------------------------------------------------

% -> Ein Kühler besitzt einen Kühlerlüfter, der den Kühler mit seiner Luftgeschwindigkeit anströmt
% -> Ein Kühlerlüfter wird als 0D angenommen
% -> Je nachdem wie es der Anwender wünscht, können Kühlerlüfter gesteuert oder ungesteuert sein
% -> Dies wird über Steuerung_Kuehlerluefter global für alle Kühlerlüfter festgelegt
Steuerung_Kuehlerluefter=1;                                                 % Steuerung der Kühlerlüfter: 1 = Kühlerlüfter gesteuert, 0 = Kühlerlüfter ungesteuert
% -> Bei einer realen Steuerung existiert eine Totzeit
% -> Totzeit = Zeitspanne zwischen der Signaländerung am Systemeingang und der Signalantwort am Systemausgang
% -> Für das Thermomanagementsystemmodell wird für Steuerung_Kuehlerluefter = 1 die Totzeit über Totzeit_Steuerung_Kuehlerluefter global für die Steuerung aller Kühlerlüfter festgelegt
% -> Da das Thermomanagementsystemmodell zeitdiskret ausgewertet wird, kann es sein, dass die Totzeit der Steuerung der Kühlerlüfter nicht exakt eingehalten wird
% -> Dies tritt für den Fall ein, wenn die Totzeit der Steuerung der Kühlerlüfter kein Vielfaches vom Zeitschritt der Simulation ist
% -> Für diesen Fall stellt sich die Signalantwort am Systemausgang zum darauffolgenden Auswertungszeitpunkt ein
Totzeit_Steuerung_Kuehlerluefter=1;                                         % Totzeit der Steuerung der Kühlerlüfter in s -> Nur benötigt für den Fall Steuerung_Kuehlerluefter = 1
% -> Im Thermomanagementsystemmodell wird ein Kühlerlüfter nicht modelliert
% -> Im Thermomanagementsystemmodell wird nur die Luftgeschwindigkeit eines Kühlerlüfters benötigt
% -> Steuerung_Kuehlerluefter bezieht sich auf die Luftgeschwindigkeiten der Kühlerlüfter
% -> Im Folgenden werden die Luftgeschwindigkeiten der Kühlerlüfter festgelegt
% -> Diese müssen nur für den entsprechenden Steuerungsfall bzgl. Steuerung_Kuehlerluefter festgelegt werden
% -> Kühlerlüfter gesteuert (Steuerung_Kuehlerluefter = 1):
% -> Für jeden Kühler muss 1 eigene Luftgeschwindigkeit des Kühlerlüfters festgelegt werden
% -> Die Luftgeschwindigkeit des Kühlerlüfters ist für 1 Kühler voreingestellt
% -> Falls n Kühler vorhanden sind, müssen n Luftgeschwindigkeiten der Kühlerlüfter festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: v_Kuehlerluefter...{i} mit i=1:n
% -> Falls bei einem Kühler kein Kühlerlüfter vorhanden ist, muss die Luftgeschwindigkeit des Kühlerlüfters trotzdem definiert werden und das Table auf [0;0] festgelegt werden (die Breakpoints müssen trotzdem mit ansteigenden Werten festgelegt sein)
% -> Bei den Lookup Tables wird nicht extrapoliert, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet
% -> Deswegen wird über die Tables die minimal und maximal mögliche Luftgeschwindigkeit der Kühlerlüfter festgelegt
% -> Achtung: Luftgeschwindigkeit eines Kühlerlüfters kann nicht < 0 sein bzw. muss >= 0 sein
v_Kuehlerluefter_Break_T_FinitesVolumen_Kuehler{1}=[273.15+25;273.15+30];   % Die Luftgeschwindigkeit des Kühlerlüfters ist abh. von der Temperatur der Kühlflüssigkeit bzgl. des Knotens des 1. oder n. finiten Volumens des Strömungsgebiets des entsprechenden Kühlers in K -> Im Thermomanagementsystemmodell kann vor der Simulation manuell zwischen der Temperatur der Kühlflüssigkeit bzgl. des Knotens des 1. und des n. finiten Volumens des Strömungsgebiets des entsprechenden Kühlers umgeschaltet werden
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_T_FinitesVolumen_Kuehler
v_Kuehlerluefter_Table{1}=[0;10];                                          % Die Luftgeschwindigkeit des Kühlerlüfters in Abh. von der Temperatur der Kühlflüssigkeit bzgl. des Knotens des 1. oder n. finiten Volumens des Strömungsgebiets des entsprechenden Kühlers in m/s -> Im Thermomanagementsystemmodell kann vor der Simulation manuell zwischen der Temperatur der Kühlflüssigkeit bzgl. des Knotens des 1. und des n. finiten Volumens des Strömungsgebiets des entsprechenden Kühlers umgeschaltet werden
% -> Kühlerlüfter ungesteuert (Steuerung_Kuehlerluefter = 0):
% -> Für jeden Kühler muss 1 eigene Luftgeschwindigkeit des Kühlerlüfters festgelegt werden
% -> Die Luftgeschwindigkeit des Kühlerlüfters ist für 1 Kühler voreingestellt
% -> Falls n Kühler vorhanden sind, müssen n Luftgeschwindigkeiten der Kühlerlüfter festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: v_Kuehlerluefter{i} mit i=1:n
% -> Spalte 1 = Zeit, Spalte 2 = Luftgeschwindigkeit des Kühlerlüfters
% -> Falls bei einem Kühler kein Kühlerlüfter vorhanden ist, muss die Luftgeschwindigkeit des Kühlerlüfters trotzdem definiert werden und durchgehend auf 0 festgelegt werden
% -> Achtung: Luftgeschwindigkeit eines Kühlerlüfters kann nicht < 0 sein bzw. muss >= 0 sein
% v_Kuehlerluefter{1}=[0,0;1000,0;1001,6.4;t_Simulation,6.4];                 % Luftgeschwindigkeit des Kühlerlüfters in m/s -> Spalte 1 = Zeit, Spalte 2 = Luftgeschwindigkeit des Kühlerlüfters

% -> Die Wärmeübertragungsfähigkeit ist für 1 Kühler voreingestellt
% -> Falls n Kühler vorhanden sind, muss die Wärmeübertragungsfähigkeit für jeden Kühler einzeln festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: UA_Kuehler...{i} mit i=1:n
% -> Für die Breakpoints sollten immer die Grenzen 0 (= Minimalwert) und Maximalwert verwendet werden, weil bei den Lookup Tables nicht extrapoliert wird, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet wird
UA_Kuehler_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table))]; % Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Kühlers ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 1
% UA_Kuehler_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf))]; % Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Kühlers ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 0
UA_Kuehler_FinitesVolumen_Break_v_Kuehlerluefter{1}=[0,max(cellfun(@(x)max(x),v_Kuehlerluefter_Table))]; % Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Kühlers ist abh. von der Luftgeschwindigkeit des Kühlerlüfters in m/s -> Definition für Steuerung_Kuehlerluefter = 1
% UA_Kuehler_FinitesVolumen_Break_v_Kuehlerluefter{1}=[0,max(cellfun(@(x)max(x(:,2)),v_Kuehlerluefter))]; % Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Kühlers ist abh. von der Luftgeschwindigkeit des Kühlerlüfters in m/s -> Definition für Steuerung_Kuehlerluefter = 0
UA_Kuehler_FinitesVolumen_Break_v_Fahrzeug{1}=[0,max(v_Fahrzeug.Data)/3.6]; % Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Kühlers ist abh. von der Fahrzeuggeschwindigkeit in m/s
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_PV_Kuehlfluessigkeit, Spalten beziehen sich auf Break_v_Kuehlerluefter, Seiten beziehen sich auf Break_v_Fahrzeug
% -> Im folgenden Table müssen die Werte für die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers angegeben werden
UA_Kuehler_Kuehlfluessigkeit_Table{1}(:,:,1)=Fluid.Kuehler.UA_Kuehler_Fluid_Table_1; % Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K
UA_Kuehler_Kuehlfluessigkeit_Table{1}(:,:,2)=Fluid.Kuehler.UA_Kuehler_Fluid_Table_2; % Die Wärmeübertragungsfähigkeit des Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K

%% Parameter Subsystem "Wärmetauscher"

% -> Im Thermonagementsystemmodell ist eine beliebige Anzahl an Wärmetauschern möglich

% -> Ein Wärmetauscher besitzt keine eigene Temperatur und wird als adiabat zu seiner Umgebung betrachtet
% -> Es gibt also keinen Wärmeaustausch zwischen Umgebungsluft und Kühlflüssigkeit, sondern nur einen Wärmeaustausch zwischen den beiden Kühlflüssigkeiten eines Wärmetauschers
% -> Deswegen ist die Wärmeübertragungsfähigkeit UA unabh. von der Luftgeschwindigkeit, die den Wärmetauscher anströmt
% -> Die Wärmeübertragungsfähigkeit UA ist jedoch abh. von den Volumenströmen der beiden Kühlflüssigkeiten 
% -> Wärmeübertragungsfähigkeit UA = Wärmedurchgangskoeffizient U * Wärmeübertragungsfläche A

%--------------------------------------------------------------------------
% Definition thermischer Paramater
%--------------------------------------------------------------------------

% -> Die Wärmeübertragungsfähigkeit ist für 1 Wärmetauscher voreingestellt
% -> Falls n Wärmetauscher vorhanden sind, muss die Wärmeübertragungsfähigkeit für jeden Wärmetauscher einzeln festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: UA_Waermetauscher...{i} mit i=1:n
% -> Für die Breakpoints sollten immer die Grenzen 0 (= Minimalwert) und Maximalwert verwendet werden, weil bei den Lookup Tables nicht extrapoliert wird, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet wird
% -> Im Folgenden wird trotz 2 Kühlflüssigkeiten in 1 Wärmetauscher nur 1 Break_PV_Kuehlfluessigkeit angegeben, weil es sich nur um Breakpoints für die Werte für die Wärmeübertragungsfähigkeit eines Wärmetauschers bzgl. der Kühlflüssigkeit in einem finiten Volumen des 1. bzw. 2. Strömungsgebiets des Wärmetauschers handelt und es sinnvoll ist, dieselben Breakpoints für die Volumenströme der 2 Kühlflüssigkeiten zu verwenden
% UA_Waermetauscher_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table))]; % Die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der Kühlflüssigkeit in einem finiten Volumen des 1. bzw. 2. Strömungsgebiets des Wärmetauschers ist abh. von den Volumenströmen der zwei Kühlflüssigkeiten in m^3/s -> Definition für Steuerung_Pumpe = 1
% UA_Waermetauscher_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf))]; % Die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der Kühlflüssigkeit in einem finiten Volumen des 1. bzw. 2. Strömungsgebiets des Wärmetauschers ist abh. von den Volumenströmen der zwei Kühlflüssigkeiten in m^3/s -> Definition für Steuerung_Pumpe = 0
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_PV_Kuehlfluessigkeit für die Kühlflüssigkeit im 1. Strömungsgebiet des Wärmetauschers, Spalten beziehen sich auf Break_PV_Kuehlfluessigkeit für die Kühlflüssigkeit im 2. Strömungsgebiet des Wärmetauschers
% -> Im folgenden Table müssen die Werte für die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der gesamten Kühlflüssigkeit im 1. bzw. 2. Strömungsgebiet des Wärmetauschers angegeben werden
% -> In einem Wärmetauscher erfolgt der Wärmeaustausch zwischen den beiden Kühlflüssigkeiten
% -> Deswegen ist die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der gesamten Kühlflüssgikeit im 1. Strömungsgebiet des Wärmetauschers identisch zur Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der gesamten Kühlflüssgikeit im 2. Strömungsgebiet des Wärmetauschers
% UA_Waermetauscher_Kuehlfluessigkeit_Table{1}=Fahrzeug.UA_Waermetauscher_Fluid_Table;                   % Die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der gesamten Kühlflüssigkeit im 1. bzw. 2. Strömungsgebiet des Wärmetauschers in Abh. von den Volumenströmen der zwei Kühlflüssigkeiten in W/K

%% Parameter Subsystem "Rad"

%--------------------------------------------------------------------------
% Definition allgemeiner Parameter
%--------------------------------------------------------------------------

r_dynamisch=vehicle.r_dynamisch;                                          % Dynamischer Radius der Räder in m
rho_Luft=vehicle.rho_Luft;                                                % Dichte von Luft in kg/m^3 (-> verwendeter Wert bei 20°C)
A_Stirn=vehicle.A_Stirn;                                                  % Stirnfläche des Fahrzeugs in m^2
c_W=vehicle.c_W;                                                          % Luftwiderstandsbeiwert des Fahrzeugs
m_Fahrzeug=vehicle.m_Fahrzeug;                                            % Masse des Fahrzeugs in kg
e_Fahrzeug=vehicle.e_Fahrzeug;                                            % Drehmassenzuschlagsfaktor des Fahrzeugs
m_Zuladung=vehicle.m_Zuladung;                                            % Masse der Zuladung in kg
f_R=vehicle.f_R;                                                          % Rollwiderstandsbeiwert der Räder

%% Parameter Subsystem "Getriebe"

% -> Im verwendeten Antriebsstrangmodell wird genau mit 1 Getriebe gerechnet
% -> Deswegen existiert in dieser Version des Thermonagementsystemmodells genau 1 Getriebe
% -> Das Getriebe kann nicht in einen Kühlkreislauf integriert werden

% -> Die thermische Modellierung des Getriebes ist im Subsystem "E-Maschine" umgesetzt
% -> Deswegen werden die thermischen Parameter des Getriebes im Abschnitt "Parameter Subsystem "E-Maschine"" erfasst

%--------------------------------------------------------------------------
% Definition allgemeiner Parameter
%--------------------------------------------------------------------------

i_Getriebe=vehicle.i_Getriebe;                                            % Übersetzungsverhältnis des Getriebes
eta_Getriebe=0.95;                                                         % Wirkungsgrad des Getriebes
    
%% Parameter Subsystem "E-Maschine"

% -> Im verwendeten Antriebsstrangmodell wird genau mit 1 E-Maschine gerechnet
% -> Deswegen existiert in dieser Version des Thermonagementsystemmodells genau 1 E-Maschine
% -> Die E-Maschine kann wahlweise in einen Kühlkreislauf integriert werden
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 E-Maschine vorhanden sein

% -> Die thermische Modellierung der E-Maschine und des Getriebes ist zusammen im Subsystem "E-Maschine" umgesetzt
% -> Deswegen werden in diesem Abschnitt ebenso die thermischen Parameter des Getriebes erfasst
% -> E-Maschine und Getriebe werden jeweils als Blockkapazität aufgefasst

% -> Die E-Maschine besitzt eine eigene Temperatur und wird als diabat zu ihrer Umgebung betrachtet
% -> Es gibt also einen Wärmeaustausch zwischen E-Maschine und Umgebungsluft
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. von dem Luftstrom, mit dem die E-Maschine beaufschlagt wird
% -> Dieser Luftstrom kann kaum gemessen werden, resultiert aber aus v_Fahrzeug
% -> Bei Straßenfahrt resultiert aufgrund v_Fahrzeug eine relative Luftgeschwindigkeit -> Die E-Maschine kann wegen dieser relativen Luftgeschwindigkeit je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Auf einem Rollenprüfstand resultieren aufgrund v_Fahrzeug Luftverwirbelungen, z.B. durch die Bewegung der Räder -> Die E-Maschine kann wegen dieser Luftverwirbelungen je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Über die Höhe der Wärmeübertragungsfähigkeit UA bezogen auf v_Fahrzeug kann eingestellt werden, wie stark die E-Maschine angeströmt wird (Einbauort: frei anströmbar vs. abgedeckt; Betrieb: Straßenfahrt vs. Rollenprüfstand)
% -> Zudem gibt es einen Wärmeaustausch zwischen E-Maschine und Kühlflüssigkeit
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. vom Volumenstrom der Kühlflüssigkeit
% -> Wärmeübertragungsfähigkeit UA = Wärmedurchgangskoeffizient U * Wärmeübertragungsfläche A

% -> Das Getriebe kann nicht in einen Kühlkreislauf integriert werden
% -> Das Getriebe besitzt aber eine eigene Temperatur und wird als diabat zu seiner Umgebung betrachtet
% -> Es gibt also einen Wärmeaustausch zwischen Getriebe und Umgebungsluft
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. von dem Luftstrom, mit dem das Getriebe beaufschlagt wird
% -> Dieser Luftstrom kann kaum gemessen werden, resultiert aber aus v_Fahrzeug
% -> Bei Straßenfahrt resultiert aufgrund v_Fahrzeug eine relative Luftgeschwindigkeit -> Das Getriebe kann wegen dieser relativen Luftgeschwindigkeit je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Auf einem Rollenprüfstand resultieren aufgrund v_Fahrzeug Luftverwirbelungen, z.B. durch die Bewegung der Räder -> Das Getriebe kann wegen dieser Luftverwirbelungen je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Über die Höhe der Wärmeübertragungsfähigkeit UA bezogen auf v_Fahrzeug kann eingestellt werden, wie stark das Getriebe angeströmt wird (Einbauort: frei anströmbar vs. abgedeckt; Betrieb: Straßenfahrt vs. Rollenprüfstand)
% -> Wärmeübertragungsfähigkeit UA = Wärmedurchgangskoeffizient U * Wärmeübertragungsfläche A

% -> Zwischen E-Maschine und Getriebe findet zudem ein Wärmeaustausch über Konduktion statt

%--------------------------------------------------------------------------
% Definition allgemeiner Parameter
%--------------------------------------------------------------------------

eta_EMaschine_Break_M_EMaschine=vehicle.eta_EMaschine_Break_M;            % Der Wirkungsgrad der E-Maschine ist abh. vom Drehmoment der E-Maschine in Nm
eta_EMaschine_Break_n_EMaschine=vehicle.eta_EMaschine_Break_n;            % Der Wirkungsgrad der E-Maschine ist abh. von der Drehzahl der E-Maschine 1/min
eta_EMaschine_Table=vehicle.eta_EMaschine_Table;                          % Der Wirkungsgrad der E-Maschine in Abh. vom Drehmoment der E-Maschine und in Abh. von der Drehzahl der E-Maschine

eta_EMaschine_Faktor_Volllast=vehicle.eta_EMaschine_Volllast;             % Faktor der Volllast für das Wirkungsgradkennfeld der E-Maschine
% -> Außerhalb der Volllastkennlinie ist das Wirkungsgradkennfeld mit 'NaN' bedatet
% -> Sollten in der Simualtion Betriebspunkte außerhalb des Kennfelds liegen, muss die Simulation noch immer funktionieren
% -> Es wird für diese Betriebspunkte dann der Wirkungsgrad am Rand des Kennfelds benutzt bzw. genauer bei eta_EMaschine_Faktor_Volllast * Volllast
% -> Dies ist notwendig, da sowohl Wirkungsgradkennfeld wie auch Lookup Table nicht stetig sind und somit zwischen Stützstellen interpolieren müssen
% -> Dies kann dazu führen, dass ein Wert, der auf der Volllastlinie sitzt, in 'NaN' im Wirkungsgradkennfeld resultiert
% -> Um dies zu vermeiden, wird mit eta_EMaschine_Faktor_Volllast * Volllast gerechnet, wenn Betriebspunkte außerhalb des Kennfelds liegen, um 'NaN' Wirkungsgrade zu vermeiden
% -> eta_EMaschine_Faktor_Volllast ist stark abh. von der Güte (Abstand der Stützstellen) des Wirkungsgradkennfeldes
% -> Für das aktuell verwendete Wirkungsgradkennfeld Wirkungsgrad_EM100.mat darf maximal mit 98.4% der Volllast gerechnet werden, um 'NaN' Wirkungsgrade zu vermeiden
% -> Deswegen ist eta_EMaschine_Faktor_Volllast zu 0.984 festgelegt

%--------------------------------------------------------------------------
% Definition thermischer Paramater
%--------------------------------------------------------------------------

T_EMaschine_init=T_init;                                                 % Initialtemperatur der E-Maschine in K
T_Getriebe_init=T_init;                                                  % Initialtemperatur des Getriebes in K

T_Offset_EMaschine_Getriebe=0;                                             % Offset zur Temperatur der Umgebungsluft bei der E-Maschine und dem Getriebe in K
% -> Temperatur der Umgebungsluft um die E-Maschine und das Getriebe kann zur normalen Temperatur der Umgebungsluft verändert sein

% -> Die Wärmeübertragungsfähigkeiten sind für 1 E-Maschine und 1 Getriebe voreingestellt
% -> Da es nur max. 1 E-Maschine und 1 Getriebe geben kann, können keine Wärmeübertragungsfähigkeiten der E-Maschine bzgl. der Umgebungsluft, des Getriebes bzgl. der Umgebeungsluft und der E-Maschine bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der E-Maschine mit einem Index > 1 festgelegt werden
% -> Für die Breakpoints sollten immer die Grenzen 0 (= Minimalwert) und Maximalwert verwendet werden, weil bei den Lookup Tables nicht extrapoliert wird, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet wird
UA_EMaschine_Umgebung_Break_v_Fahrzeug{1}=[0,max(v_Fahrzeug.Data)/3.6];     % Die Wärmeübertragungsfähigkeit der E-Maschine bzgl. der Umgebungsluft ist abh. von der Fahrzeuggeschwindigkeit in m/s
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_v_Fahrzeug
UA_EMaschine_Umgebung_Table{1}=vehicle.UA_EMaschine_Umgebung_Table;        % Die Wärmeübertragungsfähigkeit der E-Maschine bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K

UA_Getriebe_Umgebung_Break_v_Fahrzeug{1}=[0,max(v_Fahrzeug.Data)/3.6];      % Die Wärmeübertragungsfähigkeit des Getriebes bzgl. der Umgebungsluft ist abh. von der Fahrzeuggeschwindigkeit in m/s
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_v_Fahrzeug
UA_Getriebe_Umgebung_Table{1}=vehicle.UA_Getriebe_Umgebung_Table;          % Die Wärmeübertragungsfähigkeit des Getriebes bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K

UA_EMaschine_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table))]; % Die Wärmeübertragungsfähigkeit der E-Maschine bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der E-Maschine ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 1
% UA_EMaschine_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf))]; % Die Wärmeübertragungsfähigkeit der E-Maschine bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der E-Maschine ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 0
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_PV_Kuehlfluessigkeit
% -> Im folgenden Table müssen die Werte für die Wärmeübertragungsfähigkeit der E-Maschine bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet der E-Maschine angegeben werden
UA_EMaschine_Kuehlfluessigkeit_Table{1}=vehicle.UA_EMaschine_Fluid_Table;  % Die Wärmeübertragungsfähigkeit der E-Maschine bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet der E-Maschine in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K

R_EMaschine_Getriebe=0.08;                                                  % Wärmeleitwiderstand zwischen der E-Maschine und dem Getriebe in K/W

m_EMaschine=vehicle.m_EMaschine;                                           % Masse der E-Maschine in kg
c_EMaschine=450;                                                            % Spezifische Wärmekapazität der E-Maschine (Eisen) in J/(kg*K)
C_EMaschine=m_EMaschine*c_EMaschine;                                        % Wärmekapazität der E-Maschine in J/K

m_Getriebe=vehicle.m_Getriebe;                                             % Masse des Getriebes in kg
c_Getriebe=450;                                                             % Spezifische Wärmekapazität des Getriebes (Eisen) in J/(kg*K)
C_Getriebe=m_Getriebe*c_Getriebe;                                           % Wärmekapazität des Getriebes in J/K

%% Parameter Subsystem "Leistungselektronik"

% -> Im verwendeten Antriebsstrangmodell wird genau mit 1 Leistungselektronik gerechnet
% -> Deswegen existiert in dieser Version des Thermonagementsystemmodells genau 1 Leistungselektronik
% -> Die Leistungselektronik kann wahlweise in einen Kühlkreislauf integriert werden
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 Leistungselektronik vorhanden sein

% -> Das Prinizp der Modellierung der Leistungselektronik ist von Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge" übernommen
% -> Für die exakte Herleitung der Modellierung der Leistungselektronik inkl. aller getroffenen Annahmen wird deswegen auf Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge" verwiesen
% -> Für die Modellierung der Leistungselektronik wird angenommen, dass sie aus parallel angeordneten MOSFET besteht
% -> Ein MOSFET besteht aus Substrat und dem Case (Gehäuse), das das Substrat abdeckt
% -> Auf den MOSFET ist ein Kühlkörper angebracht -> Dieser wird als Blockkapazität aufgefasst
% -> Da zwischen Kühlkörper und den Case der MOSFET ein unmittelbarer Kontakt angenommen wird, haben Kühlkörper und die Case der MOSFET die gleiche Temperatur
% -> Deswegen werden der Kühlkörper und die Case der MOSFET gemeinsam als Blockkapazität betrachtet
% -> Deswegen wird aus Gründen der Allgemeingültigkeit des Thermomanagementsystemmodell angenommen, dass der Kühlkörper zu den Case der MOSFET gehört
% -> Dies äußert sich in einer Aufdickung der Case der MOSFET
% -> Dadurch resultiert, dass die Case der MOSFET gemeinsam als Blockkapazität aufgefasst werden
% -> Des Weiteren wird angenommen, dass die Substrate der MOSFET die gleiche Temperatur aufweisen
% -> Deswegen werden die Substrate der MOSFET gemeinsam als Blockkapazität aufgefasst

% -> Die Leistungselektronik besitzt eine eigene Temperatur und wird als diabat zu ihrer Umgebung betrachtet
% -> Es gibt also einen Wärmeaustausch zwischen Leistungselektronik und Umgebungsluft
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. von dem Luftstrom, mit dem die Leistungselektronik beaufschlagt wird
% -> Dieser Luftstrom kann kaum gemessen werden, resultiert aber aus v_Fahrzeug
% -> Bei Straßenfahrt resultiert aufgrund v_Fahrzeug eine relative Luftgeschwindigkeit -> Die Leistungselektronik kann wegen dieser relativen Luftgeschwindigkeit je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Auf einem Rollenprüfstand resultieren aufgrund v_Fahrzeug Luftverwirbelungen, z.B. durch die Bewegung der Räder -> Die Leistungselektronik kann wegen dieser Luftverwirbelungen je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Über die Höhe der Wärmeübertragungsfähigkeit UA bezogen auf v_Fahrzeug kann eingestellt werden, wie stark die Leistungselektronik angeströmt wird (Einbauort: frei anströmbar vs. abgedeckt; Betrieb: Straßenfahrt vs. Rollenprüfstand)
% -> Zudem gibt es einen Wärmeaustausch zwischen Leistungselektronik und Kühlflüssigkeit
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. vom Volumenstrom der Kühlflüssigkeit
% -> Wärmeübertragungsfähigkeit UA = Wärmedurchgangskoeffizient U * Wärmeübertragungsfläche A

% -> Beide genannten Wärmeaustausche finden über die Case der MOSFET statt -> Wärmeaustausch Case - Umgebungsluft und Wärmeaustausch Case - Kuehlfluessigkeit
% -> Zwischen den Substraten und den Case der MOSFET findet zudem eine Wärmeaustausch über Konduktion statt
% -> Im Thermomanagementsystemmodell sind nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge" die Substrate der MOSFET mit j und die Case der MOSFET mit c bezeichnet

%--------------------------------------------------------------------------
% Definition allgemeiner Parameter
%--------------------------------------------------------------------------

eta_Leistungselektronik_Break_M_EMaschine=vehicle.eta_Leistungselektronik_Break_M;             % Der Wirkungsgrad der Leistungselektronik ist abh. vom Drehmoment der E-Maschine in Nm
eta_Leistungselektronik_Break_n_EMaschine=vehicle.eta_Leistungselektronik_Break_n;             % Der Wirkungsgrad der Leistungselektronik ist abh. von der Drehzahl der E-Maschine 1/min
eta_Leistungselektronik_Table=vehicle.eta_Leistungselektronik_Table;                           % Der Wirkungsgrad der Leistungselektronik in Abh. vom Drehmoment der E-Maschine und in Abh. von der Drehzahl der E-Maschine

eta_Leistungselektronik_Faktor_Volllast=vehicle.eta_Leistungselektronik_Volllast;              % Faktor der Volllast für das Wirkungsgradkennfeld der Leistungselektronik
% -> Außerhalb der Volllastkennlinie ist das Wirkungsgradkennfeld mit 'NaN' bedatet
% -> Sollten in der Simualtion Betriebspunkte außerhalb des Kennfelds liegen, muss die Simulation noch immer funktionieren
% -> Es wird für diese Betriebspunkte dann der Wirkungsgrad am Rand des Kennfelds benutzt bzw. genauer bei eta_Leistungselektronik_Faktor_Volllast * Volllast
% -> Dies ist notwendig, da sowohl Wirkungsgradkennfeld wie auch Lookup Table nicht stetig sind und somit zwischen Stützstellen interpolieren müssen
% -> Dies kann dazu führen, dass ein Wert, der auf der Volllastlinie sitzt, in 'NaN' im Wirkungsgradkennfeld resultiert
% -> Um dies zu vermeiden, wird mit eta_Leistungselektronik_Faktor_Volllast * Volllast gerechnet, wenn Betriebspunkte außerhalb des Kennfelds liegen, um 'NaN' Wirkungsgrade zu vermeiden
% -> eta_Leistungselektronik_Faktor_Volllast ist stark abh. von der Güte (Abstand der Stützstellen) des Wirkungsgradkennfeldes
% -> Für das aktuell verwendete Wirkungsgradkennfeld Wirkungsgrad_LE100.mat darf maximal mit 98.4% der Volllast gerechnet werden, um 'NaN' Wirkungsgrade zu vermeiden
% -> Deswegen ist eta_Leistungselektronik_Faktor_Volllast zu 0.984 festgelegt

%--------------------------------------------------------------------------
% Definition thermischer Paramater
%--------------------------------------------------------------------------

T_j_init=T_init;                                                         % Initialtemperatur der Substrate der MOSFET in K
T_c_init=T_init;                                                         % Initialtemperatur der Case der MOSFET in K

T_Offset_Leistungselektronik=0;                                          % Offset zur Temperatur der Umgebungsluft bei der Leistungselektronik in K
% -> Temperatur der Umgebungsluft um die Leistungselektronik kann zur normalen Temperatur der Umgebungsluft verändert sein

% -> Die Wärmeübertragungsfähigkeiten sind für 1 Leistungselektronik voreingestellt
% -> Da es nur max. 1 Leistungselektronik geben kann, können keine Wärmeübertragungsfähigkeiten der Leistungselektronik/Case der MOSFET bzgl. der Umgebungsluft und der Leistungselektronik/Case der MOSFET bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der Leistungselektronik mit einem Index > 1 festgelegt werden
% -> Für die Breakpoints sollten immer die Grenzen 0 (= Minimalwert) und Maximalwert verwendet werden, weil bei den Lookup Tables nicht extrapoliert wird, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet wird
UA_c_Umgebung_Break_v_Fahrzeug{1}=[0,max(v_Fahrzeug.Data)/3.6];             % Die Wärmeübertragungsfähigkeit der Leistungselektronik/Case der MOSFET bzgl. der Umgebungsluft ist abh. von der Fahrzeuggeschwindigkeit in m/s
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_v_Fahrzeug
UA_c_Umgebung_Table{1}=vehicle.UA_c_Umgebung_Table;                        % Die Wärmeübertragungsfähigkeit der Leistungselektronik/Case der MOSFET bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K
   
UA_c_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table))]; % Die Wärmeübertragungsfähigkeit der Leistungselektronik/Case der MOSFET bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der Leistungselektronik ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 1
% UA_c_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf))]; % Die Wärmeübertragungsfähigkeit der Leistungselektronik/Case der MOSFET bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der Leistungselektronik ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 0
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_PV_Kuehlfluessigkeit
% -> Im folgenden Table müssen die Werte für die Wärmeübertragungsfähigkeit der Leistungselektronik/Case der MOSFET bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik angegeben werden
UA_c_Kuehlfluessigkeit_Table{1}=vehicle.UA_c_Fluid_Table;                  % Die Wärmeübertragungsfähigkeit der Leistungselektronik/Case der MOSFET bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K

n_MOSFET=vehicle.n_MOSFET;                                                 % Anzahl an MOSFET

R_1=0.245;                                                                  % Wärmeleitwiderstand des ersten RC-Glieds eines Halbleiterbauelements in K/W
R_2=0.155;                                                                  % Wärmeleitwiderstand des zweiten RC-Glieds eines Halbleiterbauelements in K/W
R_j_c=(R_1+R_2)/n_MOSFET;                                                   % Wärmeleitwiderstand zwischen den Substraten und der unteren Oberfläche der Case der MOSFET in Parallelschaltung in K/W (-> Case der MOSFET nicht mit eingeschlossen)

d_c=0.03;                                                                   % Dicke der Case der MOSFET in Parallelschaltung (Aluminium) in m
lambda_c=238.4;                                                             % Wärmeleitfähigkeit der Case der MOSFET in Parallelschaltung (Aluminium) in W/(m*K)
A_c=0.064;                                                                  % Fläche der Case der MOSFET in Parallelschaltung (Aluminium) in m^2 -> A=l*b -> Es handelt sich um die Fläche aller Gehäuse der parallel geschalteten MOSFET zusammen, weil diese zusammen als Blockkapazität aufgefasst werden
R_c=d_c/(lambda_c*A_c);                                                     % Wärmeleitwiderstand der Case der MOSFET in Parallelschaltung in Richtung der Verdickung (Aluminium) in K/W -> Seriell geschaltet zu R_j_c, weil bei R_j_c die Case der MOSFET nicht miteingeschlossen sind

tau_1=0.0059149;                                                            % Zeitkonstante des ersten RC-Glieds eines Halbleiterbauelementes in s
tau_2=0.0006322;                                                            % Zeitkonstante des zweiten RC-Glieds eines Halbleiterbauelementes in s
C_1=tau_1/R_1;                                                              % Wärmekapazität des ersten RC-Glieds eines Halbleiterbauelementes in J/K
C_2=tau_2/R_2;                                                              % Wärmekapazität des zweiten RC-Glieds eines Halbleiterbauelementes in J/K
C_j=(C_1+C_2)/2*n_MOSFET;                                                   % Wärmekapazität der Substrate der MOSFET in Parallelschaltung in J/K -> Die Wärmekapazität des Substrates eines MOSFET wird über den Mittelwert von C_1 und C_2 abgeschätzt

rho_c=2700;                                                                 % Dichte der Case der MOSFET in Parallelschaltung (Aluminium) in kg/m^3
c_c=945;                                                                    % Spezifische Wärmekapazität der Case der MOSFET in Parallelschaltung (Aluminium) in J/(kg*K)
C_c=rho_c*A_c*d_c*c_c;                                                      % Wärmekapazität der Case der MOSFET in Parallelschaltung (Aluminium) in J/K

%% Parameter Subsystem "Batteriepack"

% -> Im verwendeten Antriebsstrangmodell wird genau mit 1 Batteriepack gerechnet
% -> Deswegen existiert in dieser Version des Thermonagementsystemmodells genau 1 Batteriepack
% -> Das Batteriepack kann wahlweise in einen Kühlkreislauf integriert werden
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 Batteriepack vorhanden sein

% -> Das Batteriepack wird als Blockkapazität aufgefasst (-> Annahme: kein Temperaturgradient innerhalb des Batteriepacks -> einzelene Zellen weisen identische Temperatur auf)
% -> Annahme: Das Batteriepack besteht aus komplett identischen Zellen
% -> Annahme: Das Batteriepack besteht aus NCR18650PF-Zellen (zylindrische Lithium-Ionen-Zelle)
% -> Deswegen ist das Batteriepack derart modelliert, dass dass nur eine Zelle elektrisch berechnet wird und basierend auf den resultierenden Zellgrößen die Batteriepackgrößen bestimmt werden
% -> Dazu ist ein Zellmodell aus dem am FTM vorhandenen Batteriepackmodell, das im Rahmen der Semesterarbeit "Modellbasierte Entwicklung eines vollparametrischen Batteriepackmodells für Elektro- und Hybridfahrzeuge" entwickelt wurde, abgeleitet

% -> Das Batteriepack besitzt eine eigene Temperatur und wird als diabat zu seiner Umgebung betrachtet
% -> Es gibt also einen Wärmeaustausch zwischen Batteriepack und Umgebungsluft
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. von dem Luftstrom, mit dem das Batteriepack beaufschlagt wird
% -> Dieser Luftstrom kann kaum gemessen werden, resultiert aber aus v_Fahrzeug
% -> Bei Straßenfahrt resultiert aufgrund v_Fahrzeug eine relative Luftgeschwindigkeit -> Das Batteriepack kann wegen dieser relativen Luftgeschwindigkeit je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Auf einem Rollenprüfstand resultieren aufgrund v_Fahrzeug Luftverwirbelungen, z.B. durch die Bewegung der Räder -> Das Batteriepack kann wegen dieser Luftverwirbelungen je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Über die Höhe der Wärmeübertragungsfähigkeit UA bezogen auf v_Fahrzeug kann eingestellt werden, wie stark die E-Maschine angeströmt wird (Einbauort: frei anströmbar vs. abgedeckt; Betrieb: Straßenfahrt vs. Rollenprüfstand)
% -> Zudem gibt es einen Wärmeaustausch zwischen Batteriepack und Kühlflüssigkeit
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. vom Volumenstrom der Kühlflüssigkeit
% -> Wärmeübertragungsfähigkeit UA = Wärmedurchgangskoeffizient U * Wärmeübertragungsfläche A

%--------------------------------------------------------------------------
% Definition allgemeiner Parameter
%--------------------------------------------------------------------------

P_Nebenverbraucher=vehicle.P_Nebenverbraucher;                             % Leistungsanforderung der Nebenverbraucher des Fahrzeugs in W

p_Zelle=vehicle.p_Zelle;                                                   % Anzahl an parallel verschalteten Zellen im Batteriepack
s_Zelle=vehicle.s_Zelle;                                                   % Anzahl an seriell verschalteten Zellen im Batteriepack
n_Zelle=p_Zelle*s_Zelle;                                                    % Anzahl an Zellen im Batteriepack

SOC_init=vehicle.SOC_init;                                                 % Initialer SOC einer Zelle
U_Hysterese_init=0;                                                         % Initiale Hysteresespannung einer Zelle in V
U_RC1_init=0;                                                               % Initiale Spannung am ersten RC-Glied einer Zelle in V
U_RC2_init=0;                                                               % Initiale Spannung am zweiten RC-Glied einer Zelle in V
% -> Initiales Potential einer Zelle = U_SOC_init (= f(SOC_init)) + U_Hysterese_init + U_RC1_init + U_RC2_init

load('BatData_NCR18650PF');                                                 % Laden von Parameter der NCR18650PF-Zelle (zylindrische Lithium-Ionen-Zelle)
% -> Beinhaltet die Daten für alle verwendeten Lookup Tables in Thermomanagementsystemmodell/Thermomanagementsystem/Batteriepack/Batteriepack(1) elektrisch/Zelle elektrisch (abgeleitet aus Batteriepackmodell -> siehe FTM)
% -> Beinhaltet die verwendete Nennkapazität und den verwendeten Hystereseparamter der vermessenen NCR18650PF-Zelle
clearvars BatState_Init;                                                    % BatState_Init wird nicht benötigt, weil die Initialzustände oben manuell festgelegt werden

%--------------------------------------------------------------------------
% Definition thermischer Paramater
%--------------------------------------------------------------------------

T_Batteriepack_init=T_init;                                              % Initialtemperatur des Batteriepacks in K

T_Offset_Batteriepack=0;                                                    % Offset zur Temperatur der Umgebungsluft beim Batteriepack in K
% -> Temperatur der Umgebungsluft um das Batteriepack kann zur normalen Temperatur der Umgebungsluft verändert sein

% -> Die Wärmeübertragungsfähigkeiten sind für 1 Batteriepack voreingestellt
% -> Da es nur maximal 1 Batteriepack geben kann, können keine Wärmeübertragungsfähigkeiten des Batteriepacks bzgl. der Umgebungsluft und des Batteriepacks bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Batteriepacks mit einem Index > 1 festgelegt werden
% -> Für die Breakpoints sollten immer die Grenzen 0 (= Minimalwert) und Maximalwert verwendet werden, weil bei den Lookup Tables nicht extrapoliert wird, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet wird
UA_Batteriepack_Umgebung_Break_v_Fahrzeug{1}=[0,max(v_Fahrzeug.Data)/3.6];  % Die Wärmeübertragungsfähigkeit des Batteriepacks bzgl. der Umgebungsluft ist abh. von der Fahrzeuggeschwindigkeit in m/s
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_v_Fahrzeug
UA_Batteriepack_Umgebung_Table{1}=vehicle.UA_Batteriepack_Umgebung_Table;  % Die Wärmeübertragungsfähigkeit des Batteriepacks bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K

UA_Batteriepack_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table))]; % Die Wärmeübertragungsfähigkeit des Batteriepacks bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet des Batteriepacks ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 1
% UA_Batteriepack_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf))]; % Die Wärmeübertragungsfähigkeit des Batteriepacks bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet des Batteriepacks ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 0
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_PV_Kuehlfluessigkeit
% -> Im folgenden Table müssen die Werte für die Wärmeübertragungsfähigkeit des Batteriepacks bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Batteriepacks angegeben werden
UA_Batteriepack_Kuehlfluessigkeit_Table{1}=vehicle.UA_Batteriepack_Fluid_Table; % Die Wärmeübertragungsfähigkeit des Batteriepacks bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Batteriepacks in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K

m_Zelle=vehicle.m_Zelle;                                                   % Masse einer NCR18650PF-Zelle in kg -> Laut Datenblatt = 48 g
c_Zelle=450;                                                                % Spezifische Wärmekapazität einer 18650-Zelle in J/(kg*K) -> Die spezifische Wärmekapazität einer 18650-Zelle wird in einem am FTM vorhandenen MATLAB-Modell zu Ausgleichsströmen (-> thermal_model) zu 700 J/(kg*K) angenommen -> In "Jossen, Andreas; Weydanz, Wolfgang: Moderne Akkumulatoren richtig einsetzen" wird auch von einer konstanten (legitim, weil Temperaturdifferenzen relativ gering) spezifischen Wärmekapazität einer Lithium-Ionen-Zelle zu 700 J/(kg*K) ausgegangen    
C_Batteriepack=n_Zelle*m_Zelle*c_Zelle;                                     % Wärmekapazität des Batteriepacks in J/K

%% Parameter Subsystem "Ladegeraet"

% -> Im verwendeten Antriebsstrangmodell wird genau mit 1 Ladegeraet gerechnet
% -> Deswegen existiert in dieser Version des Thermonagementsystemmodells genau 1 Ladegeraet
% -> Das Ladegeraet kann wahlweise in einen Kühlkreislauf integriert werden
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 Ladegeraet vorhanden sein

% -> Das Ladegeraet wird als Blockkapazität aufgefasst (-> Annahme: kein Temperaturgradient innerhalb des Ladegeraets)

% -> Das Ladegeraet besitzt eine eigene Temperatur und wird als diabat zu seiner Umgebung betrachtet
% -> Es gibt also einen Wärmeaustausch zwischen Ladegeraet und Umgebungsluft
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. von dem Luftstrom, mit dem das Ladegeraet beaufschlagt wird
% -> Dieser Luftstrom kann kaum gemessen werden, resultiert aber aus v_Fahrzeug
% -> Bei Straßenfahrt resultiert aufgrund v_Fahrzeug eine relative Luftgeschwindigkeit -> Das Ladegeraet kann wegen dieser relativen Luftgeschwindigkeit je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Auf einem Rollenprüfstand resultieren aufgrund v_Fahrzeug Luftverwirbelungen, z.B. durch die Bewegung der Räder -> Das Ladegeraet kann wegen dieser Luftverwirbelungen je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Über die Höhe der Wärmeübertragungsfähigkeit UA bezogen auf v_Fahrzeug kann eingestellt werden, wie stark die E-Maschine angeströmt wird (Einbauort: frei anströmbar vs. abgedeckt; Betrieb: Straßenfahrt vs. Rollenprüfstand)
% -> Zudem gibt es einen Wärmeaustausch zwischen Ladegeraet und Kühlflüssigkeit
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. vom Volumenstrom der Kühlflüssigkeit
% -> Wärmeübertragungsfähigkeit UA = Wärmedurchgangskoeffizient U * Wärmeübertragungsfläche A

%--------------------------------------------------------------------------
% Definition allgemeiner Parameter
%--------------------------------------------------------------------------

load('charger_parameters.mat');                                                     % Laden von Parameter des Ladegeraets
% -> Beinhaltet die Daten für den Ladestrom abhängig von der aktuellen Batteriespannung und des aktuellen SOC
% -> Beinhaltet den Wirkungsgrad des Ladegeraets

%--------------------------------------------------------------------------
% Definition thermischer Paramater
%--------------------------------------------------------------------------

T_Ladegeraet_init=T_init;                                                 % Initialtemperatur des Ladegeraets in K

T_Ladegeraet_Offset=0;                                                      % Offset zur Temperatur der Umgebungsluft beim Ladegeraet in K
% -> Temperatur der Umgebungsluft um das Ladegeraet kann zur normalen Temperatur der Umgebungsluft verändert sein

% -> Die Wärmeübertragungsfähigkeiten sind für 1 Ladegeraet voreingestellt
% -> Da es nur maximal 1 Ladegeraet geben kann, können keine Wärmeübertragungsfähigkeiten des Ladegeraets bzgl. der Umgebungsluft und des Ladegeraets bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Ladegeraets mit einem Index > 1 festgelegt werden
% -> Für die Breakpoints sollten immer die Grenzen 0 (= Minimalwert) und Maximalwert verwendet werden, weil bei den Lookup Tables nicht extrapoliert wird, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet wird
UA_Ladegeraet_Umgebung_Break_v_Fahrzeug{1}=[0,max(v_Fahrzeug.Data)/3.6];    % Die Wärmeübertragungsfähigkeit des Ladegeraets bzgl. der Umgebungsluft ist abh. von der Fahrzeuggeschwindigkeit in m/s
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_v_Fahrzeug
UA_Ladegeraet_Umgebung_Table{1}=vehicle.UA_Ladegeraet_Umgebung_Table;      % Die Wärmeübertragungsfähigkeit des Ladegeraets bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K

UA_Ladegeraet_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table))]; % Die Wärmeübertragungsfähigkeit des Ladegeraets bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet des Ladegeraets ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 1
% UA_Ladegeraet_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf))]; % Die Wärmeübertragungsfähigkeit des Ladegeraets bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet des Ladegeraets ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 0
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_PV_Kuehlfluessigkeit
% -> Im folgenden Table müssen die Werte für die Wärmeübertragungsfähigkeit des Ladegeraets bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Ladegeraets angegeben werden
UA_Ladegeraet_Kuehlfluessigkeit_Table{1}=vehicle.UA_Ladegeraet_Fluid_Table; % Die Wärmeübertragungsfähigkeit des Ladegeraets bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Ladegeraets in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K
 
m_Ladegeraet=vehicle.m_Ladegeraet;                                         % Masse des Ladegeraets in kg
c_Ladegeraet=450;                                                           % Spezifische Waermekapazitaet des Ladegeraets J/(kg*K)
C_Ladegeraet=m_Ladegeraet*c_Ladegeraet;                                     % Waermekapazitaet des Ladegeraets in J/K


%% Parameter Subsystem "Thermischer Speicher (PCM)"

% -> Im Thermonagementsystemmodell ist eine beliebige Anzahl an Thermischen Speichern (PCM) möglich

% -> Der Thermische Speicher (PCM) wird als Blockkapazität aufgefasst (-> Annahme: kein Temperaturgradient innerhalb des Thermischen Speichers (PCM))

% -> Der thermische Speicher (PCM) besitzt eine eigene Temperatur und wird als diabat zu seiner Umgebung betrachtet
% -> Es gibt also einen Wärmeaustausch zwischen thermischen Speicher (PCM) und Umgebungsluft
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. von dem Luftstrom, mit dem das Ladegeraet beaufschlagt wird
% -> Dieser Luftstrom kann kaum gemessen werden, resultiert aber aus v_Fahrzeug
% -> Bei Straßenfahrt resultiert aufgrund v_Fahrzeug eine relative Luftgeschwindigkeit -> Der thermische Speicher (PCM) kann wegen dieser relativen Luftgeschwindigkeit je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Auf einem Rollenprüfstand resultieren aufgrund v_Fahrzeug Luftverwirbelungen, z.B. durch die Bewegung der Räder -> Der thermische Speicher (PCM) kann wegen dieser Luftverwirbelungen je nach Einbauort mehr oder weniger mit einem Luftstrom beaufschlagt werden
% -> Über die Höhe der Wärmeübertragungsfähigkeit UA bezogen auf v_Fahrzeug kann eingestellt werden, wie stark der thermische Speicher (PCM) angeströmt wird (Einbauort: frei anströmbar vs. abgedeckt; Betrieb: Straßenfahrt vs. Rollenprüfstand)
% -> Zudem gibt es einen Wärmeaustausch zwischen thermischen Speicher und Kühlflüssigkeit
% -> Die Wärmeübertragungsfähigkeit UA dieses Wärmeaustausches ist abh. vom Volumenstrom der Kühlflüssigkeit
% -> Wärmeübertragungsfähigkeit UA = Wärmedurchgangskoeffizient U * Wärmeübertragungsfläche A

%--------------------------------------------------------------------------
% Definition allgemeiner Parameter
%--------------------------------------------------------------------------
PCM(1)=class_component_PCM;                                                      % Objektzuordnung zur Klasse
PCM(1).unterer_Grenzwert_Phasenwechsel=273.15+58;                           % unterer Grenzwert des Phasenuebergangs
PCM(1).oberer_Grenzwert_Phasenwechsel=273.15+60;                            % oberer Grenzwert des Phasenuebergangs
PCM(1).dT_Faktor_Phasenwechsel=0.1;                                         % Anteil der Gesamtenthalpie, die im Phasenwechselbereich für den weiteren Themperaturanstieg zur verfügung steht
PCM(1).Aktivierbar=1;                                                       % Ist der thermische Speicher (PCM) aktivierbar? Ja=1 / Nein=0
PCM(1).Phasenumwandlung_vollstaendig=273.15+83;                             % Im Falle eines aktivierbaren thermischen Speichers (PCM) ist dies der Temperaturgrenzwert, ab dem das Material komplett umgewandelt wurde und die Phase stabil ist.
PCM(1).Zustand_init=1;                                                      % Im Falle des aktivierbaren thermischen Speichers (PCM) stellt dies den Zustand zu Beginn dar: bereits vollstaendig umgewandelt (1), nicht vollstaendig umgewandelt (0)

PCM(2)=class_component_PCM;                                                      % Objektzuordnung zur Klasse
PCM(2).unterer_Grenzwert_Phasenwechsel=273.15+40;                           % unterer Grenzwert des Phasenuebergangs
PCM(2).oberer_Grenzwert_Phasenwechsel=273.15+44;                            % oberer Grenzwert des Phasenuebergangs
PCM(2).dT_Faktor_Phasenwechsel=0.0424;                                      % Anteil der Gesamtenthalpie, die im Phasenwechselbereich für den weiteren Themperaturanstieg zur verfügung steht
PCM(2).Aktivierbar=0;                                                       % Ist der thermische Speicher (PCM) aktivierbar? Ja=1 / Nein=0
PCM(2).Phasenumwandlung_vollstaendig=0;                                     % Im Falle eines aktivierbaren thermischen Speichers (PCM) ist dies der Temperaturgrenzwert, ab dem das Material komplett umgewandelt wurde und die Phase stabil ist.
PCM(2).Zustand_init=0;                                                      % Im Falle des aktivierbaren thermischen Speichers (PCM) stellt dies den Zustand zu Beginn dar: bereits vollstaendig umgewandelt (1), nicht vollstaendig umgewandelt (0)

%--------------------------------------------------------------------------
% Definition thermischer Paramater
%--------------------------------------------------------------------------

T_PCM_init{1}=T_init;                                                    % Initialtemperatur des thermischen Speichers (PCM) in K
T_PCM_init{2}=T_init;                                                    % Initialtemperatur des thermischen Speichers (PCM) in K

T_PCM_Offset{1}=0;                                                          % Offset der Temperatur um den thermischen Speicher (PCM) im Vergleich zur Umgebungstemperatur in K 
T_PCM_Offset{2}=0;                                                          % Offset der Temperatur um den thermischen Speicher (PCM) im Vergleich zur Umgebungstemperatur in K 

PCM_Trigger{1}=[0,1;t_Simulation,1];                                        % Im Falle des aktivierbaren thermischen Speichers (PCM) stellt dies den Zeitpunkt des Auslösens dar, Spalte 1 = Zeit, Spalte 2 = State
PCM_Trigger{2}=[0,0;t_Simulation,0];                                        % Im Falle des aktivierbaren thermischen Speichers (PCM) stellt dies den Zeitpunkt des Auslösens dar, Spalte 1 = Zeit, Spalte 2 = State

% -> Die Wärmeübertragungsfähigkeiten sind für 1 thermischen Speicher (PCM) voreingestellt
% -> Falls n thermische Speicher (PCM) vorhanden sind, muss die Wärmeübertragungsfähigkeit für jeden thermischen Speicher (PCM) einzeln festgelegt werden und aufsteigend mit einem Index nummeriert werden
% -> Nummerierung: UA_PCM...{i} mit i=1:n
% -> Für die Breakpoints sollten immer die Grenzen 0 (= Minimalwert) und Maximalwert verwendet werden, weil bei den Lookup Tables nicht extrapoliert wird, sondern bei Eingangsgrößen außerhalb der Range der Breakpoints immer die entsprechende Grenze der Breakpoints verwendet wird

UA_PCM_Umgebung_Break_v_Fahrzeug{1}=[0,max(v_Fahrzeug.Data)/3.6];           % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Umgebungsluft ist abh. von der Fahrzeuggeschwindigkeit in m/s
UA_PCM_Umgebung_Break_v_Fahrzeug{2}=[0,max(v_Fahrzeug.Data)/3.6];           % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Umgebungsluft ist abh. von der Fahrzeuggeschwindigkeit in m/s
% -> Erklärung zum Table: Zeilen beziehen sich auf Break_v_Fahrzeug
UA_PCM_Umgebung_Table{1}=[1;50];                    % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K
UA_PCM_Umgebung_Table{2}=[1;50];                    % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Umgebungsluft in Abh. von der Fahrzeuggeschwindigkeit in W/K

UA_PCM_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table))]; % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet des thermischen Speichers (PCM) ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 1
% UA_PCM_FinitesVolumen_Break_PV_Kuehlfluessigkeit{1}=[0,max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf))]; % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet des thermischen Speichers (PCM) ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 0
UA_PCM_FinitesVolumen_Break_PV_Kuehlfluessigkeit{2}=[0,max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table))]; % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet des thermischen Speichers (PCM) ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 1
% UA_PCM_FinitesVolumen_Break_PV_Kuehlfluessigkeit{2}=[0,max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf))]; % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet des thermischen Speichers (PCM) ist abh. vom Volumenstrom der Kühlflüssigkeit in m^3/s -> Definition für Steuerung_Pumpe = 0

% -> Erklärung zum Table: Zeilen beziehen sich auf Break_PV_Kuehlfluessigkeit
% -> Im folgenden Table müssen die Werte für die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des thermischen Speichers (PCM) angegeben werden
UA_PCM_Kuehlfluessigkeit_Table{1}=[15;100];              % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des thermischen Speichers (PCM) in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K
UA_PCM_Kuehlfluessigkeit_Table{2}=[15;100];              % Die Wärmeübertragungsfähigkeit des thermischen Speichers (PCM) bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des thermischen Speichers (PCM) in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K

m_PCM{1}=6.648;                                                             % Masse des thermischen Speichers (PCM) in kg
c_PCM{1}=2000;                                                              % Spezifische Waermekapazitaet thermischen Speichers (PCM) J/(kg*K)
C_PCM{1}=m_PCM{1}*c_PCM{1};                                                 % Waermekapazitaet des thermischen Speichers (PCM) in J/K
m_PCM{2}=6.648;                                                             % Masse des thermischen Speichers (PCM) in kg
c_PCM{2}=2000;                                                              % Spezifische Waermekapazitaet des thermischen Speichers (PCM) J/(kg*K)
C_PCM{2}=m_PCM{2}*c_PCM{2};                                                 % Waermekapazitaet des thermischen Speichers (PCM) in J/K


%% Parameter Subsystem "Thermoelektrische Wärmepumpe (Peltier)"

% -> Im Thermonagementsystemmodell ist eine beliebige Anzahl an Thermischen Speichern (PCM) möglich

% -> Die thermoelektrische Waermepumpe (Peliter) hat keine Masse (-> Annahme: keine Wärmekapazitaet und keine Temperatur)

% -> Die thermoelektrische Waermepumpe (Peltier) besitzt keine eigene Temperatur
% -> Es gibt also keinen Wärmeaustausch zwischen thermoelektrischer Waermepumpe (Peltier) und Umgebungsluft
% -> Die Kuehl- oder Heizleistung wird mithilfe der Lookup Tables in Thermomanagementsystemmodell/Thermomanagementsystem/Peltier/Peltier(i) elektrisch bestimmt und komplett an die Kühlflüssigkeit übertragen
% -> Die dafür notwendige elektrische Leistung wird aus dem Batteriepack entnommen
% -> Es existiert kein Wert für die Wärmeübertragungsfähigkeit UA

%--------------------------------------------------------------------------
% Definition allgemeiner Parameter
%--------------------------------------------------------------------------

load('Peltier_TEC1-12706.mat');                                             % Laden von Parameter der thermoelektrischen Wärmepumpe (Peltierelement) TEC1-12706
% -> Beinhaltet die Daten für alle verwendeten Lookup Tables in Thermomanagementsystemmodell/Thermomanagementsystem/Peltier/Peltier(i) elektrisch

Steuerung_Peltier = [0,-1;1000,-1;1001,0;t_Simulation,0];                   % Zeitliche aktivierung des Petier-Elements -> Spalte 1 = Zeit, Spalte 2 = (wärmen = 1 / kühlen = -1 / inaktiv = 0)
Anzahl_Peltierelemente=10;                                                  % Anzahl der verbauten Peltierelemente
Peltier_Max_Eff=-1;                                                          % Peltier-Element im Modus maximaler Waerme-/ Kältestrom (Wert = 1) oder effektiver Waermepumpenbereich (Wert = -1)

%--------------------------------------------------------------------------
% Definition thermischer Paramater
%--------------------------------------------------------------------------

% -> Die thermoelektrische Waermepumpe (Peliter) hat keine Masse und daraus folgend keine Wärmekapazitaet und keine Temperatur
% -> Die komplette Kühl- oder Heizleistung wird an das Kühlwasser übergeben
% -> Es existiert kein Wert für die Wärmeübertragungsfähigkeit UA

%% Parameter Subsystem "Schlauch"

% -> Im Thermonagementsystemmodell ist eine beliebige Anzahl an Schläuchen möglich

% -> Ein Schlauch besitzt keine eigene Temperatur und wird als adiabat zu seiner Umgebung betrachtet
% -> Es gibt also keinen Wärmeaustausch zwischen Umgebungsluft und Kühlflüssigkeit
% -> Ein Schlauch besitzt zudem nur 1 Strömungsgebiet bzw. 1 Kühlflüssigkeit
% -> Deshalb existiert bei einem Schlauch kein Wärmeaustausch zwischen der Kühlflüssigkeit im Strömungsgebiet und ihrer Umgebung
% -> Es muss keine Wärmeübertragungsfähigkeit festgelegt werden

%% II. Fehler beim Setup des Thermomanagementsystemmodells

%--------------------------------------------------------------------------
% Fehler bei der Definition eines Fluid_Waermetauscher
%--------------------------------------------------------------------------

% -> Fluid_Waermetauscher(1,i) und Fluid_Waermetauscher(2,i) gehören zum gleichen Wärmetauscher i
% -> Deswegen müssen in Fluid_Waermetauscher immer 2 Zeilen existieren, sobald mindestens 1 Wärmetauscher vorhanden ist
% -> Deswegen müssen pro Wärmetauscher i immer Fluid_Waermetauscher(1,i) und Fluid_Waermetauscher(2,i) definiert sein (geprüft an der 2. Angabe Nr_Kuehlkreislauf ~= 0, weil die 1. Angabe Art_Waermetauscher in der nächsten Prüfung verwendet wird)
% -> Deswegen muss Angabe Art_Waermetauscher der beiden Fluid_Waermetauscher identisch sein
% -> Deswegen muss Angabe l_Kuehlfluessigkeit der beiden Fluid_Waermetauscher identisch sein, dass die Anzahl an finiten Volumen in beiden Strömungsgebieten des Wärmetauschers übereinstimmt und sich somit genau gegenüberstehen -> Bedingung für die Berechnung des Wärmeaustausches im Wärmetauscher
% -> Angabe Art_Waermetauscher darf auch nicht 0 sein, sondern muss entweder 1 (Gleichstromwärmetauscher) oder -1 (Gegenstromwärmetauscher) sein

if exist('Fluid_Waermetauscher')==1
   for i=1:size(Fluid_Waermetauscher,2)
       if size(Fluid_Waermetauscher,1)~=2
          fprintf('\nFür mindestens einen Wärmetauscher sind nicht, wie gefordert, genau zwei Fluid_Waermetauscher vorhanden!\n');
          keyboard;
       end
       if Fluid_Waermetauscher(1,i).Nr_Kuehlkreislauf==0||Fluid_Waermetauscher(2,i).Nr_Kuehlkreislauf==0
          fprintf('\nFür mindestens einen Wärmetauscher sind nicht, wie gefordert, genau zwei Fluid_Waermetauscher definiert!\n');
          keyboard;
       end
       if Fluid_Waermetauscher(1,i).Art_Waermetauscher~=Fluid_Waermetauscher(2,i).Art_Waermetauscher
          fprintf('\nAngabe Art_Waermetauscher in den beiden Fluid_Waermetauscher eines Wärmetauschers stimmt nicht überein!\n');
          keyboard;
       end
       if Fluid_Waermetauscher(1,i).l_Kuehlfluessigkeit~=Fluid_Waermetauscher(2,i).l_Kuehlfluessigkeit
          fprintf('\nAngabe l_Kuehlfluessigkeit in den beiden Fluid_Waermetauscher eines Wärmetauschers stimmt nicht überein!\n');
          keyboard;
       end
       if Fluid_Waermetauscher(1,i).Art_Waermetauscher~=1&&Fluid_Waermetauscher(1,i).Art_Waermetauscher~=-1
          fprintf('\nFür mindestens einen Wärmetauscher ist die Angabe Art_Waermetauscher in den beiden Fluid_Waermetauscher nicht korrekt (Art_Waermetauscher muss 1 oder -1 sein)!\n');
          keyboard;
       end
   end
end

%--------------------------------------------------------------------------
% Angabe l_Kuehlfluessigkeit in einer Fluid_Komponente ist kein Vielfaches von l_FinitesVolumen
%--------------------------------------------------------------------------

if exist('Fluid_Kuehler')==1
   for i=1:size(Fluid_Kuehler,2)
       if mod(Fluid_Kuehler(i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einem Fluid_Kuehler ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Waermetauscher')==1
   for i=1:size(Fluid_Waermetauscher,2)
       if mod(Fluid_Waermetauscher(1,i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einem Fluid_Waermetauscher ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

if exist('Fluid_EMaschine')==1
   for i=1:size(Fluid_EMaschine,2)
       if mod(Fluid_EMaschine(1,i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einer Fluid_EMaschine ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Leistungselektronik')==1
   for i=1:size(Fluid_Leistungselektronik,2)
       if mod(Fluid_Leistungselektronik(1,i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einer Fluid_Leistungselektronik ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Batteriepack')==1
   for i=1:size(Fluid_Batteriepack,2)
       if mod(Fluid_Batteriepack(1,i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einem Fluid_Batteriepack ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Ladegeraet')==1
   for i=1:size(Fluid_Ladegeraet,2)
       if mod(Fluid_Ladegeraet(1,i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einem Fluid_Ladegeraet ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

if exist('Fluid_PCM')==1
   for i=1:size(Fluid_PCM,2)
       if mod(Fluid_PCM(1,i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einem Fluid_PCM ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Peltier')==1
   for i=1:size(Fluid_Peltier,2)
       if mod(Fluid_Peltier(1,i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einem Fluid_Peltier ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Schlauch')==1
   for i=1:size(Fluid_Schlauch,2)
       if mod(Fluid_Schlauch(1,i).l_Kuehlfluessigkeit,l_FinitesVolumen)~=0
          fprintf('\nAngabe l_Kuehlfluessigkeit in einem Fluid_Schlauch ist kein Vielfaches von l_FinitesVolumen!\n');
          keyboard;
       end
   end
end

%--------------------------------------------------------------------------
% Fehler bei der Anzahl an Fluid_EMaschine, Fluid_Leistungselektronik, Fluid_Batteriepack
%--------------------------------------------------------------------------

% -> In dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebsstrangmodell genau mit 1 E-Maschine, 1 Leistungselektronik, 1 Batteriepack und 1 Ladegeraet gerechnet
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 E-Maschine, max. 1 Leistungselektronik, max. 1 Batteriepack und max. 1 Ladegeraet vorhanden sein
% -> Da die Komponenten durch die Fluid_Komponenten festgelegt werden, kann max. 1 Fluid_Maschine, max. 1 Fluid_Leistungselektronik, max. 1 Fluid_Batteriepack und max. 1 Fluid_Ladegeraet vorhanden sein

if exist('Fluid_EMaschine')==1                                              
   if size(Fluid_EMaschine,2)>1
      fprintf('\nIn dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebsstrangmodell genau mit einer E-Maschine gerechnet. Deswegen kann im simulierten Thermomanagementsystem maximal eine E-Maschine bzw. Fluid_EMaschine vorhanden sein!\n');
      keyboard;
    end
end

if exist('Fluid_Leistungselektronik')==1                                              
   if size(Fluid_Leistungselektronik,2)>1
      fprintf('\nIn dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebsstrangmodell genau mit einer Leistungselektronik gerechnet. Deswegen kann im simulierten Thermomanagementsystem maximal eine Leistungselektronik bzw. Fluid_Leistungselektronik vorhanden sein!\n');
      keyboard;
    end
end

if exist('Fluid_Batteriepack')==1                                              
   if size(Fluid_Batteriepack,2)>1
      fprintf('\nIn dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebsstrangmodell genau mit einem Batteriepack gerechnet. Deswegen kann im simulierten Thermomanagementsystem maximal ein Batteriepack bzw. Fluid_Batteriepack vorhanden sein!\n');
      keyboard;
    end
end

if exist('Fluid_Ladegeraet')==1                                              
   if size(Fluid_Ladegeraet,2)>1
      fprintf('\nIn dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebsstrangmodell genau mit einem Ladegeraet gerechnet. Deswegen kann im simulierten Thermomanagementsystem maximal ein Ladegeraet bzw. Fluid_Ladegeraet vorhanden sein!\n');
      keyboard;
    end
end
%--------------------------------------------------------------------------
% Index von Konfig_Kuehlkreislauf, in dem eine Fluid_Komponente konfiguriert ist, stimmt nicht mit der Angabe Nr_Kuehlkreislauf in dieser Fluid_Komponente überein
%--------------------------------------------------------------------------

for i=1:n_Kuehlkreislauf
    for j=1:size(Graph_Kuehlkreislauf{i}.Nodes,1)
        if eval([Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},'.Nr_Kuehlkreislauf'])~=i
           fprintf('\nIndex von Konfig_Kuehlkreislauf, in dem eine Fluid_Komponente konfiguriert ist, stimmt nicht mit der Angabe Nr_Kuehlkreislauf in dieser Fluid_Komponente überein!\n');
           keyboard;
        end
    end
end

%--------------------------------------------------------------------------
% Definierte Fluid_Komponente ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in dieser Fluid_Komponente) von Konfig_Kuehlkreislauf konfiguriert
%--------------------------------------------------------------------------

if exist('Fluid_Kuehler')==1
   for i=1:size(Fluid_Kuehler,2)
       if strcmp(['Fluid_Kuehler(',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_Kuehler(i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEin definierter Fluid_Kuehler ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in diesem Fluid_Kuehler) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Waermetauscher')==1
   for i=1:size(Fluid_Waermetauscher,2)
       if strcmp(['Fluid_Waermetauscher(1,',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_Waermetauscher(1,i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEin definierter Fluid_Waermetauscher ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in diesem Fluid_Waermetauscher) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
       if strcmp(['Fluid_Waermetauscher(2,',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_Waermetauscher(2,i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEin definierter Fluid_Waermetauscher ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in diesem Fluid_Waermetauscher) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end

if exist('Fluid_EMaschine')==1
   for i=1:size(Fluid_EMaschine,2)
       if strcmp(['Fluid_EMaschine(',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_EMaschine(i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEine definierte Fluid_EMaschine ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in dieser Fluid_EMaschine) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Leistungselektronik')==1
   for i=1:size(Fluid_Leistungselektronik,2)
       if strcmp(['Fluid_Leistungselektronik(',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_Leistungselektronik(i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEine definierte Fluid_Leistungselektronik ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in dieser Fluid_Leistungselektronik) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Batteriepack')==1
   for i=1:size(Fluid_Batteriepack,2)
       if strcmp(['Fluid_Batteriepack(',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_Batteriepack(i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEin definierter Fluid_Batteriepack ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in diesem Fluid_Batteriepack) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Ladegeraet')==1
   for i=1:size(Fluid_Ladegeraet,2)
       if strcmp(['Fluid_Ladegeraet(',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_Ladegeraet(i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEin definierter Fluid_Ladegeraet ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in diesem Fluid_Ladegeraet) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end

if exist('Fluid_PCM')==1
   for i=1:size(Fluid_PCM,2)
       if strcmp(['Fluid_PCM(',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_PCM(i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEin definierter Fluid_PCM ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in diesem Fluid_PCM) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end

if exist('Fluid_Peltier')==1
   for i=1:size(Fluid_Peltier,2)
       if strcmp(['Fluid_Peltier(',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_Peltier(i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEin definierter Fluid_Peltier ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in diesem Fluid_Peltier) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end


if exist('Fluid_Schlauch')==1
   for i=1:size(Fluid_Schlauch,2)
       if strcmp(['Fluid_Schlauch(',num2str(i),')'],Graph_Kuehlkreislauf{Fluid_Schlauch(i).Nr_Kuehlkreislauf}.Nodes{:,1})==0
          fprintf('\nEin definierter Fluid_Schlauch ist nicht in dem entsprechenden Index (= Angabe Nr_Kuehlkreislauf in diesem Fluid_Schlauch) von Konfig_Kuehlkreislauf konfiguriert!\n');
          keyboard;
       end
   end
end

%--------------------------------------------------------------------------
% Anzahl an Konfigurationen von Aufzweigungen in Konfig_Kuehlkreislauf innerhalb eines Kühlkreislaufs stimmt nicht mit der Anzahl an definierten Dreiwegeventilen innerhalb des entsprechnenden Kühlkreislaufs mit Angabe Nr_Kuehlkreislauf überein
%--------------------------------------------------------------------------

for i=1:n_Kuehlkreislauf
    k=0;
    for j=1:size(Graph_Kuehlkreislauf{i}.Nodes,1)
        if sum(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1)))==2
           k=k+1;
        end
    end
    l=0;
    if exist('Ventil')==1 
       for j=1:size(Ventil,2)
           if Ventil(j).Nr_Kuehlkreislauf==i
              l=l+1;
           end
       end
    end
    if k<l
       fprintf('\nIn Konfig_Kuehlkreislauf sind innerhalb eines Kühlkreislaufs weniger Aufzweigungen konfiguriert, als Dreiwegeventile innerhalb des entsprechnenden Kühlkreislaufs mit Angabe Nr_Kuehlkreislauf definiert sind!\n');
       keyboard;
    elseif k>l
           fprintf('\nIn Konfig_Kuehlkreislauf sind innerhalb eines Kühlkreislaufs mehr Aufzweigungen konfiguriert, als Dreiwegeventile innerhalb des entsprechnenden Kühlkreislaufs mit Angabe Nr_Kuehlkreislauf definiert sind!\n');
           keyboard;
    end
end

%--------------------------------------------------------------------------
% Angabe Ventil_nach oder Angabe Vereinigung_vor in einem Dreiwegeventil stimmt nicht mit der Angabe der Fluid_Komponente überein, nach der die Aufzweigung oder vor der die Vereinigung innerhalb des entsprechenden Kühlkreislaufs laut der Konfiguration in Konfig_Kuehlkreislauf stattfindet
%--------------------------------------------------------------------------

if exist('Ventil')==1
    for i=1:size(Ventil,2)
        if sum(strcmp(Ventil(i).Ventil_nach,Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf}.Edges{:,1}(:,1)))~=2
           fprintf('\nAngabe Ventil_nach in einem Dreiwegeventil stimmt nicht mit der Angabe der Fluid_Komponente überein, nach der die Aufzweigung innerhalb des entsprechenden Kühlkreislaufs laut der Konfiguration in Konfig_Kuehlkreislauf stattfindet!\n');
           keyboard;
        end
        if sum(strcmp(Ventil(i).Vereinigung_vor,Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf}.Edges{:,1}(:,2)))~=2
           fprintf('\nAngabe Vereinigung_vor in einem Dreiwegeventil stimmt nicht mit der Angabe der Fluid_Komponente überein, vor der die Vereinigung innerhalb des entsprechenden Kühlkreislaufs laut der Konfiguration in Konfig_Kuehlkreislauf stattfindet!\n');
           keyboard;
        end
    end
end

%% III. Bestimmung relevanter Parameter des Thermomanagementsystemmodells

%% Allgemeine Paramter

%--------------------------------------------------------------------------
% Bestimmung des Zeitschritts der Simulation
%--------------------------------------------------------------------------

% -> Maximaler Zeitschritt der Simulation aufgrund Courant-Friedrichs-Lewy-Zahl (CFL-Zahl):
% -> Die Fluidströmung in einem Kühlkreislauf wird über eine 1D-Simulation analysiert
% -> Das Strömungsgebiet in einem Kühlkreislauf ist nach dem Prinizp der Finiten-Volumen-Methode örtlich diskretisiert
% -> Das thermische Modell des Fluids basiert auf der Auswertung der Erhaltungssätze der Strömungsmechanik in integraler Form für jedes finite Volumen
% -> Für die Auswertung des Erhaltungssatzes der Energie (in integraler Form) in Simulink wird die Zeitdiskretisierung mittels der expliziten Euler-Methode durchgeführt
% -> Aufgrund dieser Gegebenheiten muss für numerische Stabilität der Simulation die CFL-Zahl <= 1 sein
% -> CFL-Zahl = delta_t*u/dx mit delta_t = Zeitschritt der Simulation, u = Geschwindigkeit der Größen in der Kühlflüssigkeit und dx = Giiterweite bzw. Länge eines finiten Volumens in Strömungsrichtung, also dx = l_FinitesVolumen
% -> Bedingung für numerische Stabilität: CFL-Zahl <= 1 -> delta_t <= l_FinitesVolumen/u
% -> l_FinitesVolumen ist während der Simulation stets konstant
% -> u ist abh. vom Volumenstrom und der durchströmten Querschnittsfläche -> u kann in jeder Fluid_Komponente zu jedem Zeitpunkt anders sein
% -> delta_t muss so gewählt sein, dass auch bei maximal möglicher Geschwindigkeit u_max stets die Bedingung für numerische Stabilität erfüllt ist (Worst-Case-Szenario)
% -> u_max ergibt sich aus dem während der Simulation maximal möglichen (Steuerung_Pumpe = 1) bzw. maximalen (Steuerung_Pumpe = 0) Volumenstrom der Kühlflüssigkeit in einer beliebigen Fluid_Komponente und aus der minimalen Querschnittsfläche der Kühlflüssigkeit in einer beliebigen Fluid_Komponente
% -> u_max = PV_Kuehlfluessigkeit_max/A_Kuehlfluessigkeit_min 
% -> Es kann sein, dass PV_Kuehlfluessigkeit_max während der Simulation möglicherweise nie (zu keinem Auswertungszeitpunkt) bei A_Kuehlfluessigkeit_min vorliegt
% -> Dies ist nämlich davon abh., wie der Anwender das Thermomanagementsystem konfiguriert, und zudem ob für Steuerung_Pumpe = 1 der maximal mögliche Volumenstrom in einer Fluid_Komponente erreicht wird
% -> Falls es aber dazu kommt, muss die an die CFL-Zahl gestellte Bedingung für die numerische Stabilität der Simulation erfüllt sein
% -> delta_t <= l_FinitesVolumen*A_Kuehlfluessigkeit_min/PV_Kuehlfluessigkeit_max
% -> Aus dieser Bedingung ergibt sich für den aufgrund der Bedingung an die CFL-Zahl maximalen Zeitschritt der Simulation delta_t_max_CFL folgender mathematsicher Zusammenhang:
% -> delta_t_max_CFL = l_FinitesVolumen*A_Kuehlfluessigkeit_min/PV_Kuehlfluessigkeit_max

if n_Kuehlkreislauf~=0
   if Steuerung_Pumpe==1
      PV_Kuehlfluessigkeit_max=max(cellfun(@(x)max(x),PV_Kuehlkreislauf_Table)); % Maximal möglicher Volumenstrom der Kühlflüssigkeit in einer beliebigen Fluid_Komponente in m^3/s -> Bestimmung für Steuerung_Pumpe = 1
   elseif Steuerung_Pumpe==0
          PV_Kuehlfluessigkeit_max=max(cellfun(@(x)max(x(:,2)),PV_Kuehlkreislauf)); % Maximaler Volumenstrom der Kühlflüssigkeit in einer beliebigen Fluid_Komponente in m^3/s -> Bestimmung für Steuerung_Pumpe = 0
   else
       fprintf('\nFehler bei der Angabe von Steuerung_Pumpe!\n');
       keyboard;
   end
   A_Kuehlfluessigkeit_min=[];
   if exist('Fluid_Kuehler')==1                                             %#ok<*EXIST>
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_Kuehler.A_Kuehlfluessigkeit]);
   end
   if exist('Fluid_Waermetauscher')==1
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_Waermetauscher.A_Kuehlfluessigkeit]);
   end
   if exist('Fluid_EMaschine')==1                                              
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_EMaschine.A_Kuehlfluessigkeit]);
   end
   if exist('Fluid_Leistungselektronik')==1                                    
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_Leistungselektronik.A_Kuehlfluessigkeit]);
   end
   if exist('Fluid_Batteriepack')==1                                          
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_Batteriepack.A_Kuehlfluessigkeit]);
   end
   if exist('Fluid_Ladegeraet')==1                                          
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_Ladegeraet.A_Kuehlfluessigkeit]);
   end
   if exist('Fluid_PCM')==1                                          
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_PCM.A_Kuehlfluessigkeit]);
   end
   if exist('Fluid_Peltier')==1                                               
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_Peltier.A_Kuehlfluessigkeit]);
   end
   if exist('Fluid_Schlauch')==1                                               
      A_Kuehlfluessigkeit_min(end+1)=min([Fluid_Schlauch.A_Kuehlfluessigkeit]);
   end
   A_Kuehlfluessigkeit_min=min(A_Kuehlfluessigkeit_min);                    % Minimale Querschnittsfläche der Kühlflüssigkeit in einer beliebigen Fluid_Komponente
   delta_t_max_CFL=l_FinitesVolumen*A_Kuehlfluessigkeit_min/PV_Kuehlfluessigkeit_max; % Maximaler Zeitschritt der Simulation aufgrund der Bedingung an die CFL-Zahl in s
elseif n_Kuehlkreislauf==0
       delta_t_max_CFL=[];                                                  % Wenn kein Kühlkreislauf modelliert ist, existiert kein maximaler Zeitschritt der Simulation aufgrund der Bedingung an die CFL-Zahl -> Er wird = [] festgelegt, um bei der Bestimmung des Zeitschritts der Simulation keinen Fehler zu erhalten
end

% -> Maximaler Zeitschritt der Simulation aufgrund der im Thermomanagementsystemmodell verwendeten Wärmeleit-Matrizen A_EMaschine_Getriebe und A_j_c nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge":
% -> Für numerische Stabilität der Simulation müssen die Eigenwerte der Wärmeleit-Matrizen A_EMaschine_Getriebe und A_j_c innerhalb des Einheitskreises bzw. maximal auf dem Einheitskreis liegen, weil diese jeweils die Systemmatrix einer zeitdiskreten Zustandsraumdarstellung zur Temperaturberechnung zum nächsten Auswertungszeitpunkt darstellen
% -> Betrag der Eigenwerte der Wärmeleit-Matrizen A_EMaschine_Getriebe und A_j_c muss <= 1 sein
% -> Wenn dies bei einer Wärmeleit-Matrix nicht der Fall ist, wird die Simulation instabil
% -> Die Wärmeleit-Matrizen A_EMaschine_Getriebe und A_j_c sind vom Zeitschritt delta_t abh.
% -> Die Wärmeleit-Matrizen A_EMaschine_Getriebe und A_j_c werden im weiteren Verlauf des MATLAB-Codes mit dem Zeitschritt der Simulation delta_t berechnet
% -> Zusätzlich bestehen die Wärmeleit-Matrizen im Allgemeinen aus dem Wärmeleitwiderstand zwischen den beiden betrachteten Blockkapazitäten R und aus den Wärmekapazitäten der beiden betrachteten Blockkapazitäten C_1 und C_2
% -> Dadurch, dass für numerische Stabilität der Simulation der Betrag der Eigenwerte einer Wärmeleit-Matrix <= 1 sein, ergibt sich im Allgemeinen folgende Bedingung für den Zeitschritt der Simulation delta_t:
% -> delta_t <= 2 * R / (1/C_1 + 1/C_2)
% -> Aus dieser Bedingung ergibt sich für den aufgrund einer Wärmeleit-Matrix maximalen Zeitschritt der Simulation delta_t_max_Wärmeleit-Matrix folgender mathematsicher Zusammenhang:
% -> delta_t_max_Wärmeleit-Matrix = 2 * R / (1/C_1 + 1/C_2)
% -> Dieser mathematische Zusammenhang wird im Folgenden für beide im Thermomanagementsystemmodell verwendeten Wärmeleit-Matrizen A_EMaschine_Getriebe und A_j_c angewendet

delta_t_max_A_EMaschine_Getriebe=2*R_EMaschine_Getriebe/(1/C_EMaschine+1/C_Getriebe); % Maximaler Zeitschritt der Simulation aufgrund der im Thermomanagementsystemmodell verwendeten Wärmeleit-Matrix A_EMaschine_Getriebe in s
delta_t_max_A_j_c=2*(R_j_c+R_c/2)/(1/C_j+1/C_c);                            % Maximaler Zeitschritt der Simulation aufgrund der im Thermomanagementsystemmodell verwendeten Wärmeleit-Matrix A_j_c in s -> Es wird nur die Hälfte von R_c berücksichtigt, weil der thermische Knoten der Case der MOSFET, die gemeinsam als Blockkapazität aufgefasst sind, in der Mitte der Verdickung angenommen wird und deswegen nur die Hälfte der Dicke der Case der MOSFET berücksichtigt wird

% -> Verwendeter Zeitschritt der Simulation:
% -> Der Zeitschritt der Simulation delta_t darf nicht größer sein als der minimale aller vorhandenen maximalen Zeitschritte der Simulation
% -> Aus Gründen des Simulationsaufwands ist ein möglichst großer Zeitschritt der Simualtion delta_t von Vorteil 
% -> Deswegen wird für den Zeitschritt der Simualtion delta_t zuerst der minimale aller vorhandenen maximalen Zeitschritte der Simulation ausgewählt
% -> Für den letztendlichen Zeitschritt der Simulation delta_t wird nur 99,9% des minimalen aller vorhandenen maximalen Zeitschritte der Simulation verwendet, sodass trotz Rundungsfehler bei der Berechnung der Berechnung der maximalen Zeitschritte die numerische Stabilität der Simulation in jedem Fall sichergestellt ist 

delta_t=0.999*min([delta_t_max_Anwender,delta_t_max_CFL,delta_t_max_A_EMaschine_Getriebe,delta_t_max_A_j_c]); % Zeitschritt der Simulation in s

%--------------------------------------------------------------------------
% Bestimmung des Parameters "Decimation" in den "To Workspace"-Blöcken im Subsystem "Output"
%--------------------------------------------------------------------------

% -> Der Parameter "Decimation" in einem "To Workspace"-Block gibt an, zu jedem wievielten Auswertungszeitpunkt die Simulationsergebnisse während der Simulation in Simulink zwischengespeichert und nach Ende der Simulation an MATLAB übergeben werden (-> Zeitschritte der Simulation pro Datenpunkt der Simulationsergebnisse)
% -> Der Parameter "Decimation" in einem "To Workspace"-Block muss eine natürliche Zahl größer 0 sein
% -> Dieser Parameter wird über Decimation_Output für jeden "To Workspace"-Block im Subsystem "Output" global bestimmt
% -> Decimation_Output ist abh. von Datenfrequenz_Output_max und von delta_t und wird über folgenden mathematischen Zusammenhang bestimmt:
% -> Decimation_Output=ceil(1/(Datenfrequenz_Output_max*delta_t))
% -> Da der Parameter "Decimation" in einem "To Workspace"-Block eine natürliche Zahl größer 0 sein muss, wird bei der Bestimmung von Decimation_Output aufgerundet, um immer eine natürliche Zahl und immer mindestens einen Wert = 1 zu erhalten
% -> Wenn bei der Bestimmung von Decimation_Output ein Aufrundvorgang stattfindet (Ergebnis der Division ist keine natürliche Zahl), unterscheidet sich die tatsächliche Datenfrequenz der Outputs von Datenfrequenz_Output_max, die durch den Anwender festgelegt ist
% -> Durch Aufrunden wird die tatsächliche Datenfrequenz der Outputs kleiner als Datenfrequenz_Output_max
% -> Deswegen handelt es sich bei der Angabe von Datenfrequenz_Output_max korrekterweise um einen Maximalwert

Decimation_Output=ceil(1/(Datenfrequenz_Output_max*delta_t));               % Parameter "Decimation" in den "To Workspace"-Blöcken im Subsystem "Output"

%% Parameter Subsystem "Fluid" (Kuehlfluessigkeit und finites Volumen)

%--------------------------------------------------------------------------
% Bestimmung der Stoffwerte der Kuehlfluessigkeiten mittels CoolProp-Datenbank
%--------------------------------------------------------------------------

addpath('coolprop\main');                                                   % Bei jedem Start von MATLAB muss dieser Pfad neu hinzugefügt werden
for i=1:n_Kuehlkreislauf
    Name_CoolProp{i}=['INCOMP::',Name_Kuehlfluessigkeit{i},'[0.',Anteil_Frostschutzmittel{i},']']; % Bestimmung der Bezeichnung der Kühlflüssigkeiten für CoolProp-Datenbank
    lambda_Kuehlfluessigkeit(i)=CoolProp.PropsSI('conductivity','T',T_Kuehlfluessigkeit_Referenz(i),'P',p_Kuehlfluessigkeit_Referenz(i),Name_CoolProp{i}); % Wärmeleitfähigkeit der Kühlflüssigkeit in dem entsprechenden Kühlkreisaluf in W/(m*K)
    rho_Kuehlfluessigkeit(i)=CoolProp.PropsSI('D','T',T_Kuehlfluessigkeit_Referenz(i),'P',p_Kuehlfluessigkeit_Referenz(i),Name_CoolProp{i}); % Dichte der Kühlflüssigkeit in dem entsprechenden Kühlkreislauf in kg/m^3
    c_Kuehlfluessigkeit(i)=CoolProp.PropsSI('C','T',T_Kuehlfluessigkeit_Referenz(i),'P',p_Kuehlfluessigkeit_Referenz(i),Name_CoolProp{i}); % Spezifische Wärmekapazität der Kühlflüssigkeit in dem entsprechenden Kühlkreislauf in J/(kg*K)
end

%-----------------------------------------------------------------------------
% Bestimmung relevanter Größen der finiten Volumen der Fluid_Komponenten
%-----------------------------------------------------------------------------

% -> Bestimmungen: T_FinitesVolumen_init, R_FinitesVolumen, m_FinitesVolumen, C_FinitesVolumen, b_FinitesVolumen

% -> Fluid_Kuehler
if exist('Fluid_Kuehler')==1                                               
   for i=1:size(Fluid_Kuehler,2)
       Fluid_Kuehler(i).T_FinitesVolumen_init=ones(Fluid_Kuehler(i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_Kuehler(i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des Strömungsgebiets des entsprechenden Kühlers in K -> wird als Vektor benötigt
       Fluid_Kuehler(i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_Kuehler(i).Nr_Kuehlkreislauf)*Fluid_Kuehler(i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Kühlers in K/W
       Fluid_Kuehler(i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_Kuehler(i).Nr_Kuehlkreislauf)*Fluid_Kuehler(i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Kühlers in kg
       Fluid_Kuehler(i).C_FinitesVolumen=Fluid_Kuehler(i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_Kuehler(i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Kühlers in J/K
       Fluid_Kuehler(i).b_FinitesVolumen=delta_t/Fluid_Kuehler(i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Kühlers in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end

% -> Fluid_Waermetauscher
if exist('Fluid_Waermetauscher')==1                                               
   for i=1:size(Fluid_Waermetauscher,2)
       Fluid_Waermetauscher(1,i).T_FinitesVolumen_init=ones(Fluid_Waermetauscher(1,i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_Waermetauscher(1,i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des 1. Strömungsgebiets des entsprechenden Wärmetauschers in K -> wird als Vektor benötigt
       Fluid_Waermetauscher(1,i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_Waermetauscher(1,i).Nr_Kuehlkreislauf)*Fluid_Waermetauscher(1,i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des 1. Strömungsgebiet des entsprechenden Wärmetauschers in K/W
       Fluid_Waermetauscher(1,i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_Waermetauscher(1,i).Nr_Kuehlkreislauf)*Fluid_Waermetauscher(1,i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des 1. Strömungsgebiets des entsprechenden Wärmetauschers in kg
       Fluid_Waermetauscher(1,i).C_FinitesVolumen=Fluid_Waermetauscher(1,i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_Waermetauscher(1,i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des 1. Strömungsgebiets des entsprechenden Wärmetauschers in J/K
       Fluid_Waermetauscher(1,i).b_FinitesVolumen=delta_t/Fluid_Waermetauscher(1,i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des 1. Strömungsgebiets des entsprechenden Wärmetauschers in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
       
       Fluid_Waermetauscher(2,i).T_FinitesVolumen_init=ones(Fluid_Waermetauscher(2,i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_Waermetauscher(2,i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des 2. Strömungsgebiets des entsprechenden Wärmetauschers in K -> wird als Vektor benötigt
       Fluid_Waermetauscher(2,i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_Waermetauscher(2,i).Nr_Kuehlkreislauf)*Fluid_Waermetauscher(2,i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des 2. Strömungsgebiets des entsprechenden Wärmetauschers in K/W
       Fluid_Waermetauscher(2,i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_Waermetauscher(2,i).Nr_Kuehlkreislauf)*Fluid_Waermetauscher(2,i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des 2. Strömungsgebiets des entsprechenden Wärmetauschers in kg
       Fluid_Waermetauscher(2,i).C_FinitesVolumen=Fluid_Waermetauscher(2,i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_Waermetauscher(2,i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des 2. Strömungsgebiet des entsprechenden Wärmetauschers in J/K
       Fluid_Waermetauscher(2,i).b_FinitesVolumen=delta_t/Fluid_Waermetauscher(2,i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des 2. Strömungsgebiets des entsprechenden Wärmetauschers in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end

% -> Fluid_EMaschine
if exist('Fluid_EMaschine')==1                                              
   for i=1:size(Fluid_EMaschine,2)
       Fluid_EMaschine(i).T_FinitesVolumen_init=ones(Fluid_EMaschine(i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_EMaschine(i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des Strömungsgebiets der entsprechenden E-Maschine in K -> wird als Vektor benötigt
       Fluid_EMaschine(i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_EMaschine(i).Nr_Kuehlkreislauf)*Fluid_EMaschine(i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden E-Maschine in K/W
       Fluid_EMaschine(i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_EMaschine(i).Nr_Kuehlkreislauf)*Fluid_EMaschine(i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden E-Maschine in kg
       Fluid_EMaschine(i).C_FinitesVolumen=Fluid_EMaschine(i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_EMaschine(i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden E-Maschine in J/K
       Fluid_EMaschine(i).b_FinitesVolumen=delta_t/Fluid_EMaschine(i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden E-Maschine in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end

% -> Fluid_Leistungselektronik
if exist('Fluid_Leistungselektronik')==1                                   
   for i=1:size(Fluid_Leistungselektronik,2)
       Fluid_Leistungselektronik(i).T_FinitesVolumen_init=ones(Fluid_Leistungselektronik(i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_Leistungselektronik(i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des Strömungsgebiets der entsprechenden Leistungselektronik in K -> wird als Vektor benötigt
       Fluid_Leistungselektronik(i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_Leistungselektronik(i).Nr_Kuehlkreislauf)*Fluid_Leistungselektronik(i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden Leistungselektronikin K/W
       Fluid_Leistungselektronik(i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_Leistungselektronik(i).Nr_Kuehlkreislauf)*Fluid_Leistungselektronik(i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden Leistungselektronik in kg
       Fluid_Leistungselektronik(i).C_FinitesVolumen=Fluid_Leistungselektronik(i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_Leistungselektronik(i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiet der entsprechenden Leistungselektronik in J/K
       Fluid_Leistungselektronik(i).b_FinitesVolumen=delta_t/Fluid_Leistungselektronik(i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden Leistungselektronik in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end        

% -> Fluid_Batteriepack
if exist('Fluid_Batteriepack')==1                                      
   for i=1:size(Fluid_Batteriepack,2)
       Fluid_Batteriepack(i).T_FinitesVolumen_init=ones(Fluid_Batteriepack(i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_Batteriepack(i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des Strömungsgebiets des entsprechenden Batteriepacks in K -> wird als Vektor benötigt
       Fluid_Batteriepack(i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_Batteriepack(i).Nr_Kuehlkreislauf)*Fluid_Batteriepack(i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Batteriepacks in K/W
       Fluid_Batteriepack(i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_Batteriepack(i).Nr_Kuehlkreislauf)*Fluid_Batteriepack(i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Batteriepacks in kg
       Fluid_Batteriepack(i).C_FinitesVolumen=Fluid_Batteriepack(i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_Batteriepack(i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Batteriepacks in J/K
       Fluid_Batteriepack(i).b_FinitesVolumen=delta_t/Fluid_Batteriepack(i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Batteriepacks in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end   

% -> Fluid_Batteriepack
if exist('Fluid_Ladegeraet')==1                                      
   for i=1:size(Fluid_Ladegeraet,2)
       Fluid_Ladegeraet(i).T_FinitesVolumen_init=ones(Fluid_Ladegeraet(i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_Ladegeraet(i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des Strömungsgebiets des entsprechenden Ladegeraets in K -> wird als Vektor benötigt
       Fluid_Ladegeraet(i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_Ladegeraet(i).Nr_Kuehlkreislauf)*Fluid_Ladegeraet(i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Ladegeraets in K/W
       Fluid_Ladegeraet(i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_Ladegeraet(i).Nr_Kuehlkreislauf)*Fluid_Ladegeraet(i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Ladegeraets in kg
       Fluid_Ladegeraet(i).C_FinitesVolumen=Fluid_Ladegeraet(i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_Ladegeraet(i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Ladegeraets in J/K
       Fluid_Ladegeraet(i).b_FinitesVolumen=delta_t/Fluid_Ladegeraet(i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Ladegeraets in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end   

% -> Fluid_PCM
if exist('Fluid_PCM')==1                                      
   for i=1:size(Fluid_PCM,2)
       Fluid_PCM(i).T_FinitesVolumen_init=ones(Fluid_PCM(i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_PCM(i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des Strömungsgebiets des entsprechenden PCMs in K -> wird als Vektor benötigt
       Fluid_PCM(i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_PCM(i).Nr_Kuehlkreislauf)*Fluid_PCM(i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden PCMs in K/W
       Fluid_PCM(i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_PCM(i).Nr_Kuehlkreislauf)*Fluid_PCM(i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden PCMs in kg
       Fluid_PCM(i).C_FinitesVolumen=Fluid_PCM(i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_PCM(i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden PCMs in J/K
       Fluid_PCM(i).b_FinitesVolumen=delta_t/Fluid_PCM(i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden PCMs in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end   

% -> Fluid_
if exist('Fluid_Peltier')==1                                      
   for i=1:size(Fluid_Peltier,2)
       Fluid_Peltier(i).T_FinitesVolumen_init=ones(Fluid_Peltier(i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_Peltier(i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des Strömungsgebiets des entsprechenden Peltiers in K -> wird als Vektor benötigt
       Fluid_Peltier(i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_Peltier(i).Nr_Kuehlkreislauf)*Fluid_Peltier(i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Peltiers in K/W
       Fluid_Peltier(i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_Peltier(i).Nr_Kuehlkreislauf)*Fluid_Peltier(i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Peltiers in kg
       Fluid_Peltier(i).C_FinitesVolumen=Fluid_Peltier(i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_Peltier(i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Peltiers in J/K
       Fluid_Peltier(i).b_FinitesVolumen=delta_t/Fluid_Peltier(i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Peltiers in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end   

% -> Fluid_Schlauch
if exist('Fluid_Schlauch')==1                                          
   for i=1:size(Fluid_Schlauch,2)
       Fluid_Schlauch(i).T_FinitesVolumen_init=ones(Fluid_Schlauch(i).l_Kuehlfluessigkeit/l_FinitesVolumen,1)*Fluid_Schlauch(i).T_Kuehlfluessigkeit_init; % Initialtemperaturen der Kühlflüssigkeit bzgl. der Knoten der finiten Volumen des Strömungsgebiets des entsprechenden Schlauchs in K -> wird als Vektor benötigt
       Fluid_Schlauch(i).R_FinitesVolumen=l_FinitesVolumen/(lambda_Kuehlfluessigkeit(Fluid_Schlauch(i).Nr_Kuehlkreislauf)*Fluid_Schlauch(i).A_Kuehlfluessigkeit); % Wärmeleitwiderstand der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Schlauchs in K/W
       Fluid_Schlauch(i).m_FinitesVolumen=rho_Kuehlfluessigkeit(Fluid_Schlauch(i).Nr_Kuehlkreislauf)*Fluid_Schlauch(i).A_Kuehlfluessigkeit*l_FinitesVolumen; % Masse der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Schlauchs in kg
       Fluid_Schlauch(i).C_FinitesVolumen=Fluid_Schlauch(i).m_FinitesVolumen*c_Kuehlfluessigkeit(Fluid_Schlauch(i).Nr_Kuehlkreislauf); % Wärmekapazität der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Schlauchs in J/K
       Fluid_Schlauch(i).b_FinitesVolumen=delta_t/Fluid_Schlauch(i).C_FinitesVolumen; % Größe b für die Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Schlauchs in (s*K)/J zur Berechnung der Temperaturdifferenz bzgl. der Leistungen nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
   end
end

%--------------------------------------------------------------------------
% Darstellung der gerichteten Graphen der Kühlkreisläufe
%--------------------------------------------------------------------------

% -> Darstellung der gerichteten Graphen der Kühlkreisläufe, sodass der Anwender vor der Simulation die festgelegte Konfiguration der Kühlkreisläufe überprüfen kann

% Only Plot during first call of function

persistent plot_cooling_cycle_overview

if isempty(plot_cooling_cycle_overview)
    plot_cooling_cycle_overview = true;
end    

if plot_cooling_cycle_overview == true
    for i=1:n_Kuehlkreislauf
        figure('Name', strcat("VTMS type name: ", VTMS_name));
        plot(Graph_Kuehlkreislauf{i});
        axis tight;
        set(gca,'XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[]);
        title(['Overview of cooling cycle ',num2str(i)]);
        legend(['Dots = Components',newline,'Lines = Component connections']);
    end
    plot_cooling_cycle_overview = false;
end

%--------------------------------------------------------------------------
% Bestimmung der Fluid_Komponenten innerhalb des Haupt- und Nebenpfades der Dreiwegeventile
%--------------------------------------------------------------------------

% -> Durch die Edges in Graph_Kuehlkreislauf wird geprüft, welche zwei Fluid_Komponenten nach einem Dreiwegeventil bzw. nach der Fluid_Komponente vor dem Dreiwegeventil kommen
% -> Die erste von zwei relevanten Edges in Graph_Kuehlkreislauf wurde durch den Anwender zuerst festgelegt, was bedeutet, dass dies der Hauptpfad des Dreiwegeventils ist und sich damit die resultierende Fluid_Komponente im Hauptpfad befindet
% -> Die zweite von zwei relevanten Edges in Graph_Kuehlkreislauf wurde durch den Anwender danach festgelegt, was bedeutet, dass dies der Nebenpfad des Dreiwegeventils ist und sich damit die resultierende Fluid_Komponente im Nebenpfad befindet
% -> Ausgehend von der resultierenden Fluid_Komponente im Hauptpfad bzw. im Nebenpfad des Dreiwegeventils werden über die alternierende Ausführung des "successors"-Befehls alle im gerichteten Graphen nachfolgenden Fluid_Komponenten bestimmt und in einem cell gespeichert, bis diejenige Fluid_Komponente erreicht wird, die nach der Vereinigung der zwei nach der Aufzweigung durch das Dreiwegeventil resultierenden Pfade kommt
% -> Diejenige Fluid_Komponente, die nach der Vereinigung der zwei nach der Aufzweigung durch das Dreiwegeventil resultierenden Pfade kommt, wird aus dem cell für den Hauptpfad bzw. für den Nebenpfad des Dreiwegeventils wieder gelöscht
% -> Dadurch sind im cell für den Hauptpfad bzw. für den Nebenpfad des Dreiwegeventils nur diejenigen Fluid_Komponenten gespeichert, die sich innerhalb des Hauptpfades bzw. des Nebenpfades des Dreiwegeventils befinden
% -> Dieser Vorgang wird für alle Dreiwegeventile durchgeführt
% -> Bei verschachtelten Dreiwegeventilen kann sich eine Fluid_Komponente korrekterweise bei mehreren Dreiwegeventilen im Haupt- oder Nebenpfad befinden

if exist('Ventil')==1
   for i=1:size(Ventil,2)
       Ventil(i).Knoten_Hauptpfad={};
       Ventil(i).Knoten_Hauptpfad{1,1}=Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf}.Edges{:,1}(... % Mit dem niedrigeren Index, der die Zeile in den Edges ansteuert und die erste Edge im Hauptpfad des Dreiwegeventils angibt (siehe Erklärung Zeile darunter) und mit dem zweiten Index 2 (siehe 6 Zeilen darunter), der die 2. Spalte der Edges des Graph_Kuehlkreislauf mit der Spaltennummer "Ventil(i).Nr_Kuehlkreislauf" ansteuert, wird der erste Knoten gefunden, der sich im Hauptpfad des Dreiwegeventils befindet
                                       min(...                              % Mithilfe des "min"-Befehls wird der niedrigere der beiden resultierenden Indizes (siehe Erklärung Zeile darunter) gefunden -> Der niedrigere Index bedeutet, dass dies die erste durch den Anwender festgelegte Edge ist und dies somit der Hauptpfad des Dreiwegeventils ist (unten wird die gleiche Abfrage gestartet, nur wird mit dem "max"-Befehl der höhere der beiden Indizes gesucht -> Dann handelt es sich um die zweite durch den Anwender festgelegte Edge und somit um den Nebenpfad des Dreiwegeventils)
                                           find(...                         % Mithilfe des "find"-Befehls werden die Indizes des Spaltenvektors mit 1- und 0-Einträgen (siehe Erklärung Zeile darunter) gefunden, in denen eine 1 steht -> Das sind die Zeilenindizes der Edges, in denen sich der betrachtete Knoten in der 1. Spalte der Edges befindet -> In diesem Fall gibt es 2 Indizes, weil sich nach dem betrachteten Knoten "Ventil(i).Ventil_nach" ein Dreiwegeventil befindet, was bedeutet, dass von diesem Knoten 2 Edges zu 2 neuen Knoten weggehen -> Der betrachtete Knoten tritt 2 mal als Startknoten einer Edge auf, also 2 mal in der 1. Spalte der Edges
                                                strcmp(Ventil(i).Ventil_nach,Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf}.Edges{:,1}(:,1))... % Über den "strcmp"-Befehl wird der im Graph_Kuehlkreislauf mit dem Index "Ventil(i).Nr_Kuehlkreislauf" (Index von Graph_Kuehlkreislauf drückt die Nummer des Kühlkreislaufs aus) vorhandene Knoten "Ventil(i).Ventil_nach" in der 1. Spalte der Edges des Graph_Kuehlkreislauf mit dem Index "Ventil(i).Nr_Kuehlkreislauf" Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf}.Edges{:,1}(:,1) gesucht ({:,1}: Umwandlung des Tables, in dem die Edges gespeichert sind, in ein struct mit 2 Spalten (Startknoten und Endknoten der Edge); (:,1): Ansteuerung nur der 1. Spalte) -> Das Ergebnis ist ein Spaltenvektor, der über 1 und 0 angibt, ob sich der betrachtete Knoten in der 1. Spalte der Edges befindet (1) oder nicht (0)
                                                )...
                                            )...
                                        ,2);                                %#ok<*MXFND>
       % -> Das Prinzip dieser Abfrage wird sehr ausführlich erklärt, weil es sich um eine komplizierte und mehrmals verschachtelte Abfrage handelt
       % -> Im weiteren Verlauf des MATLAB-Codes kommen des Öfteren ähnliche Abfragen, bei denen über den "strcmp"-Befehl verglichen wird, ob sich ein Knoten eines Kühlkreislaufs in einer Spalte der Edges des Kühlkreislaufs befindet, mit dem Ziel herauszufinden, entweder wie oft sich dieser Knoten in der untersuchten Spalte der Edges befindet oder wo sich dieser Knoten in der untersuchten Spalte der Edges befindet (z.B. in der ersten oder zweiten durch den Anwender festgelegten Edge bei Auftreten eines Dreiwegeventils oder einer Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade) oder um mit dem resultierenden Zeilenindex der Edges den Knoten vor oder nach dem betrachteten Knoten zu erhalten usw.
       % -> Da dies aber vom Prinzip her ähnlich, wie gerade ausführlich erklärt, abläuft, wird darauf im Folgenden nicht mehr näher eingegangen
       j=1;
       while j<=size(Ventil(i).Knoten_Hauptpfad,2)
             k=1;
             m=1;
             while k<=size(Ventil(i).Knoten_Hauptpfad,1)
                   if isempty(Ventil(i).Knoten_Hauptpfad{k,j})==0
                      for l=1:size(Ventil(i).Knoten_Hauptpfad{k,j},1)
                          if strcmp(Ventil(i).Knoten_Hauptpfad{k,j}{l},Ventil(i).Vereinigung_vor)==0
                             Ventil(i).Knoten_Hauptpfad{m,j+1}=successors(Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf},Ventil(i).Knoten_Hauptpfad{k,j}{l});
                             m=m+1;
                          elseif strcmp(Ventil(i).Knoten_Hauptpfad{k,j}{l},Ventil(i).Vereinigung_vor)==1
                                 Ventil(i).Knoten_Hauptpfad{k,j}=[];
                          end
                      end
                   end
                   k=k+1;
             end
             j=j+1;
       end
       Ventil(i).Knoten_Hauptpfad(:,end)=[];  
       Ventil(i).Knoten_Nebenpfad={};
       Ventil(i).Knoten_Nebenpfad{1,1}=Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf}.Edges{:,1}(max(find(strcmp(Ventil(i).Ventil_nach,Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf}.Edges{:,1}(:,1)))),2); % -> Hier wird nach dem gleichen Prinzip wie oben der erste Knoten gefunden, der sich im Nebenpfad des Dreiwegeventils befindet -> Es handelt sich um die gleiche Abfrage, nur wird hier statt dem "min"-Befehl der "max"-Befehl verwendet, was dazu führt, dass der höhere der beiden Indizes verwendet wird -> Dies hat zur Folge, dass es sich um zweite durch den Anwender festgelegte Edge und somit um den Nebenpfad des Dreiwegeventils handelt -> Dadurch wird der erste Knoten im Nebenpfad des Dreiwegeventils gefunden
       j=1;
       while j<=size(Ventil(i).Knoten_Nebenpfad,2)
             k=1;
             m=1;
             while k<=size(Ventil(i).Knoten_Nebenpfad,1)
                   if isempty(Ventil(i).Knoten_Nebenpfad{k,j})==0
                      for l=1:size(Ventil(i).Knoten_Nebenpfad{k,j},1)
                          if strcmp(Ventil(i).Knoten_Nebenpfad{k,j}{l},Ventil(i).Vereinigung_vor)==0
                             Ventil(i).Knoten_Nebenpfad{m,j+1}=successors(Graph_Kuehlkreislauf{Ventil(i).Nr_Kuehlkreislauf},Ventil(i).Knoten_Nebenpfad{k,j}{l});
                             m=m+1;
                          elseif strcmp(Ventil(i).Knoten_Nebenpfad{k,j}{l},Ventil(i).Vereinigung_vor)==1
                                 Ventil(i).Knoten_Nebenpfad{k,j}=[];
                          end
                      end
                   end
                   k=k+1;
             end
             j=j+1;
       end
       Ventil(i).Knoten_Nebenpfad(:,end)=[];       
   end
end

%% Parameter Subsystem "Kühler"

%--------------------------------------------------------------------------
% Bestimmung thermischer Paramater
%--------------------------------------------------------------------------

% -> Die Werte für die Wärmeübertragungsfähigkeit eines Kühlers bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Kühlers geteilt durch die Anzahl an finiten Volumen des Strömungsgebiets des Kühlers ergeben die Werte für die Wärmeübertragungsfähigkeit des Kühlers bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Kühlers
% -> Dies wird angenommen, weil für das Thermomanagementsystemmodell gilt, dass das Strömungsgebiet eines Kühlers durch identische finite Volumen örtlich diskretisiert ist
if exist('Fluid_Kuehler')==1
   for i=1:size(Fluid_Kuehler,2)
       UA_Kuehler_FinitesVolumen_Table{i}=UA_Kuehler_Kuehlfluessigkeit_Table{i}/(Fluid_Kuehler(i).l_Kuehlfluessigkeit/l_FinitesVolumen); % Die Wärmeübertragungsfähigkeit des entsprechenden Kühlers bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Kühlers in Abh. vom Volumenstrom der Kühlflüssigkeit, in Abh. von der Luftgeschwindigkeit des Kühlerlüfters und in Abh. von der Fahrzeuggeschwindigkeit in W/K -> Fluid_Kuehler(i).l_Kuehlfluessigkeit/l_FinitesVolumen = Anzahl an finiten Volumen des Strömungsgebiets des i. Kühlers
   end
end

%% Parameter Subsystem "Wärmetauscher"

%--------------------------------------------------------------------------
% Bestimmung thermischer Paramater
%--------------------------------------------------------------------------

% -> Die Werte für die Wärmeübertragungsfähigkeit eines Wärmetauschers bzgl. der gesamten Kühlflüssigkeit im 1. bzw. 2. Strömungsgebiet des Wärmetauschers geteilt durch die Anzahl an finiten Volumen des 1. bzw. 2. Strömungsgebiets des Wärmetauschers ergeben die Werte für die Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der Kühlflüssigkeit in einem finiten Volumen des 1. bzw. 2. Strömungsgebiets des Wärmetauschers
% -> Dies wird angenommen, weil für das Thermomanagementsystemmodell gilt, dass das 1. bzw. 2. Strömungsgebiet eines Wärmetauschers durch identische finite Volumen örtlich diskretisiert ist
% -> Da bei beiden Strömungsgebieten die Länge des Kühlflüssigkeitsstroms definitionsbedingt identisch sein muss, ergibt sich für das 1. und 2. Strömungsgebiet des Wärmetauschers die gleiche Anzahl an finten Volumen, die sich somit zum Wärmeaustausch genau gegenüberstehen -> Bedingung für die Berechnung des Wärmeaustausches im Wärmetauscher
% -> Deswegen entspricht die Wärmeübertragungsfähigkeit eines Wärmetauschers bzgl. der Kühlflüssigkeit in einem finiten Volumen des 1. Strömungsgebiet des Wärmetauschers der Wärmeübertragungsfähigkeit des Wärmetauschers bzgl. der Kühlflüssigkeit in einem finiten Volumen des 2. Strömungsgebiets des Wärmetauschers, weil genau ein finites Volumen des 1. Strömungsgebiets des Wärmetauschers mit einem finten Volumen des 2. Strömungsgebiets des Wärmetauschers Wärme austauscht
if exist('Fluid_Waermetauscher')==1
   for i=1:size(Fluid_Waermetauscher,2)
       UA_Waermetauscher_FinitesVolumen_Table{i}=UA_Waermetauscher_Kuehlfluessigkeit_Table{i}/(Fluid_Waermetauscher(1,i).l_Kuehlfluessigkeit/l_FinitesVolumen); % Die Wärmeübertragungsfähigkeit des entsprechenden Wärmetauschers bzgl. der Kühlflüssigkeit in einem finiten Volumen des 1. bzw. 2. Strömungsgebiets des entsprechenden Wärmetauschers in Abh. von den Volumenströmen der zwei Kühlflüssigkeiten in W/K -> Fluid_Waermetauscher(1,i).l_Kuehlfluessigkeit/l_FinitesVolumen = Anzahl an finiten Volumen des 1. bzw. 2. Strömungsgebiets des i. Wärmetauschers
   end
end

%% Parameter Subsystem "E-Maschine"

%--------------------------------------------------------------------------
% Bestimmung allgemeiner Paramater
%--------------------------------------------------------------------------

M_EMaschine_max=zeros(2,numel(eta_EMaschine_Break_n_EMaschine));            % Maximales Drehmoment der E-Maschine nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
i=1;
while i<=numel(eta_EMaschine_Break_n_EMaschine)
    j=1;
    k=1;
    while  k>=0 && j<=numel(eta_EMaschine_Break_M_EMaschine)
        k=eta_EMaschine_Table(j,i);
        if k>=0
            M_EMaschine_max(2,i)=eta_EMaschine_Break_M_EMaschine(j);
        else
            M_EMaschine_max(2,i)=eta_EMaschine_Break_M_EMaschine(j-1);
        end
        j=j+1;        
    end
    M_EMaschine_max(1,i)=eta_EMaschine_Break_n_EMaschine(i);
    i=i+1;
end 

P_EMaschine_max=[M_EMaschine_max(1,:);(M_EMaschine_max(1,:).*M_EMaschine_max(2,:)*pi/30)]; % Maximale Leistung der E-Maschine = 2 * pi * maximales Drehmoment der E-Maschine * Drehzahl der E-Maschine / 60 mit Drehzal in 1/min nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"

%--------------------------------------------------------------------------
% Bestimmung thermischer Paramater
%--------------------------------------------------------------------------

T_EMaschine_Getriebe_init=[T_EMaschine_init;T_Getriebe_init];               % Vektor für die Inititaltemperaturen der E-Maschine und des Getriebes

% -> Die Werte für die Wärmeübertragungsfähigkeit der E-Maschine bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet der E-Maschine geteilt durch die Anzahl an finiten Volumen des Strömungsgebiets der E-Maschine ergeben die Werte für die Wärmeübertragungsfähigkeit der E-Maschine bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der E-Maschine
% -> Dies wird angenommen, weil für das Thermomanagementsystemmodell gilt, dass das Strömungsgebiet der E-Maschine durch identische finite Volumen örtlich diskretisiert ist
if exist('Fluid_EMaschine')==1
   for i=1:size(Fluid_EMaschine,2)
       UA_EMaschine_FinitesVolumen_Table{i}=UA_EMaschine_Kuehlfluessigkeit_Table{i}/(Fluid_EMaschine(i).l_Kuehlfluessigkeit/l_FinitesVolumen); % Die Wärmeübertragungsfähigkeit der entsprechenden E-Maschine bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden E-Maschine in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K -> Fluid_EMaschine(1).l_Kuehlfluessigkeit/l_FinitesVolumen = Anzahl an finiten Volumen des Strömungsgebiets der i. E-Maschine
   end
end

A_EMaschine_Getriebe=zeros(2);                                              % Wärmeleit-Matrix A für die Konduktion zwischen der E-Maschine und dem Getriebe nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"
A_EMaschine_Getriebe(1,1)=1-delta_t/(R_EMaschine_Getriebe*C_EMaschine);  
A_EMaschine_Getriebe(1,2)=delta_t/(R_EMaschine_Getriebe*C_EMaschine); 
A_EMaschine_Getriebe(2,1)=delta_t/(R_EMaschine_Getriebe*C_Getriebe);  
A_EMaschine_Getriebe(2,2)=1-delta_t/(R_EMaschine_Getriebe*C_Getriebe);

b_EMaschine=[delta_t/C_EMaschine;0];                                        % Vektor b für die E-Maschine in (s*K)/J nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"

b_Getriebe=[0;delta_t/C_Getriebe];                                          % Vektor b für das Getriebe (s*K)/J nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"

%% Parameter Subsystem "Leistungselektronik"

%--------------------------------------------------------------------------
% Bestimmung thermischer Paramater
%--------------------------------------------------------------------------

T_Leistungselektronik_init=[T_j_init;T_c_init];                             % Vektor für die Inititaltemperaturen der Substrate der MOSFET und der Case der MOSFET

% -> Die Werte für die Wärmeübertragungsfähigkeit der Leistungselektronik/Case der MOSFET bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet der Leistungselektronik geteilt durch die Anzahl an finiten Volumen des Strömungsgebiets der Leistungselektronik ergeben die Werte für die Wärmeübertragungsfähigkeit der Leistungselektronik/Case der MOSFET bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der Leistungselektronik
% -> Dies wird angenommen, weil für das Thermomanagementsystemmodell gilt, dass das Strömungsgebiet der Leistungselektronik durch identische finite Volumen örtlich diskretisiert ist
if exist('Fluid_Leistungselektronik')==1
   for i=1:size(Fluid_Leistungselektronik,2)
       UA_c_FinitesVolumen_Table{i}=UA_c_Kuehlfluessigkeit_Table{i}/(Fluid_Leistungselektronik(i).l_Kuehlfluessigkeit/l_FinitesVolumen); % Die Wärmeübertragungsfähigkeit der entsprechenden Leistungselektronik/Case der MOSFET bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets der entsprechenden Leistungselektronik in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K -> Fluid_Leistungselektronik(i).l_Kuehlfluessigkeit/l_FinitesVolumen = Anzahl an finiten Volumen des Strömungsgebiets der i. Leistungselektronik
   end
end

A_j_c=zeros(2);                                                             % Wärmeleit-Matrix A für die Konduktion in der Leistungselektronik zwischen den Substraten und den Case der MOSFET nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"	
A_j_c(1,1)=1-delta_t/((R_j_c+R_c/2)*C_j);                                   % Es wird nur die Hälfte von R_c berücksichtigt, weil der thermische Knoten der Case der MOSFET, die gemeinsam als Blockkapazität aufgefasst sind, in der Mitte der Verdickung angenommen wird und deswegen nur die Hälfte der Dicke der Case der MOSFET berücksichtigt wird
A_j_c(1,2)=delta_t/((R_j_c+R_c/2)*C_j);                                     % Es wird nur die Hälfte von R_c berücksichtigt, weil der thermische Knoten der Case der MOSFET, die gemeinsam als Blockkapazität aufgefasst sind, in der Mitte der Verdickung angenommen wird und deswegen nur die Hälfte der Dicke der Case der MOSFET berücksichtigt wird
A_j_c(2,1)=delta_t/((R_j_c+R_c/2)*C_c);                                     % Es wird nur die Hälfte von R_c berücksichtigt, weil der thermische Knoten der Case der MOSFET, die gemeinsam als Blockkapazität aufgefasst sind, in der Mitte der Verdickung angenommen wird und deswegen nur die Hälfte der Dicke der Case der MOSFET berücksichtigt wird
A_j_c(2,2)=1-delta_t/((R_j_c+R_c/2)*C_c);                                   % Es wird nur die Hälfte von R_c berücksichtigt, weil der thermische Knoten der Case der MOSFET, die gemeinsam als Blockkapazität aufgefasst sind, in der Mitte der Verdickung angenommen wird und deswegen nur die Hälfte der Dicke der Case der MOSFET berücksichtigt wird

b_j=[delta_t/C_j;0];                                                        % Vektor b für die Substrate der MOSFET in (s*K)/J nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"

b_c=[0;delta_t/C_c];                                                        % Vektor b für die Case der MOSFET in (s*K)/J nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge" 

%% Parameter Subsystem "Batteriepack"

%--------------------------------------------------------------------------
% Bestimmung thermischer Paramater
%--------------------------------------------------------------------------

% -> Die Werte für die Wärmeübertragungsfähigkeit des Batteriepacks bzgl. der gesamten Kühlflüssigkeit im Strömungsgebiet des Batteriepacks geteilt durch die Anzahl an finiten Volumen des Strömungsgebiets des Batteriepacks ergeben die Werte für die Wärmeübertragungsfähigkeit des Batteriepacks bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des Batteriepacks
% -> Dies wird angenommen, weil für das Thermomanagementsystemmodell gilt, dass das Strömungsgebiet des Batteriepacks durch identische finite Volumen örtlich diskretisiert ist
if exist('Fluid_Batteriepack')==1
   for i=1:size(Fluid_Batteriepack,2)
       UA_Batteriepack_FinitesVolumen_Table{i}=UA_Batteriepack_Kuehlfluessigkeit_Table{i}/(Fluid_Batteriepack(i).l_Kuehlfluessigkeit/l_FinitesVolumen); % Die Wärmeübertragungsfähigkeit des entsprechenden Batteriepacks bzgl. der Kühlflüssigkeit in einem finiten Volumen des Strömungsgebiets des entsprechenden Batteriepacks in Abh. vom Volumenstrom der Kühlflüssigkeit in W/K -> Fluid_Batteriepack(i).l_Kuehlfluessigkeit/l_FinitesVolumen = Anzahl an finiten Volumen des Strömungsgebiets des i. Batteriepacks
   end
end

b_Batteriepack=delta_t/C_Batteriepack;                                      % Größe b (hier ein Skalar, weil es keine weitere Komponente gibt, mit der Konduktion auftritt -> Deswegen existiert auch keine Wärmeleit-Matrix A) für das Batteriepack in (s*K)/J nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstränge"

%% Parameter Subsystem "Ladegeraet"

%--------------------------------------------------------------------------
% Bestimmung thermischer Paramater
%--------------------------------------------------------------------------

% -> Die Werte fuer die Waermeuebertragungsfaehigkeit des Ladegeraets bzgl. der Kuehlfluessigkeit geteilt durch die Anzahl der finiten Volumen im Ladegeraet ergeben die Werte fuer die Waermeuebertragungsfaehigkeit des Batteriepacks bzgl. einem finiten Volumen
% -> Dies ist der Fall, weil jedes finite Volumen im Ladegeraet gleich groß ist und weil von einer konstanten Waermedurchgangszahl ausgegangen wird und weil die Summe der Waermeuebertragungsflaechen bzgl. der finten Volumen im Ladegeraet gleich der Waermeuebertragungsflaeche bzgl. der Kuehlfluessigkeit im Ladegeraet ist
if exist('Fluid_Ladegeraet')==1
   for i=1:size(Fluid_Ladegeraet,2)
       UA_Ladegeraet_FinitesVolumen_Table{i}=UA_Ladegeraet_Kuehlfluessigkeit_Table{i}/(Fluid_Ladegeraet(i).l_Kuehlfluessigkeit/l_FinitesVolumen); % Die Waermeuebertragungsfaehigkeit des Ladegeraet bzgl. einem finiten Volumen in Abh. vom Volumenstrom der Kuehlfluessigkeit in W/K -> Fluid_Ladegeraet(1).l_Kuehlfluessigkeit/l_FinitesVolumen = Anzahl der finiten Volumen im i. Ladegeraet
   end
end

b_Ladegeraet=delta_t/C_Ladegeraet;                                               % Größe b (hier ein Skalar, weil es keine weitere Komponente gibt, mit der Konduktion auftritt -> Deswegen existiert auch keine Waermeleit-Matrix A) fuer das Ladegeraet in (s*K)/J nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstraenge"

%% Parameter Subsystem "PCM"

%--------------------------------------------------------------------------
% Bestimmung thermischer Paramater
%--------------------------------------------------------------------------

% -> Die Werte fuer die Waermeuebertragungsfaehigkeit des PCMs bzgl. der Kuehlfluessigkeit geteilt durch die Anzahl der finiten Volumen im PCM ergeben die Werte fuer die Waermeuebertragungsfaehigkeit des Batteriepacks bzgl. einem finiten Volumen
% -> Dies ist der Fall, weil jedes finite Volumen im PCM gleich groß ist und weil von einer konstanten Waermedurchgangszahl ausgegangen wird und weil die Summe der Waermeuebertragungsflaechen bzgl. der finten Volumen im PCM gleich der Waermeuebertragungsflaeche bzgl. der Kuehlfluessigkeit im PCM ist
if exist('Fluid_PCM')==1
   for i=1:size(Fluid_PCM,2)
       UA_PCM_FinitesVolumen_Table{i}=UA_PCM_Kuehlfluessigkeit_Table{i}/(Fluid_PCM(i).l_Kuehlfluessigkeit/l_FinitesVolumen); % Die Waermeuebertragungsfaehigkeit des PCM bzgl. einem finiten Volumen in Abh. vom Volumenstrom der Kuehlfluessigkeit in W/K -> Fluid_PCM(1).l_Kuehlfluessigkeit/l_FinitesVolumen = Anzahl der finiten Volumen im i. PCM
       
   end
end

for i=1:size(PCM,2)
PCM(i).b_PCM=delta_t/C_PCM{i};                                                   % Größe b (hier ein Skalar, weil es keine weitere Komponente gibt, mit der Konduktion auftritt -> Deswegen existiert auch keine Waermeleit-Matrix A) fuer das PCM in (s*K)/J nach Schötz "Thermische Modellierung und Optimierung elektrischer Antriebsstraenge"
end

%% Parameter Subsystem "Peltier"

% -> Die Aufteilung der Leistung auf die einzelnen finiten Volumen findet in der Simulation abhaengig der Größe des Temperaturvektors statt


%% Parameter Subsystem "Schlauch"

% -> In dieser Version des Thermomanagementsystemmodells nicht vorhanden

%% IV. Aufbau und Parametrierung bzw. Bearbeitung des Thermomanagementsystemmodells

%% Aufbau und Parametrierung des Subsystems "Fluid"

%--------------------------------------------------------------------------
% Aufbau und Parametrierung des Subsystems "Bestimmung PV_Kuehlkreislauf" im Subsystem "Fluid" für die Bestimmung der Volumenströme in den Kühlkreisläufen
%--------------------------------------------------------------------------

if n_Kuehlkreislauf~=0
   for i=1:n_Kuehlkreislauf
       add_block([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf'],[Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')'],'CopyOption','duplicate'); % Kopieren des allgemein modellierten Kuehlkreislauf und Umbenennen in entsprechenden Kuehlkreislauf
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf'],'Position')+[0,i*120,0,i*120]); % Positionierung des neu erzeugten Kuehlkreislauf
       add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf'],'EMaschine_Output/1',['Kuehlkreislauf(',num2str(i),')/1'],'autorouting','on'); % Verbindung des Eingangs für EMaschine_Output mit dem entsprechenden Kuehlkreislauf       
       add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf'],'Leistungselektronik_Output/1',['Kuehlkreislauf(',num2str(i),')/2'],'autorouting','on'); % Verbindung des Eingangs für Leistungselektronik_Output mit dem entsprechenden Kuehlkreislauf       
       add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf'],'Batteriepack_Output/1',['Kuehlkreislauf(',num2str(i),')/3'],'autorouting','on'); % Verbindung des Eingangs für Batteriepack_Output mit dem entsprechenden Kuehlkreislauf       
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Bus Creator'],'Inputs',num2str(n_Kuehlkreislauf)); % Bestimmung der Anzahl der Inputs des Bus Creators für PV_Kuehlkreislauf
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf'],['Kuehlkreislauf(',num2str(i),')/1'],['Bus Creator/',num2str(i)],'autorouting','on'),'Name',['PV_Kuehlkreislauf(',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Kuehlkreislauf mit einem Input des Bus Creators für PV_Kuehlkreislauf und Benennung des Signals    
       if Steuerung_Pumpe==1
          j=2;
          if any(strcmp('Fluid_EMaschine(1)',Graph_Kuehlkreislauf{i}.Nodes{:,1}))==1
             set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Bus Selector'],'OutputSignals','T_EMaschine_Getriebe [K].T_EMaschine [K]'); % Parametrierung des Bus Selectors für EMaschine_Output in dem entsprechenden Kuehlkreislauf
             set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Max'],'Inputs',num2str(j)); % Bestimmung der Anzahl der Inputs des Blocks "Max" in dem entsprechenden Kuehlkreislauf
             add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe'],'Bus Selector/1',['Max/',num2str(j)],'autorouting','on'); % Verbindung des Output-Signals des Bus Selectors für EMaschine_Output mit dem Block "Max"
             j=j+1;
          elseif any(strcmp('Fluid_EMaschine(1)',Graph_Kuehlkreislauf{i}.Nodes{:,1}))==0
                 set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für EMaschine_Output in dem entsprechenden Kuehlkreislauf
          end
          if any(strcmp('Fluid_Leistungselektronik(1)',Graph_Kuehlkreislauf{i}.Nodes{:,1}))==1
             set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Bus Selector1'],'OutputSignals','T_Leistungselektronik [K].T_c [K]'); % Parametrierung des Bus Selectors für Leistungselektronik_Output in dem entsprechenden Kuehlkreislauf
             set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Max'],'Inputs',num2str(j)); % Bestimmung der Anzahl der Inputs des Blocks "Max" in dem entsprechenden Kuehlkreislauf
             add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe'],'Bus Selector1/1',['Max/',num2str(j)],'autorouting','on'); % Verbindung des Output-Signals des Bus Selectors für Leistungselektronik_Output mit dem Block "Max"
             j=j+1;
          elseif any(strcmp('Fluid_Leistungselektronik(1)',Graph_Kuehlkreislauf{i}.Nodes{:,1}))==0
                 set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Bus Selector1'],'commented','on'); % Auskommentieren des Bus Selectors für Leistungselektronik_Output in dem entsprechenden Kuehlkreislauf
          end
          if any(strcmp('Fluid_Batteriepack(1)',Graph_Kuehlkreislauf{i}.Nodes{:,1}))==1
             set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Bus Selector2'],'OutputSignals','T_Batteriepack [K]'); % Parametrierung des Bus Selectors für Batteriepack_Output in dem entsprechenden Kuehlkreislauf
             set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Max'],'Inputs',num2str(j)); % Bestimmung der Anzahl der Inputs des Blocks "Max" in dem entsprechenden Kuehlkreislauf
             add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe'],'Bus Selector2/1',['Max/',num2str(j)],'autorouting','on'); % Verbindung des Output-Signals des Bus Selectors für Batteriepack_Output mit dem Block "Max"
          elseif any(strcmp('Fluid_Batteriepack(1)',Graph_Kuehlkreislauf{i}.Nodes{:,1}))==0
                 set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/Bus Selector2'],'commented','on'); % Auskommentieren des Bus Selectors für Batteriepack_Output in dem entsprechenden Kuehlkreislauf
          end
          set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/n-D Lookup Table'],'BreakpointsForDimension1',mat2str(PV_Kuehlkreislauf_Break_T_Komponente_max{i})); % Parametrierung von n-D Lookup Table für PV_Kuehlkreislauf mit Breakpoints 1 in dem entsprechenden Kuehlkreislauf 
          set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe/n-D Lookup Table'],'Table',mat2str(PV_Kuehlkreislauf_Table{i})); % Parametrierung von n-D Lookup Table für PV_Kuehlkreislauf mit Table data in dem entsprechenden Kuehlkreislauf 
          set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/PV_Kuehlkreislauf'],'commented','on'); % Auskommentieren von PV_Kuehlkreislauf, wenn die Pumpen gesteuert sind und deswegen PV_Kuehlkreislauf nicht von Bedeutung ist
       elseif Steuerung_Pumpe==0
              set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/PV_Kuehlkreislauf'],'VariableName',mat2str(PV_Kuehlkreislauf{i})); % Parametrierung von PV_Kuehlkreislauf in dem entsprechenden Kuehlkreislauf
              set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')/Steuerung Pumpe'],'commented','on'); % Auskommentieren des Subsystems "Steuerung Pumpe" in dem entsprechenden Kuehlkreislauf, wenn die Pumpen ungesteuert sind und deswegen das Subsystem "Steuerung Pumpe" nicht von Bedeutung ist   
       end
   end
   set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator6'],'Inputs','1'); % Festlegung der Anzahl der Inputs des Bus Creators für Kuehlkreislauf_Output = 1, wenn mindestens ein Kühlkreislauf modelliert ist (n_Kuehlkreislauf ~= 0), weil dann der Bus mit PV_Kuehlkreislauf Daten enthält
   set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1','Bus Creator6/1','autorouting','on'),'Name','PV_Kuehlkreislauf [m^3*s^-1]'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem Input 1 des Bus Creators für Kuehlkreislauf_Output und Benennung des Signals
elseif n_Kuehlkreislauf==0
       set_param([Modell,'/Output/Kuehlkreislauf'],'commented','on');       % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Kühlkreislauf modelliert ist (n_Kuehlkreislauf = 0) und es dadaurch keine Daten gibt
end

%--------------------------------------------------------------------------
% Aufbau und Parametrierung des Subsystems "Bestimmung Zustand_Ventil" im Subsystem "Fluid" für die Bestimmung der Zustände der Dreiwegeventile
%--------------------------------------------------------------------------

if exist('Ventil')==1
   for i=1:size(Ventil,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil'],[Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')'],'CopyOption','duplicate'); % Kopieren des allgemein modellierten Ventil und Umbenennen in entsprechendes Ventil
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil'],'Position')+[0,i*120,0,i*120]); % Positionierung des neu erzeugten Ventil
       add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil'],'Fluid_Schlauch_Output/1',['Ventil(',num2str(i),')/1'],'autorouting','on'); % Verbindung des Eingangs für Fluid_Schlauch_Output mit dem entsprechenden Ventil       
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Bus Creator'],'Inputs',num2str(size(Ventil,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Zustand_Ventil
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil'],['Ventil(',num2str(i),')/1'],['Bus Creator/',num2str(i)],'autorouting','on'),'Name',['Zustand_Ventil(',num2str(i),') [-]']); % Verbindung des entsprechenden Ventil mit einem Input des Bus Creators für Zustand_Ventil und Benennung des Signals    
       if Steuerung_Ventil==1
          set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')/Steuerung Ventil/Bus Selector'],'OutputSignals',['T_FinitesVolumen_',regexprep(Ventil(i).Ventil_nach,'Fluid_',''),' [K]']); % Parametrierung des Bus Selectors für Fluid_Schlauch_Output in dem entsprechenden Ventil
          set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')/Steuerung Ventil/Selector_n'],'IndexParamArray',{num2str(eval([Ventil(i).Ventil_nach,'.l_Kuehlfluessigkeit'])/l_FinitesVolumen)}); % Parametrierung des Selectors bzgl. des n. finiten Volumens der Fluid_Komponente, die bei Ventil_nach festgelegt ist, in dem entsprechenden Ventil
          set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')/Steuerung Ventil/n-D Lookup Table'],'BreakpointsForDimension1',mat2str(Ventil(i).Zustand_Ventil_Break_T_FinitesVolumen_Ventil_nach)); % Parametrierung von n-D Lookup Table für Zustand_Ventil mit Breakpoints 1 in dem entsprechenden Ventil 
          set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')/Steuerung Ventil/n-D Lookup Table'],'Table',mat2str(Ventil(i).Zustand_Ventil_Table)); % Parametrierung von n-D Lookup Table für Zustand_Ventil mit Table data in dem entsprechenden Ventil 
          set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')/Zustand_Ventil'],'commented','on'); % Auskommentieren von Zustand_Ventil in dem entsprechenden Ventil, wenn die Dreiwegeventile gesteuert sind und deswegen Zustand_Ventil nicht von Bedeutung ist
       elseif Steuerung_Ventil==0
              set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')/Zustand_Ventil'],'VariableName',mat2str(Ventil(i).Zustand_Ventil)); % Parametrierung von Zustand_Ventil in dem entsprechenden Ventil
              set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')/Steuerung Ventil'],'commented','on'); % Auskommentieren des Subsystems "Steuerung Ventil" in dem entsprechenden Ventil, wenn die Dreiwegeventile ungesteuert sind und deswegen das Subsystem "Steuerung Ventil" nicht von Bedeutung ist   
      else
           fprintf('\nFehler bei der Angabe von Steuerung_Ventil!\n');
           keyboard;
       end
   end
   set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator6'],'Inputs','2'); % Festlegung der Anzahl der Inputs des Bus Creators für Kuehlkreislauf_Output = 2, wenn mindestens ein Dreiwegeventil festgelegt ist, weil dann der Bus mit Zustand_Ventil Daten enthält (Input 1 ist mit dem Bus von PV_Kuehlkreislauf verbunden, weil Dreiwegeventile nur festgelegt sein können, wenn mindestens ein Kühlkreislauf modelliert ist und dadurch der Bus mit PV_Kuehlkreislauf Daten enthält und mit Input 1 verbunden ist)
   set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1','Bus Creator6/2','autorouting','on'),'Name','Zustand_Ventil [-]'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem Input 2 des Bus Creators für Kuehlkreislauf_Output und Benennung des Signals    
end

%--------------------------------------------------------------------------
% Aufbau und Parametrierung der Fluid_Komponenten im Subsystem "Fluid"
%--------------------------------------------------------------------------

j=1;
% -> Fluid_Kuehler
if exist('Fluid_Kuehler')==1
   k=1;
   for i=1:size(Fluid_Kuehler,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechenden Fluid_Kuehler
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung des neu erzeugten Fluid_Kuehler
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Kuehler(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem entsprechenden Fluid_Kuehler
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Kuehler(',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem entsprechenden Fluid_Kuehler
       j=j+1;
       Bus_Selector_Fluid{i}=['PQ_Kuehler(',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für Kuehler_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Fluid,', ')); % Parametrierung des Bus Selectors für Kuehler_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector/',num2str(i)],['Fluid_Kuehler(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Kuehler_Output mit dem entsprechenden Fluid_Kuehler
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator'],'Inputs',num2str(2*size(Fluid_Kuehler,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_Kuehler_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Kuehler(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(k)],'autorouting','on'),'Name',['T_FinitesVolumen_Kuehler(',num2str(i),') [K]']); % Verbindung des entsprechenden Fluid_Kuehler mit einem Input des Bus Creators für Fluid_Kuehler_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Kuehler(',num2str(i),') thermisch/3'],['Bus Creator/',num2str(k)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_Kuehler(',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Fluid_Kuehler mit einem Input des Bus Creators für Fluid_Kuehler_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_Kuehler(i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in dem entsprechenden Fluid_Kuehler
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_Kuehler(i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in dem entsprechenden Fluid_Kuehler
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_Kuehler(i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in dem entsprechenden Fluid_Kuehler
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_Kuehler(i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in dem entsprechenden Fluid_Kuehler
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_Kuehler(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Kuehler
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_Kuehler(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Kuehler       
   end
elseif exist('Fluid_Kuehler')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Kuehler_Output, wenn kein Fluid_Kuehler existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Fluid_Kuehler'],'commented','on');        % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Fluid_Kuehler existiert und es dadaurch keine Daten gibt
end

% -> Fluid_Waermetauscher
if exist('Fluid_Waermetauscher')==1
   k=1;
   l=1;
   for i=1:size(Fluid_Waermetauscher,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung des neu erzeugten Fluid_Waermetauscher
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Waermetauscher(1,',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem entsprechenden Fluid_Waermetauscher
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Waermetauscher(1,',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem entsprechenden Fluid_Waermetauscher
       j=j+1;
       Bus_Selector1_Fluid{k}=['PQ_Waermetauscher(1_',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für Waermetauscher_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector1'],'OutputSignals',strjoin(Bus_Selector1_Fluid,', ')); % Parametrierung des Bus Selectors für Waermetauscher_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector1/',num2str(k)],['Fluid_Waermetauscher(1,',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Waermetauscher_Output mit dem entsprechenden Fluid_Waermetauscher
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator1'],'Inputs',num2str(4*size(Fluid_Waermetauscher,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_Waermetauscher_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Waermetauscher(1,',num2str(i),') thermisch/1'],['Bus Creator1/',num2str(l)],'autorouting','on'),'Name',['T_FinitesVolumen_Waermetauscher(1_',num2str(i),') [K]']); % Verbindung des entsprechenden Fluid_Waermetauscher mit einem Input des Bus Creators für Fluid_Waermetauscher_Output und Benennung des Signals 
       l=l+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Waermetauscher(1,',num2str(i),') thermisch/3'],['Bus Creator1/',num2str(l)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_Waermetauscher(1_',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Fluid_Waermetauschere mit einem Input des Bus Creators für Fluid_Waermetauscher_Output und Benennung des Signals
       l=l+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_Waermetauscher(1,i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_Waermetauscher(1,i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_Waermetauscher(1,i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_Waermetauscher(1,i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_Waermetauscher(1,i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_Waermetauscher(1,i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Waermetauscher 
       
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung des neu erzeugten Fluid_Waermetauscher
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Waermetauscher(2,',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem entsprechenden Fluid_Waermetauscher
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Waermetauscher(2,',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem entsprechenden Fluid_Waermetauscher
       j=j+1;
       Bus_Selector1_Fluid{k}=['PQ_Waermetauscher(2_',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für Waermetauscher_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector1'],'OutputSignals',strjoin(Bus_Selector1_Fluid,', ')); % Parametrierung des Bus Selectors für Waermetauscher_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector1/',num2str(k)],['Fluid_Waermetauscher(2,',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Waermetauscher_Output mit dem entsprechenden Fluid_Waermetauscher
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Waermetauscher(2,',num2str(i),') thermisch/1'],['Bus Creator1/',num2str(l)],'autorouting','on'),'Name',['T_FinitesVolumen_Waermetauscher(2_',num2str(i),') [K]']); % Verbindung des entsprechenden Fluid_Waermetauscher mit einem Input des Bus Creators für Fluid_Waermetauscher_Output und Benennung des Signals 
       l=l+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Waermetauscher(2,',num2str(i),') thermisch/3'],['Bus Creator1/',num2str(l)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_Waermetauscher(2_',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Fluid_Waermetauscher mit einem Input des Bus Creators für Fluid_Waermetauscher_Output und Benennung des Signals
       l=l+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_Waermetauscher(2,i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_Waermetauscher(2,i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_Waermetauscher(2,i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_Waermetauscher(2,i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_Waermetauscher(2,i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_Waermetauscher(2,i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Waermetauscher 
   end
elseif exist('Fluid_Waermetauscher')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector1'],'commented','on'); % Auskommentieren des Bus Selectors für Waermetauscher_Output, wenn kein Fluid_Waermetauscher existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Fluid_Waermetauscher'],'commented','on'); % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Fluid_Waermetauscher existiert und es dadaurch keine Daten gibt
end

% -> Fluid_EMaschine
if exist('Fluid_EMaschine')==1 
   k=1;
   for i=1:size(Fluid_EMaschine,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechende Fluid_EMaschine
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung der neu erzeugten Fluid_EMaschine
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_EMaschine(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit der entsprechenden Fluid_EMaschine
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_EMaschine(',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit der entsprechenden Fluid_EMaschine
       j=j+1;
       Bus_Selector2_Fluid{i}=['PQ_EMaschine(',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors EMaschine_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector2'],'OutputSignals',strjoin(Bus_Selector2_Fluid,', ')); % Parametrierung des Bus Selectors für EMaschine_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector2/',num2str(i)],['Fluid_EMaschine(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für EMaschine_Output mit der entsprechenden Fluid_EMaschine
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator2'],'Inputs',num2str(2*size(Fluid_EMaschine,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_EMaschine_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_EMaschine(',num2str(i),') thermisch/1'],['Bus Creator2/',num2str(k)],'autorouting','on'),'Name',['T_FinitesVolumen_EMaschine(',num2str(i),') [K]']); % Verbindung der entsprechenden Fluid_EMaschine mit einem Input des Bus Creators für Fluid_EMaschine_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_EMaschine(',num2str(i),') thermisch/3'],['Bus Creator2/',num2str(k)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_EMaschine(',num2str(i),') [m^3*s^-1]']); % Verbindung der entsprechenden Fluid_EMaschine mit einem Input des Bus Creators für Fluid_EMaschine_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_EMaschine(i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in der entsprechenden Fluid_EMaschine
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_EMaschine(i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in der entsprechenden Fluid_EMaschine
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_EMaschine(i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in der entsprechenden Fluid_EMaschine
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_EMaschine(i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in der entsprechenden Fluid_EMaschine
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_EMaschine(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in der entsprechenden Fluid_EMaschine
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_EMaschine(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in der entsprechenden Fluid_EMaschine 
   end
elseif exist('Fluid_EMaschine')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector2'],'commented','on'); % Auskommentieren des Bus Selectors für EMaschine_Output, wenn keine Fluid_EMaschine existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Fluid_EMaschine'],'commented','on');      % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn keine Fluid_EMaschine existiert und es dadaurch keine Daten gibt
end

% -> Fluid_Leistungselektronik
if exist('Fluid_Leistungselektronik')==1
   k=1;
   for i=1:size(Fluid_Leistungselektronik,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechende Fluid_Leistungselektronik
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung der neu erzeugten Fluid_Leistungselektronik
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Leistungselektronik(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit der entsprechenden Fluid_Leistungselektronik
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Leistungselektronik(',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit der entsprechenden Fluid_Leistungselektronik
       j=j+1;
       Bus_Selector3_Fluid{i}=['PQ_Leistungselektronik(',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für Leistungselektronik_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector3'],'OutputSignals',strjoin(Bus_Selector3_Fluid,', ')); % Parametrierung des Bus Selectors für Leistungselektronik_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector3/',num2str(i)],['Fluid_Leistungselektronik(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Leistungselektronik_Output mit der entsprechenden Fluid_Leistungselektronik
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator3'],'Inputs',num2str(2*size(Fluid_Leistungselektronik,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_Leistungselektronik_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Leistungselektronik(',num2str(i),') thermisch/1'],['Bus Creator3/',num2str(k)],'autorouting','on'),'Name',['T_FinitesVolumen_Leistungselektronik(',num2str(i),') [K]']); % Verbindung der entsprechenden Fluid_Leistungselektronik mit einem Input des Bus Creators für Fluid_Leistungselektronik_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Leistungselektronik(',num2str(i),') thermisch/3'],['Bus Creator3/',num2str(k)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_Leistungselektronik(',num2str(i),') [m^3*s^-1]']); % Verbindung der entsprechenden Fluid_Leistungselektronik mit einem Input des Bus Creators für Fluid_Leistungselektronik_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_Leistungselektronik(i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in der entsprechenden Fluid_Leistungselektronik
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_Leistungselektronik(i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in der entsprechenden Fluid_Leistungselektronik
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_Leistungselektronik(i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in der entsprechenden Fluid_Leistungselektronik
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_Leistungselektronik(i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in der entsprechenden Fluid_Leistungselektronik       
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_Leistungselektronik(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in der entsprechenden Fluid_Leistungselektronik
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_Leistungselektronik(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in der entsprechenden Fluid_Leistungselektronik 
   end
elseif exist('Fluid_Leistungselektronik')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector3'],'commented','on'); % Auskommentieren des Bus Selectors für Leistungselektronik_Output, wenn keine Fluid_Leistungselektronik existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Fluid_Leistungselektronik'],'commented','on'); % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn keine Fluid_Leistungselektronik existiert und es dadaurch keine Daten gibt
end        

% -> Fluid_Batteriepack
if exist('Fluid_Batteriepack')==1
   k=1;
   for i=1:size(Fluid_Batteriepack,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechendes Fluid_Batteriepack
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung des neu erzeugten Fluid_Batteriepack
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Batteriepack(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem entsprechenden Fluid_Batteriepack
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Batteriepack(',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem entsprechenden Fluid_Batteriepack
       j=j+1;
       Bus_Selector4_Fluid{i}=['PQ_Batteriepack(',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für Batteriepack_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector4'],'OutputSignals',strjoin(Bus_Selector4_Fluid,', ')); % Parametrierung des Bus Selectors für Batteriepack_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector4/',num2str(i)],['Fluid_Batteriepack(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Batteriepack_Output mit dem entsprechenden Fluid_Batteriepack
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator4'],'Inputs',num2str(2*size(Fluid_Batteriepack,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_Batteriepack_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Batteriepack(',num2str(i),') thermisch/1'],['Bus Creator4/',num2str(k)],'autorouting','on'),'Name',['T_FinitesVolumen_Batteriepack(',num2str(i),') [K]']); % Verbindung des entsprechenden Fluid_Batteriepack mit einem Input des Bus Creators für Fluid_Batteriepack_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Batteriepack(',num2str(i),') thermisch/3'],['Bus Creator4/',num2str(k)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_Batteriepack(',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Fluid_Batteriepack mit einem Input des Bus Creators für Fluid_Batteriepack_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_Batteriepack(i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in dem entsprechenden Fluid_Batteriepack
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_Batteriepack(i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in dem entsprechenden Fluid_Batteriepack
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_Batteriepack(i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in dem entsprechenden Fluid_Batteriepack      
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_Batteriepack(i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in dem entsprechenden Fluid_Batteriepack       
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_Batteriepack(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Batteriepack
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_Batteriepack(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Batteriepack 
   end
elseif exist('Fluid_Batteriepack')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector4'],'commented','on'); % Auskommentieren des Bus Selectors für Batteriepack_Output, wenn kein Fluid_Batteriepack existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Fluid_Batteriepack'],'commented','on');   % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Fluid_Batteriepack existiert und es dadaurch keine Daten gibt
end     

% -> Fluid Ladegeraet
if exist('Fluid_Ladegeraet')==1
   k=1;
   for i=1:size(Fluid_Ladegeraet,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechendes Fluid_Ladegeraet
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung des neu erzeugten Fluid_Ladegeraet
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Ladegeraet(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem entsprechenden Fluid_Ladegeraet
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Ladegeraet(',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem entsprechenden Fluid_Ladegeraet
       j=j+1;
       Bus_Selector6_Fluid{i}=['PQ_Ladegeraet(',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für Ladegeraet_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector6'],'OutputSignals',strjoin(Bus_Selector6_Fluid,', ')); % Parametrierung des Bus Selectors für Ladegeraet_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector6/',num2str(i)],['Fluid_Ladegeraet(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Ladegeraet_Output mit dem entsprechenden Fluid_Ladegeraet
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator7'],'Inputs',num2str(2*size(Fluid_Ladegeraet,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_Ladegeraet_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Ladegeraet(',num2str(i),') thermisch/1'],['Bus Creator7/',num2str(k)],'autorouting','on'),'Name',['T_FinitesVolumen_Ladegeraet(',num2str(i),') [K]']); % Verbindung des entsprechenden Fluid_Ladegeraet mit einem Input des Bus Creators für Fluid_Ladegeraet_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Ladegeraet(',num2str(i),') thermisch/3'],['Bus Creator7/',num2str(k)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_Ladegeraet(',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Fluid_Ladegeraet mit einem Input des Bus Creators für Fluid_Ladegeraet_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_Ladegeraet(i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in dem entsprechenden Fluid_Ladegeraet
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_Ladegeraet(i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in dem entsprechenden Fluid_Ladegeraet
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_Ladegeraet(i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in dem entsprechenden Fluid_Ladegeraet      
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_Ladegeraet(i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in dem entsprechenden Fluid_Ladegeraet       
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_Ladegeraet(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Ladegeraet
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_Ladegeraet(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Ladegeraet 
   end
elseif exist('Fluid_Ladegeraet')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector6'],'commented','on'); % Auskommentieren des Bus Selectors für Ladegeraet_Output, wenn kein Fluid_Ladegeraet existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Fluid_Ladegeraet'],'commented','on');   % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Fluid_Ladegeraet existiert und es dadaurch keine Daten gibt
end     

% -> Fluid_PCM
if exist('Fluid_PCM')==1
   k=1;
   for i=1:size(Fluid_PCM,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechendes Fluid_PCM
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung des neu erzeugten Fluid_PCM
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_PCM(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem entsprechenden Fluid_PCM
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_PCM(',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem entsprechenden Fluid_PCM
       j=j+1;
       Bus_Selector7_Fluid{i}=['PQ_PCM(',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für PCM_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector7'],'OutputSignals',strjoin(Bus_Selector7_Fluid,', ')); % Parametrierung des Bus Selectors für PCM_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector7/',num2str(i)],['Fluid_PCM(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für PCM_Output mit dem entsprechenden Fluid_PCM
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator8'],'Inputs',num2str(2*size(Fluid_PCM,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_PCM_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_PCM(',num2str(i),') thermisch/1'],['Bus Creator8/',num2str(k)],'autorouting','on'),'Name',['T_FinitesVolumen_PCM(',num2str(i),') [K]']); % Verbindung des entsprechenden Fluid_PCM mit einem Input des Bus Creators für Fluid_PCM_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_PCM(',num2str(i),') thermisch/3'],['Bus Creator8/',num2str(k)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_PCM(',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Fluid_PCM mit einem Input des Bus Creators für Fluid_PCM_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_PCM(i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in dem entsprechenden Fluid_PCM
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_PCM(i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in dem entsprechenden Fluid_PCM
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_PCM(i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in dem entsprechenden Fluid_PCM      
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_PCM(i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in dem entsprechenden Fluid_PCM       
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_PCM(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_PCM
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_PCM(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_PCM 
   end
elseif exist('Fluid_PCM')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector7'],'commented','on'); % Auskommentieren des Bus Selectors für PCM_Output, wenn kein Fluid_PCM existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Fluid_PCM'],'commented','on');   % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Fluid_PCM existiert und es dadaurch keine Daten gibt
end     

% -> Fluid_Peltier
if exist('Fluid_Peltier')==1
   k=1;
   for i=1:size(Fluid_Peltier,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechendes Fluid_Peltier
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung des neu erzeugten Fluid_Peltier
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Peltier(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem entsprechenden Fluid_Peltier
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Peltier(',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem entsprechenden Fluid_Peltier
       j=j+1;
       Bus_Selector8_Fluid{i}=['PQ_Peltier(',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für Peltier_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector8'],'OutputSignals',strjoin(Bus_Selector8_Fluid,', ')); % Parametrierung des Bus Selectors für Peltier_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector8/',num2str(i)],['Fluid_Peltier(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Peltier_Output mit dem entsprechenden Fluid_Peltier
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator9'],'Inputs',num2str(2*size(Fluid_Peltier,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_Peltier_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Peltier(',num2str(i),') thermisch/1'],['Bus Creator9/',num2str(k)],'autorouting','on'),'Name',['T_FinitesVolumen_Peltier(',num2str(i),') [K]']); % Verbindung des entsprechenden Fluid_Peltier mit einem Input des Bus Creators für Fluid_Peltier_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Peltier(',num2str(i),') thermisch/3'],['Bus Creator9/',num2str(k)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_Peltier(',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Fluid_Peltier mit einem Input des Bus Creators für Fluid_Peltier_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_Peltier(i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in dem entsprechenden Fluid_Peltier
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_Peltier(i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in dem entsprechenden Fluid_Peltier
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_Peltier(i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in dem entsprechenden Fluid_Peltier      
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_Peltier(i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in dem entsprechenden Fluid_Peltier       
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_Peltier(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Peltier
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_Peltier(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Peltier 
   end
elseif exist('Fluid_Peltier')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector8'],'commented','on'); % Auskommentieren des Bus Selectors für Peltier_Output, wenn kein Fluid_Peltier existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Fluid_Peltier'],'commented','on');   % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Fluid_Peltier existiert und es dadaurch keine Daten gibt
end     

% -> Fluid_Schlauch
if exist('Fluid_Schlauch')==1
   k=1;
   for i=1:size(Fluid_Schlauch,2)
       add_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],[Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren der allgemein modellierten Fluid_Komponente und Umbenennen in entsprechenden Fluid_Schlauch
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'Position')+[0,j*360,0,j*360]); % Positionierung des neu erzeugten Fluid_Schlauch
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Schlauch(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung PV_Kuehlkreislauf" mit dem entsprechenden Fluid_Schlauch
       add_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Schlauch(',num2str(i),') thermisch/13'],'autorouting','on'); % Verbindung des Subsystems "Bestimmung Zustand_Ventil" mit dem entsprechenden Fluid_Schlauch
       j=j+1;
       Bus_Selector5_Fluid{i}=['PQ_Schlauch(',num2str(i),')_FinitesVolumen [W]']; % Liste der Namen der Output-Signale des Bus Selectors für Schlauch_Output
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector5'],'OutputSignals',strjoin(Bus_Selector5_Fluid,', ')); % Parametrierung des Bus Selectors für Schlauch_Output
       add_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector5/',num2str(i)],['Fluid_Schlauch(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Schlauch_Output mit dem entsprechenden Fluid_Schlauch
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Creator5'],'Inputs',num2str(2*size(Fluid_Schlauch,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Fluid_Schlauch_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Schlauch(',num2str(i),') thermisch/1'],['Bus Creator5/',num2str(k)],'autorouting','on'),'Name',['T_FinitesVolumen_Schlauch(',num2str(i),') [K]']); % Verbindung des entsprechenden Fluid_Schlauch mit einem Input des Bus Creators für Fluid_Schlauch_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Schlauch(',num2str(i),') thermisch/3'],['Bus Creator5/',num2str(k)],'autorouting','on'),'Name',['PV_Kuehlfluessigkeit_Schlauch(',num2str(i),') [m^3*s^-1]']); % Verbindung des entsprechenden Fluid_Schlauch mit einem Input des Bus Creators für Fluid_Schlauch_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch/T_FinitesVolumen_init'],'Value',mat2str(Fluid_Schlauch(i).T_FinitesVolumen_init)); % Parametrierung von T_FinitesVolumen_init in dem entsprechenden Fluid_Schlauch
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch/R_FinitesVolumen'],'Value',num2str(Fluid_Schlauch(i).R_FinitesVolumen)); % Parametrierung von R_FinitesVolumen in dem entsprechenden Fluid_Schlauch
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch/b_FinitesVolumen'],'Value',num2str(Fluid_Schlauch(i).b_FinitesVolumen)); % Parametrierung von b_FinitesVolumen in dem entsprechenden Fluid_Schlauch     
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch/Bus Selector'],'OutputSignals',['PV_Kuehlkreislauf(',num2str(Fluid_Schlauch(i).Nr_Kuehlkreislauf),') [m^3*s^-1]']); % Parametrierung des Bus Selectors für PV_Kuehlkreislauf in dem entsprechenden Fluid_Schlauch       
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch/rho_Kuehlfluessigkeit'],'Value',num2str(rho_Kuehlfluessigkeit(Fluid_Schlauch(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Schlauch
       set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch/c_Kuehlfluessigkeit'],'Value',num2str(c_Kuehlfluessigkeit(Fluid_Schlauch(i).Nr_Kuehlkreislauf))); % Parametrierung von rho_Kuehlfluessigkeit in dem entsprechenden Fluid_Schlauch 
   end
elseif exist('Fluid_Schlauch')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector5'],'commented','on'); % Auskommentieren des Bus Selectors für Schlauch_Output, wenn kein Fluid_Schlauch existiert, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist    
       set_param([Modell,'/Output/Fluid_Schlauch'],'commented','on');       % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Fluid_Schlauch existiert und es dadaurch keine Daten gibt
end

%--------------------------------------------------------------------------
% Kopplung der Fluid_Komponenten im Subsystem "Fluid" abh. von der Konfiguration der Kühlkreisläufe
%--------------------------------------------------------------------------

% -> Eingänge und Ausgänge der Fluid_Komponenten ergeben sich aus den benötigten Größen für die Kopplung unterschiedlicher Fuid_Komponenten, um den Energierhaltungssatz auswerten zu können
% -> Die Fluid_Komponenten werden miteinander verbunden, weil sie gekoppelt werden müssen, um die Konduktion für alle finiten Volumen (auch für das 1. und n. finite Volumen einer Fluid_Komponente) berechnen zu können und um die Differenz der Energieströme zwischen Eingang und Ausgang aller finiten Volumen (auch des 1. finiten Volumens einer Fluid_Komponente) berechnen zu können
% -> Die Kopplungen der Fluid_Komponenten sind in den Edges von Graph_Kuehlkreislauf festgelegt

for i=1:n_Kuehlkreislauf
    for j=1:size(Graph_Kuehlkreislauf{i}.Edges,1)
        Port_Verbindung=get_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch'],'PortConnectivity');
        if Port_Verbindung(3).SrcBlock==-1
           add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/1'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/3'],'autorouting','on');
           add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/2'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/4'],'autorouting','on');
           add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/3'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/5'],'autorouting','on');
        else
            add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/1'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/6'],'autorouting','on');
            add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/2'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/7'],'autorouting','on');
            add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/3'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/8'],'autorouting','on');
        end
        Port_Verbindung=get_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch'],'PortConnectivity');
        if Port_Verbindung(9).SrcBlock==-1
           add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/1'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/9'],'autorouting','on');
           add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/2'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/10'],'autorouting','on');
        else
            add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/1'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/11'],'autorouting','on');
            add_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/2'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/12'],'autorouting','on');
        end
    end
end

%--------------------------------------------------------------------------
% Erfassung des korrekten Kopplungsfalls in einer Fluid_Komponente im Subsystem "Fluid" für die Bestimmung der Konduktion für das 1. und n. finite Volumen
%--------------------------------------------------------------------------

% -> Für das 1. finite Volumen:
% -> Je nach Kopplung im Kühlkreislauf wird 1 von 3 Kopplungsfällen in der Fluid_Komponente ausgewählt bzw. die 2 von 3 anderen Kopplungsfällen in der Fluid_Komponente auskommentiert
% -> if-clause 1: Betrachtete Fluid_Komponente befindet sich nach Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade -> Betrachtete Fluid_Komponente befindet sich nach 2 Fluid_Komponenten
% -> if-clause 2: Betrachtete Fluid_Komponente befindet sich nach Dreiwegeventil -> Betrachtete Fluid_Komponente befindet sich nach 1 Fluid_Komponente + Fluid_Komponente vor betrachteter Fluid_Komponente befindet sich vor 2 Fluid_Komponenten
% -> if-clause 3: Betrachtete Fluid_Komponente befindet sich nach anderer Fluid_Komponente ohne Dreiwegeventil oder Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade -> Betrachtete Fluid_Komponente befindet sich nach 1 Fluid_Komponente + Fluid_Komponente vor betrachteter Fluid_Komponente befindet sich vor 1 Fluid_Komponente

for i=1:n_Kuehlkreislauf
    for j=1:size(Graph_Kuehlkreislauf{i}.Nodes,1)
        % -> if-clause 1
        if sum(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)))==2
           set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion 1. finites Volumen mit vorheriger Fluid_Komponente - normal'],'commented','on');
           set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion 1. finites Volumen mit vorheriger Fluid_Komponente - Ventil'],'commented','on');
           set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bus Selector1'],'commented','on'); % Der entsprechende Bus Selector für Zustand_Ventil ist mit dem Subsystem "Konduktion 1. finites Volumen mit vorheriger Fluid_Komponente - Ventil" gekoppelt -> Wenn dieses Subsystem auskommentiert wird bzw. dieser Kopplungsfall nicht vorliegt, muss auch der entsprechende Bus Selector für Zustand_Ventil auskommentiert werden, weil er kein Output-Signal beinhaltet und es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
        % -> if-clause 2+3
        elseif sum(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)))==1
               % -> if-clause 2
               if sum(strcmp(Graph_Kuehlkreislauf{i}.Edges{:,1}{strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)),1},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1)))==2
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion 1. finites Volumen mit vorheriger Fluid_Komponente - normal'],'commented','on');
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion 1. finites Volumen mit vorherigen Fluid_Komponenten - Vereinigung'],'commented','on');
                  % -> Betrachtete Fluid_Komponente befindet sich im Hauptpfad eines Dreiwegeventils
                  if find(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)))==min(find(strcmp(Graph_Kuehlkreislauf{i}.Edges{:,1}{strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)),1},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1))))
                     set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion 1. finites Volumen mit vorheriger Fluid_Komponente - Ventil/Hauptpfad'],'Value','1');
                  % -> Betrachtete Fluid_Komponente befindet sich im Nebenpfad eines Dreiwegeventils
                  elseif find(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)))==max(find(strcmp(Graph_Kuehlkreislauf{i}.Edges{:,1}{strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)),1},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1))))
                         set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion 1. finites Volumen mit vorheriger Fluid_Komponente - Ventil/Hauptpfad'],'Value','0');
                  else
                      fprintf('\nFehler bei der Konfiguration eines Kühlkreislaufs!\n');
                  end
               % -> if-clause 3
               elseif sum(strcmp(Graph_Kuehlkreislauf{i}.Edges{:,1}{strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)),1},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1)))==1
                      set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion 1. finites Volumen mit vorheriger Fluid_Komponente - Ventil'],'commented','on');
                      set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bus Selector1'],'commented','on'); % Der entsprechende Bus Selector für Zustand_Ventil ist mit dem Subsystem "Konduktion 1. finites Volumen mit vorheriger Fluid_Komponente - Ventil" gekoppelt -> Wenn dieses Subsystem auskommentiert wird bzw. dieser Kopplungsfall nicht vorliegt, muss auch der entsprechende Bus Selector für Zustand_Ventil auskommentiert werden, weil er kein Output-Signal beinhaltet und es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
                      set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion 1. finites Volumen mit vorherigen Fluid_Komponenten - Vereinigung'],'commented','on');
               else
                   fprintf('\nFehler bei der Konfiguration eines Kühlkreislaufs!\n');
               end
        else
            fprintf('\nFehler bei der Konfiguration eines Kühlkreislaufs!\n');
        end
    end
end

% -> Für das n. finite Volumen:
% -> Je nach Kopplung im Kühlkreislauf wird 1 von 3 Kopplungsfällen in der Fluid_Komponente ausgewählt bzw. die 2 von 3 anderen Kopplungsfällen in der Fluid_Komponente auskommentiert
% -> if-clause 1: Betrachtete Fluid_Komponente befindet sich vor Dreiwegeventil -> Betrachtete Fluid_Komponente befindet sich vor 2 Fluid_Komponenten
% -> if-clause 2: Betrachtete Fluid_Komponente befindet sich vor Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade -> Betrachtete Fluid_Komponente befindet sich vor 1 Fluid_Komponente + Fluid_Komponente nach betrachteter Fluid_Komponente befindet sich nach 2 Fluid_Komponenten
% -> if-clause 3: Betrachtete Fluid_Komponente befindet sich vor anderer Fluid_Komponente ohne Dreiwegeventil oder Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade -> Betrachtete Fluid_Komponente befindet sich vor 1 Fluid_Kompnente + Fluid_Komponente nach betrachteter Fluid_Komponente befindet sich nach 1 Fluid_Komponente

for i=1:n_Kuehlkreislauf
    for j=1:size(Graph_Kuehlkreislauf{i}.Nodes,1)
        % -> if-clause 1
        if sum(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1)))==2
           set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion n. finites Volumen mit nachfolgender Fluid_Komponente - normal'],'commented','on');
           set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion n. finites Volumen mit nachfolgender Fluid_Komponente - Vereinigung'],'commented','on');
        % -> if-clause 2+3
        elseif sum(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1)))==1
               % -> if-clause 2
               if sum(strcmp(Graph_Kuehlkreislauf{i}.Edges{:,1}{strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1)),2},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)))==2
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion n. finites Volumen mit nachfolgender Fluid_Komponente - normal'],'commented','on');
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion n. finites Volumen mit nachfolgenden Fluid_Komponenten - Ventil'],'commented','on');
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bus Selector2'],'commented','on'); % Der entsprechende Bus Selector für Zustand_Ventil ist mit dem Subsystem "Konduktion n. finites Volumen mit nachfolgenden Fluid_Komponenten - Ventil" gekoppelt -> Wenn dieses Subsystem auskommentiert wird bzw. dieser Kopplungsfall nicht vorliegt, muss auch der entsprechende Bus Selector für Zustand_Ventil auskommentiert werden, weil er kein Output-Signal beinhaltet und es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
               % -> if-clause 3
               elseif sum(strcmp(Graph_Kuehlkreislauf{i}.Edges{:,1}{strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,1)),2},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)))==1
                      set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion n. finites Volumen mit nachfolgender Fluid_Komponente - Vereinigung'],'commented','on');
                      set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Konduktion n. finites Volumen mit nachfolgenden Fluid_Komponenten - Ventil'],'commented','on');
                      set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bus Selector2'],'commented','on'); % Der entsprechende Bus Selector für Zustand_Ventil ist mit dem Subsystem "Konduktion n. finites Volumen mit nachfolgenden Fluid_Komponenten - Ventil" gekoppelt -> Wenn dieses Subsystem auskommentiert wird bzw. dieser Kopplungsfall nicht vorliegt, muss auch der entsprechende Bus Selector für Zustand_Ventil auskommentiert werden, weil er kein Output-Signal beinhaltet und es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
               else
                   fprintf('\nFehler bei der Konfiguration eines Kühlkreislaufs!\n');
               end
        else
            fprintf('\nFehler bei der Konfiguration eines Kühlkreislaufs!\n');
        end
    end
end

%--------------------------------------------------------------------------
% Parametrierung der Fluid_Komponenten im Subsystem "Fluid", die in Verbindung mit einem Dreiwegeventil stehen, mit dem Zustand des entsprechenden Dreiwegeventils für die Bestimmung der Konduktion
%--------------------------------------------------------------------------

% -> Zur Berechnung der Konduktion zwischen Fluid_Komponenten zwischen denen sich ein Dreiwegeventil befindet, wird der Zustand des entsprechenden Dreiwegeventils benötigt
% -> Je nach dem Zustand des entsprechenden Dreiwegeventils stehen die 1. finten Volumen der beiden Fluid_Komponenten nach dem Dreiwegeventil anteilig mit der Querschnittsfläche des n. finten Volumens der Fluid_Komponente vor dem Dreiwegeventil in Kontakt
% -> Deswegen wird die Fluid_Komponente vor dem Dreiwegeventil, die 1. Fluid_Komponente im Hauptpfad des Dreiwegeventils und die 1. Fluid_Komponente im Nebenpfad des Dreiwegeventils mit dem Zustand des entsprechenden Dreiwegeventils parametriert

if exist('Ventil')==1
   for i=1:size(Ventil,2)
       set_param([Modell,'/Thermomanagementsystem/Fluid/',Ventil(i).Ventil_nach,' thermisch/Bus Selector2'],'OutputSignals',['Zustand_Ventil(',num2str(i),') [-]']); % Parametrierung des entsprechenden Bus Selectors für Zustand_Ventil
       set_param([Modell,'/Thermomanagementsystem/Fluid/',Ventil(i).Knoten_Hauptpfad{1,1}{1},' thermisch/Bus Selector1'],'OutputSignals',['Zustand_Ventil(',num2str(i),') [-]']); % Parametrierung des entsprechenden Bus Selectors für Zustand_Ventil            
       set_param([Modell,'/Thermomanagementsystem/Fluid/',Ventil(i).Knoten_Nebenpfad{1,1}{1},' thermisch/Bus Selector1'],'OutputSignals',['Zustand_Ventil(',num2str(i),') [-]']); % Parametrierung des entsprechenden Bus Selectors für Zustand_Ventil
   end
end

%--------------------------------------------------------------------------
% Aufbau und Parametrierung des Subsystems "Bestimmung PV_Kuehlfluessigkeit" in den Fluid_Komponenten im Subsystem "Fluid" für die Bestimmung des korrekten Volumenstroms der Kühlflüssigkeit in einer Fluid_Komponente
%--------------------------------------------------------------------------

% -> Der Massenstrom sowie wegen der inkommpressiblen Annahme und, weil ein homogenes Dichtefeld in einem Kühlkreislauf angenommen wird, auch der Volumenstrom in einem Kühlkreislauf ist im gesamten Kühlkreislauf identisch
% -> Durch ein Dreiwegeventil kommt es in einem Kühlkreislauf zur Aufzweigung des einen Pfades in den Hauptpfad und in den Nebenpfad dieses Dreiwegeventils
% -> Deswegen teilt sich Volumenstrom im Kühlkreislauf in den Hauptpfad und in den Nebenpfad dieses Dreiwegeventils entsprechend dessen Zustand auf
% -> Der Volumenstrom der Kühlflüssigkeit in einer Fluid_Komponente ist also davon abh., ob sich die Fluid_Komponente innerhalb von Dreiwegeventilen befindet
% -> Die Berechnung des Volumenstroms der Kühlflüssigkeit in einer Fluid_Komponente erfolgt in Simulink
% -> Im Folgenden wird für jede Fluid_Komponente geprüft, ob sie sich innerhalb von Dreiwegeventilen befindet und innerhalb welchen Dreiwegeventilen sie sich befindet
% -> Dementsprechend wird das Subsystem "Bestimmung PV_Kuehlfluessigkeit" in der entsprechenden Fluid_Komponente im Subsystem "Fluid" mithilfe des allgemein modellierten Ventil aufgebaut und parametriert

for i=1:n_Kuehlkreislauf
    for j=1:size(Graph_Kuehlkreislauf{i}.Nodes,1)
        if exist('Ventil')==1
           l=1;
           for k=1:size(Ventil,2)
               % -> Betrachtete Fluid_Komponente befindet sich innerhalb des Hauptpfades des betrachteten Dreiwegeventils
               if any(any(cellfun(@any,cellfun(@(x)strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},x),Ventil(k).Knoten_Hauptpfad,'UniformOutput',false))))==1
                  add_block([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil'],[Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil(',num2str(k),')'],'CopyOption','duplicate'); % Kopieren des allgemein modellierten Ventil und Umbenennen in entsprechendes Ventil
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil(',num2str(k),')'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil'],'Position')+[0,l*50,0,l*50]); % Positionierung des neu erzeugten Ventil
                  add_line([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit'],'Zustand_Ventil [-]/1',['Ventil(',num2str(k),')/1'],'autorouting','on'); % Verbindung des Eingangs für Zustand_Ventil mit dem entsprechenden Ventil
                  l=l+1;
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Product'],'Inputs',num2str(l)); % Bestimmung der Anzahl der Inputs des Products
                  set_param(add_line([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit'],['Ventil(',num2str(k),')/1'],['Product/',num2str(l)],'autorouting','on'),'Name',['PV_Kuehlkreislauf_Faktor_Ventil(',num2str(k),') [-]']); % Verbindung des entsprechenden Ventil mit einem Input des Products und Benennung des Signals
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil(',num2str(k),')/Bus Selector'],'OutputSignals',['Zustand_Ventil(',num2str(k),') [-]']); % Parametrierung des Bus Selectors für Zustand_Ventil in dem entsprechenden Ventil
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil(',num2str(k),')/Hauptpfad'],'Value','1'); % Parametrierung von Hauptpfad mit 1 in dem entsprechenden Ventil, weil sich die Fluid_Komponente in diesem Fall im Hauptpfad des Dreiwegeventils befindet
               end
               % -> Betrachtete Fluid_Komponente befindet sich innerhalb des Nebenpfades des betrachteten Dreiwegeventils
               if any(any(cellfun(@any,cellfun(@(x)strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},x),Ventil(k).Knoten_Nebenpfad,'UniformOutput',false))))==1
                  add_block([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil'],[Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil(',num2str(k),')'],'CopyOption','duplicate'); % Kopieren des allgemein modellierten Ventil und Umbenennen in entsprechendes Ventil
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil(',num2str(k),')'],'Position',get_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil'],'Position')+[0,l*50,0,l*50]);  % Positionierung des neu erzeugten Ventil
                  add_line([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit'],'Zustand_Ventil [-]/1',['Ventil(',num2str(k),')/1'],'autorouting','on'); % Verbindung des Eingangs für Zustand_Ventil mit dem entsprechenden Ventil
                  l=l+1;
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Product'],'Inputs',num2str(l)); % Bestimmung der Anzahl der Inputs des Products
                  set_param(add_line([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit'],['Ventil(',num2str(k),')/1'],['Product/',num2str(l)],'autorouting','on'),'Name',['PV_Kuehlkreislauf_Faktor_Ventil(',num2str(k),') [-]']); % Verbindung des entsprechenden Ventil mit einem Input des Products und Benennung des Signals
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil(',num2str(k),')/Bus Selector'],'OutputSignals',['Zustand_Ventil(',num2str(k),') [-]']); % Parametrierung des Bus Selectors für Zustand_Ventil in dem entsprechenden Ventil
                  set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil(',num2str(k),')/Hauptpfad'],'Value','0'); % Parametrierung von Hauptpfad mit 0 in dem entsprechenden Ventil, weil sich die Fluid_Komponente in diesem Fall nicht im Hauptpfad sondern im Nebenpfad des Dreiwegeventils befindet
               end
           end
        end
        set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Bestimmung PV_Kuehlfluessigkeit/Ventil'],'commented','on'); % Auskommentieren des allgemein modellierten Ventil
   end
end

%--------------------------------------------------------------------------
% Erfassung des korrekten Kopplungsfalls in einer Fluid_Komponente im Subsystem "Fluid" für die Bestimmung der Differenz der Energieströme zwischen Eingang und Ausgang des 1. finiten Volumens
%--------------------------------------------------------------------------

% -> Wegen der Aufwind-Interpolation ist nur für die Bestimmung der Differenz der Energieströme zwischen Eingang und Ausgang des 1. finiten Volumens die Kopplung von Fluid_Komponenten notwendig
% -> Je nach Kopplung im Kühlkreislauf wird 1 von 2 Kopplungsfällen in der Fluid_Komponente ausgewählt bzw. der andere Kopplungsfall in der Fluid_Komponente auskommentiert
% -> if-clause 1: Betrachtete Fluid_Komponente befindet sich nach 2 Fluid_Komponenten -> Betrachtete Fluid_Komponente befindet sich nach Vereinigung der zwei nach der Aufzweigung durch ein Dreiwegeventil resultierenden Pfade 
% -> if-clause 2: Betrachtete Fluid_Komponente befindet sich nach 1 Fluid_Komponente -> Es ist irrelevant, ob sich zwischen den beiden Fluid_Komponenten ein Dreiwegeventil befindet oder nicht

for i=1:n_Kuehlkreislauf
    for j=1:size(Graph_Kuehlkreislauf{i}.Nodes,1)
        % -> if-clause 1
        if sum(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)))==2
           set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Energiestroeme 1. finites Volumen durch Kopplung mit vorheriger Fluid_Komponente - normal+Ventil'],'commented','on');
        % -> if-clause 2
        elseif sum(strcmp(Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},Graph_Kuehlkreislauf{i}.Edges{:,1}(:,2)))==1
               set_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Nodes{:,1}{j},' thermisch/Energiestroeme 1. finites Volumen durch Kopplung mit vorherigen Fluid_Komponenten - Vereinigung'],'commented','on');
        else
            fprintf('\nFehler bei der Konfiguration eines Kühlkreislaufs!\n');
        end
    end
end

%% Aufbau und Parametrierung der Subsysteme "Kühler", "Wärmetauscher", "Schlauch" und Bearbeitung der Subsysteme "E-Maschine", "Leistungselektronik", "Batteriepack"

% -> Der Aufbau und die Parametrierung bzw. die Bearbeitung dieser Subsysteme wird abh. von den Fluid_Komponenten umgesetzt
% -> Die Anzahl an Fluid_Komponenten einer Objektart bestimmt die Anzahl an existierenden Komponenten im Thermomanagementsystem
% -> Das Thermomanagementsystem wird demnach durch die Festlegung der Fluid_Komponenten, durch die Festlegung von Konfig_Kuehlkreislauf und durch die Festlegung der Dreiwegeventile vollständig bestimmt

%--------------------------------------------------------------------------
% Aufbau und Parametrierung der Kuehler im Subsystem "Kühler"
%--------------------------------------------------------------------------

if exist('Fluid_Kuehler')==1
   j=1;
   k=1;
   for i=1:size(Fluid_Kuehler,2)
       add_block([Modell,'/Thermomanagementsystem/Kühler/Kuehler thermisch'],[Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren des allgemein modellierten Kuehler und Umbenennen in entsprechenden Kuehler
       set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler thermisch'],'Position')+[0,i*180,0,i*180]); % Positionierung des neu erzeugten Kuehler
       Bus_Selector_Kuehler{j}=['T_FinitesVolumen_Kuehler(',num2str(i),') [K]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_Kuehler_Output
       set_param([Modell,'/Thermomanagementsystem/Kühler/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Kuehler,', ')); % Parametrierung des Bus Selectors für Fluid_Kuehler_Output
       add_line([Modell,'/Thermomanagementsystem/Kühler'],['Bus Selector/',num2str(j)],['Kuehler(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_Kuehler_Output mit dem entsprechenden Kuehler
       j=j+1;
       Bus_Selector_Kuehler{j}=['PV_Kuehlfluessigkeit_Kuehler(',num2str(i),') [m^3*s^-1]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_Kuehler_Output
       set_param([Modell,'/Thermomanagementsystem/Kühler/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Kuehler,', ')); % Parametrierung des Bus Selectors für Fluid_Kuehler_Output
       add_line([Modell,'/Thermomanagementsystem/Kühler'],['Bus Selector/',num2str(j)],['Kuehler(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_Kuehler_Output mit dem entsprechenden Kuehler       
       j=j+1;
       add_line([Modell,'/Thermomanagementsystem/Kühler'],'T_Umgebung [K]/1',['Kuehler(',num2str(i),') thermisch/3'],'autorouting','on'); % Verbindung des Eingangs der Temperatur der Umgebungsluft mit dem entsprechenden Kuehler       
       add_line([Modell,'/Thermomanagementsystem/Kühler'],'v_Fahrzeug [m*s^-1]/1',['Kuehler(',num2str(i),') thermisch/4'],'autorouting','on'); % Verbindung des Eingangs der Fahrzeuggeschwindigkeit mit dem entsprechenden Kuehler 
       set_param([Modell,'/Thermomanagementsystem/Kühler/Bus Creator'],'Inputs',num2str(2*size(Fluid_Kuehler,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Kuehler_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Kühler'],['Kuehler(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(k)],'autorouting','on'),'Name',['PQ_Kuehler(',num2str(i),')_FinitesVolumen [W]']); % Verbindung des entsprechenden Kuehler mit einem Input des Bus Creators für Kuehler_Output und Benennung des Signals    
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Kühler'],['Kuehler(',num2str(i),') thermisch/2'],['Bus Creator/',num2str(k)],'autorouting','on'),'Name',['v_Kuehlerluefter(',num2str(i),') [m*s^-1]']); % Verbindung des entsprechenden Kuehler mit einem Input des Bus Creators für Kuehler_Output und Benennung des Signals 
       k=k+1;
       if Steuerung_Kuehlerluefter==1
          set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/Bestimmung v_Kuehlerluefter/Steuerung Kuehlerluefter/Selector_1'],'IndexParamArray',{'1'}); % Parametrierung des entsprechenden Selectors bzgl. des 1. finiten Volumens des entsprechenden Fluid_Kuehler in dem entsprechenden Kuehler
          set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/Bestimmung v_Kuehlerluefter/Steuerung Kuehlerluefter/Selector_n'],'IndexParamArray',{num2str(Fluid_Kuehler(i).l_Kuehlfluessigkeit/l_FinitesVolumen)}); % Parametrierung des entsprechenden Selectors bzgl. des n. finiten Volumens des entsprechenden Fluid_Kuehler in dem entsprechenden Kuehler
          set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/Bestimmung v_Kuehlerluefter/Steuerung Kuehlerluefter/n-D Lookup Table'],'BreakpointsForDimension1',mat2str(v_Kuehlerluefter_Break_T_FinitesVolumen_Kuehler{i})); % Parametrierung von n-D Lookup Table für v_Kuehlerluefter mit Breakpoints 1 in dem entsprechenden Kuehler 
          set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/Bestimmung v_Kuehlerluefter/Steuerung Kuehlerluefter/n-D Lookup Table'],'Table',mat2str(v_Kuehlerluefter_Table{i})); % Parametrierung von n-D Lookup Table für v_Kuehlerluefter mit Table data in dem entsprechenden Kuehler 
          set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/Bestimmung v_Kuehlerluefter/v_Kuehlerluefter'],'commented','on'); % Auskommentieren von v_Kuehlerluefter in dem entsprechenden Kuehler, wenn die Kühlerlüfter gesteuert sind und deswegen v_Kuehlerluefter nicht von Bedeutung ist
       elseif Steuerung_Kuehlerluefter==0
              set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/Bestimmung v_Kuehlerluefter/v_Kuehlerluefter'],'VariableName',mat2str(v_Kuehlerluefter{i})); % Parametrierung von v_Kuehlerluefter in dem entsprechenden Kuehler 
              set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/Bestimmung v_Kuehlerluefter/Steuerung Kuehlerluefter'],'commented','on'); % Auskommentieren des Subsystems "Steuerung Kuehlerluefter" in dem entsprechenden Kuehler, wenn die Kühlerlüfter ungesteuert sind und deswegen das Subsystem "Steuerung Kuehlerluefter" nicht von Bedeutung ist
       else
           fprintf('\nFehler bei der Angabe von Steuerung_Kuehlerluefter!\n');
           keyboard;
       end
       set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/n-D Lookup Table'],'BreakpointsForDimension1',mat2str(UA_Kuehler_FinitesVolumen_Break_PV_Kuehlfluessigkeit{i})); % Parametrierung von n-D Lookup Table für UA_Kuehler_FinitesVolumen mit Breakpoints 1 in dem entsprechenden Kuehler    
       set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/n-D Lookup Table'],'BreakpointsForDimension2',mat2str(UA_Kuehler_FinitesVolumen_Break_v_Kuehlerluefter{i})); % Parametrierung von n-D Lookup Table für UA_Kuehler_FinitesVolumen mit Breakpoints 2 in dem entsprechenden Kuehler        
       set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/n-D Lookup Table'],'BreakpointsForDimension3',mat2str(UA_Kuehler_FinitesVolumen_Break_v_Fahrzeug{i})); % Parametrierung von n-D Lookup Table für UA_Kuehler_FinitesVolumen mit Breakpoints 3 in dem entsprechenden Kuehler
       set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch/n-D Lookup Table'],'Table',['reshape(',mat2str(reshape(UA_Kuehler_FinitesVolumen_Table{i},size(UA_Kuehler_FinitesVolumen_Table{i},1),size(UA_Kuehler_FinitesVolumen_Table{i},2)*size(UA_Kuehler_FinitesVolumen_Table{i},3),1)),',',num2str(size(UA_Kuehler_FinitesVolumen_Table{i},1)),',',num2str(size(UA_Kuehler_FinitesVolumen_Table{i},2)),',',num2str(size(UA_Kuehler_FinitesVolumen_Table{i},3)),')']); % Parametrierung von n-D Lookup Table für UA_Kuehler_FinitesVolumen mit Table data in dem entsprechenden Kuehler
       % -> Die 3D-Matrix von UA_Kuehler_FinitesVolumen_Table{i} wird über den "reshape"-Befehl in eine 2D-Matrix umgewandelt, um mit dem "mat2str"-Befehl einen string erzeugen zu können, der für die Übergabe an Simulink benötigt wird
       % -> Dieser erzeugte string wird in einen übergeordneten string eingefügt, der den "reshape"-Befehl und die ursprünglichen 3D-Dimension beinhaltet, um in Simulink die zur Übergabe erzeugte 2D-Matrix wieder in die ursprüngliche und benötigte 3D-Matrix von UA_Kuehler_FinitesVolumen_Table{i} zurückzuwandeln
   end
elseif exist('Fluid_Kuehler')==0
       set_param([Modell,'/Thermomanagementsystem/Kühler/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Fluid_Kuehler_Output, wenn kein Kuehler im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/Kuehler'],'commented','on');              % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein Kuehler im Thermomanagementsystem integriert ist und es dadaurch keine Daten gibt
end

%--------------------------------------------------------------------------
% Aufbau und Parametrierung der Waermetauscher im Subsystem "Wärmetauscher"
%--------------------------------------------------------------------------

if exist('Fluid_Waermetauscher')==1
   j=1;
   k=1;
   for i=1:size(Fluid_Waermetauscher,2)
       add_block([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher thermisch'],[Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren des allgemein modellierten Waermetauscher und Umbenennen in entsprechenden Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher thermisch'],'Position')+[0,i*240,0,i*240]); % Positionierung des neu erzeugten Waermetauscher
       Bus_Selector_Waermetauscher{j}=['T_FinitesVolumen_Waermetauscher(1_',num2str(i),') [K]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_Waermetauscher_Output
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Waermetauscher,', ')); % Parametrierung des Bus Selectors für Fluid_Waermetauscher_Output
       add_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Bus Selector/',num2str(j)],['Waermetauscher(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_Waermetauscher_Output mit dem entsprechenden Waermetauscher
       j=j+1;
       Bus_Selector_Waermetauscher{j}=['PV_Kuehlfluessigkeit_Waermetauscher(1_',num2str(i),') [m^3*s^-1]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_Waermetauscher_Output
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Waermetauscher,', ')); % Parametrierung des Bus Selectors für Fluid_Waermetauscher_Output
       add_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Bus Selector/',num2str(j)],['Waermetauscher(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_Waermetauscher_Output mit dem entsprechenden Waermetauscher       
       j=j+1;
       Bus_Selector_Waermetauscher{j}=['T_FinitesVolumen_Waermetauscher(2_',num2str(i),') [K]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_Waermetauscher_Output
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Waermetauscher,', ')); % Parametrierung des Bus Selectors für Fluid_Waermetauscher_Output
       add_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Bus Selector/',num2str(j)],['Waermetauscher(',num2str(i),') thermisch/3'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_Waermetauscher_Output mit dem entsprechenden Waermetauscher
       j=j+1;
       Bus_Selector_Waermetauscher{j}=['PV_Kuehlfluessigkeit_Waermetauscher(2_',num2str(i),') [m^3*s^-1]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_Waermetauscher_Output
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Waermetauscher,', ')); % Parametrierung des Bus Selectors für Fluid_Waermetauscher_Output
       add_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Bus Selector/',num2str(j)],['Waermetauscher(',num2str(i),') thermisch/4'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_Waermetauscher_Output mit dem entsprechenden Waermetauscher       
       j=j+1;
       add_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],'T_Umgebung [K]/1',['Waermetauscher(',num2str(i),') thermisch/5'],'autorouting','on'); % Verbindung des Eingangs der Temperatur der Umgebungsluft mit dem entsprechenden Waermetauscher       
       add_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],'v_Fahrzeug [m*s^-1]/1',['Waermetauscher(',num2str(i),') thermisch/6'],'autorouting','on'); % Verbindung des Eingangs der Fahrzeuggeschwindigkeit mit dem entsprechenden Waermetauscher 
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Bus Creator'],'Inputs',num2str(2*size(Fluid_Waermetauscher,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Waermetauscher_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Waermetauscher(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(k)],'autorouting','on'),'Name',['PQ_Waermetauscher(1_',num2str(i),')_FinitesVolumen [W]']); % Verbindung des entsprechenden Waermetauscher mit einem Input des Bus Creators für Waermetauscher_Output und Benennung des Signals
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Waermetauscher(',num2str(i),') thermisch/2'],['Bus Creator/',num2str(k)],'autorouting','on'),'Name',['PQ_Waermetauscher(2_',num2str(i),')_FinitesVolumen [W]']); % Verbindung des entsprechenden Waermetauscher mit einem Input des Bus Creators für Waermetauscher_Output und Benennung des Signals
       k=k+1;
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher(',num2str(i),') thermisch/Art_Waermetauscher'],'Value',num2str(Fluid_Waermetauscher(1,i).Art_Waermetauscher)) % Parametrierung von Art_Waermetauscher in dem entsprechenden Waermetauscher
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher(',num2str(i),') thermisch/n-D Lookup Table'],'BreakpointsForDimension1',mat2str(UA_Waermetauscher_FinitesVolumen_Break_PV_Kuehlfluessigkeit{i})); % Parametrierung von n-D Lookup Table für UA_Waermetauscher_FinitesVolumen mit Breakpoints 1 in dem entsprechenden Waermetauscher    
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher(',num2str(i),') thermisch/n-D Lookup Table'],'BreakpointsForDimension2',mat2str(UA_Waermetauscher_FinitesVolumen_Break_PV_Kuehlfluessigkeit{i})); % Parametrierung von n-D Lookup Table für UA_Waermetauscher_FinitesVolumen mit Breakpoints 2 in dem entsprechenden Waermetauscher        
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher(',num2str(i),') thermisch/n-D Lookup Table'],'Table',mat2str(UA_Waermetauscher_FinitesVolumen_Table{i})); % Parametrierung von n-D Lookup Table für UA_Waermetauscher_FinitesVolumen mit Table data in dem entsprechenden Waermetauscher
   end
elseif exist('Fluid_Waermetauscher')==0
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Fluid_Waermetauscher_Output, wenn kein Waermetauscher im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
end

%--------------------------------------------------------------------------
% Aufbau und Parametrierung der PCM-Speicher im Subsystem "PCM"
%--------------------------------------------------------------------------

if exist('Fluid_PCM')==1
   j=1;
   k=1;
   for i=1:size(Fluid_PCM,2)
       add_block([Modell,'/Thermomanagementsystem/PCM/PCM thermisch'],[Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren des allgemein modellierten PCM und Umbenennen in entsprechenden PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/PCM/PCM thermisch'],'Position')+[0,i*180,0,i*180]); % Positionierung des neu erzeugten PCM
       Bus_Selector_PCM{j}=['T_FinitesVolumen_PCM(',num2str(i),') [K]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_PCM_Output
       set_param([Modell,'/Thermomanagementsystem/PCM/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_PCM,', ')); % Parametrierung des Bus Selectors für Fluid_PCM_Output
       add_line([Modell,'/Thermomanagementsystem/PCM'],['Bus Selector/',num2str(j)],['PCM(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_PCM_Output mit dem entsprechenden PCM
       j=j+1;
       Bus_Selector_PCM{j}=['PV_Kuehlfluessigkeit_PCM(',num2str(i),') [m^3*s^-1]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_PCM_Output
       set_param([Modell,'/Thermomanagementsystem/PCM/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_PCM,', ')); % Parametrierung des Bus Selectors für Fluid_PCM_Output
       add_line([Modell,'/Thermomanagementsystem/PCM'],['Bus Selector/',num2str(j)],['PCM(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_PCM_Output mit dem entsprechenden PCM       
       j=j+1;
       add_line([Modell,'/Thermomanagementsystem/PCM'],'T_Umgebung [K]/1',['PCM(',num2str(i),') thermisch/3'],'autorouting','on'); % Verbindung des Eingangs der Umgebungstemperatur mit dem entsprechenden PCM       
       add_line([Modell,'/Thermomanagementsystem/PCM'],'v_Fahrzeug [m*s^-1]/1',['PCM(',num2str(i),') thermisch/4'],'autorouting','on'); % Verbindung des Eingangs der Fahrzeuggeschwindigkeit mit dem entsprechenden PCM 
       set_param([Modell,'/Thermomanagementsystem/PCM/Bus Creator'],'Inputs',num2str(2*size(Fluid_PCM,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für PCM_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/PCM'],['PCM(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(k)],'autorouting','on'),'Name',['T_PCM(',num2str(i),') [K]']); % Verbindung des entsprechenden PCM mit einem Input des Bus Creators für PCM_Output und Benennung des Signals    
       k=k+1;
       set_param(add_line([Modell,'/Thermomanagementsystem/PCM'],['PCM(',num2str(i),') thermisch/2'],['Bus Creator/',num2str(k)],'autorouting','on'),'Name',['PQ_PCM(',num2str(i),')_FinitesVolumen [W]']); % Verbindung des entsprechenden PCM mit einem Input des Bus Creators für PCM_Output und Benennung des Signals 
       k=k+1;
       
       
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/Phasenuebergang/Phasenwechsel_uGW'],'Value',mat2str(PCM(i).unterer_Grenzwert_Phasenwechsel)); % Parametrierung des unteren Werts des Phasenuebergangs des PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/Trigger/Phasenwechsel_uGW'],'Value',mat2str(PCM(i).unterer_Grenzwert_Phasenwechsel)); % Parametrierung des unteren Werts des Phasenuebergangs des PCM fuer die Aktivierbarkeit des PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/Phasenuebergang/Phasenwechsel_oGW'],'Value',mat2str(PCM(i).oberer_Grenzwert_Phasenwechsel)); % Parametrierung des oberen Werts des Phasenuebergangs des PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/Phasenuebergang/Faktor_Phasenwechsel'],'Value',mat2str(PCM(i).dT_Faktor_Phasenwechsel)); % Parametrierung des Faktors Temperaturanstieg konstante Phase zu Temperaturanstieg Phasenuebergang des PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/Trigger/Phasenumwandlung_vollstaendig'],'Value',mat2str(PCM(i).Phasenumwandlung_vollstaendig)); % Parametrierung des Werts des vollstaendigen Phasenuebergangs
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/Trigger/IC'],'Value',mat2str(PCM(i).Zustand_init)); % Parametrierung des des Initialszustands des aktivierbaren PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/Trigger/Delay1'],'InitialCondition',mat2str(PCM(i).Zustand_init)); % Parametrierung des des Initialszustands des aktivierbaren PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/b_PCM'],'Value',mat2str(PCM(i).b_PCM)); % Parametrierung des Faktors b_PCM des PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/T_PCM_init'],'Value',mat2str(T_PCM_init{i})); % Parametrierung der Initialtemperatur des PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/T_PCM_Offset'],'Value',mat2str(T_PCM_Offset{i})); % Parametrierung des Temperaturoffsets des PCM
       set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/PCM_Trigger'],'VariableName',mat2str(PCM_Trigger{i}));
        
       if PCM(i).Aktivierbar==0
           set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/Trigger'],'commented','through');
           set_param([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch/PCM_Trigger'],'VariableName','[0 0]');
       end      
   end
elseif exist('Fluid_PCM')==0
       set_param([Modell,'/Thermomanagementsystem/PCM/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Fluid_PCM_Output, wenn kein PCM im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       set_param([Modell,'/Output/PCM'],'commented','on');                  % Auskommentieren der Datenübergabe von Simulink an MATLAB, wenn kein PCM im Thermomanagementsystem integriert ist und es dadaurch keine Daten gibt
end

       set_param([Modell,'/Thermomanagementsystem/PCM/PCM thermisch'],'commented','on');

%--------------------------------------------------------------------------
% Aufbau und Parametrierung der Schlauch im Subsystem "Schlauch"
%--------------------------------------------------------------------------

if exist('Fluid_Schlauch')==1
   j=1;
   for i=1:size(Fluid_Schlauch,2)
       add_block([Modell,'/Thermomanagementsystem/Schlauch/Schlauch thermisch'],[Modell,'/Thermomanagementsystem/Schlauch/Schlauch(',num2str(i),') thermisch'],'CopyOption','duplicate'); % Kopieren des allgemein modellierten Schlauch und Umbenennen in entsprechenden Schlauch
       set_param([Modell,'/Thermomanagementsystem/Schlauch/Schlauch(',num2str(i),') thermisch'],'Position',get_param([Modell,'/Thermomanagementsystem/Schlauch/Schlauch thermisch'],'Position')+[0,i*180,0,i*180]); % Positionierung des neu erzeugten Schlauch
       Bus_Selector_Schlauch{j}=['T_FinitesVolumen_Schlauch(',num2str(i),') [K]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_Schlauch_Output
       set_param([Modell,'/Thermomanagementsystem/Schlauch/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Schlauch,', ')); % Parametrierung des Bus Selectors für Fluid_Schlauch_Output
       add_line([Modell,'/Thermomanagementsystem/Schlauch'],['Bus Selector/',num2str(j)],['Schlauch(',num2str(i),') thermisch/1'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_Schlauch_Output mit dem entsprechenden Schlauch
       j=j+1;
       Bus_Selector_Schlauch{j}=['PV_Kuehlfluessigkeit_Schlauch(',num2str(i),') [m^3*s^-1]']; % Liste der Namen der Output-Signale des Bus Selectors für Fluid_Schlauch_Output
       set_param([Modell,'/Thermomanagementsystem/Schlauch/Bus Selector'],'OutputSignals',strjoin(Bus_Selector_Schlauch,', ')); % Parametrierung des Bus Selectors für Fluid_Schlauch_Output
       add_line([Modell,'/Thermomanagementsystem/Schlauch'],['Bus Selector/',num2str(j)],['Schlauch(',num2str(i),') thermisch/2'],'autorouting','on'); % Verbindung der Output-Signale des Bus Selectors für Fluid_Schlauch_Output mit dem entsprechenden Schlauch       
       j=j+1;
       add_line([Modell,'/Thermomanagementsystem/Schlauch'],'T_Umgebung [K]/1',['Schlauch(',num2str(i),') thermisch/3'],'autorouting','on'); % Verbindung des Eingangs der Temperatur der Umgebungsluft mit dem entsprechenden Schlauch       
       add_line([Modell,'/Thermomanagementsystem/Schlauch'],'v_Fahrzeug [m*s^-1]/1',['Schlauch(',num2str(i),') thermisch/4'],'autorouting','on'); % Verbindung des Eingangs der Fahrzeuggeschwindigkeit mit dem entsprechenden Schlauch 
       set_param([Modell,'/Thermomanagementsystem/Schlauch/Bus Creator'],'Inputs',num2str(size(Fluid_Schlauch,2))); % Bestimmung der Anzahl der Inputs des Bus Creators für Schlauch_Output
       set_param(add_line([Modell,'/Thermomanagementsystem/Schlauch'],['Schlauch(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(i)],'autorouting','on'),'Name',['PQ_Schlauch(',num2str(i),')_FinitesVolumen [W]']); % Verbindung des entsprechenden Schlauch mit einem Input des Bus Creators für Schlauch_Output und Benennung des Signals
   end
elseif exist('Fluid_Schlauch')==0
       set_param([Modell,'/Thermomanagementsystem/Schlauch/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Fluid_Schlauch_Output, wenn kein Schlauch im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
end

%--------------------------------------------------------------------------
% Bearbeitung von EMaschine(1) im Subsystem "E-Maschine"
%--------------------------------------------------------------------------

% -> In dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebsstrangmodell genau mit 1 E-Maschine gerechnet
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 E-Maschine vorhanden sein
% -> Dies wird in "Fehler beim Setup des Thermomanagementsystemmodells" anhand der Anzahl an Fluid_EMaschine geprüft (darf nicht > 1 sein)
% -> Aus diesem Grund existiert im Thermomanagementsystemmodell dauerhaft EMaschine(1) im Subsystem "E-Maschine"
% -> Unter anderem wird zusätzlich zu EMaschine(1) auch Getriebe(1) im Subsystem "E-Maschine" thermisch berechnet
% -> Da EMaschine(1) eine eigene Temperatur besitzt und diabat zur Umgebung betrachtet wird, hat EMaschine(1) einen Wärmeaustausch mit der Umgebungsluft, auch wenn EMaschine(1) nicht im Thermomanagementsystem integriert ist
% -> Falls EMaschine(1) nicht im Thermomanagementsystem integriert ist (es existiert keine Fluid_EMaschine(1) -> siehe oben: Fluid_Komponenten definieren das Thermomanagementsystem), existiert kein Wärmeaustausch zwischen EMaschine(1) und Kühlflüssigkeit 
% -> Dies wird über das Auskommentieren des Subsystems "Waermeaustausch EMaschine - Kuehlfluessigkeit" von EMaschine(1) umgesetzt

if exist('Fluid_EMaschine')==1
   set_param([Modell,'/Thermomanagementsystem/E-Maschine/Bus Selector'],'OutputSignals','T_FinitesVolumen_EMaschine(1) [K],PV_Kuehlfluessigkeit_EMaschine(1) [m^3*s^-1]') % Parametrierung des Bus Selectors für Fluid_EMaschine_Output      
elseif exist('Fluid_EMaschine')==0       
       set_param([Modell,'/Thermomanagementsystem/E-Maschine/EMaschine(1) + Getriebe(1) thermisch/Waermeaustausch EMaschine - Kuehlfluessigkeit'],'commented','on'); % Auskommentieren des Subsystems "Waermeaustausch EMaschine - Kuehlfluessigkeit" von EMaschine(1), wenn EMaschine(1) nicht im Thermomanagementsystem integriert ist
       set_param([Modell,'/Thermomanagementsystem/E-Maschine/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Fluid_EMaschine_Output, wenn EMaschine(1) nicht im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
end

%--------------------------------------------------------------------------
% Bearbeitung von Leistungselektronik(1) im Subsystem "Leistungselektronik"
%--------------------------------------------------------------------------

% -> In dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebsstrangmodell genau mit 1 Leistungselektronik gerechnet
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 Leistungselektronik vorhanden sein
% -> Dies wird in "Fehler beim Setup des Thermomanagementsystemmodells" anhand der Anzahl an Fluid_Leistungselektronik geprüft (darf nicht > 1 sein)
% -> Aus diesem Grund existiert im Thermomanagementsystemmodell dauerhaft Leistungselektronik(1) im Subsystem "Leistungselektronik"
% -> Da Leistungselektronik(1) eine eigene Temperatur besitzt und diabat zur Umgebung betrachtet wird, hat Leistungselektronik(1) einen Wärmeaustausch mit der Umgebungsluft (aktuell umgesetzt über die Case der MOSFET, die die Substrate der MOSFET abdecken), auch wenn Leistungselektronik(1) nicht im Thermomanagementsystem integriert ist
% -> Falls Leistungselektronik(1) nicht im Thermomanagementsystem integriert ist (es existiert keine Fluid_Leistungselektronik(1) -> siehe oben: Fluid_Komponenten definieren das Thermomanagementsystem), existiert kein Wärmeaustausch zwischen Leistungselektronik(1) und Kühlflüssigkeit (aktuell umgesetzt über die Case der MOSFET, die die Substrate der MOSFET abdecken) 
% -> Dies wird über das Auskommentieren des Subsystems "Waermeaustausch Case - Kuehlfluessigkeit" von Leistungselektronik(1) umgesetzt

if exist('Fluid_Leistungselektronik')==1
   set_param([Modell,'/Thermomanagementsystem/Leistungselektronik/Bus Selector'],'OutputSignals','T_FinitesVolumen_Leistungselektronik(1) [K],PV_Kuehlfluessigkeit_Leistungselektronik(1) [m^3*s^-1]'); % Parametrierung des Bus Selectors für Fluid_Leistungselektronik_Output   
elseif exist('Fluid_Leistungselektronik')==0
       set_param([Modell,'/Thermomanagementsystem/Leistungselektronik/Leistungselektronik(1) thermisch/Waermeaustausch Case - Kuehlfluessigkeit'],'commented','on'); % Auskommentieren des Subsystems "Waermeaustausch Case - Kuehlfluessigkeit" von Leistungselektronik(1), wenn Leistungselektronik(1) nicht im Thermomanagementsystem integriert ist
       set_param([Modell,'/Thermomanagementsystem/Leistungselektronik/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors Fluid_Leistungselektronik_Output, wenn Leistungselektronik(1) nicht im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
end

%--------------------------------------------------------------------------
% Bearbeitung von Batteriepack(1) im Subsystem "Batteriepack"
%--------------------------------------------------------------------------

% -> In dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebsstrangmodell genau mit 1 Batteriepack gerechnet
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 Batteriepack vorhanden sein
% -> Dies wird in "Fehler beim Setup des Thermomanagementsystemmodells" anhand der Anzahl an Fluid_Batteriepack geprüft (darf nicht > 1 sein)
% -> Aus diesem Grund existiert im Thermomanagementsystemmodell dauerhaft Batteriepack(1) im Subsystem "Batteriepack"
% -> Da Batteriepack(1) eine eigene Temperatur besitzt und diabat zur Umgebung betrachtet wird, hat Batteriepack(1) einen Wärmeaustausch mit der Umgebungsluft, auch wenn Batteriepack(1) nicht im Thermomanagementsystem integriert ist
% -> Falls Batteriepack(1) nicht im Thermomanagementsystem integriert ist (es existiert keine Fluid_Batteriepack(1) -> siehe oben: Fluid_Komponenten definieren das Thermomanagementsystem), existiert kein Wärmeaustausch zwischen Batteriepack(1) und Kühlflüssigkeit 
% -> Dies wird über das Auskommentieren des Subsystems "Waermeaustausch Batteriepack - Kuehlfluessigkeit" von Batteriepack(1) umgesetzt

if exist('Fluid_Batteriepack')==1
   set_param([Modell,'/Thermomanagementsystem/Batteriepack/Bus Selector'],'OutputSignals','T_FinitesVolumen_Batteriepack(1) [K],PV_Kuehlfluessigkeit_Batteriepack(1) [m^3*s^-1]'); % Parametrierung des Bus Selectors für Fluid_Batteriepack_Output     
elseif exist('Fluid_Batteriepack')==0
       set_param([Modell,'/Thermomanagementsystem/Batteriepack/Batteriepack(1) thermisch/Waermeaustausch Batteriepack - Kuehlfluessigkeit'],'commented','on'); % Auskommentieren des Subsystems "Waermeaustausch Batteriepack - Kuehlfluessigkeit" von Batteriepack(1), wenn Batteriepack(1) nicht im Thermomanagementsystem integriert ist
       set_param([Modell,'/Thermomanagementsystem/Batteriepack/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Fluid_Batteriepack_Output, wenn Batteriepack(1) nicht im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
end


%--------------------------------------------------------------------------
% Bearbeitung von Ladegeraet(1) im Subsystem "Ladegeraet"
%--------------------------------------------------------------------------

% -> In dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebstrangmodell genau mit 1 Ladegeraet gerechnet
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 Ladegeraet vorhanden sein
% -> Dies wird in "Fehler beim Setup des Thermomanagementsystemmodells" anhand der Anzahl an Fluid_Ladegeraet geprüft (darf nicht > 1 sein)
% -> Aus diesem Grund existiert im Thermomanagementsystemmodell dauerhaft Ladegeraet(1) im Subsystem "Ladegeraet"
% -> Da Ladegeraet(1) eine eigene Temperatur besitzt und diabat zur Umgebung betrachtet wird, hat Ladegeraet(1) einen Wärmeaustausch mit der Umgebung, auch wenn Ladegeraet(1) nicht im Thermomanagementsystem integriert ist
% -> Falls Ladegeraet(1) nicht im Thermomanagementsystem integriert ist (es existiert keine Fluid_Ladegeraet(1) -> siehe oben: Fluid_Komponenten definieren das Thermomanagementsystem), existiert kein Wärmeaustausch zwischen Ladegeraet(1) und Fluid 
% -> Dies wird über das Auskommentieren des Subsystems "Waermeaustausch Ladegeraet - Fluid" von Ladegeraet(1) umgesetzt

if exist('Fluid_Ladegeraet')==1
   set_param([Modell,'/Thermomanagementsystem/Ladegeraet/Bus Selector'],'OutputSignals','T_FinitesVolumen_Ladegeraet(1) [K],PV_Kuehlfluessigkeit_Ladegeraet(1) [m^3*s^-1]'); % Parametrierung des Bus Selectors für Fluid_Ladegeraet_Output     
elseif exist('Fluid_Ladegeraet')==0
       set_param([Modell,'/Thermomanagementsystem/Ladegeraet/Ladegeraet(1) thermisch/Waermeaustausch Ladegeraet - Kuehlfluessigkeit'],'commented','on'); % Auskommentieren des Subsystems "Waermeaustausch Ladegeraet - Fluid" von Ladegeraet(1), wenn Ladegeraet(1) nicht im Thermomanagementsystem integriert ist
       set_param([Modell,'/Thermomanagementsystem/Ladegeraet/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Fluid_Ladegeraet_Output, wenn Ladegeraet(1) nicht im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
end

%--------------------------------------------------------------------------
% Bearbeitung von Peltier(1) im Subsystem "Peltier"
%--------------------------------------------------------------------------

% -> In dieser Version des Thermomanagementsystemmodells wird im verwendeten Antriebstrangmodell genau mit 1 Peltier-Element gerechnet
% -> Deswegen kann im simulierten Thermomanagementsystem max. 1 Peltier-Element vorhanden sein
% -> Dies wird in "Fehler beim Setup des Thermomanagementsystemmodells" anhand der Anzahl an Fluid_Peltier geprüft (darf nicht > 1 sein)
% -> Aus diesem Grund existiert im Thermomanagementsystemmodell dauerhaft Peltier(1) im Subsystem "Peltier"
% -> Da Peltier(1) eine eigene Temperatur besitzt und diabat zur Umgebung betrachtet wird, hat Peltier(1) einen Wärmeaustausch mit der Umgebung, auch wenn Peltier(1) nicht im Thermomanagementsystem integriert ist
% -> Falls Peltier(1) nicht im Thermomanagementsystem integriert ist (es existiert keine Fluid_Peltier(1) -> siehe oben: Fluid_Komponenten definieren das Thermomanagementsystem), existiert kein Wärmeaustausch zwischen Peltier(1) und Fluid 
% -> Dies wird über das Auskommentieren des Subsystems "Waermeaustausch Peltier - Fluid" von Peltier(1) umgesetzt

if exist('Fluid_Peltier')==1
   set_param([Modell,'/Thermomanagementsystem/Peltier/Bus Selector'],'OutputSignals','T_FinitesVolumen_Peltier(1) [K]'); % Parametrierung des Bus Selectors für Fluid_Peltier_Output      
elseif exist('Fluid_Peltier')==0
       set_param([Modell,'/Thermomanagementsystem/Peltier/Peltier(1) thermisch'],'commented','on'); % Auskommentieren des Subsystems "Waermeaustausch Peltier - Fluid" von Peltier(1), wenn Peltier(1) nicht im Thermomanagementsystem integriert ist
       set_param([Modell,'/Thermomanagementsystem/Peltier/Bus Selector'],'commented','on'); % Auskommentieren des Bus Selectors für Fluid_Peltier_Output, wenn Peltier(1) nicht im Thermomanagementsystem integriert ist, weil es sonst zu einer Fehlermeldung kommt, wenn ein Output-Signal nicht im Bus vorhanden ist
       Steuerung_Peltier = [0,0];
end

%% V. Allgemeine Einstellungen zur Vermeidung von Warnungen bei der Simulation des Thermomanagemensystemmodells

set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf'],'commented','on'); % Auskommentieren des allgemein modellierten Kuehlkreislauf
set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil'],'commented','on'); % Auskommentieren des allgemein modellierten Ventil
set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'commented','on'); % Auskommentieren der allgemein modellierten Fluid_Komponente
set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler thermisch'],'commented','on'); % Auskommentieren des allgemein modellierten Kuehler
set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher thermisch'],'commented','on'); % Auskommentieren des allgemein modellierten Waermetauscher
set_param([Modell,'/Thermomanagementsystem/Schlauch/Schlauch thermisch'],'commented','on'); % Auskommentieren des allgemein modellierten Schlauch
set_param(Modell,'UnconnectedInputMsg','none');                             % Unverbundene Eingänge sollen keine Warnung ausgeben -> Diese können wegen dem allgemein modellierten Thermomanagementsystemmodell vorhanden sein, führen aber zu keinem Fehler, weil die entsprechenden unverbundenen Eingänge für die Simulation nicht benötigt werden
set_param(Modell,'UnconnectedOutputMsg','none');                            % Unverbundene Ausgänge sollen keine Warnung ausgeben -> Diese können wegen dem allgemein modellierten Thermomanagementsystemmodell vorhanden sein, führen aber zu keinem Fehler, weil die entsprechenden unverbundenen Ausgänge für die Simulation nicht benötigt werden

%% VI. Simulation des Thermomanagementsystemmodells

%keyboard;

% Variablen werden in den Modelworkspace geschrieben, damit das
% Simulinkmodell funktioniert
% Get Modelworkspace
hws = get_param(Modell, 'modelworkspace');
% Get the list of variables defined within the function
list = whos;        
N = length(list);
% Assign everything from the local fucntion workspace to the model workspace
for  i = 1:N
      hws.assignin(list(i).name,eval(list(i).name));
end

tic;                                                                       % tic-toc zum Mitstoppen, wie lange die Simulation des Thermomanagementsystemmodells in Simulink dauert
sim(Modell);                                                               % Simulation des Thermomanagementsystemmodells in Simulink wird gestartet
fprintf('\nThe VTMS Simulation took %.2f s.\n',toc); % Ausgabe, wie lange die Simulation des Thermomanagementsystemmodells in Simulink dauerte

 %% VII. Darstellung der Simulationsergebnisse des Thermomanagementsystemmodells
% 
% keyboard;
% 
% %--------------------------------------------------------------------------
% % Darstellung der Temperaturen der Komponenten
% %--------------------------------------------------------------------------
% 
% if exist('EMaschine_Output')==1
%    figure
%    plot(EMaschine_Output.T_EMaschine_Getriebe__K_.T_Getriebe__K_.Time,EMaschine_Output.T_EMaschine_Getriebe__K_.T_Getriebe__K_.Data(:)-273.15);
%    grid on;
%    axis tight;
%    title('Temperatur des 1. Getriebes');
%    xlabel('Zeit in s');
%    ylabel('Temperatur in °C');
% 
%    figure
%    plot(EMaschine_Output.T_EMaschine_Getriebe__K_.T_EMaschine__K_.Time,EMaschine_Output.T_EMaschine_Getriebe__K_.T_EMaschine__K_.Data(:)-273.15);
%    grid on;
%    axis tight;
%    title('Temperatur der 1. E-Maschine');
%    xlabel('Zeit in s');
%    ylabel('Temperatur in °C');
% end
% 
% if exist('Leistungselektronik_Output')==1
%    figure
%    plot(Leistungselektronik_Output.T_Leistungselektronik__K_.T_j__K_.Time,Leistungselektronik_Output.T_Leistungselektronik__K_.T_j__K_.Data(:)-273.15);
%    grid on;
%    axis tight;
%    title('Temperatur der Substrate der MOSFET der 1. Leistungselektronik');
%    xlabel('Zeit in s');
%    ylabel('Temperatur in °C');
% 
%    figure
%    plot(Leistungselektronik_Output.T_Leistungselektronik__K_.T_c__K_.Time,Leistungselektronik_Output.T_Leistungselektronik__K_.T_c__K_.Data(:)-273.15);
%    grid on;
%    axis tight;
%    title('Temperatur der Gehäuse der MOSFET der 1. Leistungselektronik');
%    xlabel('Zeit in s');
%    ylabel('Temperatur in °C');
% end
% 
% if exist('Batteriepack_Output')==1
%    figure
%    plot(Batteriepack_Output.T_Batteriepack__K_.Time,Batteriepack_Output.T_Batteriepack__K_.Data(:)-273.15);
%    grid on;
%    axis tight;
%    title('Temperatur des 1. Batteriepacks');
%    xlabel('Zeit in s');
%    ylabel('Temperatur in °C');
% end
% 
% if exist('Ladegeraet_Output')==1
%    figure
%    plot(Ladegeraet_Output.T_Ladegeraet__K_.Time,Ladegeraet_Output.T_Ladegeraet__K_.Data(:)-273.15);
%    grid on;
%    axis tight;
%    title('Temperatur des 1. Ladegeraets');
%    xlabel('Zeit in s');
%    ylabel('Temperatur in °C');
% end
% 
% if exist('PCM_Output')==1
%    for i=1:(ceil(size(fieldnames(PCM_Output),1)/2))
%        figure
%        plot(PCM_Output.(['T_PCM_',num2str(i),'___K_']).Time,PCM_Output.(['T_PCM_',num2str(i),'___K_']).Data(:)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur des ',num2str(i),'. PCM']);
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
%    end
% end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Temperatur der Umgebungsluft
% %--------------------------------------------------------------------------
% 
% figure
% plot([0;t_Simulation],[T_Umgebung;T_Umgebung]-273.15);
% grid on;
% axis tight;
% title('Temperatur der Umgebungsluft');
% xlabel('Zeit in s');
% ylabel('Temperatur in °C');
% 
% %--------------------------------------------------------------------------
% % Darstellung der Temperaturen der Kühlflüssigkeiten in den Strömungsgebieten der Komponenten am Anfang, ca. Mitte und am Ende
% %--------------------------------------------------------------------------
% 
% if exist('Fluid_Kuehler_Output')==1
%    for i=1:(size(fieldnames(Fluid_Kuehler_Output),1)/2)
%        figure
%        plot(Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Time,Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Time,Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Data(:,Fluid_Kuehler(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Time,Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Data(:,Fluid_Kuehler(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kühlflüssigkeit im Strömungsgebiet des ',num2str(i),'. Kühlers']);
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% if exist('Fluid_Waermetauscher_Output')==1
%    for i=1:(size(fieldnames(Fluid_Waermetauscher_Output),1)/4)
%        figure
%        plot(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Time,Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Time,Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Data(:,Fluid_Waermetauscher(1,i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Time,Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Data(:,Fluid_Waermetauscher(1,i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kühlflüssigkeit im 1. Strömungsgebiet des ',num2str(i),'. Wärmetauschers']);
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%        
%        figure
%        plot(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Time,Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Time,Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Data(:,Fluid_Waermetauscher(2,i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Time,Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Data(:,Fluid_Waermetauscher(2,i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kühlflüssigkeit im 2. Strömungsgebiet des ',num2str(i),'. Wärmetauscher']);
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% if exist('Fluid_EMaschine_Output')==1
%    for i=1:(size(fieldnames(Fluid_EMaschine_Output),1)/2)
%        figure
%        plot(Fluid_EMaschine_Output.(['T_FinitesVolumen_EMaschine_',num2str(i),'___K_']).Time,Fluid_EMaschine_Output.(['T_FinitesVolumen_EMaschine_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_EMaschine_Output.(['T_FinitesVolumen_EMaschine_',num2str(i),'___K_']).Time,Fluid_EMaschine_Output.(['T_FinitesVolumen_EMaschine_',num2str(i),'___K_']).Data(:,Fluid_EMaschine(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_EMaschine_Output.(['T_FinitesVolumen_EMaschine_',num2str(i),'___K_']).Time,Fluid_EMaschine_Output.(['T_FinitesVolumen_EMaschine_',num2str(i),'___K_']).Data(:,Fluid_EMaschine(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kühlflüssigkeit im Strömungsgebiet der ',num2str(i),'. E-Maschine']);
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% if exist('Fluid_Leistungselektronik_Output')==1
%    for i=1:(size(fieldnames(Fluid_Leistungselektronik_Output),1)/2)
%        figure
%        plot(Fluid_Leistungselektronik_Output.(['T_FinitesVolumen_Leistungselektronik_',num2str(i),'___K_']).Time,Fluid_Leistungselektronik_Output.(['T_FinitesVolumen_Leistungselektronik_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_Leistungselektronik_Output.(['T_FinitesVolumen_Leistungselektronik_',num2str(i),'___K_']).Time,Fluid_Leistungselektronik_Output.(['T_FinitesVolumen_Leistungselektronik_',num2str(i),'___K_']).Data(:,Fluid_Leistungselektronik(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_Leistungselektronik_Output.(['T_FinitesVolumen_Leistungselektronik_',num2str(i),'___K_']).Time,Fluid_Leistungselektronik_Output.(['T_FinitesVolumen_Leistungselektronik_',num2str(i),'___K_']).Data(:,Fluid_Leistungselektronik(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kühlflüssigkeit im Strömungsgebiet der ',num2str(i),'. Leistungselektronik']);
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% if exist('Fluid_Batteriepack_Output')==1
%    for i=1:(size(fieldnames(Fluid_Batteriepack_Output),1)/2)
%        figure
%        plot(Fluid_Batteriepack_Output.(['T_FinitesVolumen_Batteriepack_',num2str(i),'___K_']).Time,Fluid_Batteriepack_Output.(['T_FinitesVolumen_Batteriepack_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_Batteriepack_Output.(['T_FinitesVolumen_Batteriepack_',num2str(i),'___K_']).Time,Fluid_Batteriepack_Output.(['T_FinitesVolumen_Batteriepack_',num2str(i),'___K_']).Data(:,Fluid_Batteriepack(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_Batteriepack_Output.(['T_FinitesVolumen_Batteriepack_',num2str(i),'___K_']).Time,Fluid_Batteriepack_Output.(['T_FinitesVolumen_Batteriepack_',num2str(i),'___K_']).Data(:,Fluid_Batteriepack(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kühlflüssigkeit im Strömungsgebiet des ',num2str(i),'. Batteriepacks']);
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% % if exist('Fluid_Schlauch_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Schlauch_Output),1)/2)
% %        figure
% %        plot(Fluid_Schlauch_Output.(['T_FinitesVolumen_Schlauch_',num2str(i),'___K_']).Time,Fluid_Schlauch_Output.(['T_FinitesVolumen_Schlauch_',num2str(i),'___K_']).Data(:,1)-273.15);
% %        hold on;
% %        plot(Fluid_Schlauch_Output.(['T_FinitesVolumen_Schlauch_',num2str(i),'___K_']).Time,Fluid_Schlauch_Output.(['T_FinitesVolumen_Schlauch_',num2str(i),'___K_']).Data(:,Fluid_Schlauch(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
% %        hold on;
% %        plot(Fluid_Schlauch_Output.(['T_FinitesVolumen_Schlauch_',num2str(i),'___K_']).Time,Fluid_Schlauch_Output.(['T_FinitesVolumen_Schlauch_',num2str(i),'___K_']).Data(:,Fluid_Schlauch(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
% %        grid on;
% %        axis tight;
% %        title(['Temperatur der Kühlflüssigkeit im Strömungsgebiet des ',num2str(i),'. Schlauchs']);
% %        xlabel('Zeit in s');
% %        ylabel('Temperatur in °C');
% %        legend('Anfang','Ca. Mitte','Ende');
% %    end
% % end
% 
% if exist('Fluid_Ladegeraet_Output')==1
%    for i=1:(size(fieldnames(Fluid_Ladegeraet_Output),1)/2)
%        figure
%        plot(Fluid_Ladegeraet_Output.(['T_FinitesVolumen_Ladegeraet_',num2str(i),'___K_']).Time,Fluid_Ladegeraet_Output.(['T_FinitesVolumen_Ladegeraet_',num2str(i),'___K_']).Data(:,1)-273.15);
%        hold on;
%        plot(Fluid_Ladegeraet_Output.(['T_FinitesVolumen_Ladegeraet_',num2str(i),'___K_']).Time,Fluid_Ladegeraet_Output.(['T_FinitesVolumen_Ladegeraet_',num2str(i),'___K_']).Data(:,Fluid_Ladegeraet(i).l_Kuehlfluessigkeit/l_FinitesVolumen/2)-273.15);
%        hold on;
%        plot(Fluid_Ladegeraet_Output.(['T_FinitesVolumen_Ladegeraet_',num2str(i),'___K_']).Time,Fluid_Ladegeraet_Output.(['T_FinitesVolumen_Ladegeraet_',num2str(i),'___K_']).Data(:,Fluid_Ladegeraet(i).l_Kuehlfluessigkeit/l_FinitesVolumen)-273.15);
%        grid on;
%        axis tight;
%        title(['Temperatur der Kuehlfluessigkeit im ',num2str(i),'. Ladegeraet']);
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
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
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
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
%        xlabel('Zeit in s');
%        ylabel('Temperatur in °C');
%        legend('Anfang','Ca. Mitte','Ende');
%    end
% end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Temperaturen der Kühlflüssigkeiten bzgl. der Knoten aller finiter Volumen in den Strömungsgebieten der Komponenten
% %--------------------------------------------------------------------------
% 
% % if exist('Fluid_Kuehler_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Kuehler_Output),1)/2)
% %        figure
% %        for j=1:(Fluid_Kuehler(i).l_Kuehlfluessigkeit/l_FinitesVolumen)
% %            plot(Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Time,Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Data(:,j)-273.15);
% %            hold on;
% %        end
% %        grid on;
% %        axis tight;
% %        title(['Temperatur der Kühlflüssigkeit bzgl. der Knoten aller finiter Volumen des Strömungsgebiets des ',num2str(i),'. Kühlers']);
% %        xlabel('Zeit in s');
% %        ylabel('Temperatur in °C');
% %    end
% % end
% % 
% % if exist('Fluid_Waermetauscher_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Waermetauscher_Output),1)/4)
% %        figure
% %        for j=1:(Fluid_Waermetauscher(1,i).l_Kuehlfluessigkeit/l_FinitesVolumen)
% %            plot(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Time,Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Data(:,j)-273.15);
% %            hold on;
% %        end
% %        grid on;
% %        axis tight;
% %        title(['Temperatur der Kühlflüssigkeit bzgl. der Knoten aller finiter Volumen des 1. Strömungsgebiets des ',num2str(i),'. Wärmetauschers']);
% %        xlabel('Zeit in s');
% %        ylabel('Temperatur in °C');
% % 
% %        figure
% %        for j=1:(Fluid_Waermetauscher(2,i).l_Kuehlfluessigkeit/l_FinitesVolumen)
% %            plot(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Time,Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Data(:,j)-273.15);
% %            hold on;
% %        end
% %        grid on;
% %        axis tight;
% %        title(['Temperatur der Kühlflüssigkeit bzgl. der Knoten aller finite Volumen des 2. Strömungsgebiets des  ',num2str(i),'. Wärmetauschers']);
% %        xlabel('Zeit in s');
% %        ylabel('Temperatur in °C');
% %    end
% % end
% % 
% % if exist('Fluid_EMaschine_Output')==1
% %    for i=1:(size(fieldnames(Fluid_EMaschine_Output),1)/2)
% %        figure
% %        for j=1:(Fluid_EMaschine(i).l_Kuehlfluessigkeit/l_FinitesVolumen)
% %            plot(Fluid_EMaschine_Output.(['T_FinitesVolumen_EMaschine_',num2str(i),'___K_']).Time,Fluid_EMaschine_Output.(['T_FinitesVolumen_EMaschine_',num2str(i),'___K_']).Data(:,j)-273.15);
% %            hold on;
% %        end
% %        grid on;
% %        axis tight;
% %        title(['Temperatur der Kühlflüssigkeit bzgl. der Knoten aller finiter Volumen des Strömungsgebiets der ',num2str(i),'. E-Maschine']);
% %        xlabel('Zeit in s');
% %        ylabel('Temperatur in °C');
% %    end
% % end
% % 
% % if exist('Fluid_Leistungselektronik_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Leistungselektronik_Output),1)/2)
% %        figure
% %        for j=1:(Fluid_Leistungselektronik(i).l_Kuehlfluessigkeit/l_FinitesVolumen)
% %            plot(Fluid_Leistungselektronik_Output.(['T_FinitesVolumen_Leistungselektronik_',num2str(i),'___K_']).Time,Fluid_Leistungselektronik_Output.(['T_FinitesVolumen_Leistungselektronik_',num2str(i),'___K_']).Data(:,j)-273.15);
% %            hold on;
% %        end
% %        grid on;
% %        axis tight;
% %        title(['Temperatur der Kühlflüssigkeit bzgl. der Knoten aller finiter Volumen des Strömungsgebiets der ',num2str(i),'. Leistungselektronik']);
% %        xlabel('Zeit in s');
% %        ylabel('Temperatur in °C');
% %    end
% % end
% % 
% % if exist('Fluid_Batteriepack_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Batteriepack_Output),1)/2)
% %        figure
% %        for j=1:(Fluid_Batteriepack(i).l_Kuehlfluessigkeit/l_FinitesVolumen)
% %            plot(Fluid_Batteriepack_Output.(['T_FinitesVolumen_Batteriepack_',num2str(i),'___K_']).Time,Fluid_Batteriepack_Output.(['T_FinitesVolumen_Batteriepack_',num2str(i),'___K_']).Data(:,j)-273.15);
% %            hold on;
% %        end
% %        grid on;
% %        axis tight;
% %        title(['Temperatur der Kühlflüssigkeit bzgl. der Knoten aller finiter Volumen des Strömungsgebiets des ',num2str(i),'. Batteriepacks']);
% %        xlabel('Zeit in s');
% %        ylabel('Temperatur in °C');
% %    end
% % end
% % 
% % if exist('Fluid_Schlauch_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Schlauch_Output),1)/2)
% %        figure
% %        for j=1:(Fluid_Schlauch(i).l_Kuehlfluessigkeit/l_FinitesVolumen)
% %            plot(Fluid_Schlauch_Output.(['T_FinitesVolumen_Schlauch_',num2str(i),'___K_']).Time,Fluid_Schlauch_Output.(['T_FinitesVolumen_Schlauch_',num2str(i),'___K_']).Data(:,j)-273.15);
% %            hold on;
% %        end
% %        grid on;
% %        axis tight;
% %        title(['Temperatur der Kühlflüssigkeit bzgl. der Knoten aller finiter Volumen des Strömungsgebiets des ',num2str(i),'. Schlauchs']);
% %        xlabel('Zeit in s');
% %        ylabel('Temperatur in °C');
% %    end
% % end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Volumenströme der Kühlflüssigkeiten in den Kühlkreisläufen
% %--------------------------------------------------------------------------
% 
% if exist('Kuehlkreislauf_Output')==1
%    for i=1:size(fieldnames(Kuehlkreislauf_Output.PV_Kuehlkreislauf__m_3_s__1_),1)
%        figure
%        plot(Kuehlkreislauf_Output.PV_Kuehlkreislauf__m_3_s__1_.(['PV_Kuehlkreislauf_',num2str(i),'___m_3_s__1_']).Time,Kuehlkreislauf_Output.PV_Kuehlkreislauf__m_3_s__1_.(['PV_Kuehlkreislauf_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
%        grid on;
%        axis tight;
%        title(['Volumenstrom der Kühlflüssigkeit im ',num2str(i),'. Kühlkreislauf']);
%        xlabel('Zeit in s');
%        ylabel('Volumenstrom in l/h');
%    end
% end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Zustände der Dreiwegeventile
% %--------------------------------------------------------------------------
% 
% if exist('Kuehlkreislauf_Output')==1
%    if exist('Ventil')==1
%       for i=1:size(fieldnames(Kuehlkreislauf_Output.Zustand_Ventil____),1)
%           figure
%           plot(Kuehlkreislauf_Output.Zustand_Ventil____.(['Zustand_Ventil_',num2str(i),'_____']).Time,Kuehlkreislauf_Output.Zustand_Ventil____.(['Zustand_Ventil_',num2str(i),'_____']).Data(:)*100);
%           grid on;
%           axis tight;
%           title(['Zustand des ',num2str(i),'. Dreiwegeventils']);
%           xlabel('Zeit in s');
%           ylabel('Zustand in %');
%       end
%    end
% end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Volumenströme der Kühlflüssigkeiten in den Strömungsgebieten der Komponenten
% %--------------------------------------------------------------------------
% 
% % if exist('Fluid_Kuehler_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Kuehler_Output),1)/2)
% %        figure
% %        plot(Fluid_Kuehler_Output.(['PV_Kuehlfluessigkeit_Kuehler_',num2str(i),'___m_3_s__1_']).Time,Fluid_Kuehler_Output.(['PV_Kuehlfluessigkeit_Kuehler_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kühlflüssigkeit im Strömungsgebiet des ',num2str(i),'. Kühlers']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %    end
% % end
% % 
% % if exist('Fluid_Waermetauscher_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Waermetauscher_Output),1)/4)
% %        figure
% %        plot(Fluid_Waermetauscher_Output.(['PV_Kuehlfluessigkeit_Waermetauscher_1_',num2str(i),'___m_3_s__1_']).Time,Fluid_Waermetauscher_Output.(['PV_Kuehlfluessigkeit_Waermetauscher_1_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kühlflüssigkeit im 1. Strömungsgebiet des ',num2str(i),'. Wärmetauschers']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %        
% %        figure
% %        plot(Fluid_Waermetauscher_Output.(['PV_Kuehlfluessigkeit_Waermetauscher_2_',num2str(i),'___m_3_s__1_']).Time,Fluid_Waermetauscher_Output.(['PV_Kuehlfluessigkeit_Waermetauscher_2_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kühlflüssigkeit im 2. Strömungsgebiet des ',num2str(i),'. Wärmetauschers']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %    end
% % end
% % 
% % if exist('Fluid_EMaschine_Output')==1
% %    for i=1:(size(fieldnames(Fluid_EMaschine_Output),1)/2)
% %        figure
% %        plot(Fluid_EMaschine_Output.(['PV_Kuehlfluessigkeit_EMaschine_',num2str(i),'___m_3_s__1_']).Time,Fluid_EMaschine_Output.(['PV_Kuehlfluessigkeit_EMaschine_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kühlflüssigkeit im Strömungsgebiet der ',num2str(i),'. E-Maschine']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %    end
% % end
% % 
% % if exist('Fluid_Leistungselektronik_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Leistungselektronik_Output),1)/2)
% %        figure
% %        plot(Fluid_Leistungselektronik_Output.(['PV_Kuehlfluessigkeit_Leistungselektronik_',num2str(i),'___m_3_s__1_']).Time,Fluid_Leistungselektronik_Output.(['PV_Kuehlfluessigkeit_Leistungselektronik_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kühlflüssigkeit im Strömungsgebiet der ',num2str(i),'. Leistungselektronik']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %    end
% % end
% % 
% % if exist('Fluid_Batteriepack_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Batteriepack_Output),1)/2)
% %        figure
% %        plot(Fluid_Batteriepack_Output.(['PV_Kuehlfluessigkeit_Batteriepack_',num2str(i),'___m_3_s__1_']).Time,Fluid_Batteriepack_Output.(['PV_Kuehlfluessigkeit_Batteriepack_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kühlflüssigkeit im Strömungsgebiet des ',num2str(i),'. Batteriepacks']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %    end
% % end
% % 
% % if exist('Fluid_Schlauch_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Schlauch_Output),1)/2)
% %        figure
% %        plot(Fluid_Schlauch_Output.(['PV_Kuehlfluessigkeit_Schlauch_',num2str(i),'___m_3_s__1_']).Time,Fluid_Schlauch_Output.(['PV_Kuehlfluessigkeit_Schlauch_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kühlflüssigkeit im Strömungsgebiet des ',num2str(i),'. Schlauchs']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %    end
% % end
% % 
% % if exist('Fluid_Ladegeraet_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Ladegeraet_Output),1)/2)
% %        figure
% %        plot(Fluid_Ladegeraet_Output.(['PV_Kuehlfluessigkeit_Ladegeraet_',num2str(i),'___m_3_s__1_']).Time,Fluid_Ladegeraet_Output.(['PV_Kuehlfluessigkeit_Ladegeraet_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kuehlfluessigkeit im ',num2str(i),'. Ladegeraet']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %     end
% % end
% % 
% % if exist('Fluid_PCM_Output')==1
% %    for i=1:(size(fieldnames(Fluid_PCM_Output),1)/2)
% %        figure
% %        plot(Fluid_PCM_Output.(['PV_Kuehlfluessigkeit_PCM_',num2str(i),'___m_3_s__1_']).Time,Fluid_PCM_Output.(['PV_Kuehlfluessigkeit_PCM_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kuehlfluessigkeit im ',num2str(i),'. PCM']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %    end
% % end
% % 
% % if exist('Fluid_Peltier_Output')==1
% %    for i=1:(size(fieldnames(Fluid_Peltier_Output),1)/2)
% %        figure
% %        plot(Fluid_Peltier_Output.(['PV_Kuehlfluessigkeit_Peltier_',num2str(i),'___m_3_s__1_']).Time,Fluid_Peltier_Output.(['PV_Kuehlfluessigkeit_Peltier_',num2str(i),'___m_3_s__1_']).Data(:)*10^3*3600);
% %        grid on;
% %        axis tight;
% %        title(['Volumenstrom der Kuehlfluessigkeit im ',num2str(i),'. Peltier-Elements']);
% %        xlabel('Zeit in s');
% %        ylabel('Volumenstrom in l/h');
% %    end
% % end
% 
% 
% %--------------------------------------------------------------------------
% % Darstellung der Luftgeschwindigkeiten der Kühlerlüfter
% %--------------------------------------------------------------------------
% 
% if exist('Kuehler_Output')==1
%    for i=1:(size(fieldnames(Kuehler_Output),1)/2)
%        figure
%        plot(Kuehler_Output.(['v_Kuehlerluefter_',num2str(i),'___m_s__1_']).Time,Kuehler_Output.(['v_Kuehlerluefter_',num2str(i),'___m_s__1_']).Data(:)*3.6);
%        grid on;
%        axis tight;
%        title(['Luftgeschwindigkeit des ',num2str(i),'. Kühlerlüfters']);
%        xlabel('Zeit in s');
%        ylabel('Geschwindigkeit in km/h');
%    end
% end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Fahrzeuggeschwindigkeit
% %--------------------------------------------------------------------------
% 
% figure
% plot([v_Fahrzeug.Time;t_Simulation],[v_Fahrzeug.Data(:);0]);
% grid on;
% axis tight;
% title('Fahrzeuggeschwindigkeit');
% xlabel('Zeit in s');
% ylabel('Geschwindigkeit in km/h');
% 
% %--------------------------------------------------------------------------
% % Darstellung der Steigung der Strecke
% %--------------------------------------------------------------------------
% 
% figure
% plot([alpha_Strecke(:,1);t_Simulation],[alpha_Strecke(:,2);0]);
% grid on;
% axis tight;
% title('Steigung der Strecke');
% xlabel('Zeit in s');
% ylabel('Steigung in %');
% 
% %--------------------------------------------------------------------------
% % Darstellung der Leistung der Peltierelemente
% %--------------------------------------------------------------------------
% if exist('Peltier_Output')==1
%     figure
%     plot(Peltier_Output.P_Peltier_Bat__W_.Time,Peltier_Output.P_Peltier_Bat__W_.Data);
%     hold on
%     plot(Peltier_Output.PQ_ges.Time,Peltier_Output.PQ_ges.Data);
%     grid on;
%     axis tight;
%     title('Leistung der Peltierelemente');
%     xlabel('Zeit in s');
%     ylabel('Leistung in W');
%     legend('P_{el}','P_Q');
% end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Leistungsanforderungen an die Räder, an die 1. E-Maschine, an die 1. Leistungselektronik und an das 1. Batteriepack
% %--------------------------------------------------------------------------
% 
% if exist('Rad_Output')==1
%    figure
%    plot(Rad_Output.P_Rad__W_.Time,Rad_Output.P_Rad__W_.Data(:)/1000);
%    grid on;
%    axis tight;
%    title('Leistungsanforderung an die Räder');
%    xlabel('Zeit in s');
%    ylabel('Leistung in kW');
% end
% 
% if exist('Getriebe_Output')==1
%    figure
%    plot(Getriebe_Output.P_EMaschine__W_.Time,Getriebe_Output.P_EMaschine__W_.Data(:)/1000);
%    grid on;
%    axis tight;
%    title('Leistungsanforderung an die 1. E-Maschine');
%    xlabel('Zeit in s');
%    ylabel('Leistung in kW');
% end
% 
% if exist('EMaschine_Output')==1
%    figure
%    plot(EMaschine_Output.P_Leistungselektronik__W_.Time,EMaschine_Output.P_Leistungselektronik__W_.Data(:)/1000);
%    grid on;
%    axis tight;
%    title('Leistungsanforderung an die 1. Leistungselektronik');
%    xlabel('Zeit in s');
%    ylabel('Leistung in kW');
% end
% 
% if exist('Leistungselektronik_Output')==1
%    figure
%    plot(Leistungselektronik_Output.P_Batteriepack_Fahrbetrieb__W_.Time,(Leistungselektronik_Output.P_Batteriepack_Fahrbetrieb__W_.Data(:)+P_Nebenverbraucher)/1000);
%    grid on;
%    axis tight;
%    title('Leistungsanforderung an das 1. Batteriepack');
%    xlabel('Zeit in s');
%    ylabel('Leistung in kW');
% end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Drehzahl und des Drehmoments der 1. E-Maschine
% %--------------------------------------------------------------------------
% 
% if exist('Getriebe_Output')==1
%    figure
%    plot(Getriebe_Output.n_EMaschine__min__1_.Time,Getriebe_Output.n_EMaschine__min__1_.Data(:));
%    grid on;
%    axis tight;
%    title('Drehzahl der 1. E-Maschine');
%    xlabel('Zeit in s');
%    ylabel('Drehzahl in 1/min');
% 
%    figure
%    plot(Getriebe_Output.M_EMaschine__Nm_.Time,Getriebe_Output.M_EMaschine__Nm_.Data(:));
%    grid on;
%    axis tight;
%    title('Drehmoment der 1. E-Maschine');
%    xlabel('Zeit in s');
%    ylabel('Moment in Nm');
% end
% 
% %--------------------------------------------------------------------------
% % Darstellung der Klemmenspannung, der Strombelastung und des SOC des Batteriepacks
% %-------------------------------------------------------------------------
% 
% if exist('Batteriepack_Output')==1
%    figure
%    plot(Batteriepack_Output.U_Batteriepack__V_.Time,Batteriepack_Output.U_Batteriepack__V_.Data(:));
%    grid on;
%    axis tight;
%    title('Klemmenspannung des 1. Batteriepacks');
%    xlabel('Zeit in s');
%    ylabel('Spannung in V');
% 
%    figure
%    plot(Batteriepack_Output.I_Batteriepack__A_.Time,Batteriepack_Output.I_Batteriepack__A_.Data(:));
%    grid on;
%    axis tight;
%    title('Strombelastung des 1. Batteriepacks');
%    xlabel('Zeit in s');
%    ylabel('Strom in A');
% 
%    figure
%    plot(Batteriepack_Output.SOC_Batteriepack____.Time,Batteriepack_Output.SOC_Batteriepack____.Data(:)*100);
%    grid on;
%    axis tight;
%    title('SOC des 1. Batteriepacks');
%    xlabel('Zeit in s');
%    ylabel('SOC in %');
% end

%% VIII. Zurücksetzung des Thermomanagementsystemmodells

%keyboard;

% -> Die Zurücksetzung des Thermomanagementsystemmodells in Simulink in den Ausgangszustand ist notwendig, um eine erneute Simulation eines beliebigen Thermomanagementsystems zu ermöglichen

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Aufbau und Parametrierung des Subsystems "Bestimmung PV_Kuehlkreislauf" im Subsystem "Fluid" für die Bestimmung der Volumenströme in den Kühlkreisläufen"
%--------------------------------------------------------------------------

if n_Kuehlkreislauf~=0
   for i=1:n_Kuehlkreislauf
       delete_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf'],'EMaschine_Output/1',['Kuehlkreislauf(',num2str(i),')/1']);       
       delete_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf'],'Leistungselektronik_Output/1',['Kuehlkreislauf(',num2str(i),')/2']);       
       delete_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf'],'Batteriepack_Output/1',['Kuehlkreislauf(',num2str(i),')/3']);       
       delete_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf'],['Kuehlkreislauf(',num2str(i),')/1'],['Bus Creator/',num2str(i)]);
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf(',num2str(i),')']);
   end
   delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1','Bus Creator6/1');
elseif n_Kuehlkreislauf==0
       set_param([Modell,'/Output/Kuehlkreislauf'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Aufbau und Parametrierung des Subsystems "Bestimmung Zustand_Ventil" im Subsystem "Fluid" für die Bestimmung der Zustände der Dreiwegeventile"
%--------------------------------------------------------------------------


if exist('Ventil')==1
   for i=1:size(Ventil,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil'],'Fluid_Schlauch_Output/1',['Ventil(',num2str(i),')/1']);       
       delete_line([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil'],['Ventil(',num2str(i),')/1'],['Bus Creator/',num2str(i)]);    
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil(',num2str(i),')']);
   end
   delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1','Bus Creator6/2');    
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Kopplung der Fluid_Komponenten im Subsystem "Fluid" abh. von der Konfiguration der Kühlkreisläufe"
%--------------------------------------------------------------------------

for i=1:n_Kuehlkreislauf
    for j=size(Graph_Kuehlkreislauf{i}.Edges,1):-1:1
        Port_Verbindung=get_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch'],'PortConnectivity');
        if Port_Verbindung(6).SrcBlock==-1
           delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/1'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/3']);
           delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/2'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/4']);
           delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/3'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/5']);
        else
            delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/1'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/6']);
            delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/2'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/7']);
            delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/3'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/8']);
        end
        Port_Verbindung=get_param([Modell,'/Thermomanagementsystem/Fluid/',Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch'],'PortConnectivity');
        if Port_Verbindung(11).SrcBlock==-1
           delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/1'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/9']);
           delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/2'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/10']);
        else
            delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/1'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/11']);
            delete_line([Modell,'/Thermomanagementsystem/Fluid'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,2},' thermisch/2'],[Graph_Kuehlkreislauf{i}.Edges{:,1}{j,1},' thermisch/12']);
        end
    end
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Aufbau und Parametrierung der Fluid_Komponenten im Subsystem "Fluid""
%--------------------------------------------------------------------------

% -> Fluid_Kuehler
if exist('Fluid_Kuehler')==1
   k=1;
   for i=1:size(Fluid_Kuehler,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Kuehler(',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Kuehler(',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector/',num2str(i)],['Fluid_Kuehler(',num2str(i),') thermisch/2']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Kuehler(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Kuehler(',num2str(i),') thermisch/3'],['Bus Creator/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Kuehler(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Kuehler')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector'],'commented','off');
       set_param([Modell,'/Output/Fluid_Kuehler'],'commented','off');
end

% -> Fluid_Waermetauscher
if exist('Fluid_Waermetauscher')==1                                               
   k=1;
   l=1;
   for i=1:size(Fluid_Waermetauscher,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Waermetauscher(1,',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Waermetauscher(1,',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector1/',num2str(k)],['Fluid_Waermetauscher(1,',num2str(i),') thermisch/2']);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Waermetauscher(1,',num2str(i),') thermisch/1'],['Bus Creator1/',num2str(l)]);
       l=l+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Waermetauscher(1,',num2str(i),') thermisch/3'],['Bus Creator1/',num2str(l)]);
       l=l+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(1,',num2str(i),') thermisch']);
       
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Waermetauscher(2,',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Waermetauscher(2,',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector1/',num2str(k)],['Fluid_Waermetauscher(2,',num2str(i),') thermisch/2']);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Waermetauscher(2,',num2str(i),') thermisch/1'],['Bus Creator1/',num2str(l)]);
       l=l+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Waermetauscher(2,',num2str(i),') thermisch/3'],['Bus Creator1/',num2str(l)]);
       l=l+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Waermetauscher(2,',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Waermetauscher')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector1'],'commented','off');
       set_param([Modell,'/Output/Fluid_Waermetauscher'],'commented','off');
end

% -> Fluid_EMaschine
if exist('Fluid_EMaschine')==1
   k=1;
   for i=1:size(Fluid_EMaschine,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_EMaschine(',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_EMaschine(',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector2/',num2str(i)],['Fluid_EMaschine(',num2str(i),') thermisch/2']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_EMaschine(',num2str(i),') thermisch/1'],['Bus Creator2/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_EMaschine(',num2str(i),') thermisch/3'],['Bus Creator2/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_EMaschine(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_EMaschine')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector2'],'commented','off');
       set_param([Modell,'/Output/Fluid_EMaschine'],'commented','off');
end

% -> Fluid_Leistungselektronik
if exist('Fluid_Leistungselektronik')==1
   k=1;
   for i=1:size(Fluid_Leistungselektronik,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Leistungselektronik(',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Leistungselektronik(',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector3/',num2str(i)],['Fluid_Leistungselektronik(',num2str(i),') thermisch/2']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Leistungselektronik(',num2str(i),') thermisch/1'],['Bus Creator3/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Leistungselektronik(',num2str(i),') thermisch/3'],['Bus Creator3/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Leistungselektronik(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Leistungselektronik')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector3'],'commented','off');
       set_param([Modell,'/Output/Fluid_Leistungselektronik'],'commented','off');
end        

% -> Fluid_Batteriepack
if exist('Fluid_Batteriepack')==1
   k=1;
   for i=1:size(Fluid_Batteriepack,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Batteriepack(',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Batteriepack(',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector4/',num2str(i)],['Fluid_Batteriepack(',num2str(i),') thermisch/2']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Batteriepack(',num2str(i),') thermisch/1'],['Bus Creator4/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Batteriepack(',num2str(i),') thermisch/3'],['Bus Creator4/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Batteriepack(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Batteriepack')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector4'],'commented','off');
       set_param([Modell,'/Output/Fluid_Batteriepack'],'commented','off');
end     

% -> Fluid_Schlauch
if exist('Fluid_Schlauch')==1
   k=1;
   for i=1:size(Fluid_Schlauch,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Schlauch(',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Schlauch(',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector5/',num2str(i)],['Fluid_Schlauch(',num2str(i),') thermisch/2']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Schlauch(',num2str(i),') thermisch/1'],['Bus Creator5/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Schlauch(',num2str(i),') thermisch/3'],['Bus Creator5/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Schlauch(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Schlauch')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector5'],'commented','off');
       set_param([Modell,'/Output/Fluid_Schlauch'],'commented','off');
end

% -> Fluid_Ladegeraet
if exist('Fluid_Ladegeraet')==1
   k=1;
   for i=1:size(Fluid_Ladegeraet,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Ladegeraet(',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Ladegeraet(',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector6/',num2str(i)],['Fluid_Ladegeraet(',num2str(i),') thermisch/2']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Ladegeraet(',num2str(i),') thermisch/1'],['Bus Creator7/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Ladegeraet(',num2str(i),') thermisch/3'],['Bus Creator7/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Ladegeraet(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Ladegeraet')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector6'],'commented','off');
       set_param([Modell,'/Output/Fluid_Ladegeraet'],'commented','off');
end

% -> Fluid_PCM
if exist('Fluid_PCM')==1
   k=1;
   for i=1:size(Fluid_PCM,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_PCM(',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_PCM(',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector7/',num2str(i)],['Fluid_PCM(',num2str(i),') thermisch/2']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_PCM(',num2str(i),') thermisch/1'],['Bus Creator8/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_PCM(',num2str(i),') thermisch/3'],['Bus Creator8/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_PCM(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_PCM')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector7'],'commented','off');
       set_param([Modell,'/Output/Fluid_PCM'],'commented','off');
end

% -> Fluid_Peltier
if exist('Fluid_Peltier')==1
   k=1;
   for i=1:size(Fluid_Peltier,2)
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung PV_Kuehlkreislauf/1',['Fluid_Peltier(',num2str(i),') thermisch/1']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],'Bestimmung Zustand_Ventil/1',['Fluid_Peltier(',num2str(i),') thermisch/13']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Bus Selector8/',num2str(i)],['Fluid_Peltier(',num2str(i),') thermisch/2']);
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Peltier(',num2str(i),') thermisch/1'],['Bus Creator9/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Fluid'],['Fluid_Peltier(',num2str(i),') thermisch/3'],['Bus Creator9/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Fluid/Fluid_Peltier(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Peltier')==0
       set_param([Modell,'/Thermomanagementsystem/Fluid/Bus Selector8'],'commented','off');
       set_param([Modell,'/Output/Fluid_Peltier'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Aufbau und Parametrierung der Kuehler im Subsystem "Kühler""
%--------------------------------------------------------------------------

if exist('Fluid_Kuehler')==1
   j=1;
   k=1;
   for i=1:size(Fluid_Kuehler,2)
       delete_line([Modell,'/Thermomanagementsystem/Kühler'],['Bus Selector/',num2str(j)],['Kuehler(',num2str(i),') thermisch/1']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/Kühler'],['Bus Selector/',num2str(j)],['Kuehler(',num2str(i),') thermisch/2']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/Kühler'],'T_Umgebung [K]/1',['Kuehler(',num2str(i),') thermisch/3']);       
       delete_line([Modell,'/Thermomanagementsystem/Kühler'],'v_Fahrzeug [m*s^-1]/1',['Kuehler(',num2str(i),') thermisch/4']);
       delete_line([Modell,'/Thermomanagementsystem/Kühler'],['Kuehler(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Kühler'],['Kuehler(',num2str(i),') thermisch/2'],['Bus Creator/',num2str(k)]); 
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Kühler/Kuehler(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Kuehler')==0
       set_param([Modell,'/Thermomanagementsystem/Kühler/Bus Selector'],'commented','off');
       set_param([Modell,'/Output/Kuehler'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Aufbau und Parametrierung der Waermetauscher im Subsystem "Wärmetauscher""
%--------------------------------------------------------------------------

if exist('Fluid_Waermetauscher')==1
   j=1;
   k=1;
   for i=1:size(Fluid_Waermetauscher,2)
       delete_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Bus Selector/',num2str(j)],['Waermetauscher(',num2str(i),') thermisch/1']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Bus Selector/',num2str(j)],['Waermetauscher(',num2str(i),') thermisch/2']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Bus Selector/',num2str(j)],['Waermetauscher(',num2str(i),') thermisch/3']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Bus Selector/',num2str(j)],['Waermetauscher(',num2str(i),') thermisch/4']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],'T_Umgebung [K]/1',['Waermetauscher(',num2str(i),') thermisch/5']);
       delete_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],'v_Fahrzeug [m*s^-1]/1',['Waermetauscher(',num2str(i),') thermisch/6']);
       delete_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Waermetauscher(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/Wärmetauscher'],['Waermetauscher(',num2str(i),') thermisch/2'],['Bus Creator/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Waermetauscher')==0
       set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Bus Selector'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Aufbau und Parametrierung der Schlauch im Subsystem "Schlauch""
%--------------------------------------------------------------------------

if exist('Fluid_Schlauch')==1
   j=1;
   for i=1:size(Fluid_Schlauch,2)
       delete_line([Modell,'/Thermomanagementsystem/Schlauch'],['Bus Selector/',num2str(j)],['Schlauch(',num2str(i),') thermisch/1']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/Schlauch'],['Bus Selector/',num2str(j)],['Schlauch(',num2str(i),') thermisch/2']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/Schlauch'],'T_Umgebung [K]/1',['Schlauch(',num2str(i),') thermisch/3']);
       delete_line([Modell,'/Thermomanagementsystem/Schlauch'],'v_Fahrzeug [m*s^-1]/1',['Schlauch(',num2str(i),') thermisch/4']);
       delete_line([Modell,'/Thermomanagementsystem/Schlauch'],['Schlauch(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(i)]);
       delete_block([Modell,'/Thermomanagementsystem/Schlauch/Schlauch(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_Schlauch')==0
       set_param([Modell,'/Thermomanagementsystem/Schlauch/Bus Selector'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Aufbau und Parametrierung der PCM im Subsystem "PCM""
%--------------------------------------------------------------------------
if exist('Fluid_PCM')==1
   j=1;
   k=1;
   for i=1:size(Fluid_PCM,2)
       delete_line([Modell,'/Thermomanagementsystem/PCM'],['Bus Selector/',num2str(j)],['PCM(',num2str(i),') thermisch/1']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/PCM'],['Bus Selector/',num2str(j)],['PCM(',num2str(i),') thermisch/2']);
       j=j+1;
       delete_line([Modell,'/Thermomanagementsystem/PCM'],'T_Umgebung [K]/1',['PCM(',num2str(i),') thermisch/3']);
       delete_line([Modell,'/Thermomanagementsystem/PCM'],'v_Fahrzeug [m*s^-1]/1',['PCM(',num2str(i),') thermisch/4']);
       delete_line([Modell,'/Thermomanagementsystem/PCM'],['PCM(',num2str(i),') thermisch/1'],['Bus Creator/',num2str(k)]);
       k=k+1;
       delete_line([Modell,'/Thermomanagementsystem/PCM'],['PCM(',num2str(i),') thermisch/2'],['Bus Creator/',num2str(k)]);
       k=k+1;
       delete_block([Modell,'/Thermomanagementsystem/PCM/PCM(',num2str(i),') thermisch']);
   end
elseif exist('Fluid_PCM')==0
       set_param([Modell,'/Thermomanagementsystem/PCM/Bus Selector'],'commented','off');
end


%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Bearbeitung von EMaschine(1) im Subsystem "E-Maschine""
%--------------------------------------------------------------------------

if exist('Fluid_EMaschine')==0
   set_param([Modell,'/Thermomanagementsystem/E-Maschine/Bus Selector'],'commented','off');
   set_param([Modell,'/Thermomanagementsystem/E-Maschine/EMaschine(1) + Getriebe(1) thermisch/Waermeaustausch EMaschine - Kuehlfluessigkeit'],'commented','off'); 
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Bearbeitung von Leistungselektronik(1) im Subsystem "Leistungselektronik""
%--------------------------------------------------------------------------

if exist('Fluid_Leistungselektronik')==0
   set_param([Modell,'/Thermomanagementsystem/Leistungselektronik/Bus Selector'],'commented','off');
   set_param([Modell,'/Thermomanagementsystem/Leistungselektronik/Leistungselektronik(1) thermisch/Waermeaustausch Case - Kuehlfluessigkeit'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Bearbeitung von Batteriepack(1) im Subsystem "Batteriepack""
%--------------------------------------------------------------------------

if exist('Fluid_Batteriepack')==0
   set_param([Modell,'/Thermomanagementsystem/Batteriepack/Bus Selector'],'commented','off');
   set_param([Modell,'/Thermomanagementsystem/Batteriepack/Batteriepack(1) thermisch/Waermeaustausch Batteriepack - Kuehlfluessigkeit'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Bearbeitung von Ladegeraet(1) im Subsystem "Ladegeraet""
%--------------------------------------------------------------------------

if exist('Fluid_Ladegeraet')==0
   set_param([Modell,'/Thermomanagementsystem/Ladegeraet/Bus Selector'],'commented','off');
   set_param([Modell,'/Thermomanagementsystem/Ladegeraet/Ladegeraet(1) thermisch/Waermeaustausch Ladegeraet - Kuehlfluessigkeit'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Bearbeitung von Peltier(1) im Subsystem "Peltier""
%--------------------------------------------------------------------------

if exist('Fluid_Peltier')==0
   set_param([Modell,'/Thermomanagementsystem/Peltier/Bus Selector'],'commented','off');
   set_param([Modell,'/Thermomanagementsystem/Peltier/Peltier(1) thermisch'],'commented','off');
end

%--------------------------------------------------------------------------
% Zurücksetzung bzgl. "Allgemeine Einstellungen zur Vermeidung von Warnungen bei der Simulation des Thermomanagemensystemmodells"
%--------------------------------------------------------------------------

set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung PV_Kuehlkreislauf/Kuehlkreislauf'],'commented','off');
set_param([Modell,'/Thermomanagementsystem/Fluid/Bestimmung Zustand_Ventil/Ventil'],'commented','off');
set_param([Modell,'/Thermomanagementsystem/Fluid/Fluid_Komponente thermisch'],'commented','off');
set_param([Modell,'/Thermomanagementsystem/Kühler/Kuehler thermisch'],'commented','off');
set_param([Modell,'/Thermomanagementsystem/Wärmetauscher/Waermetauscher thermisch'],'commented','off');
set_param([Modell,'/Thermomanagementsystem/Schlauch/Schlauch thermisch'],'commented','off');
set_param([Modell,'/Thermomanagementsystem/PCM/PCM thermisch'],'commented','off');
set_param(Modell,'UnconnectedInputMsg','warning');
set_param(Modell,'UnconnectedOutputMsg','warning');

%--------------------------------------------------------------------------
% Schließen des Simulink Modells ohne Änderungen zu speichern
%--------------------------------------------------------------------------
close_system(Modell, 0)

%% IX Abspeichern der Simulationsergebnisse

%keyboard;

% Batterie
if exist('Batteriepack_Output')==1
    Output.battery_system.Time = Batteriepack_Output.I_Batteriepack__A_.Time;
    Output.battery_system.I = Batteriepack_Output.I_Batteriepack__A_.Data;
    Output.battery_system.U = Batteriepack_Output.U_Batteriepack__V_.Data;
    Output.battery_system.SOC = Batteriepack_Output.SOC_Batteriepack____.Data;
    Output.battery_system.T = Batteriepack_Output.T_Batteriepack__K_.Data;
end

if exist('Fluid_Batteriepack_Output')==1
    l_Fluid_Batteriepack_T = size(Fluid_Batteriepack_Output.T_FinitesVolumen_Batteriepack_1___K_.Data);
    Output.Fluid_battery_system.Time = Fluid_Batteriepack_Output.T_FinitesVolumen_Batteriepack_1___K_.Time;
    Output.Fluid_battery_system.T_begin = Fluid_Batteriepack_Output.T_FinitesVolumen_Batteriepack_1___K_.Data(:,1);
    Output.Fluid_battery_system.T_middle = Fluid_Batteriepack_Output.T_FinitesVolumen_Batteriepack_1___K_.Data(:,round(l_Fluid_Batteriepack_T(2)/2));
    Output.Fluid_battery_system.T_end = Fluid_Batteriepack_Output.T_FinitesVolumen_Batteriepack_1___K_.Data(:,end);
end

% Leistungselektronik
if exist('Leistungselektronik_Output')==1
    Output.power_electronics.Time = Leistungselektronik_Output.P_Batteriepack_Fahrbetrieb__W_.Time;
    Output.power_electronics.P_bat = Leistungselektronik_Output.P_Batteriepack_Fahrbetrieb__W_.Data(:);
    Output.power_electronics.T_j_K = Leistungselektronik_Output.T_Leistungselektronik__K_.T_j__K_.Data;
    Output.power_electronics.T_c_K = Leistungselektronik_Output.T_Leistungselektronik__K_.T_c__K_.Data;
end

if exist('Fluid_Leistungselektronik_Output')==1
    l_Fluid_Leistungselektronik_T = size(Fluid_Leistungselektronik_Output.T_FinitesVolumen_Leistungselektronik_1___K_.Data);
    Output.Fluid_power_electronics.Time = Fluid_Leistungselektronik_Output.T_FinitesVolumen_Leistungselektronik_1___K_.Time;
    Output.Fluid_power_electronics.T_begin = Fluid_Leistungselektronik_Output.T_FinitesVolumen_Leistungselektronik_1___K_.Data(:,1);
    Output.Fluid_power_electronics.T_middle = Fluid_Leistungselektronik_Output.T_FinitesVolumen_Leistungselektronik_1___K_.Data(:,round(l_Fluid_Leistungselektronik_T(2)/2));
    Output.Fluid_power_electronics.T_end = Fluid_Leistungselektronik_Output.T_FinitesVolumen_Leistungselektronik_1___K_.Data(:,end);
end

% E-Maschine
if exist('EMaschine_Output')==1
    Output.electric_machine.Time = EMaschine_Output.P_Leistungselektronik__W_.Time;
    Output.electric_machine.P_PE = EMaschine_Output.P_Leistungselektronik__W_.Data(:);
    Output.electric_machine.T_emachine = EMaschine_Output.T_EMaschine_Getriebe__K_.T_EMaschine__K_.Data;
    Output.electric_machine.T_transmission = EMaschine_Output.T_EMaschine_Getriebe__K_.T_Getriebe__K_.Data;
end

if exist('Fluid_EMaschine_Output')==1
    Output.Fluid_electric_machine = Fluid_EMaschine_Output;
    l_Fluid_EMaschine_T = size(Fluid_EMaschine_Output.T_FinitesVolumen_EMaschine_1___K_.Data);
    Output.Fluid_electric_machine.Time = Fluid_EMaschine_Output.T_FinitesVolumen_EMaschine_1___K_.Time;
    Output.Fluid_electric_machine.T_begin = Fluid_EMaschine_Output.T_FinitesVolumen_EMaschine_1___K_.Data(:,1);
    Output.Fluid_electric_machine.T_middle = Fluid_EMaschine_Output.T_FinitesVolumen_EMaschine_1___K_.Data(:,round(l_Fluid_Leistungselektronik_T(2)/2));
    Output.Fluid_electric_machine.T_end = Fluid_EMaschine_Output.T_FinitesVolumen_EMaschine_1___K_.Data(:,end);
end

% Kuehler
if exist('Kuehler_Output')==1
    for i=1:(size(fieldnames(Kuehler_Output),1)/2)
        Output.(['radiator_',num2str(i)]).Time = Kuehler_Output.(['v_Kuehlerluefter_',num2str(i),'___m_s__1_']).Time;
        Output.(['radiator_',num2str(i)]).v_fan = Kuehler_Output.(['v_Kuehlerluefter_',num2str(i),'___m_s__1_']).Data(:);
    end
end

if exist('Fluid_Kuehler_Output')==1
    for i=1:(size(fieldnames(Fluid_Kuehler_Output),1)/2)
        l_Fluid_Kuehler_T = size(Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Data);
        Output.(['Fluid_radiator_',num2str(i)]).Time = Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Time;
        Output.(['Fluid_radiator_',num2str(i)]).T_begin = Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Data(:,1);
        Output.(['Fluid_radiator_',num2str(i)]).T_middle = Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Data(:,round(l_Fluid_Kuehler_T(2)/2));
        Output.(['Fluid_radiator_',num2str(i)]).T_end = Fluid_Kuehler_Output.(['T_FinitesVolumen_Kuehler_',num2str(i),'___K_']).Data(:,end);
    end
end

% Waermetauscher
if exist('Fluid_Waermetauscher_Output')==1
    for i=1:(size(fieldnames(Fluid_Waermetauscher_Output),1)/4)
        l_Fluid_Waermetauscher1_T = size(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Data);
        Output.(['Fluid_heat_exchanger_1__',num2str(i)]).Time = Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Time;
        Output.(['Fluid_heat_exchanger_1__',num2str(i)]).T_begin = Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Data(:,1);
        Output.(['Fluid_heat_exchanger_1__',num2str(i)]).T_middle = Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Data(:,round(l_Fluid_Waermetauscher1_T(2)/2));
        Output.(['Fluid_heat_exchanger_1__',num2str(i)]).T_end = Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_1_',num2str(i),'___K_']).Data(:,end);
        
        l_Fluid_Waermetauscher2_T = size(Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Data);
        Output.(['Fluid_heat_exchanger_2__',num2str(i)]).T_begin = Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Data(:,1);
        Output.(['Fluid_heat_exchanger_2__',num2str(i)]).T_middle = Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Data(:,round(l_Fluid_Waermetauscher2_T(2)/2));
        Output.(['Fluid_heat_exchanger_2__',num2str(i)]).T_end = Fluid_Waermetauscher_Output.(['T_FinitesVolumen_Waermetauscher_2_',num2str(i),'___K_']).Data(:,end);
    end
end

% Ladegeraet
if exist('Ladegeraet_Output')==1
    Output.charger.Time = Ladegeraet_Output.P_Ladegeraet_Bat__W_.Time;
    Output.charger.P_bat_charge = Ladegeraet_Output.P_Ladegeraet_Bat__W_.Data;
    Output.charger.T = Ladegeraet_Output.T_Ladegeraet__K_.Data;
end

if exist('Fluid_Ladegeraet_Output')==1
    l_Fluid_Ladegeraet_T = size(Fluid_Ladegeraet_Output.T_FinitesVolumen_Ladegeraet_1___K_.Data);
    Output.Fluid_charger.Time = Fluid_Ladegeraet_Output.T_FinitesVolumen_Ladegeraet_1___K_.Time;
    Output.Fluid_charger.T_begin = Fluid_Ladegeraet_Output.T_FinitesVolumen_Ladegeraet_1___K_.Data(:,1);
    Output.Fluid_charger.T_middle = Fluid_Ladegeraet_Output.T_FinitesVolumen_Ladegeraet_1___K_.Data(:,round(l_Fluid_Ladegeraet_T(2)/2));
    Output.Fluid_charger.T_end = Fluid_Ladegeraet_Output.T_FinitesVolumen_Ladegeraet_1___K_.Data(:,end);
end

% Getriebe
if exist('Getriebe_Output')==1
    Output.transmission.Time = Getriebe_Output.n_EMaschine__min__1_.Time;
    Output.transmission.n_emachine = Getriebe_Output.n_EMaschine__min__1_.Data(:);
    Output.transmission.M_emachine = Getriebe_Output.M_EMaschine__Nm_.Data(:);
    Output.transmission.P_emachine = Getriebe_Output.P_EMaschine__W_.Data(:);
end

% Kuehlkreislauf
if exist('Kuehlkreislauf_Output')==1
    for i=1:size(fieldnames(Kuehlkreislauf_Output.PV_Kuehlkreislauf__m_3_s__1_),1)
        Output.(['Coolant_cycle_',num2str(i)]).Time = Kuehlkreislauf_Output.PV_Kuehlkreislauf__m_3_s__1_.(['PV_Kuehlkreislauf_',num2str(i),'___m_3_s__1_']).Time;
        Output.(['Coolant_cycle_',num2str(i)]).V_dot = Kuehlkreislauf_Output.PV_Kuehlkreislauf__m_3_s__1_.(['PV_Kuehlkreislauf_',num2str(i),'___m_3_s__1_']).Data;
    end
end

% Peltier
if exist('Peltier_Output')==1
    Output.Peltier.Time = Peltier_Output.P_Peltier_Bat__W_.Time;
    Output.Peltier.P_bat = Peltier_Output.P_Peltier_Bat__W_.Data;
end

% PCM
if exist('PCM_Output')==1
    for i=1:(ceil(size(fieldnames(PCM_Output),1)/2))
        Output.(['PCM_',num2str(i)]).Time = PCM_Output.(['T_PCM_',num2str(i),'___K_']).Time;
        Output.(['PCM_',num2str(i)]).T = PCM_Output.(['T_PCM_',num2str(i),'___K_']).Data;
    end
end

if exist('Fluid_PCM_Output')==1
    for i=1:(size(fieldnames(Fluid_PCM_Output),1)/2)
        l_Fluid_PCM_T = size(Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Data);
        Output.(['Fluid_PCM_',num2str(i)]).Time = Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Time;
        Output.(['Fluid_PCM_',num2str(i)]).T_begin = Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Data(:,1);
        Output.(['Fluid_PCM_',num2str(i)]).T_middle = Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Data(:,round(l_Fluid_PCM_T(2)/2));
        Output.(['Fluid_PCM_',num2str(i)]).T_end = Fluid_PCM_Output.(['T_FinitesVolumen_PCM_',num2str(i),'___K_']).Data(:,end);
    end
end
% Rad
if exist('Rad_Output')==1
    Output.wheel.Time = Rad_Output.n_Rad__min__1_.Time;
    Output.wheel.n = Rad_Output.n_Rad__min__1_.Data(:);
    Output.wheel.M = Rad_Output.M_Rad__Nm_.Data(:);
    Output.wheel.P = Rad_Output.P_Rad__W_.Data(:);
end

% Geschwindigkeit
if exist('v_Fahrzeug')==1
    Output.vehicle.Time = v_Fahrzeug.Time;
    Output.vehicle.v = v_Fahrzeug.Data;
end

%save(fullfile(pwd,'\Output','Output_test.mat'),'-struct','Output');

OutputData.Output = Output;
OutputData.vehicle = vehicle;
%OutputData.Zyklus = Zyklus;

end