function [] = parsave(filename, Output, target_folder)
% Function to save data structs within a parfor-loop

save(fullfile(pwd,target_folder,filename),'-struct','Output');
end

