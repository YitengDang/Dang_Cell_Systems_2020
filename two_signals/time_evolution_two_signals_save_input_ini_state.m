% Runs multiple simulations of the system with two signalling molecules and saves
% them.
% Parameters can be input by hand, or loaded from a saved simulation file
% with the correct syntax.
% First counts how many simulations to run, based on the number of
% simulation files already present in the specified folder.
% Then, runs the simulations by looping over some given parameter loop, in
% such a way that each parameter set should have the same number of final
% simulations (+-1).

% ----------- Updates ----------------
% v3: use the randomization algorithm to place the cells on a
% different lattice
% v4: inner loop over K12 to keep the number of simulations with given
% parameters more or less constant
% v5: decrease the number of periodicity checks to one every t_check time
% steps
% v6: shortened loop over simulations by defining a function for each run
% input_ini_state: manually input an initial state (from excel file)
close all
clear all
%% Simulation parameters
% variable to loop over
sigma_D_all = 10.^[-3 -2 -1];

% number of simulations to do 
sim_count = 20;

% other settings
% InitiateI = 0; % generate lattice with input I?
tmax = 10^3; % max. number of time steps 

% folder to save simulations in
parent_folder = 'N:\tnw\BN\HY\Shared\Yiteng\two_signals\moving_cells';

%subfolder = sprintf('K12_%d', K12_all);
subfolder = 'subdomain_oscillations';

save_folder = fullfile(parent_folder, subfolder);
            
% default file name
sim_ID = 'two_signal_mult';

%% (2) Load parameters from saved trajectory
%
% with parameters saved as structure array 
% load data
data_folder = 'H:\My Documents\Multicellular automaton\app\data\time_evolution\moving_cells';
file = 'subdomain_oscillation_sigmaD_0_neg_control';
%[file, data_folder] = uigetfile(fullfile(data_folder, '\*.mat'), 'Load saved simulation');
load(fullfile(data_folder, file));

s = save_consts_struct;
N = s.N;
a0 = s.a0;
K = s.K;
Con = s.Con;
Coff = s.Coff;
M_int = s.M_int;
hill = s.hill;
noise = s.noise;
rcell = s.rcell;
lambda12 = s.lambda12;
lambda = [1 lambda12];
mcsteps = str2double(s.mcsteps);

p0 = s.p_ini;
%tmax =  s.tmax;
gz = sqrt(N);
Rcell = rcell*a0;

cell_type = zeros(N,1);

% Initial I
InitiateI = 0;
I0 = [0 0];
s_fields = fieldnames(s);
for i=1:numel(s_fields)
    if strcmp(s_fields{i},'I_ini_str')
        if ~isempty(s.I_ini_str)
            I0 = s.I_ini;
            InitiateI = 1;
        end
    end
end
%

I_ini_str = '';
if InitiateI
    I_ini_str = sprintf('_I_ini_%.2f_%.2f', I0(1), I0(2));
end
%}
%% Extra input

% Initial state
t = 64;
cells_ini = cells_hist{t+1};

growth_rate = 0;
R_division = 0;
%% First, calculate how many simulations are needed 

sim_to_do = zeros(numel(sigma_D_all));

for idx_loop=1:numel(sigma_D_all)
    sigma_D = sigma_D_all(idx_loop);
    
    % subfolder
    folder = save_folder;
    if exist(folder, 'dir') ~= 7
        mkdir(folder);
    end
    %}
    if exist(folder, 'dir') ~= 7
        warning('Folder does not exist! ');
        break
    end
    
    % Filename pattern
    % !!!
    pattern = strrep(sprintf('%s_sigma_D_%.3f_t_out_%s_period_%s-v%s',...
            sim_ID, sigma_D, '(\d+)', '(\d+|Inf)', '(\d+)'), '.', 'p');
        
    listing = dir(folder);
    num_files = numel(listing)-2;
    names = {};
    filecount = 0;
    for i = 1:num_files
        filename = listing(i+2).name;
        % remove extension and do not include txt files
        [~,name,ext] = fileparts(filename);
        if strcmp(ext, '.mat')
            match = regexp(name, pattern, 'match');
            %disp(match);
            if ~isempty(match)
                filecount = filecount + 1;
                names{end+1} = name;
            end
        end
    end

    fprintf('N=%d, sigma_D = %.2f sim to do: %d \n', N, sigma_D, sim_count-filecount);
    sim_to_do(idx_loop) = sim_count-filecount;
end

%% Then, do the simulations
for idx_loop=1:numel(sigma_D_all)
    sigma_D = sigma_D_all(idx_loop);
    for trial=1:sim_count
        fprintf('sigma_D %.3f, trial %d \n', sigma_D, trial);

        % skip simulation if enough simulations have been done
        if trial > sim_to_do(idx_loop)
            continue;
        end
        % ----------- simulation ------------------------------------
        %{
        [cells_hist, period, t_onset] = time_evolution_save_func_efficient_checks(...
            N, a0, Rcell, lambda, hill, noise, M_int, K, Con, Coff,...
            distances, positions, sim_ID, mcsteps, InitiateI, p0, I0, tmax, save_folder);
        %}
        display_fig = 0;
        [cells_hist, period, t_onset] = time_evolution_save_func_efficient_checks_moving_cells(...
            N, a0, Rcell, lambda, hill, noise, M_int, K, Con, Coff,...
            distances, positions, sigma_D, cells_ini, ...
            growth_rate, R_division, sim_ID, tmax, save_folder, display_fig);
        %--------------------------------------------------------------------------
        %}
    end
end