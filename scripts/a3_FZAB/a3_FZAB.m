%% a3_FZAB - EEG Preprocessing Script
% Steps: Filter → ZAPLINE → ASR → Bad Channels
%
% This script performs EEG preprocessing in four main steps:
%
% F - Filter:
%     Applies bandpass filtering to remove slow drifts (e.g., below 0.5 Hz)
%     and high-frequency noise (e.g., above 30 Hz). Optional notch filtering
%     can remove line noise (e.g., 60 Hz).
%
% Z - ZAPLINE:
%     Uses the zapline-plus algorithm to adaptively remove line noise
%     and its harmonics without introducing distortion.
%
% A - ASR (Artifact Subspace Reconstruction):
%     Automatically detects and removes transient, high-amplitude artifacts
%     using statistical thresholding (via the clean_artifacts() function).
%
% B - Bad Channels:
%     Identifies and marks persistently bad EEG channels for later interpolation,
%     based on criteria such as flatline duration or correlation with neighbors.

%% DEFINING PATHS AND GROUPS
clc % clear CW
clear % clear Workspace

% Get fullpath
fullpath = mfilename('fullpath');

% Path manipulation
fpSplit = strsplit(fullpath,'\'); % Split fullpath
fpSplit = fpSplit(1:end-3); % Erase last n folders (we use 2 due to dummy)
basePath = strjoin(fpSplit,'\'); % Base Path

% Add path of eeglab
addpath(genpath(fullfile(basePath,'toolboxes')))

% Define groups
Groups = {'ControlGroup'};

% Define heart channel
heartChannel = 130;

%% LOAD AND PREPROCESS
% Start group iteration
for gi = 1:length(Groups)

    % Define load and save path
    loadPath = fullfile(basePath,'analysis', Groups{gi},'a2_reject');
    savePath = fullfile(basePath,'analysis', Groups{gi},'a3_FZAB');

    % Define subjects directory
    cd(loadPath)
    sDir = dir('*.set');
    sDir = sDir(~ismember({sDir.name},{'.','..'})); % Stay only with .mff within dir

    % Start iteration through subjects
    for si = 1:size(sDir,1)

        %% LOAD SUBJECT
        % Load the subject and redraw the GUI
        EEG = pop_loadset('filename',sDir(si).name,'filepath',loadPath);
        EEG = eeg_checkset( EEG );
        eeglab redraw % Redraw the GUI
        EEGHeart = EEG.data(heartChannel,:); EEG.data(heartChannel,:) = zeros(length(EEG.data(heartChannel,:)),1)';

        % Filtering
        EEG = pop_eegfiltnew( EEG , 30, 0.5); % Low 0.5 and High 30 for HEP (we can later play with this but this numbers are literature guided see Salamone et al. 2021)
        EEG = eeg_checkset( EEG ); % Reload to save within variables

        % Run zapline plus
        EEG = clean_data_with_zapline_plus_eeglab_wrapper(EEG,struct('noisefreqs','line','maxfreq',30,'winSizeCompleteSpectrum',floor(length(EEG.data)/EEG.srate/8)));
        EEG = eeg_checkset( EEG );
        eeglab redraw;
        close all
        
        %% Bad channels
        EEGClone = EEG;
        [EEG,~,~,removed_channels] = clean_artifacts(EEG,'WindowCriterion','off'); % Modified to avoid deleting start and end task events
        EEG = eeg_checkset( EEG ); % Reload to save within variables
        EEG.chanlocs = EEGClone.chanlocs(1:heartChannel); 
        EEG.nbchan = heartChannel;

        % Add heart
        EEG.data(heartChannel,:) = EEGHeart;
        EEG = clean_windows(EEG,0.25,[-inf 7]); % Mod to avoid deleting Start and end marks from data.
        EEGHeart = EEG.data(heartChannel,:); EEG.data(heartChannel,:) = zeros(length(EEG.data(heartChannel,:)),1)'; % Make the new segmented heart be our heart
        
        % Add removed channels on their original position to interpolate
        newData = repelem(zeros(1,size(EEG.data, 2)),heartChannel,1);
        counter = 0;
        for rci = 1:length(removed_channels)
            if ~removed_channels(rci)
                newData(rci,:) = EEG.data(rci-counter,:);
            else
                counter = counter + 1;
            end
        end
        EEG.data = newData; clear newData;
        EEG.data(heartChannel,:) = EEGHeart; % Add heart back again

        % Interpolate channels
        EEG = pop_interp(EEG, find([removed_channels;0;0]),'spherical');
        EEG = eeg_checkset( EEG ); % Reload to save within variables
        
        % Re-referencing
        EEG = pop_reref( EEG , [],'exclude', heartChannel); % Rereference to average channels (modify if using different references)
        EEG = eeg_checkset( EEG ); % Reload to save within variables
        eeglab redraw % Redraw the GUI

        %% SAVE SET AND GO TO THE NEXT ITERATION
        pop_saveset(EEG, [sDir(si).name(1:4),'_a3.set'], savePath) % Save it in savePath
        eeglab redraw; % Redraw the GUI
    end
end