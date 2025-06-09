%% a6_eventRename - Automatic MDTT task event name changer.
%
% This code is specific to the MDTT task used for the HEP analysis we are
% doing. It loads the step 3 EEG data, looks for the starting and ending
% events of each block, and renames them to make them unique for each
% block, thus allowing for easier interblock analysis. 
%
% R-Peak events are also block-specific-renamed to be able to look for HEP
% within each block.
%
% The block sequence for the MDTT Task is as follows:
%     
%       - Motor block x2, intero block x2, feedback x1, intero block x2
%
% The new event names are as follows:
%
%       - MOT / INT / FED + _S_blockNumber for event start (i.e. MOT_S_1)
%
%       - MOT / INT / FED + _E_blockNumber for event end (i.e. MOT_E_1)
%
%       - MOT / INT / FED + _T_blockNumber for behavioral action (i.e. MOT_B_1)
%
%       - MOT / INT / FED + _HBT_blockNumber for R-peak (i.e. MOT_HBT_1)



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
addpath(genpath(fullfile(basePath,'toolboxes'))) % Paths

% Define groups
Groups = {'ControlGroup'};

%% LOAD AND PREPROCESS
% Start group iteration
for gi = 1:length(Groups)

    % Define load and save path
    loadPath =  fullfile(basePath,'analysis', Groups{gi},'a5_boundaryCorrection');
    savePath =  fullfile(basePath,'analysis', Groups{gi},'a6_eventRename');
    
    % Define subjects directory
    cd(loadPath);
    sDir = dir('*.set');
    sDir = sDir(~ismember({sDir.name},{'.','..'}));% Stay only with .set within dir
    
    % Start iteration through subjects
    for si = 11:length(sDir)
         
        % Subject Name
        sName = sDir(si).name;

        %% LOAD SUBJECT
        % Load the subject and redraw the GUI
        eeglab;
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; %#ok
        EEG = pop_loadset('filename',sName,'filepath',loadPath);
        [~, EEG, ~] = eeg_store( ALLEEG, EEG, 0 );
        eeglab redraw;
        
        %% DEFINE NEW EVENT NAMES
        % Remove extra events from EEG
        eventRemCell = {'DIN3', 'IEND', 'IBEG', 'boundary'};
        for ee = 1:length(eventRemCell)
            extraEvents = find(contains({EEG.event.type},eventRemCell{ee})); % Get index of extra event
            if ~isempty(extraEvents)
                EEG = pop_editeventvals(EEG,'delete',extraEvents); % remove it
                EEG = eeg_checkset( EEG ); % reload EEG
            end
            clear extraEvents
        end

        % Get unique events
        events = {EEG.event.type}; [c,ia,ic] = unique(events);

        % Find empty cells and remove
        emptyCells = cellfun(@isempty,c); c(emptyCells) = []; clear emptyCells

        % Find start events
        c = c(contains(c,'S'));
        eventTxt = {0,0}; % Preallocate for speed zoom-zoom

        % Get HBT Indexes
        eventHBTIndex = find(contains({EEG.event.type},'HBT'));
        INSDone = 0;

        % Iteration through unique events
        for ei = 1:length(c)
            
            % Skip having to do this twice
            if INSDone; INSDone = 0; continue; end

            % Make sure they are start events
            eventx = c{ei};
            
           
            % Find start, end, tapping, and r-peaks
            if ~strcmp(eventx(1:3),'INS')
                eventSIndex = find(contains({EEG.event.type},eventx));
                eventEIndex = find(contains({EEG.event.type},regexprep(eventx,'S','E')));
                eventBIndex = find(contains({EEG.event.type},regexprep(eventx,'S','B')));
            else
                eventSIndex = find(contains({EEG.event.type},eventx(1:3)));
                eventEIndex = find(contains({EEG.event.type},regexprep(eventx(1:3),'S','E')));
                eventBIndex = find(contains({EEG.event.type},regexprep(eventx(1:3),'S','B')));
                INSDone = 1;
            end
            
            % Iteration through Block start events
            for esi = 1:length(eventSIndex)

                % Create txt with block start and end events to import adding type and latency
                % (can add more if wanted)
                if ~strcmp(eventx(1:3),'INS')
                    [filenameS] = deal([eventx(1:3),'_S_',num2str(esi)]);
                    [filenameE] = deal([eventx(1:3),'_E_',num2str(esi)]);
                else
                    % Here we are solving the intero event name mismatch by
                    % calling it INT instead of INS
                    [filenameS] = deal([eventx(1:2),'T_S_',num2str(esi)]);
                    [filenameE] = deal([eventx(1:2),'T_E_',num2str(esi)]);
                end
                
                % Transpose only if needed
                if size(filenameS,1) > 1; filenameS = filenameS'; filenameE = filenameE'; end

                % Get events inside Start and End of block
                blockBLatencies = eventBIndex(cell2mat({EEG.event(eventBIndex).latency}) > EEG.event(eventSIndex(esi)).latency & cell2mat({EEG.event(eventBIndex).latency}) < EEG.event(eventEIndex(esi)).latency);
                blockHBTLatencies = eventHBTIndex(cell2mat({EEG.event(eventHBTIndex).latency}) > EEG.event(eventSIndex(esi)).latency & cell2mat({EEG.event(eventHBTIndex).latency}) < EEG.event(eventEIndex(esi)).latency);

                % Create Behavioral and HBT events
                if ~strcmp(eventx(1:3),'INS')
                    [filenameB{1:length(blockBLatencies)}] = deal([eventx(1:3),'_B_',num2str(esi)]);
                    [filenameHBT{1:length(blockHBTLatencies)}] = deal([eventx(1:3),'_HBT_',num2str(esi)]);
                else
                    % Here we are solving the intero event name mismatch by
                    % calling it INT instead of INS
                    [filenameB{1:length(blockBLatencies)}] = deal([eventx(1:2),'T_B_',num2str(esi)]);
                    [filenameHBT{1:length(blockHBTLatencies)}] = deal([eventx(1:2),'T_HBT_',num2str(esi)]);
                end

                % Append to txt
                eventTxt = vertcat(eventTxt,horzcat(filenameS, num2cell(cell2mat({EEG.event(eventSIndex(esi)).latency})/EEG.srate)')); %#ok
                eventTxt = vertcat(eventTxt,horzcat(filenameE, num2cell(cell2mat({EEG.event(eventEIndex(esi)).latency})/EEG.srate)')); %#ok
                eventTxt = vertcat(eventTxt,horzcat(filenameB', num2cell(cell2mat({EEG.event(blockBLatencies).latency})/EEG.srate)')); %#ok
                eventTxt = vertcat(eventTxt,horzcat(filenameHBT', num2cell(cell2mat({EEG.event(blockHBTLatencies).latency})/EEG.srate)')); %#ok
                
                clear filenameS filenameE filenameB filenameHBT
            end
            
        end
        
        % Sort them by latency and delete dummy first row
        eventTxt = sortrows(eventTxt,2);
        eventTxt(1,:) = [];
        
        %% PRINT TO TXT AND IMPORT TO EEG
        % Length of latencies (amount of latencies) and define txt
        nr_lines = length(eventTxt);
        file_txt = fullfile(savePath, 'newEventNames.txt');

        % Define file identifier to write in
        fid = fopen(file_txt, 'w');

        % iter through lines copying latencies and codes
        for j = 1:nr_lines
            fprintf(fid, '%s\t%d\n', eventTxt{j,1}, eventTxt{j,2});
        end

        % Close file identifier
        fclose(fid);
        
        % Load subject (again for safety)
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; %#ok
        EEG = pop_loadset('filename',sName,'filepath',loadPath);
        eeglab redraw;
        
        % Import events on a new ALLEEG
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = pop_importevent( EEG, 'event',file_txt,'fields',{'type' 'latency'},'skipline',0,'timeunit',1,'append', 'no');
        EEG.data = EEG.data(1:128,:); EEG.chanlocs = EEG.chanlocs(1:128); EEG.urchanlocs = EEG.urchanlocs(1:128); % Remove externals
        EEG = eeg_checkset( EEG );
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); %#ok
        EEG = eeg_checkset( EEG );
        
        %% SAVE SET AND GO TO THE NEXT ITERATION
        newName = strsplit(sDir(si).name, '_'); newName = [strjoin(newName(1),'_'), '_a6.set']; % Rename it adding 
        pop_saveset(EEG, newName, savePath) % Save it in savePath
        eeglab redraw; % Redraw the GUI
    end
end