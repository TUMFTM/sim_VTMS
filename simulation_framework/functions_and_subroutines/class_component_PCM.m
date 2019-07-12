%% Info

% Create 'PCM' class


%% classdef

classdef class_component_PCM
    properties
        unterer_Grenzwert_Phasenwechsel=0;
        oberer_Grenzwert_Phasenwechsel=0;
        Phasenumwandlung_vollstaendig=0;
        dT_Faktor_Phasenwechsel=0;
        Aktivierbar=0;
        b_PCM=0;
        Zustand_init=0;
    end
end