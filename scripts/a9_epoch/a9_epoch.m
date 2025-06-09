%% a9_epoch - Epoch and clean the epoched data
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
addpath(genpath(fullfile(basePath,'toolboxes','eeglab','eeglab2020_0')))

% Define groups
Groups = {'ControlGroup'};

% Define Block HBT events to epoch separately
BlocksHBT = {'MOT_HBT_1','MOT_HBT_2','INT_HBT_1','INT_HBT_2','FED_HBT_1','INT_HBT_3','INT_HBT_4'};

% Define Block HBT events to epoch together
%BlocksHBT = {{'MOT_HBT_1','MOT_HBT_2'},{'INT_HBT_1','INT_HBT_2'},{'FED_HBT_1'},{'INT_HBT_3','INT_HBT_4'}};

%% LOAD AND PREPROCESS
% Start group iteration
for gi = 1:length(Groups)

    % Define load and save path
    loadPath = fullfile(basePath,'analysis', Groups{gi},'a8_remComp');
    savePath = fullfile(basePath,'analysis', Groups{gi},'a9_epoch');

    % Define subjects directory
    cd(loadPath);
    sDir = dir('*.set');
    sDir = sDir(~ismember({sDir.name},{'.','..'}));% Stay only with .set within dir

    % Start iteration through subjects
    for si = 1:length(sDir)

        % Subject Name and load bad channels
        sName = sDir(si).name;
        
        %% LOAD SUBJECT
        % Load the subject and redraw the GUI
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; %#ok
        EEG = pop_loadset('filename',sName,'filepath',loadPath);
        [~, EEG, ~] = eeg_store( ALLEEG, EEG, 0 );
        eeglab redraw;

        % Clone it to recover it after each epoch for further epochin
        % other blocks
        EEGClone = EEG;

        for bi = 1:length(BlocksHBT)
             
            % Specific savepath
            savePathx = [savePath, filesep, strrep(BlocksHBT{bi},'_HBT','')];
            
            % % Merged
            % if bi ~= 4
            %     savePathx = [savePath, filesep, BlocksHBT{bi}{1}(1:3)];
            % else
            %     savePathx = [savePath, filesep, BlocksHBT{bi}{1}(1:3),'_POST'];
            % end

            % Detrend each channel individually and put back in original position
            EEG.data = detrend(EEG.data);

            % Epoch -300-600ms for HEP and baseline removal if
            % wanted in the future
            EEG = pop_epoch(EEG, BlocksHBT(bi), [-0.3,0.6],'newname',[sName(1:4),'_',strrep(BlocksHBT{bi},'_HBT',''),'_b8.set']);

            % % Merged
            % if bi ~= 4
            %     EEG = pop_epoch(EEG, BlocksHBT{bi}, [-0.3,0.6],'newname',[BlocksHBT{bi}{1}(1:3),'_b8.set']);
            % else
            %     EEG = pop_epoch(EEG, BlocksHBT{bi}, [-0.3,0.6],'newname',[BlocksHBT{bi}{1}(1:3),'_POST','_b8.set']);
            % end

            EEG = eeg_checkset( EEG );
            
            % Keep channels with data
            allch = 1:128;
            allch((EEG.data(:,1,1) == 0)) = [];
            
            % %% REJECT EPOCHS WITH ALL REJECTION METHODS BUT SPECTRAL
            % % Reject epochs with linear trend, joint probability, kurtosis
            % EEG = pop_eegthresh(EEG,1,allch,-50,50,-0.3,0.498,0,0); % Threshold based rejection
            % EEG = pop_rejtrend(EEG,1,allch,500,75,0.3,0,0,0); % Constant based rejection
            EEG = pop_jointprob(EEG,1,allch,10,10,0,0,0,[],0); % Joint probability based rejection - Modified to run with external channels
            EEG = pop_rejkurt(EEG,1,allch,5,5,0,0,0,[],0); % Kurtosis based rejection
            % EEG = pop_rejspec( EEG, 1,'elecrange',allch ...
            %     ,'method','fft','threshold',[-50 50;-100 25],'freqlimits',[0 2;20 30]); % Frequency based
            EEG = eeg_rejsuperpose( EEG, 1, 0, 1, 1, 0, 1, 1, 1); % Superpose them all to delete
            EEG = pop_rejepoch( EEG, [EEG.reject.rejglobal] ,0); % Remove events
   
            %Save the subject
            pop_saveset(EEG,[sName(1:4),'_',strrep(BlocksHBT{bi},'_HBT',''),'_a9.set'], savePathx) % Save it in savePath
            
            % % Merged
            % if bi ~= 4
            %     pop_saveset(EEG,[sName(1:4),'_',BlocksHBT{bi}{1}(1:3),'_b8.set'], savePathx) % Save it in savePath
            % else
            %     pop_saveset(EEG,[sName(1:4),'_',BlocksHBT{bi}{1}(1:3),'_POST','_b8.set'], savePathx) % Save it in savePath
            % end

            eeglab redraw; % Redraw the GUI
            EEG = EEGClone;
        end 
    end
end