%% a2_reject - Automatic data scroll opener for manual rejection.
%
% As we are doing HEP analysis with the EKG added as an external channel,
% we want to reject every part of the data scroll where the EKG signal has
% noise. This is due to the following script marking the R-Peaks requiring
% the signal to be continuous. If values for the signal are too extreme,
% the peak-finding algorythm will stop marking the events, thus, it will
% not work.
%
% Rejection of extreme noise is also recommended for every part of the data
% scroll in case you want to use the data outside of your task blocks as a
% baseline. 
% 
% Noise within the channels you will be searching for your ERP's
% is also recommended to reject.


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
addpath([basePath,'\toolboxes\eeglab\eeglab2020_0']) % Paths
eeglab % Open eeglab

% Define groups
Groups = {'ControlGroup'};

%% LOAD AND PREPROCESS
% Start group iteration
for gi = 1:length(Groups)

    % Define load and save path
    loadPath = fullfile(basePath,'analysis', Groups{gi},'a1_loadDownsample');
    savePath = fullfile(basePath,'analysis', Groups{gi},'a2_reject');

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
        
        %% OPEN REJECT PANEL
        pop_eegplot( EEG, 1, 1, 1, 1, 'winlength', 20); % EEGLAB MODIFYED TO USE ZXCV INSTEAD FO 'leftarrow', 'rightarrow' @eegplot_readkey

        % ASCII ART BECAUSE WHY NOT
        fprintf( ['\n\n\n|-------------------------------------------------|\n', ...
            '|                                                 |\n', ...
            '|    USE ~ Z-X-C-V ~ TO MOVE THROUGH DATA SCROLL  |\n', ...
            '|       USE MOUSE TO SELECT AREAS TO REJECT       |\n', ...
            '|       PRESS ~REJECT~ TO REJECT YOUR DATA        |\n', ...
            '|                                                 |\n', ...
            '|   PRESS ~ ENTER ~ AFTER YOU REJECT YOUR DATA    |\n', ...
            '|                                                 |\n', ...
            '|-------------------------------------------------|\n'], sDir(si).name)
        pause;

        %% SAVE SET AND GO TO THE NEXT ITERATION
        newName = strsplit(sDir(si).name, '_'); newName = [strjoin(newName(1:end-2),'_'), '_a2.set']; % Rename it adding 
        pop_saveset(EEG, newName, savePath) % Save it in savePath
        EEG = eeg_checkset( EEG );
    end
end