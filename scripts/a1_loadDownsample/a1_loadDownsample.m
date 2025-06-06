%% a1_loadDownsample - Loading and downsampling.
%
% This code loads and downsamples the data. 
%
% All scripts within this HEP preprocessing repository are intended to be...
% used for HEP analysis but can be modified to best suit your needs.
%
% │﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌ │
% │    ﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎﹎    │
% │  ║    First step of Evoked Potentials analysis   ║    │
% │    ﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊    │
% │                     _ ---~~(~~-_.                     │
% │                   _{         )    )                   │ 
% │                 ,    ) -~~- ( ,- ' )_                 │ 
% │               (    `-,_..`., )--  '_,)                │
% │              (   ` _)  (  -~( -_ `,  }                │
% │              (_-    _ ~_-~~~~`,  ,'  )                │
% │                 `~ -^(     __;-,((()))                │
% │                       ~~~~ {_ -_(())                  │  
% │                               `\  }                   │
% │                                 { }                   │
% │                                                       │
% │   ASCII ART: From: Steven James Walker                │
% │              <swalker1@emerald.tufts.edu>             │
% │                                                       │
%  ﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌

% │﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌│
% │ ● Inputs:  ► Raw EEG data                             │
% │                                                       │
% │ ● Outputs: ► .set file with downsampled data          │
% │                                                       │
% │                                                       │
% │ ● Reqs:    ► Eeglab                                   │
% │            ► Guide folder organization                │
% │                                                       │
%  ﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌ 

% │﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌│                                               
% │ ● Contact: ► matias.fraile@ku.edu                     │
% │            ► carissa.cascio@ku.edu                    │
% │                                                       │
%  ﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌﹌ 

%% LICENSE
% The license is intended to apply to all codes within this repository.
%
% The MIT License
% 
% Copyright (c) 2011 Dominic Tarr
% 
% Permission is hereby granted, free of charge, 
% to any person obtaining a copy of this software and 
% associated documentation files (the "Software"), to 
% deal in the Software without restriction, including 
% without limitation the rights to use, copy, modify, 
% merge, publish, distribute, sublicense, and/or sell 
% copies of the Software, and to permit persons to whom 
% the Software is furnished to do so, 
% subject to the following conditions:
% 
% The above copyright notice and this permission notice 
% shall be included in all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
% ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

%% DEFINING PATHS AND GROUPS
clc % clear CW
clear % clear Workspace

% Get fullpath
fullpath = mfilename('fullpath');

% Path manipulation
fpSplit = strsplit(fullpath,'\'); % Split fullpath
fpSplit = fpSplit(1:end-3); % Erase last n folders
basePath = fullfile(fpSplit{:}); % Base Path

% Add path and open eeglab
addpath(genpath(fullfile(basePath,'toolboxes','eeglab','eeglab2020_0'))) % Paths
eeglab % Open eeglab

% Define groups and event bases
Groups = {'ControlGroup'}; % Put your Group names here

% Define sampling rate
srate = 512;

%% LOAD AND PREPROCESS
% Start group iteration
for gi = 1:length(Groups)

    % Define load and save paths
    loadPath = fullfile(basePath, 'analysis', Groups{gi}, 'a0_raw');
    savePath = fullfile(basePath, 'analysis', Groups{gi}, 'a1_loadDownsample');

    if ~exist(savePath, 'dir')
        mkdir(savePath); % Create save directory if it doesn't exist
    end

    % Get list of subject files (.mff)
    sDir = dir(fullfile(loadPath, '*.mff'));
    sDir = sDir(~ismember({sDir.name}, {'.', '..'})); % Just in case (redundant here, but harmless)

    % Iterate through subjects
    for si = 1:numel(sDir)

        %% LOAD SUBJECT (MFF FILES USED HERE - MODIFY IF NEEDED)
        EEG = pop_mffimport({fullfile(loadPath, sDir(si).name)}, {'code'}, 0, 0); % Full path is safer
        EEG = eeg_checkset(EEG);

        %% PREPROCESSING STEP: RESAMPLING
        EEG = pop_resample(EEG, srate); % Downsample to 512 Hz
        EEG = eeg_checkset(EEG);

        %% SAVE SET WITH NEW NAME
        % Construct new filename by removing last two parts of original name
        nameParts = strsplit(sDir(si).name, '_'); % CHECK YOUR DELIMITER AND LENGTH
        if numel(nameParts) < 3
            error('Unexpected filename structure for: %s', sDir(si).name);
        end
        newName = [strjoin(nameParts(1:end-2), '_'), '_a1.set'];

        pop_saveset(EEG, 'filename', newName, 'filepath', savePath);
        eeglab redraw;

    end
end
