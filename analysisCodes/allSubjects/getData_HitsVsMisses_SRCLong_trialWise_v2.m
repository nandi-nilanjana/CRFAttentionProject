%This function saves the data in the following matrix -
%{freqrange}{subject}{condition}(iBootstrap,elec,:)

function [powerValsBL_all, powerValsTG_all,badElecs] =...
    getData_HitsVsMisses_SRCLong_trialWise_v2(protocolType,gridType,badTrialStr,bootstrapTimes)


[subjectNames,expDates,protocolNames,dataFolderSourceString] = dataInformationSRCProtocols_HumanEEG(gridType,protocolType);
capType = 'actiCap64';

tapers = [1 1];

timingParameters.blRange = [-1.000 0];
timingParameters.tgRange = [-1.000 0];




    for iBootStrap =1:bootstrapTimes
        tic
        for iSub = 1:size(subjectNames,1)
            disp(['Processing data for Subject: ' num2str(iSub) ', Bootstrap: ' num2str(iBootStrap)])
            folderName = fullfile(dataFolderSourceString,'data',subjectNames{iSub},gridType,expDates{iSub},protocolNames{iSub});
            folderExtract= fullfile(folderName,'extractedData');
            folderSegment= fullfile(folderName,'segmentedData');
            folderLFP = fullfile(folderSegment,'LFP');
            
            if iSub<8 % First Set of Recording- Nov-Dec 2021
                freqRanges{1} = [8 12];    % alpha
                freqRanges{2} = [25 70];   % gamma
                freqRanges{3} = [23 23];   % SSVEP Left Stim; Flicker Freq moved by 0.5 Hz due one extra blank Frame
                freqRanges{4} = [31 31];   % SSVEP Right Stim; Flicker Freq moved by 0.5 Hz due one extra blank Frame
                
            
            else % Second Set of Recording- Jan-Mar 2022
                freqRanges{1} = [8 12];    % alpha
                freqRanges{2} = [25 70];   % gamma
                freqRanges{3} = [24 24];   % SSVEP Left Stim; Flicker Freq bug Fixed
                freqRanges{4} = [32 32];   % SSVEP Right Stim; Flicker Freq bug Fixed
                
            end
          
            
            % load LFP Info
            [analogChannelsStored,timeVals,~,~] = loadlfpInfo(folderLFP);
            
            % Get Parameter Combinations for SRC-Long Protocols
            [parameterCombinations,parameters]= ...
                loadParameterCombinations(folderExtract); %#ok<ASGLU>
            
            % timing related Information
            Fs = round(1/(timeVals(2)-timeVals(1)));
            if round(diff(timingParameters.blRange)*Fs) ~= round(diff(timingParameters.tgRange)*Fs)
                disp('baseline and stimulus ranges are not the same');
            else
                range = timingParameters.blRange;
                rangePos = round(diff(range)*Fs);
                blPos = find(timeVals>=timingParameters.blRange(1),1)+ (1:rangePos);
                tgPos = find(timeVals>=timingParameters.tgRange(1),1)+ (1:rangePos);
            end
            
            % Set up params for MT
            params.tapers   = tapers;
            params.pad      = -1;
            params.Fs       = Fs;
            params.fpass    = [0 250];
            params.trialave = 0;
            
            % Electrode and trial related Information
            photoDiodeChannels = [65 66];
            
            refType='unipolar';
            electrodeList = getElectrodeList(capType,refType,1);
            
            % Get bad trials
            badTrialFile = fullfile(folderSegment,['badTrials_' badTrialStr '.mat']);
            if ~exist(badTrialFile,'file')
                disp('Bad trial file does not exist...');
                badElecs = [];
            else
                [badTrials,badElectrodes,badTrialsUnique] = loadBadTrials(badTrialFile);
                badElecsAll = unique([badElectrodes.badImpedanceElecs; badElectrodes.noisyElecs; badElectrodes.flatPSDElecs; badElectrodes.flatPSDElecs]);
            end
            
            highPriorityElectrodeNums = getHighPriorityElectrodes(capType);
            
            
            badElecs{iSub} = intersect(setdiff(analogChannelsStored,photoDiodeChannels),badElecsAll);
            disp(['Unipolar, all bad elecs: ' num2str(length(badElecsAll)) '; all high-priority bad elecs: ' num2str(length(intersect(highPriorityElectrodeNums,badElecsAll))) ]);
            
            
            
            for iCondition = 1:12
                for iElec = 1:length(electrodeList)
                    clear x
                  
                        if iElec == length(electrodeList)
                            disp('Processed unipolar electrodes')
                        end
                        x = load(fullfile(folderLFP,['elec' num2str(electrodeList{iElec}{1}) '.mat']));
                  
                    
                    switch iCondition
                        case 1;  c = 1; tf = 1; eotCode = 1; attLoc = 2;  s=1;
                        case 2;  c = 1; tf = 1; eotCode = 1; attLoc = 1;  s=1;
                        case 3;  c = 1; tf = 2; eotCode = 1; attLoc = 2;  s=1;
                        case 4;  c = 1; tf = 2; eotCode = 1; attLoc = 1;  s=1;
                        case 5;  c = 1; tf = 3; eotCode = 1; attLoc = 2;  s=1;
                        case 6;  c = 1; tf = 3; eotCode = 1; attLoc = 1;  s=1;
                        case 7;  c = 1; tf = 1; eotCode = 2; attLoc = 2;  s=1;
                        case 8;  c = 1; tf = 1; eotCode = 2; attLoc = 1;  s=1;
                        case 9;  c = 1; tf = 2; eotCode = 2; attLoc = 2;  s=1;
                        case 10; c = 1; tf = 2; eotCode = 2; attLoc = 1;  s=1;
                        case 11; c = 1; tf = 3; eotCode = 2; attLoc = 2;  s=1;
                        case 12; c = 1; tf = 3; eotCode = 2; attLoc = 1;  s=1;
                    end
                    
                    goodPosTMP = setdiff(parameterCombinations.targetOnset{c,tf,eotCode,attLoc,s},union(badTrials,badTrialsUnique.badEyeTrials));
%                     goodPosTMP = goodPos_TMP(allGoodStimNums{1,iBootStrap}{1,iSub}{1,iCondition});
                    goodPos_all{iBootStrap}{iSub,iCondition} =  goodPosTMP ;
                    goodStimNums{iBootStrap}{iSub,iCondition} = length(goodPosTMP);  %#ok<*AGROW>
                    
                    % Segmenting data according to timePos
                    dataBL = x.analogData.stimOnset(goodPosTMP,blPos)';
                    dataTG = x.analogData.targetOnset(goodPosTMP,tgPos)';
                    
                    % power spectral density estimation
                    [tmpEBL,freqValsBL] = mtspectrumc(dataBL,params);
                    [tmpETG,freqValsTG] = mtspectrumc(dataTG,params);
                    
                    if isequal(freqValsBL,freqValsBL) && isequal(freqValsBL,freqValsTG)
                        freqVals = freqValsTG;
                    end
                   
                    if iCondition == 1 || iCondition == 2 || iCondition == 7 || iCondition == 8
                        tf1 = 0; tf2 = 0;
                    elseif  iCondition == 3 || iCondition == 4 || iCondition == 9 || iCondition == 10
                        tf1 = 12; tf2= 16;                        
                    elseif  iCondition == 5 || iCondition == 6 || iCondition == 11 || iCondition == 12
                        tf1 = 12; tf2 = 16;                        
                    end
                    
                  
                    
                    for iFreqRange=1:length(freqRanges)
                        if iFreqRange == 3||iFreqRange == 4
                            remove_NthHarmonicOnwards = 3;
                        else
                            remove_NthHarmonicOnwards = 2;
                        end
                        deltaF_LineNoise = 2; deltaF_tfHarmonics = 0;
                        badFreqPos = getBadFreqPos(freqVals,deltaF_LineNoise,deltaF_tfHarmonics,remove_NthHarmonicOnwards,tf1,tf2);
                        powerValsBL{iFreqRange}{iSub}{iCondition}(iBootStrap,iElec,:)=getMeanEnergyForAnalysis(tmpEBL',freqVals,freqRanges{iFreqRange},badFreqPos);
                        powerValsTG{iFreqRange}{iSub}{iCondition}(iBootStrap,iElec,:) = getMeanEnergyForAnalysis(tmpETG',freqVals,freqRanges{iFreqRange},badFreqPos);
                    end
                    
%                    
                end
            end
        end
    end
    
    powerValsBL_all = powerValsBL; 
    powerValsTG_all= powerValsTG;
%     goodPos_allRef{iRef} = goodPos_all;
%     goodStimNums_allRef{iRef} = goodStimNums;
    toc



fileSave = (['D:\SUPRATIM BACKUP\supratim\data\AritraSRCLongData\savedData2\HitsVsMissesData_allTrials_targetOnsetMatch_0_bootstrap_' num2str(bootstrapTimes) '.mat']);
save(fileSave,'powerValsBL_all','powerValsTG_all','badElecs')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%  Accessory Functions  %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get parameter combinations
function [parameterCombinations,parameters] = loadParameterCombinations(folderExtract)
load(fullfile(folderExtract,'parameterCombinations.mat')); %#ok<*LOAD>
end

% Get Bad Trials
function [badTrials,badElecs,badTrialsUnique] = loadBadTrials(badTrialFile) %#ok<*STOUT>
load(badTrialFile);
% badEyeTrials = badTrialsUnique.badEyeTrials;
end

% Load LFP Info
function [analogChannelsStored,timeVals,goodStimPos,analogInputNums] = loadlfpInfo(folderLFP) %#ok<*STOUT>
load(fullfile(folderLFP,'lfpInfo.mat'));
analogChannelsStored=sort(analogChannelsStored); %#ok<NODEF>
if ~exist('analogInputNums','var')
    analogInputNums=[];
end
end

% Get MeanEnergy for different frequency bands
function eValue = getMeanEnergyForAnalysis(mEnergy,freq,freqRange,badFreqPos) %#ok<*DEFNU>
posToAverage = setdiff(intersect(find(freq>=freqRange(1)),find(freq<=freqRange(2))),badFreqPos);
eValue   = sum(mEnergy(:,posToAverage),2);
end

function badFreqPos = getBadFreqPos(freqVals,deltaF_LineNoise,deltaF_TFHarmonics,remove_NthHarmonicOnwards,tfLeft,tfRight)
% During this Project, line Noise was at
% 51 Hz for 1 Hz Freq Resolution and
% 52 Hz for 2 Hz Freq Resolution

if nargin<2
    deltaF_LineNoise = 1; deltaF_TFHarmonics = 0; tfLeft = 0; tfRight = 0;
end

if tfLeft>0 && tfRight>0 % Flickering Stimuli
    badFreqs = 51:51:max(freqVals);
    tfHarmonics1 = remove_NthHarmonicOnwards*tfLeft:tfLeft:max(freqVals); % remove nth SSVEP harmonic and beyond
    tfHarmonics2 = remove_NthHarmonicOnwards*tfRight:tfRight:max(freqVals); % remove nth SSVEP harmonic and beyond
    tfHarmonics = unique([tfHarmonics1 tfHarmonics2]);
elseif tfLeft==0 && tfRight==0 % Static Stimuli
    badFreqs = 51:51:max(freqVals);
end

badFreqPos = [];  
for i=1:length(badFreqs)
    badFreqPos = cat(2,badFreqPos,intersect(find(freqVals>=badFreqs(i)-deltaF_LineNoise),find(freqVals<=badFreqs(i)+deltaF_LineNoise)));
end

if exist('tfHarmonics','var')
    freqPosToRemove =  [];
    for i=1:length(badFreqs)
        freqPosToRemove = cat(2,freqPosToRemove,intersect(find(freqVals>=tfHarmonics(i)-deltaF_TFHarmonics),find(freqVals<=tfHarmonics(i)+deltaF_TFHarmonics)));
    end
    badFreqPos = unique([badFreqPos freqPosToRemove]);
end
end

