%This function saves the hits Vs miss data as follows: two separate
%variables for attended powerValues in hits and miss condition of target period. in each
%variable it will be stored as {freqrange}{subject}{electrode
%Group} (elec,trials)

function getData_HitsVsMisses_ConsolidatedResults(subjectIdx,bootstrapTimes,removeBadElectrodeData)

fileName = (['D:\SUPRATIM BACKUP\supratim\data\AritraSRCLongData\savedData2\HitsVsMissesData_allTrials_targetOnsetMatch_0_bootstrap_' num2str(bootstrapTimes) '.mat']);
gridLayout=2;

if exist(fileName, 'file')
    load(fileName) %#ok<*LOAD>
else
    error('File not Found!')
end

% remove Bad Electrodes- converting the data for bad Elecs to NaN
if removeBadElectrodeData
    for iBootstrap=1:bootstrapTimes
        for iSub = 1:length(subjectIdx)
            
            clear badElecsTMP
            badElecsTMP = badElecs{subjectIdx(iSub)}; %#ok<*USENS>
            
            for iCond=1:12
                
                
                for iFreqRanges = 1: 4
                    powerValsTG_all{iFreqRanges}{subjectIdx(iSub)}{iCond}(iBootstrap,badElecsTMP,:) = NaN;
                    
                    
                end
            end
            
        end
    end

end


 % Grouping the good electrodes in different catagories:
 numElectrode = 64; %unipolar electrode array
 [~,~,~,electrodeGroupList,groupNameList,~] = electrodePositionOnGrid(numElectrode,'EEG',[],gridLayout);

%Occipetal Group
 showOccipitalElecsUnipolarLeft = [24 29 57 61]; %electrode numbers 24 26 57 58 are originally included in centro-parietal electrode list from electrodePositionOnGrid func.
showOccipitalElecsUnipolarRight = [26 31 58 63];
 
%Centro-Parietal Group
showFrontalElecsUnipolarLeft = [1 33 34 3 37 4];
showFrontalElecsUnipolarRight = [2 35 36 6 40 7];

%Fronto-Central Group
showCentroParietalElecsUnipolarLeft = [18 19 52 23 56];
showCentroParietalElecsUnipolarRight = [20 21 27 54 59];

%Frontal Group
showFrontoCentralElecsUnipolarLeft = [8 9 13 43 47 48];
showFrontoCentralElecsUnipolarRight = [10 11 15 44 49 50];

%Temporal Group
showTemporalElecsUnipolarLeft = [12 17 41 42 51];
showTemporalElecsUnipolarRight = [16 22 45 46 55];


for iElecGroup = 1:length(groupNameList)
    rhythmIDs = [1 2 3 4]; %freq Ranges
    switch iElecGroup
        case 1
            elecsLeft =  showOccipitalElecsUnipolarLeft ;
            elecsRight =  showOccipitalElecsUnipolarRight;
            
        case 2
            elecsLeft = showCentroParietalElecsUnipolarLeft;
            elecsRight = showCentroParietalElecsUnipolarRight ;
            
        case 3
            elecsLeft =  showFrontoCentralElecsUnipolarLeft;
            elecsRight = showFrontoCentralElecsUnipolarRight;
            
        case 4
            elecsLeft = showFrontalElecsUnipolarLeft ;
            elecsRight =showFrontalElecsUnipolarRight;
        case 5
            elecsLeft = showTemporalElecsUnipolarLeft ;
            elecsRight =showTemporalElecsUnipolarRight ;
    end
    
  %This function is used to concatenate the electrode data for hits and miss for 3 freqRanges -   
[HitsData,MissesData]= ...
    getHitsVsMisses_PowerVals_FlickerStimuli(powerValsTG_all,....
    rhythmIDs,subjectIdx,elecsLeft,elecsRight);
HitsAnalysisData{iElecGroup}=HitsData;
MissesAnalysisData{iElecGroup}=MissesData;


    
end

fileSave = 'D:\SUPRATIM BACKUP\supratim\data\AritraSRCLongData\savedData2\HitsVsMissesConsolidatedData_allTrials_targetOnsetMatch_0.mat'; 
save(fileSave,'HitsAnalysisData','MissesAnalysisData')




end

function [HitsData,MissData]=getHitsVsMisses_PowerVals_FlickerStimuli(powerData,....
    rhythmIDs,subjectIdx,elecsLeft,elecsRight)

data{1} = powerData{rhythmIDs(1)}; % Alpha Unipolar Ref
data{2} = powerData{rhythmIDs(2)}; % Gamma Unipolar Ref
data{3} = powerData{rhythmIDs(3)}; % SSVEP 24 Hz
data{4} = powerData{rhythmIDs(4)}; % SSVEP 32 Hz

attendLocs = [1 2]; % AttendLoc; 1- Right; 2-Left
ssvepFreqs = [1 2]; % SSVEPFreq; 1- 24 Hz; 2- 32 Hz

for iSub=1:length(subjectIdx)
  clear HitsDataCount  MissesDataCount HitsSSVEP_all MissSSVEP_all
    disp (['Processing Attend In Data for subject number ' num2str(subjectIdx(iSub))]);
    
    for iCount = 1:length(attendLocs)*length(ssvepFreqs)
        switch iCount
            case 1
                attLoc = 2; ign_AttLoc = 1; att_TF = 2; ign_AttTF = 3; conditionID_Hits = 3; conditionID_Misses = 9; elecs = elecsRight;
                dataTMP = powerData{rhythmIDs(3)};
            case 2
                attLoc = 1; ign_AttLoc = 2; att_TF = 2; ign_AttTF = 3; conditionID_Hits = 4; conditionID_Misses = 10; elecs = elecsLeft;
                dataTMP = powerData{rhythmIDs(3)};
            case 3
                attLoc = 2; ign_AttLoc = 1; att_TF = 3; ign_AttTF = 2; conditionID_Hits = 5; conditionID_Misses = 11; elecs = elecsRight;
                dataTMP = powerData{rhythmIDs(4)};
            case 4
                attLoc = 1; ign_AttLoc = 2; att_TF = 3; ign_AttTF = 2; conditionID_Hits = 6; conditionID_Misses = 12; elecs = elecsLeft;
                dataTMP = powerData{rhythmIDs(4)}; %dataTMP is taken out separately to later combine the SSVEP power for condition 1,3 and 2,4.
        end
     %here only concatenates the data for attend in condition for alpha gamma and SSVEP power in target period across 4 attention conditions   
        for iDataType = 1: length(data)-1
            
           
             
            if length(size(data{iDataType}{subjectIdx(iSub)}{conditionID_Misses}))<3
            
              data{iDataType}{subjectIdx(iSub)}{conditionID_Misses} = data{iDataType}{subjectIdx(iSub)}{conditionID_Misses}';
              dataTMP{subjectIdx(iSub)}{conditionID_Misses}= dataTMP{subjectIdx(iSub)}{conditionID_Misses}';
            end
              
            if length(size(data{iDataType}{subjectIdx(iSub)}{conditionID_Hits}))<3
                data{iDataType}{subjectIdx(iSub)}{conditionID_Hits} = data{iDataType}{subjectIdx(iSub)}{conditionID_Hits}';
                dataTMP{subjectIdx(iSub)}{conditionID_Hits}= dataTMP{subjectIdx(iSub)}{conditionID_Hits}';
            end
            
            data{iDataType}{subjectIdx(iSub)}{conditionID_Misses} = squeeze(data{iDataType}{subjectIdx(iSub)}{conditionID_Misses});
            dataTMP{subjectIdx(iSub)}{conditionID_Misses} = squeeze(dataTMP{subjectIdx(iSub)}{conditionID_Misses});
            data{iDataType}{subjectIdx(iSub)}{conditionID_Hits} = squeeze(data{iDataType}{subjectIdx(iSub)}{conditionID_Hits});
            dataTMP{subjectIdx(iSub)}{conditionID_Hits}= squeeze(dataTMP{subjectIdx(iSub)}{conditionID_Hits});
            
            
            
            if iCount==1 || iCount== 2
                
               if iDataType<3
               HitsDataCount{iDataType}{attLoc}=  (data{iDataType}{subjectIdx(iSub)}{conditionID_Hits}(elecs,:));
               MissesDataCount{iDataType}{attLoc} = (data{iDataType}{subjectIdx(iSub)}{conditionID_Misses}(elecs,:));
               
               else
               
               HitsSSVEP_all{attLoc} = (dataTMP{subjectIdx(iSub)}{conditionID_Hits}(elecs,:));
               MissSSVEP_all{attLoc} = (dataTMP{subjectIdx(iSub)}{conditionID_Misses}(elecs,:));
               
               end
                
            else
            
            if iDataType<3
            HitsDataTMP{iDataType}{subjectIdx(iSub)}{attLoc} = cat(2,HitsDataCount{iDataType}{attLoc}, (data{iDataType}{subjectIdx(iSub)}{conditionID_Hits}(elecs,:)));
            MissesDataTMP{iDataType}{subjectIdx(iSub)}{attLoc} = cat(2,MissesDataCount{iDataType}{attLoc},(data{iDataType}{subjectIdx(iSub)}{conditionID_Misses}(elecs,:)));
            
            else
            HitsDataTMP{iDataType}{subjectIdx(iSub)}{attLoc} = cat(2, HitsSSVEP_all{attLoc}, (dataTMP{subjectIdx(iSub)}{conditionID_Hits}(elecs,:)));
            MissesDataTMP{iDataType}{subjectIdx(iSub)}{attLoc} = cat(2,MissSSVEP_all{attLoc}, (dataTMP{subjectIdx(iSub)}{conditionID_Misses}(elecs,:)));
            
                
            end
            
            
            end
        end
    end
   
    

end
HitsData = HitsDataTMP;
MissData =  MissesDataTMP;

end
