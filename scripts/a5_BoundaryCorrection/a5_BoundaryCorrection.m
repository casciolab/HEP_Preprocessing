%% a5_BoundaryCorrection
% =========================================================================
% 🫀 Automatic Boundary-Based Rejection for Clean Heartbeat Segments
% =========================================================================
%
% This function/script automatically rejects EEG segments between heartbeats
% that are interrupted by event boundaries, preventing the creation of
% “Frankenstein Monster” heartbeats caused by stitching together mismatched
% signal segments.
%
% 🔍 How it works:
% - The function recursively scans for **event boundaries** occurring
%   between **R-R intervals** (i.e., between two R-peaks).
%
% - If a boundary is found and **no neighboring boundaries  ** are present
%   in adjacent R-R intervals:
%     → The script rejects the segment from the *later* R-peak to the
%       *earlier* R-peak, with a precision of `0.001 * srate` (sample rate).
%
% - If neighboring boundaries *are* found in adjacent R-R intervals:
%     → The rejection window is **expanded and merged** to include all
%       connected boundary-interrupted R-R segments.
%     → This continues recursively until no more neighboring boundaries
%       are found.
%
% 🧹 Post-processing steps:
% - Removes **duplicate rejection windows**
% - Corrects for **overlapping time windows**, ensuring no two windows
%   start/end in conflict (this is rare but included for robustness).
%
% 📌 Notes:
% - Designed for use in heartbeat-locked EEG (e.g., HEP analysis).
% - Assumes accurate R-peak detection and properly marked boundary events.
%
% -------------------------------------------------------------------------

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
addpath(genpath(fullfile(basePath,'toolboxes')))

% Define groups
Groups = {'ControlGroup'};

for gi = 1:length(Groups)

    % Define load and save path
    loadPath = fullfile(basePath,'analysis', Groups{gi},'\a4_heplab');
    savePath = fullfile(basePath,'analysis', Groups{gi},'\a5_boundaryCorrection');

    % Define subjects directory
    cd(loadPath)
    sDir = dir('*.set');
    sDir = sDir(~ismember({sDir.name},{'.','..'})); % Stay only with .mff within dir

    % Start iteration through subjects
    for si = 1:size(sDir,1)
        
        %% LOAD SUBJECT
        % Load the subject and redraw the GUI
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; %#ok
        EEG = pop_loadset('filename',sDir(si).name,'filepath',loadPath);
        EEG = eeg_checkset( EEG );
        eeglab redraw % Redraw the GUI

        %% Create reject windows based on HBT and boundary events. We will make it...
        % 50ms before the last and next HBT of the boundary we are standing in.
        bounds = find(contains({EEG.event.type}, 'boundary'));
        HBTS = find(contains({EEG.event.type}, 'HBT'));
        [eventLabels,~,~] = unique({EEG.event.code});
        emptyCells = cellfun(@isempty,eventLabels); eventLabels(emptyCells) = []; clear emptyCells;
        startEvents = unique(eventLabels(contains(eventLabels,'S')));
        endEvents = unique(eventLabels(contains(cellfun(@(c) c(end-1:end),eventLabels,'uniformOutput',false),'E'))); % MONSTER CODE
        rejWindows = [];
        
        for bi = 1:length(bounds)

            % Make sure there are HBT events before and after
            if ~any(contains({EEG.event(1:bounds(bi)).type}, 'HBT')) || ~any(contains({EEG.event(bounds(bi):end).type}, 'HBT'))
                continue
            end

            % Initialize variables
            backTrack = 0;
            backFound = 0;
            forwardTrack = 0;
            forwardFound = 0;
            windowFound = 0;

            % Go through boundaries checking one heartbeat apart boundaries and
            % create reject windows merging those that are one heartbeat apart from
            % each other to avoid having frankenstain hearts.
            while ~windowFound

                % Check how many HBT we reject backwards
                if ~backFound
                    boundaryBT = bounds((bounds-bounds(bi)) < 0); % Get boundaries before current boundary
                    HBTback = HBTS(HBTS < bounds(bi)); % Get HBTs before current boundary

                    % Break if no future boundary and use the closest HBT to
                    % current boundary
                    if isempty(boundaryBT)
                        lastHBT = HBTback(end-backTrack); % As we are looking backwards, we grab the last index
                        backFound = 1; % Found window start, now break
                        continue
                    end

                    % Check backwards for consecutive boundaries in between
                    % heartbeats to avoid two boundaries rejecting one same
                    % heartbeat and complicating things
                    if backTrack >= length(HBTback) || backTrack >= length(boundaryBT) % We cant backtrack more than amount of events
                        lastHBT = HBTback(end-backTrack);
                        backFound = 1;

                        % If there is a boundary in between heartbeats we keep backtracking
                    elseif boundaryBT(end-backTrack) < HBTback(end-backTrack) && boundaryBT(end-backTrack) > HBTback(end-backTrack-1)
                        backTrack = backTrack + 1;
                        % If it is an aislated boundary we just use the closes
                        % heartbeat
                    else
                        lastHBT = HBTback(end-backTrack);
                        backFound = 1;
                    end
                end

                % Check how many HBT we reject forwards
                if ~forwardFound
                    boundaryFT = bounds((bounds-bounds(bi)) > 0); % Get boundaries after current boundary
                    HBTforward = HBTS(HBTS > bounds(bi)); % Get HBT after current boundary

                    % Break if no future boundary or if no future HBT
                    if isempty(boundaryFT)
                        nextHBT = HBTforward(1+forwardTrack);
                        forwardFound = 1;
                        continue
                    end

                    % Check forwards for consecutive boundaries in between heartbeats
                    if forwardTrack >= length(HBTforward) || forwardTrack >= length(boundaryFT)
                        nextHBT = HBTforward(forwardTrack+1);
                        forwardFound = 1;
                    elseif boundaryFT(1+forwardTrack) > HBTforward(1+forwardTrack) && boundaryFT(1+forwardTrack) < HBTforward(1+forwardTrack)
                        forwardTrack = forwardTrack + 1;
                    else
                        nextHBT = HBTforward(1+forwardTrack);
                        forwardFound = 1;
                    end
                end

                % Create rejection window once both back and forwards latencies
                % defined
                if backFound && forwardFound
                    rejWindows = [rejWindows; (EEG.event(lastHBT).latency - 1), (EEG.event(nextHBT).latency - 1)]; %#ok
                    windowFound = 1;
                end
            end
        end
        
        if ~isempty(rejWindows)
            %% Delete all the windows that are on top of an end or start event
            % Start events
            for ei = 1:length(startEvents)
                latenciesSE = find(strcmp({EEG.event.type},startEvents{ei}) == 1);
                for li = 1:length(latenciesSE)
                    eventx = (rejWindows(:,1) < EEG.event(latenciesSE(li)).latency) + (rejWindows(:,2) > EEG.event(latenciesSE(li)).latency) - 1;
                    if any(eventx)
                        eventxIdx = find(eventx);
                        for eix = 1:length(eventxIdx)
                            rejWindows(eventxIdx(eix),1) = EEG.event(latenciesSE(li)).latency+1;%#ok
                        end
                    end
                end
            end
            clear eventx eventxIdx latenciesSE
            
            % End events
            for ei = 1:length(endEvents)
                latenciesSE = find(strcmp({EEG.event.type},endEvents{ei}) == 1);
                for li = 1:length(latenciesSE)
                    eventx = (rejWindows(:,1) < EEG.event(latenciesSE(li)).latency) + (rejWindows(:,2) > EEG.event(latenciesSE(li)).latency) - 1;
                    if any(eventx)
                        eventxIdx = find(eventx);
                        for eix = 1:length(eventxIdx)
                            rejWindows(eventxIdx(eix),2) = EEG.event(latenciesSE(li)).latency-1;%#ok
                        end
                    end
                end
            end

            %% Correct for more than one boundary within two HBT events
            % reject
            [GC,GR] = groupcounts(rejWindows(:,1));
            counter = 0;
            rejWindowsNew = [];
            for gri = 1:length(GR)
                counter = counter + GC(gri);
                rejWindowsNew(gri,:) = [GR(gri,1), rejWindows(counter,2)];%#ok
            end

            %% Check consecutive boundaries and merge them into a big one
            contRej = find(rejWindowsNew(1:end-1,2) <= rejWindowsNew(2:end,1));
            contRej = [1;contRej];
            rejWindowsV3 = [];
            for cri = 1:length(contRej)-1
                if cri == 1
                    rejWindowsV3 = [rejWindowsV3;rejWindowsNew(contRej(cri),1),rejWindowsNew(contRej(cri+1),2)];
                else
                    rejWindowsV3 = [rejWindowsV3;rejWindowsNew(contRej(cri)+1,1),rejWindowsNew(contRej(cri+1),2)];
                end
            end

            if ~isempty(rejWindowsNew)
                EEG = eeg_eegrej(EEG,rejWindowsV3);
                EEG = eeg_checkset( EEG ); % Reload to save within variables
                EEG = eeg_checkset( EEG );
                eeglab redraw % Redraw the GUI
            else
                EEG = eeg_eegrej(EEG,rejWindows);
                EEG = eeg_checkset( EEG ); % Reload to save within variables
                EEG = eeg_checkset( EEG );
                eeglab redraw % Redraw the GUI
            end
        end
        %% SAVE SET AND GO TO THE NEXT ITERATION
        pop_saveset(EEG, [sDir(si).name(1:4),'_a5.set'], savePath) % Save it in savePath
        EEG = eeg_checkset( EEG );
        eeglab redraw % Redraw the GUI
    end
end