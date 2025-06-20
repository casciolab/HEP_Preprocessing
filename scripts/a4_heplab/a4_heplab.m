%% a4_heplab - R-peak event marker using heplab.
%
% We will be marking the R-Peaks as HBT events to use as our starting point
% from which we can find the HEP within our frontal channels.
% 
% A modified version of Heplab will be used during the event marking.
% Heplab uses different peak finding algorythms, but we will be specificly
% using the Pan-Tompkings one from all of them.
%
% After marking the HBT events, we will have to do a visual inspection of
% the events rejecting, removing, and adding those events that were
% missplaced by heplab.
%
% 
% Third step for preprocessing Evoked Potentials
% 
%   Inputs: reject.m .set outputs               
%   Outputs:.set file with R-Peaks from EKG marked

% Clear all
clc % clear CW
clear % clear Workspace

%% Creating our paths
% Get fullpath
fullpath = mfilename('fullpath');

% Fullpath manipulation
fpSplit = strsplit(fullpath,'\'); % Split fullpath
fpSplit = fpSplit(1:end-3); % Erase last n folders (we use 2 due to dummy)

% Define paths
basePath = strjoin(fpSplit,'\'); % Base Path

% Add path and open eeglab
addpath(genpath(fullfile(basePath,'toolboxes','eeglab','eeglab2020_0'))) % Paths
addpath(genpath(fullfile(basePath,'toolboxes','HEPLAB')))

% Define struct for Heplab (preallocate for speed)
Heplab_struct = struct;

% Define groups
Groups = {'ControlGroup'};

% Define heart channel
heartChannel = 130;

for gi = 1:length(Groups)

    % Define load and save path
    loadPath = fullfile(basePath,'analysis', Groups{gi},'a3_ZBRF');
    savePath = fullfile(basePath,'analysis', Groups{gi},'a4_heplab');
    heplabPath = fullfile(basePath,'analysis', Groups{gi},'a4.5_heplabStruct');
    
   % Define subjects directory
    cd(loadPath);
    sDir = dir('*.set');
    sDir = sDir(~ismember({sDir.name},{'.','..'})); % Stay only with .mff within dir

    % Start iteration through subjects
    for si = 1:length(sDir)
        %% HEPLAB modification, ECG and Srate structures needed
        % Heplab toolbox was manualy modified for it to run automatically
        % without need of using the cursor. Peak finder algorithm used:
        % Pan-Tompink

        % Subject Name
        sName = sDir(si).name;

        % Load subj in eeglab (if your Heart channel is separated from eeg avoid this)
        eeglab;
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; %#ok
        EEG = pop_loadset('filename',sName,'filepath',loadPath);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 ); %#ok
        eeglab redraw;
        
        %% HEPLAB MANIPULATION STARTS
        % Set variables needed for heplab to run: ecg and srate fields
        % structure, and file name and path to load that structure after
        % saving it to structure savepath
        % EEG.data(130,:) = EEG.data(130,:).*-1;
        ecg = EEG.data(heartChannel,:);
        srate = EEG.srate;
        Heplab_struct.ecg = ecg;
        Heplab_struct.srate = srate;
        file = ['Heplab_struct_',sName(1:end-4)]; % name of structure we just saved
        path = heplabPath; % path of where to load the structure

        % Save structure in structure folder
        cd(heplabPath)
        save(file, 'Heplab_struct') % the 1:end-4 deletes the file termination, check if its ok on your files
        
        % Run heplab (already modified for automatization)
        heplab; 

        % Use Pan-Tomkin on ECG (documantation argues in favor of this peak
        % finding algorythm compared to others). Can play with srate if HR
        % of patient is weird.
        [~,HEP.qrs] = heplab_pan_tompkin(HEP.ecg,500); % inputs: ECG, sampling rate (can do a HRV weighted SR for r-peak consistecy)
        if size(HEP.qrs,1) < size(HEP.qrs,2)
            HEP.qrs = HEP.qrs';
        end

        % Set handle and plot the algorythm working
        HEP.ecg_handle = heplab_ecgplot(HEP.ecg,HEP.srate,HEP.qrs,HEP.sec_ini,HEP.ecg_handle,HEP.winsec);

        % Save the HBT marked ECG
        HEP.savefilename = (['Heplab_HEP_Matrix_',sName(1:end-4)]);
        save([HEP.savefilename,'.mat'],'HEP');

        % Save heplab events
        if ~isempty(HEP.qrs)
            heplab_save_events;
        else
            errordlg('No cardiac events available!');
        end
        close HEPLAB

        %% PRINT TO TXT AND IMPORT TO EEG
        % Set peaks as HEP latencies in secs
        picos = HEP.qrs/EEG.srate;

        % Store event name and latency
        for i= 1:length(picos)
            HBTP{i,1} = 'HBT';    %#ok
            HBTP{i,2} = picos(i); %#ok
        end
        
        % Length of latencies (amount of latencies) and define txt
        transposed = HBTP;
        typelatency = transposed(:,1:2);
        nr_lines = length(typelatency);

        % Print to txt
        archivo_txt = fullfile(savePath, 'markers_reposo.txt');
        fid = fopen(archivo_txt, 'w'); % File identifier to open txt

        % iter through lines copying latencies and codes
        for ri = 1:nr_lines
            fprintf(fid, '%s\t%d\n', typelatency{ri,1}, typelatency{ri,2});
        end

        % Close file identifier
        fclose(fid);

        % Import the events
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; %#ok
        EEG = pop_loadset('filename',sName,'filepath',loadPath);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = pop_importevent( EEG, 'event',archivo_txt,'fields',{'type' 'latency'},'skipline',1,'timeunit',1);
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); %#ok
        EEG = eeg_checkset( EEG );

        %% Save as new set
        cd(savePath)
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'savenew',fullfile(savePath, [sName(1:end-7),'_a4']),'gui','off'); %#ok
        eeglab redraw;

        % Clear vars
        clear HEP ecg file path picos amp HBTP archivo_txt EEG
    end
end