%% a8_rem_comp - Remove ICA Eye components
%
% After adding the ICA information to our EEG structure, we will use an
% automatic ICA labeling function to select the eye components found by ICA
% and remove them from the data.

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
addpath(genpath(fullfile(basePath,'scripts','a7_remComp')))
addpath(genpath(fullfile(basePath,'toolboxes','eeglab','eeglab2020_0')))


% Define groups
Groups = {'ControlGroup'};

%% LOAD AND PREPROCESS
% Start group iteration
for gi = 1:length(Groups)

    % Define load and save path
    loadPath = fullfile(basePath,'analysis', Groups{gi},'a6_eventRename');
    loadPath2 = fullfile(basePath,'analysis', Groups{gi},'a7_AMICA');
    savePath = fullfile(basePath,'analysis', Groups{gi},'a8_remComp');

    % Define subjects directory
    cd(loadPath2);
    sDir = dir();
    sDir = sDir([sDir(:).isdir]);
    sDir = sDir(~ismember({sDir.name},{'.','..'}));% Stay only with .set within dir


    % Start iteration through subjects
    for si = 1:length(sDir)

        % Subject Name and load bad channels
        sName = sDir(si).name;
        
        %% LOAD SUBJECT
        % Load the subject and redraw the GUI
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; %#ok
        EEG = pop_loadset('filename',[sName,'_b5.set'],'filepath',loadPath);
        [~, EEG, ~] = eeg_store( ALLEEG, EEG, 0 );
        eeglab redraw;

        % load individual ICA model into EEG structure and modify to fit the 130
        % channels      
        EEG.etc.amica  = loadmodout15([loadPath2, filesep, sName]);

        % ONLY IF RUNNING MORE THAN ONE MODEL TO CHECK WHICH ONE TO USE
        % % compute model probability
        % model_prob = 10 .^ modout.v; % modout.v (#models x #samples)
        % figure, imagesc(model_prob(:,1:10*EEG.srate));
        
        % model_index = 1; % Use first model
        EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :); % Weirdly, I saw size(S,1) be larger than rank. This process does not hurt anyway.
        EEG.icaweights = EEG.etc.amica.W;
        EEG.icasphere  = EEG.etc.amica.S;
        EEG = eeg_checkset(EEG, 'ica');

        % Label ICA components to later remove
        EEG = iclabel(EEG);
        EEG = eeg_checkset(EEG);
        eeglab redraw

        % Only select eye components and remove them
        EEG = pop_icflag(EEG, [0 0;0 0; 0.9 1; 0.9 1; 0 0; 0 0; 0 0]); % see function help message
        rejected_comps = find(EEG.reject.gcompreject > 0);
        EEG = pop_subcomp(EEG, rejected_comps);
        EEG = eeg_checkset(EEG);
        eeglab redraw
        
        % Save the subject
        pop_saveset(EEG, [sName,'_a8.set'], savePath) % Save it in savePath
        eeglab redraw; % Redraw the GUI
        
    end
end