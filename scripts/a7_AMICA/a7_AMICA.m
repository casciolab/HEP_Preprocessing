%% a7_AMICA - Adaptive Mixture Independent Component Analysis
%
% Quick AMICA automatization to remove eye movement components from our signal.
% 
% AMICA is an ML algorythm that fits the best model to specific components
% by using 2nd Order Newton
% (https://en.wikipedia.org/wiki/Newton%27s_method)
%
%
% AMICA Tutorial at: 
% https://sccn.ucsd.edu/githubwiki/files/eeg_nonstationarity_and_amica.pdf
%
% Paper at:
%   Palmer, Jason A., Ken Kreutz-Delgado, and Scott Makeig. ...
%   "AMICA: An adaptive mixture of independent component analyzers with shared components." ...
%   Swartz Center for Computatonal Neursoscience, ...
%   University of California San Diego, Tech. Rep (2012): 1-15.

%% DEFINING PATHS AND GROUPS
clc % clear CW
clear % clear Workspace

% Get fullpath
fullpath = mfilename('fullpath');

% Path manipulation
fpSplit = strsplit(fullpath,'\'); % Split fullpath
fpSplit = fpSplit(1:end-3); % Erase last n folders (we use 2 due to dummy)
basePath = strjoin(fpSplit,'\'); % Base Path

% Add path and open eeglab
addpath(genpath(fullfile(basePath,'toolboxes','eeglab','eeglab2020_0')))

% Define groups
Groups = {'ControlGroup'};

%% LOAD AND PREPROCESS
% Start group iteration
for gi = 1:length(Groups)

    % Define load and save path
    loadPath = fullfile(basePath,'analysis', Groups{gi},'a6_eventRename');
    savePath = fullfile(basePath,'analysis', Groups{gi},'a7_AMICA');
    
    % Define subjects directory
    cd(loadPath);
    sDir = dir('*.set'); 
    sDir = sDir(~ismember({sDir.name},{'.','..'}));% Stay only with .set within dir
    

    % Start iteration through subjects
    % 16 for gi = 1
    for si = 1:length(sDir)
         
        % Subject Name and load bad channels
        sName = sDir(si).name;

        %% LOAD SUBJECT
        % Load the subject and redraw the GUI
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; %#ok
        EEG = pop_loadset('filename',sName,'filepath',loadPath);
        [~, EEG, ~] = eeg_store( ALLEEG, EEG, 0 );
        eeglab redraw;
        
        % Create Dir
        mkdir([savePath, filesep, sName(1:4)])

        % AMICA params
        max_threads = 8;
        max_iter = 2000;
        num_models = 1;
        numprocs = 1;

        % Run AMICA
        dataRank = sum(eig(cov(double(EEG.data'))) > 1E-6); % 1E-6 follows pop_runica() line 531, changed from 1E-7.
        runamica15(EEG.data(1:128,:), 'num_models',num_models, 'outdir',[savePath, filesep, sName(1:4)], ...
        'numprocs', numprocs, 'max_threads', max_threads, 'max_iter',max_iter,'pcakeep', dataRank);
        EEG = eeg_checkset( EEG );
        eeglab redraw;
    end
end
