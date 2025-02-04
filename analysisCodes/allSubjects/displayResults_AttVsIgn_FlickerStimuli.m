% This program displays Topoplots,change in Power wrt to Baseline for
% flickering stimuli, PSD and Delta Power Changes for selected electrodes
% for attended and Ignored conditions

function displayResults_AttVsIgn_FlickerStimuli(protocolType,analysisMethodFlag,...
    subjectIdx,timeEpoch,eotCodeIdx,removeBadElectrodeData,...
    BaselineCondition,topoplot_style,colorMap,badTrialStr,showNeuralMeasure,statTest)

close all;
if ~exist('folderSourceString','var');  folderSourceString='E:\';        end
if ~exist('gridType','var');            gridType='EEG';      end

tapers = [1 1];

timingParameters.blRange = [-1.000 0];
timingParameters.stRange = [0.250 1.250];
timingParameters.tgRange = [-1.000 0];
timingParameters.erpRange = [0 0.250];

if  all(subjectIdx<8) % First Set of Recording- Nov-Dec 2021
    freqRanges{1} = [8 12];    % alpha
    freqRanges{2} = [25 70];   % gamma
    freqRanges{3} = [23 23];   % SSVEP Left Stim; Flicker Freq moved by 0.5 Hz due one extra blank Frame
    freqRanges{4} = [31 31];   % SSVEP Right Stim; Flicker Freq moved by 0.5 Hz due one extra blank Frame
    freqRanges{5} = [26 34];   % Slow Gamma
    freqRanges{6} = [44 56];   % Fast Gamma
    freqRanges{7} = [102 250]; % High Gamma
    
else                   % Second Set of Recording- Jan-Mar 2022
    freqRanges{1} = [8 12];    % alpha
    freqRanges{2} = [25 70];   % gamma
    freqRanges{3} = [24 24];   % SSVEP Left Stim; Flicker Freq bug Fixed
    freqRanges{4} = [32 32];   % SSVEP Right Stim; Flicker Freq bug Fixed
    freqRanges{5} = [26 34];   % Slow Gamma
    freqRanges{6} = [44 56];   % Fast Gamma
    freqRanges{7} = [102 250]; % High Gamma
end
numFreqs = length(freqRanges);

fileName = fullfile(folderSourceString,'Projects\Aritra_AttentionEEGProject\savedData\',[protocolType '_tapers_' num2str(tapers(2)) ...
    '_TG_' num2str(freqRanges{2}(1)) '-' num2str(freqRanges{2}(2)) 'Hz'...
    '_SG_' num2str(freqRanges{5}(1)) '-' num2str(freqRanges{5}(2)) 'Hz'...
    '_FG_' num2str(freqRanges{6}(1)) '-' num2str(freqRanges{6}(2)) 'Hz_' 'badTrial_' badTrialStr '.mat']);

if exist(fileName, 'file')
    load(fileName,'erpData','energyData','badElecs','badHighPriorityElecs') %#ok<*LOAD>
else
    [erpData,fftData,energyData,freqRanges_SubjectWise,badHighPriorityElecs,badElecs] = ...
        getData_SRCLongProtocols_v1(protocolType,gridType,timingParameters,tapers);
    save(fileName,'erpData','fftData','energyData','freqRanges_SubjectWise','badHighPriorityElecs','badElecs')
end



% remove Bad Electrodes- converting the data for bad Elecs to NaN
declaredBadElectrodes = [8 9 10 11 43 44]; %  13 47 52 15 50 54
if removeBadElectrodeData
    for iSub = 1:length(subjectIdx)
        for iRef = 1:2
            clear badElecsTMP
%             if subjectIdx(iSub)>7
                badElecsTMP = union(badElecs{iRef}{subjectIdx(iSub)},declaredBadElectrodes);
%             else
%                 badElecsTMP = badElecs{iRef}{subjectIdx(iSub)};
%             end

            
            % removing ERP data for Bad Electrodes
            % removing ERP data for Bad Electrodes
            erpData.dataST{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:,:) = NaN;
            erpData.dataTG{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:,:) = NaN;
            erpData.analysisData_BL{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
            erpData.analysisData_ST{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
            erpData.analysisData_TG{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
            
            % removing Energy data (PSD & Power) for Bad Electrodes
            energyData.dataBL{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:,:) = NaN;
            energyData.dataST{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:,:) = NaN;
            energyData.dataTG{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:,:) = NaN;
            energyData.dataBL_trialAvg{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:,:) = NaN;
            energyData.dataST_trialAvg{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:,:) = NaN;
            energyData.dataTG_trialAvg{iRef}(subjectIdx(iSub),badElecsTMP,:,:,:,:) = NaN;
            
            for iFreqRanges = 1: length(freqRanges)
                energyData.analysisDataBL{iRef}{iFreqRanges}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
                energyData.analysisDataST{iRef}{iFreqRanges}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
                energyData.analysisDataTG{iRef}{iFreqRanges}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
                energyData.analysisDataBL_trialAvg{iRef}{iFreqRanges}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
                energyData.analysisDataST_trialAvg{iRef}{iFreqRanges}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
                energyData.analysisDataTG_trialAvg{iRef}{iFreqRanges}(subjectIdx(iSub),badElecsTMP,:,:,:) = NaN;
            end

        end
    end
end

% Replace the PSD and power Values if trial avg  PSD and power is plotted
if analysisMethodFlag
    clear energyData.dataBL energyData.dataST energyData.dataTG
    clear energyData.analysisDataBL energyData.analysisDataST energyData.analysisDataTG
    for iRef = 1:2
        energyData.dataBL{iRef} = energyData.dataBL_trialAvg{iRef};
        energyData.dataST{iRef} = energyData.dataST_trialAvg{iRef};
        energyData.dataTG{iRef} = energyData.dataTG_trialAvg{iRef};
        
        energyData.analysisDataBL{iRef} = energyData.analysisDataBL_trialAvg{iRef};
        energyData.analysisDataST{iRef} = energyData.analysisDataST_trialAvg{iRef};
        energyData.analysisDataTG{iRef} = energyData.analysisDataTG_trialAvg{iRef};
    end
end

nanFlag = 'omitnan';

% Plots
hFig1 = figure(2); colormap(colorMap)
set(hFig1,'units','normalized','outerPosition',[0 0 1 1]);
hPlot1 = getPlotHandles(5,3,[0.05 0.07, 0.5 0.85],0.02,0.04,0);
hPlot2 = getPlotHandles(5,2,[0.59 0.07, 0.18 0.86],0.035,0.04,0);
hPlot3 = getPlotHandles(5,2,[0.81 0.07, 0.18 0.86],0.035,0.04,0);

if BaselineCondition
    cLimsRaw = [-2 2]; % range in dB
    cLimsDiff = [-1 2]; % range in dB
else
    cLimsRaw = [-1 2]; % range in log10 scale
    cLimsDiff = [-1 2]; % range in log10 scale
end

fontSizeLarge = 14; tickLengthMedium = [0.025 0];

showMode = 'dots';
showOccipitalElecsUnipolarLeft = [24 29 57 61];
showOccipitalElecsUnipolarRight = [26 31 58 63];
showOccipitalElecsBipolarLeft = [93 94 101];
showOccipitalElecsBipolarRight = [96 97 102];
showOccipitalElecsUnipolar = [showOccipitalElecsUnipolarLeft showOccipitalElecsUnipolarRight];
showOccipitalElecsBipolar = [showOccipitalElecsBipolarLeft showOccipitalElecsBipolarRight];

showOccipitalElecsLeft{1} = showOccipitalElecsUnipolarLeft;
showOccipitalElecsLeft{2} = showOccipitalElecsBipolarLeft;
showOccipitalElecsRight{1} = showOccipitalElecsUnipolarRight;
showOccipitalElecsRight{2} = showOccipitalElecsBipolarRight;

showFrontalElecsUnipolarLeft = [1 33 34 3 37 4];
showFrontalElecsUnipolarRight = [2 35 36 6 40 7];
showFrontalElecsBipolarLeft = [1 2 5 7 8 9 10 15 16 17];
showFrontalElecsBipolarRight = [3 4 6 11 12 13 14 20 21 22];
showFrontalElecsUnipolar = [showFrontalElecsUnipolarLeft showFrontalElecsUnipolarRight];
showFrontalElecsBipolar = [showFrontalElecsBipolarLeft showFrontalElecsBipolarRight];

showFrontalElecsLeft{1} = showFrontalElecsUnipolarLeft;
showFrontalElecsLeft{2} = showFrontalElecsBipolarLeft;
showFrontalElecsRight{1} = showFrontalElecsUnipolarRight;
showFrontalElecsRight{2} = showFrontalElecsBipolarRight;


% Get the electrode list
capLayout = {'actiCap64'};
cL_Unipolar = load(fullfile(pwd,'programs\ProgramsMAP','Montages',...
    'Layouts',capLayout{1},[capLayout{1} '.mat']));
chanlocs_Unipolar = cL_Unipolar.chanlocs;

cL_Bipolar = load(fullfile(pwd,'programs\ProgramsMAP','Montages',...
    'Layouts',capLayout{1},['bipolarChanlocs' capLayout{1} '.mat']));
bL = load(fullfile(pwd,'programs\ProgramsMAP','Montages',...
    'Layouts',capLayout{1},['bipChInfo' capLayout{1} '.mat'])); %#ok<*NASGU>
chanlocs_Bipolar = cL_Bipolar.eloc;

if strcmp(timeEpoch,'StimOnset')
    powerData = energyData.analysisDataST;
    powerDataBL = energyData.analysisDataBL;
    ERPData = erpData.dataST;
    psdData = energyData.dataST;
    psdDataBL = energyData.dataBL;
    rmsERPData = erpData.analysisData_ST;
elseif strcmp(timeEpoch,'PreTarget')
    powerData = energyData.analysisDataTG;
    powerDataBL = energyData.analysisDataBL;
    ERPData = erpData.dataTG;
    psdData = energyData.dataTG;
    psdDataBL = energyData.dataBL;
    rmsERPData = erpData.analysisData_TG;
end

% topoPlotType = 'LeftVsRight'; % rhythmIDs = [1 3 4 5 6];

% hFig2 = figure(2); colormap(colorMap)
% set(hFig2,'units','normalized','outerPosition',[0 0 1 1]);
% hPlot1 = getPlotHandles(2,3,[0.07 0.5, 0.45 0.42],0.02,0.02,0);
% hPlot2 = getPlotHandles(2,3,[0.07 0.01, 0.45 0.42],0.02,0.02,0);
% hPlot3 = getPlotHandles(1,3,[0.58 0.56, 0.42 0.3],0.04,0.02,0);
% hPlot4 = getPlotHandles(1,3,[0.58 0.07, 0.42 0.3],0.04,0.02,0);
fontSize = 12;

% SSVEP Topoplots (Figure 2)
if strcmp(showNeuralMeasure,'alpha')
    rhythmIDs = [1 1];
    refType = 1;
    if analysisMethodFlag
        if strcmp(BaselineCondition,'none')
            cLimsSSVEPRaw = [-3 -1];
            cLimsSSVEPDiff = [-2 5];
        else
            cLimsSSVEPRaw = [-2 2];
            cLimsSSVEPDiff = [-1 2];
        end
    else
        if strcmp(BaselineCondition,'none')
            cLimsSSVEPRaw = [-1 3];
            cLimsSSVEPDiff = [-1 1];
        else
            cLimsSSVEPRaw = [-2 2];
            cLimsSSVEPDiff = [-1 2];
        end
    end
elseif strcmp(showNeuralMeasure,'gamma')
    rhythmIDs = [2 2];
    refType = 1;
    if analysisMethodFlag
        if strcmp(BaselineCondition,'none')
            cLimsSSVEPRaw = [-2 -1];
            cLimsSSVEPDiff = [-2 2];
        else
            cLimsSSVEPRaw = [-2 2];
            cLimsSSVEPDiff = [-1 2];
        end
    else
        if strcmp(BaselineCondition,'none')
            cLimsSSVEPRaw = [-2 1];
            cLimsSSVEPDiff = [-1 1];
            
        else
            cLimsSSVEPRaw = [-2 2];
            cLimsSSVEPDiff = [-1 2];
        end
    end
elseif strcmp(showNeuralMeasure,'SSVEP')
    rhythmIDs = [3 4]; % 3- SSVEP Response at 24 Hz; 4- SSVEP Response at 32 Hz
    refType = 1;
    if analysisMethodFlag
        if strcmp(BaselineCondition,'none')
            cLimsSSVEPRaw = [-1 3];
            cLimsSSVEPDiff = [-1 2];
        else
            cLimsSSVEPRaw = [-1 10];
            cLimsSSVEPDiff = [0 4];
        end
    else
        if strcmp(BaselineCondition,'none')
            cLimsSSVEPRaw = [-2 1];
            cLimsSSVEPDiff = [0 1];
        else
            cLimsSSVEPRaw = [-1 2];
            cLimsSSVEPDiff = [0 1];

        end
    end
end

topoPlotFlag = 1;
[attData_Topo,ignData_Topo]= ...
    getAttendVsIgnored_TopoPlotPowerData_FlickerStimuli...
    (powerData,rhythmIDs,showNeuralMeasure,refType,subjectIdx,eotCodeIdx,nanFlag);

[attDataBL_Topo,ignDataBL_Topo]= ...
    getAttendVsIgnored_TopoPlotPowerData_FlickerStimuli...
    (powerDataBL,rhythmIDs,showNeuralMeasure,refType,subjectIdx,eotCodeIdx,nanFlag);

for iPlot = 1:5
    switch iPlot
        case 1
            if strcmp(showNeuralMeasure,'gamma')
            showElecIDs = [showOccipitalElecsUnipolarRight]; %#ok<*NBRAK>
                chanLocs = chanlocs_Unipolar;
            else
            showElecIDs = [showOccipitalElecsUnipolarRight];
                chanLocs = chanlocs_Unipolar;
            end
        case 2
            if strcmp(showNeuralMeasure,'gamma')
            showElecIDs = [showOccipitalElecsUnipolarLeft];
                chanLocs = chanlocs_Unipolar;
            else
            showElecIDs = [showOccipitalElecsUnipolarLeft];
                chanLocs = chanlocs_Unipolar;
            end
        case 3
            if strcmp(showNeuralMeasure,'gamma')
            showElecIDs = [showOccipitalElecsUnipolarRight];
                chanLocs = chanlocs_Unipolar;
                
            else
            showElecIDs = [showOccipitalElecsUnipolarRight];
                chanLocs = chanlocs_Unipolar;
            end
        case 4
            if strcmp(showNeuralMeasure,'gamma')
            showElecIDs = [showOccipitalElecsUnipolarLeft];
                chanLocs = chanlocs_Unipolar;
                
            else
            showElecIDs = [showOccipitalElecsUnipolarLeft];
                chanLocs = chanlocs_Unipolar;
            end
        case 5
            if strcmp(showNeuralMeasure,'gamma') %#ok<*IFBDUP>
            showElecIDs = [showOccipitalElecsUnipolarRight];
                chanLocs = chanlocs_Unipolar;
                
            else
            showElecIDs = [showOccipitalElecsUnipolarRight];
                chanLocs = chanlocs_Unipolar;
            end
    end
    
    if strcmp(BaselineCondition,'Att')
        topoPlot_Attended =  10*(attData_Topo{1,iPlot}-attDataBL_Topo{1,iPlot});
        topoPlot_Ignored = 10*(ignData_Topo{1,iPlot}-attDataBL_Topo{1,iPlot});
        topoPlot_AttendedMinusIgnored = topoPlot_Attended-topoPlot_Ignored;
    elseif strcmp(BaselineCondition,'Ign')
        topoPlot_Attended =  10*(attData_Topo{1,iPlot}-ignDataBL_Topo{1,iPlot});
        topoPlot_Ignored = 10*(ignData_Topo{1,iPlot}-ignDataBL_Topo{1,iPlot});
        topoPlot_AttendedMinusIgnored = topoPlot_Attended-topoPlot_Ignored;
    elseif strcmp(BaselineCondition,'Respective')
        topoPlot_Attended =  10*(attData_Topo{1,iPlot}-attDataBL_Topo{1,iPlot});
        topoPlot_Ignored = 10*(ignData_Topo{1,iPlot}-ignDataBL_Topo{1,iPlot});
        topoPlot_AttendedMinusIgnored = topoPlot_Attended-topoPlot_Ignored;
        
    elseif strcmp(BaselineCondition,'Average')
        avgBL_Topo = (attDataBL_Topo{1,iPlot}+ignDataBL_Topo{1,iPlot})/2;
        topoPlot_Attended =  10*(attData_Topo{1,iPlot}-avgBL_Topo);
        topoPlot_Ignored = 10*(ignData_Topo{1,iPlot}-avgBL_Topo);
        topoPlot_AttendedMinusIgnored = topoPlot_Attended-topoPlot_Ignored;

    elseif strcmp(BaselineCondition,'none')
        topoPlot_Attended =  attData_Topo{1,iPlot};
        topoPlot_Ignored = ignData_Topo{1,iPlot};
        topoPlot_AttendedMinusIgnored = 10*(topoPlot_Attended-topoPlot_Ignored);
    end
    
    tickPlotLength = get(hPlot1(1,1),'TickLength');
    subplot(hPlot1(iPlot,1)); cla; hold on;
    topoplot_murty(topoPlot_Attended,chanLocs,'electrodes','on',...
        'style',topoplot_style,'drawaxis','off','nosedir','+X',...
        'emarkercolors',topoPlot_Attended);
    caxis(cLimsSSVEPRaw);    cBar_Att = colorbar; cTicks = [cLimsSSVEPRaw(1) 0:cLimsSSVEPRaw(2)/2:cLimsSSVEPRaw(2)];
    set(cBar_Att,'Ticks',cTicks,'tickLength',3*tickPlotLength(1),'TickDir','out','fontSize',fontSize);
    
    topoplot_murty([],chanLocs,'electrodes','on',...
        'style','blank','drawaxis','off','nosedir','+X','plotchans',showElecIDs);
    
    subplot(hPlot1(iPlot,2)); cla; hold on;
    topoplot_murty(topoPlot_Ignored,chanLocs,'electrodes','on','style',topoplot_style,'drawaxis','off','nosedir','+X','emarkercolors',topoPlot_Ignored);
    caxis(cLimsSSVEPRaw); cBar_Ign = colorbar; cTicks = [cLimsSSVEPRaw(1) 0:cLimsSSVEPRaw(2)/2:cLimsSSVEPRaw(2)];
    set(cBar_Ign,'Ticks',cTicks,'tickLength',3*tickPlotLength(1),'TickDir','out','fontSize',fontSize);
    
    topoplot_murty([],chanLocs,'electrodes','on','style','blank','drawaxis','off','nosedir','+X','plotchans',showElecIDs);
    
    subplot(hPlot1(iPlot,3)); cla; hold on;
    topoplot_murty(topoPlot_AttendedMinusIgnored,chanLocs,...
        'electrodes','on','style',topoplot_style,'drawaxis','off',...
        'nosedir','+X','emarkercolors',topoPlot_AttendedMinusIgnored);
    caxis(cLimsSSVEPDiff);   cBar_Diff = colorbar; cTicks = [cLimsSSVEPDiff(1) cLimsSSVEPDiff(2)/2 cLimsSSVEPDiff(2)];
    set(cBar_Diff,'Ticks',cTicks,'tickLength',3*tickPlotLength(1),'TickDir','out','fontSize',fontSize);
    if iPlot==5
        cBar_Diff.Label.String ='\Delta Power (dB)'; cBar_Diff.Label.FontSize = 14;
    end
    
    topoplot_murty([],chanLocs,'electrodes','on',...
        'style','blank','drawaxis','off','nosedir','+X','plotchans',showElecIDs);
    
end

% % get ERP Data for Attended and Ignored Conditions for Flicker Stimuli
% [attData_erp,ignData_erp]= getAttendVsIgnoredCombinedData_FlickerStimuli...
%     (ERPData,refType,subjectIdx,eotCodeIdx,nanFlag,showElecsLeft,showElecsRight);

% get PSD Data for Attended and Ignored Conditions for Flicker Stimuli


for iElecgroup = 1:2 % 1: Occipital PSD, 2: Frontal PSD
    clear attData_psd ignData_psd attDataBL_psd ignDataBL_psd
    switch iElecgroup
        case 1
            elecsLeft = showOccipitalElecsLeft;
            elecsRight = showOccipitalElecsRight;
            hPlot = hPlot2(:,1);
        case 2
            elecsLeft = showFrontalElecsLeft;
            elecsRight = showFrontalElecsRight;
            hPlot = hPlot3(:,1);
    end
[attData_psd,ignData_psd]= getAttendVsIgnoredCombinedData_FlickerStimuli...
    (psdData,refType,subjectIdx,eotCodeIdx,nanFlag,elecsLeft,elecsRight);
[attDataBL_psd,ignDataBL_psd]= getAttendVsIgnoredCombinedData_FlickerStimuli...
    (psdDataBL,refType,subjectIdx,eotCodeIdx,nanFlag,elecsLeft,elecsRight);

for iPlot= 1:5
    psd_Att = squeeze(mean(log10(mean(attData_psd(iPlot,:,:,:),3,nanFlag)),2,nanFlag));
    psd_Ign = squeeze(mean(log10(mean(ignData_psd(iPlot,:,:,:),3,nanFlag)),2,nanFlag));
    psdBL_Att = squeeze(mean(log10(mean(attDataBL_psd(iPlot,:,:,:),3,nanFlag)),2,nanFlag));
    psdBL_Ign = squeeze(mean(log10(mean(ignDataBL_psd(iPlot,:,:,:),3,nanFlag)),2,nanFlag));
    diffPSD = 10*(psd_Att-psd_Ign);
    
    plot(hPlot(iPlot,1),energyData.freqVals,psd_Att,'r'); hold(hPlot(iPlot,1),'on');
    plot(hPlot(iPlot,1),energyData.freqVals,psd_Ign,'b');
    plot(hPlot(iPlot,1),energyData.freqVals,psdBL_Att,'k');
    plot(hPlot(iPlot,1),energyData.freqVals,psdBL_Ign,'--k');
    plot(hPlot(iPlot,1),energyData.freqVals,diffPSD,'k'); 
    xlim(hPlot(iPlot,1),[0 72])
    ylim(hPlot(iPlot,1),[-4 4])
end
end

% get rmsERP Data and power Data for Selective Analysis Electrodes
% for Attended and Ignored Conditions for Flicker Stimuli

colors = {'k','r','c'};
for iElecGroup = 1:2
rhythmIDs = [1 2 3 4 5 6];
    switch iElecGroup
        case 1
            elecsLeft = showOccipitalElecsLeft;
            elecsRight = showOccipitalElecsRight;
            hPlot = hPlot2(:,2);
        case 2
            elecsLeft = showFrontalElecsLeft;
            elecsRight = showFrontalElecsRight;
            hPlot = hPlot3(:,2);
    end

[attAnalysisData,ignAnalysisData]= ...
    getAttendVsIgnored_BarPlotData_FlickerStimuli(rmsERPData,powerData,....
    rhythmIDs,subjectIdx,eotCodeIdx,nanFlag,elecsLeft,elecsRight);

[attAnalysisDataBL,ignAnalysisDataBL]= ...
    getAttendVsIgnored_BarPlotData_FlickerStimuli(rmsERPData,powerDataBL,....
    rhythmIDs,subjectIdx,eotCodeIdx,nanFlag,elecsLeft,elecsRight);

dataIDs = [1 2 9];

for iPlot = 1:5
    for iBar = 1:length(dataIDs)
        attTMP = squeeze(mean(attAnalysisData{dataIDs(iBar)}(iPlot,:,:),3,nanFlag));
        ignTMP = squeeze(mean(ignAnalysisData{dataIDs(iBar)}(iPlot,:,:),3,nanFlag));
        attBLTMP = squeeze(mean(attAnalysisDataBL{dataIDs(iBar)}(iPlot,:,:),3,nanFlag));
        ignBLTMP = squeeze(mean(ignAnalysisDataBL{dataIDs(iBar)}(iPlot,:,:),3,nanFlag));
        avgBLTMP = (attBLTMP+ignBLTMP)/2;
        
        if strcmp(BaselineCondition,'Att')
            attData = log10(attTMP)-log10(attBLTMP);
            ignData = log10(ignTMP)-log10(attBLTMP);
            
        elseif strcmp(BaselineCondition,'Ign')
            attData = log10(attTMP)-log10(ignBLTMP);
            ignData = log10(ignTMP)-log10(ignBLTMP);
        
        elseif strcmp(BaselineCondition,'Respective')
            attData = log10(attTMP)-log10(attBLTMP);
            ignData = log10(ignTMP)-log10(ignBLTMP);
        
        elseif strcmp(BaselineCondition,'Average')
            attData = log10(attTMP)-log10(avgBLTMP);
            ignData = log10(ignTMP)-log10(avgBLTMP);
            
        elseif strcmp(BaselineCondition,'none')
            attData = log10(attTMP);
            ignData = log10(ignTMP);
        end
        
        diffData = 10*(attData-ignData); %dB
        mBar = mean(diffData,2,nanFlag);
        errorBar = std(diffData,[],2,nanFlag)./sqrt(length(diffData));
        
        mBars(iBar) = mBar; %#ok<*AGROW>
        eBars(iBar) = errorBar;
        

        subplot(hPlot(iPlot,1));hold(hPlot(iPlot,1),'on');
        barPlot = bar(iBar,mBar);
        barPlot.FaceColor = colors{iBar};
        ylim(hPlot(iPlot,1),[-4 4])
        swarmchart(iBar*ones(1,length(diffData)),diffData,30,'k','filled')
%         scatter(iBar,diffData,'k','filled','jitter','on','jitterAmount',0.3)
        statData(iBar,:) = diffData;
        
    end
    errorbar(hPlot(iPlot,1),1:length(mBars),mBars,eBars,'.','color','k');
    if iPlot==5
       disp('We are here!')
       NeuralMeasures = {'alpha','gamma', 'SSVEP'};
       statData(1,:) = -statData(1,:); % making the delta alpha powers negative
       allCombinations = nchoosek(1:size(statData,1),2);
       for iComb=1:size(allCombinations,1)
           if strcmp(statTest,'RankSum')
               pVals(iComb) = ranksum(statData(allCombinations(iComb,1),:),statData(allCombinations(iComb,2),:));
           elseif strcmp(statTest,'t-test')
               [~,pVals(iComb)] = ttest(statData(allCombinations(iComb,1),:),statData(allCombinations(iComb,2),:));
           end
       end
       H = sigstar({[1,2],[1,3],[2,3]},pVals,0);
    end
end
end


tickPlotLength = get(hPlot2(1,1),'TickLength');
fontSize = 12;

for i=1:5
    for j=1:2
    set(hPlot2(i,j),'fontSize',fontSize,'box','off','tickLength',2*tickPlotLength,'TickDir','out')
    set(hPlot3(i,j),'fontSize',fontSize,'box','off','tickLength',2*tickPlotLength,'TickDir','out')
    end
end

linkaxes(hPlot2(1:5,1)); xlim(hPlot2(1,1),[0 72]); ylim(hPlot2(1,1),[-4.5 4.5])
linkaxes(hPlot3(1:5,1));  xlim(hPlot2(1,1),[0 72]); ylim(hPlot3(1,1),[-4.5 4.5])

linkaxes(hPlot2(1:5,2)); xlim(hPlot2(1,2),[0 4]); ylim(hPlot2(1,2),[-2 4.5])
linkaxes(hPlot3(1:5,2)); xlim(hPlot3(1,2),[0 4]); ylim(hPlot3(1,2),[-2 4.5])

Datalabels = {'alpha','gamma','SSVEP'};

% set(hPlot2(1,2),'yTick',[-2 0 3],'xTick',1:2,'xTickLabel',Datalabels(1:2),'XTickLabelRotation',30);
% set(hPlot3(1,2),'yTick',[-2 0 3],'xTick',1:2,'xTickLabel',Datalabels(1:2),'XTickLabelRotation',30);

for i=5:5
set(hPlot2(i,2),'yTick',[-2 0 2],'xTick',1:3,'xTickLabel',Datalabels,'XTickLabelRotation',30);
set(hPlot3(i,2),'yTick',[-2 0 2],'xTick',1:3,'xTickLabel',Datalabels,'XTickLabelRotation',30);
end

for i=1:4
set(hPlot2(i,2),'yTick',[-4 0 4]);
set(hPlot3(i,2),'yTick',[-4 0 4]);
end


lineWidth_lines = 1.3;
for i=1:5
set(hPlot2(i,1),'yTick',[-4 0 4],'xTick',[0 50 70]);
set(hPlot3(i,1),'yTick',[-4 0 4],'xTick',[0 50 70]);
yline(hPlot2(i,1),0,'color',colors{1},'LineWidth',lineWidth_lines)
yline(hPlot3(i,1),0,'color',colors{1},'LineWidth',lineWidth_lines)
xline(hPlot2(i,1),8,'color',colors{1},'LineWidth',lineWidth_lines)
xline(hPlot2(i,1),12,'color',colors{1},'LineWidth',lineWidth_lines)
xline(hPlot2(i,1),25,'color',colors{2},'LineWidth',lineWidth_lines)
xline(hPlot2(i,1),70,'color',colors{2},'LineWidth',lineWidth_lines)
xline(hPlot3(i,1),8,'color',colors{1},'LineWidth',lineWidth_lines)
xline(hPlot3(i,1),12,'color',colors{1},'LineWidth',lineWidth_lines)
xline(hPlot3(i,1),25,'color',colors{2},'LineWidth',lineWidth_lines)
xline(hPlot3(i,1),70,'color',colors{2},'LineWidth',lineWidth_lines)

xline(hPlot2(i,1),24,'color',colors{3},'LineWidth',lineWidth_lines)
xline(hPlot2(i,1),32,'color',colors{3},'LineWidth',lineWidth_lines)
xline(hPlot3(i,1),24,'color',colors{3},'LineWidth',lineWidth_lines)
xline(hPlot3(i,1),32,'color',colors{3},'LineWidth',lineWidth_lines)
end

ylabel(hPlot2(5,1),'log_1_0 (Power (\muV^2))'); xlabel(hPlot2(5,1),'Frequency (Hz)'); 
ylabel(hPlot2(5,2),'Change in Power (dB)'); 

annotation('textbox',[0.63 0.97 0.2 0.0241],'EdgeColor','none','String','Occipital Electrodes','fontSize',14,'fontWeight','bold');
annotation('textbox',[0.85 0.97 0.2 0.0241],'EdgeColor','none','String','Frontal Electrodes','fontSize',14,'fontWeight','bold');
title(hPlot2(1,1),'PSD','fontSize',fontSize);
title(hPlot2(1,2),'\Delta Power','fontSize',fontSize);
title(hPlot3(1,1),'PSD','fontSize',fontSize);
title(hPlot3(1,2),'\Delta Power','fontSize',fontSize);



textStartPosGapFromMidline = 0.02;
textWidth = 0.15; textHeight = 0.025;
textGap = 0.26;
topoPlotLabels = {'Attended','Ignored','Attended - Ignored'};

annotation('textbox',[0.08 0.97 0.1 0.0241],'EdgeColor','none','String','Attended','fontSize',14,'fontWeight','bold');
annotation('textbox',[0.14+ 0.12 0.97 0.1 0.0241],'EdgeColor','none','String','Ignored','fontSize',14,'fontWeight','bold');
annotation('textbox',[0.32+ 0.1 0.97 0.3 0.0241],'EdgeColor','none','String','Attended - Ignored','fontSize',14,'fontWeight','bold');
% 

if strcmp(showNeuralMeasure,'alpha')
%     textH1 = getPlotHandles(1,1,[0.03 0.4 0.01 0.01]);
%     textString1 = {'Alpha (8-12 Hz)'};
%     set(textH1,'Visible','Off');
%     text(0.35,1.15,textString1,'unit','normalized','fontsize',18,'fontweight','bold','rotation',90,'parent',textH1);
    stringLabel = {'Alpha' '(8-12 Hz)'};
    annotation('textbox',[0.001 0.86-4*0.18 0.08 0.0241],'EdgeColor','none','HorizontalAlignment','center','String',stringLabel,'fontSize',14);
elseif strcmp(showNeuralMeasure,'gamma')
%     textH1 = getPlotHandles(1,1,[0.03 0.4 0.01 0.01]);
%     textString1 = {'Gamma (25-70 Hz)'};
%     set(textH1,'Visible','Off');
%     text(0.35,1.15,textString1,'unit','normalized','fontsize',18,'fontweight','bold','rotation',90,'parent',textH1);
        stringLabel = {'Gamma' '(25-70 Hz)'};
    annotation('textbox',[0.001 0.86-4*0.18 0.08 0.0241],'EdgeColor','none','HorizontalAlignment','center','String',stringLabel,'fontSize',14);

elseif strcmp(showNeuralMeasure,'SSVEP')
    stringLabels1 = {'SSVEP Response' 'at 24 Hz'};
    stringLabels2 = {'SSVEP Response' 'at 24 Hz'};
    stringLabels3 = {'SSVEP Response' 'at 32 Hz'};
    stringLabels4 = {'SSVEP Response' 'at 32 Hz'};
    stringLabels5 = {'SSVEP Response' 'Combined'};
    
    annotation('textbox',[0.001 0.86 0.08 0.0241],'EdgeColor','none','HorizontalAlignment','center','String',stringLabels1,'fontSize',14);
    annotation('textbox',[0.001 0.86-0.18 0.08 0.0241],'EdgeColor','none','HorizontalAlignment','center','String',stringLabels2,'fontSize',14);
    annotation('textbox',[0.001 0.86-2*0.18 0.08 0.0241],'EdgeColor','none','HorizontalAlignment','center','String',stringLabels3,'fontSize',14);
    annotation('textbox',[0.001 0.86-3*0.18 0.08 0.0241],'EdgeColor','none','HorizontalAlignment','center','String',stringLabels4,'fontSize',14);
    annotation('textbox',[0.001 0.86-4*0.18 0.08 0.0241],'EdgeColor','none','HorizontalAlignment','center','String',stringLabels5,'fontSize',14);
    
end


% Stim TF: Left 12 Hz; Right 16 Hz; Attended Left: 12 Hz; Ignored Left: 12 Hz;
attLoc{1,1} = 1;
attLoc{1,2} = 2;
attLoc{2,1} = 2;
attLoc{2,2} = 1;
attLoc{3,1} = 1;
attLoc{3,2} = 2;
attLoc{4,1} = 2;
attLoc{4,2} = 1;
attLoc{5,1} = 1;
attLoc{5,2} = 2;

ssvepFreqs{1,1} = [12 16];
ssvepFreqs{1,2} = [12 16];
ssvepFreqs{2,1} = [16 12];
ssvepFreqs{2,2} = [16 12];
ssvepFreqs{3,1} = [16 12];
ssvepFreqs{3,2} = [16 12];
ssvepFreqs{4,1} = [12 16];
ssvepFreqs{4,2} = [12 16];
ssvepFreqs{5,1} = [];
ssvepFreqs{5,2} = [];

for i=1:5
    for j=1:2
        plotStimDisks(hPlot1(i,j),attLoc{i,j},ssvepFreqs{i,j})
    end
end

% save Figures
if eotCodeIdx == 1
    eotString = 'Hits';
elseif eotCodeIdx == 2
    eotString = 'Misses';
end

if length(subjectIdx) == 26
    subString = ['subjects_N' num2str(length(subjectIdx)) '_'];
elseif length(subjectIdx) == 1
    subString = ['subjects_N' num2str(length(subjectIdx)) '_SubjectID_' num2str(subjectIdx) '_'];
else
    subString = ['subjects_N' num2str(length(subjectIdx)) '_SubjectIDs_'];
    for i= 1:length(subjectIdx)
        subString = strcat(subString,[num2str(subjectIdx(i)),'_']);
    end
end

if analysisMethodFlag == 1
    ssvepMethod = 'MT_upon_trial-averaged_signal';
else
    ssvepMethod = 'MT_upon_singleTrial_signal';
end

% annotation('textbox',[0.0 0.88 0.1 0.09],'EdgeColor','none','HorizontalAlignment','center','String','A','fontWeight','bold','fontSize',28);
% annotation('textbox',[0.0 0.7 0.1 0.09],'EdgeColor','none','HorizontalAlignment','center','String','B','fontWeight','bold','fontSize',28);
% annotation('textbox',[0.0 0.52 0.1 0.09],'EdgeColor','none','HorizontalAlignment','center','String','C','fontWeight','bold','fontSize',28);
% annotation('textbox',[0.0 0.34 0.1 0.09],'EdgeColor','none','HorizontalAlignment','center','String','D','fontWeight','bold','fontSize',28);
% annotation('textbox',[0.0 0.16 0.1 0.09],'EdgeColor','none','HorizontalAlignment','center','String','E','fontWeight','bold','fontSize',28);


saveFolder = fullfile(folderSourceString,'Projects\Aritra_AttentionEEGProject\Figures\SRC-Attention\Topoplots\AttendedVsIgnored\');
figName1 = fullfile(saveFolder,[protocolType '_' subString  timeEpoch '_FlickerStimuli_',showNeuralMeasure,'_' ssvepMethod,'_' eotString '_tapers_' , ...
    num2str(tapers(2)) '_TG_' num2str(freqRanges{2}(1)) '-' num2str(freqRanges{2}(2)) 'Hz'...
    '_SG_' num2str(freqRanges{5}(1)) '-' num2str(freqRanges{5}(2)) 'Hz'...
    '_FG_' num2str(freqRanges{6}(1)) '-' num2str(freqRanges{6}(2)) 'Hz' 'badTrial_' badTrialStr]);


saveas(hFig1,[figName1 'v2.fig'])
print(hFig1,[figName1 'v2.tif'],'-dtiff','-r600')


end


%% Accessory Functions



% Process Attend Vs. Ignored TopoPlot data for Flickering Stimuli
function [attData,ignData]= ...
    getAttendVsIgnored_TopoPlotPowerData_FlickerStimuli...
    (data,rhythmIDs,neuralMeasure,refType,subjectIdx,eotCodeIdx,nanFlag)

attendLocs = [1 2]; % AttendLoc; 1- Right; 2-Left
ssvepFreqs = [1 2]; % SSVEPFreq; 1- 24 Hz; 2- 32 Hz

attData = cell(1,length(attendLocs)*length(ssvepFreqs)+1);
ignData = cell(1,length(attendLocs)*length(ssvepFreqs)+1);

for iCount = 1: length(attendLocs)*length(ssvepFreqs)
    switch(iCount)
        case 1
            attLoc = 2; ign_AttLoc = 1; att_TF = 2; ign_AttTF = 3; SSVEPFreq = 1;
        case 2
            attLoc = 1; ign_AttLoc = 2; att_TF = 2; ign_AttTF = 3; SSVEPFreq = 1;
        case 3
            attLoc = 2; ign_AttLoc = 1; att_TF = 3; ign_AttTF = 2; SSVEPFreq = 2;
        case 4
            attLoc = 1; ign_AttLoc = 2; att_TF = 3; ign_AttTF = 2; SSVEPFreq = 2;
    end
    
    attDataTMP = squeeze(mean(log10(data{refType}{rhythmIDs(SSVEPFreq)}(subjectIdx,:,eotCodeIdx,attLoc,att_TF)),1,nanFlag));
    ignDataTMP = squeeze(mean(log10(data{refType}{rhythmIDs(SSVEPFreq)}(subjectIdx,:,eotCodeIdx,ign_AttLoc,ign_AttTF)),1,nanFlag));
    
    attData{iCount} = attDataTMP;
    ignData{iCount} = ignDataTMP;
end

%  averaged across all conditions and log-averaged over all subjects with AttR conditions mirrored with z-line
for iCount = 1: length(attendLocs)*length(ssvepFreqs)
    switch(iCount)
        case 1
            attLoc = 2; ign_AttLoc = 1; att_TF = 2; ign_AttTF = 3; SSVEPFreq = 1;
            topoDataTMP = data{refType}{rhythmIDs(SSVEPFreq)};
        case 2
            attLoc = 1; ign_AttLoc = 2; att_TF = 2; ign_AttTF = 3; SSVEPFreq = 1;
            topoDataTMP = mirrorTopoplotData(data{refType}{rhythmIDs(SSVEPFreq)},refType);
        case 3
            attLoc = 2; ign_AttLoc = 1; att_TF = 3; ign_AttTF = 2; SSVEPFreq = 2;
            topoDataTMP = data{refType}{rhythmIDs(SSVEPFreq)};
        case 4
            attLoc = 1; ign_AttLoc = 2; att_TF = 3; ign_AttTF = 2; SSVEPFreq = 2;
            topoDataTMP = mirrorTopoplotData(data{refType}{rhythmIDs(SSVEPFreq)},refType);
    end
    
    attData_allcondTMP(iCount,:,:) = squeeze(topoDataTMP(subjectIdx,:,eotCodeIdx,attLoc,att_TF));
    ignData_allcondTMP(iCount,:,:) = squeeze(topoDataTMP(subjectIdx,:,eotCodeIdx,ign_AttLoc,ign_AttTF));
    
end

if strcmp(neuralMeasure,'alpha')||strcmp(neuralMeasure,'gamma')
attData{length(attendLocs)*length(ssvepFreqs)+1} = squeeze(mean(log10(mean(attData_allcondTMP([1 3],:,:),1,nanFlag)),2,nanFlag));
ignData{length(attendLocs)*length(ssvepFreqs)+1} = squeeze(mean(log10(mean(ignData_allcondTMP([1 3],:,:),1,nanFlag)),2,nanFlag));
elseif strcmp(neuralMeasure,'SSVEP')
attData{length(attendLocs)*length(ssvepFreqs)+1} = squeeze(mean(log10(mean(attData_allcondTMP,1,nanFlag)),2,nanFlag));
ignData{length(attendLocs)*length(ssvepFreqs)+1} = squeeze(mean(log10(mean(ignData_allcondTMP,1,nanFlag)),2,nanFlag));
end


end



% Process Attend Vs. Ignored PSD data combined for Attend Left and Attend Right
% Conditions
function [attData,ignData]= ...
    getAttendVsIgnoredCombinedData_FlickerStimuli...
    (data,refType,subjectIdx,eotCodeIdx,nanFlag,elecsLeft,elecsRight) %#ok<*INUSL>

attendLocs = [1 2]; % AttendLoc; 1- Right; 2-Left
ssvepFreqs = [1 2]; % SSVEPFreq; 1- 24 Hz; 2- 32 Hz


for iCount = 1:length(attendLocs)*length(ssvepFreqs)
    switch iCount
        case 1
            attLoc = 2; ign_AttLoc = 1; att_TF = 2; ign_AttTF = 3; elecNums = elecsRight;
        case 2
            attLoc = 1; ign_AttLoc = 2; att_TF = 2; ign_AttTF = 3; elecNums = elecsLeft;
        case 3
            attLoc = 2; ign_AttLoc = 1; att_TF = 3; ign_AttTF = 2; elecNums = elecsRight;
        case 4
            attLoc = 1; ign_AttLoc = 2; att_TF = 3; ign_AttTF = 2; elecNums = elecsLeft;
    end
    
    elecs = elecNums{refType};
    
    attDataTMP = squeeze(data{refType}(subjectIdx,elecs,eotCodeIdx,attLoc,att_TF,:));
    ignDataTMP = squeeze(data{refType}(subjectIdx,elecs,eotCodeIdx,ign_AttLoc,ign_AttTF,:));
    
    attData(iCount,:,:,:) = attDataTMP;
    ignData(iCount,:,:,:) = ignDataTMP;
end

attData(1+length(attendLocs)*length(ssvepFreqs),:,:,:) = squeeze(mean(attData,1,nanFlag));
ignData(1+length(attendLocs)*length(ssvepFreqs),:,:,:) = squeeze(mean(ignData,1,nanFlag));

end

% Process Attend Vs. Ignored Power data combined for Attend Left and Attend Right
% Conditions for Analysis Electrodes

function [attData,ignData]= ...
    getAttendVsIgnored_BarPlotData_FlickerStimuli...
    (rmsERPData,powerData,rhythmIDs,subjectIdx,eotCodeIdx,nanFlag,...
    elecsLeft,elecsRight)

dataLabels = {'Alpha Uni Ref.','Slow gamma Uni','Fast Gamma Uni'...
    'Slow gamma Bi','Fast Gamma Bi','SSVEP 23/24 Hz','SSVEP 31/32 Hz'};


refType = 1;
data{1} = powerData{refType}{rhythmIDs(1)}; % Alpha Unipolar Ref
data{2} = powerData{refType}{rhythmIDs(2)}; % Gamma Unipolar Ref
data{3} = powerData{refType}{rhythmIDs(3)}; % SSVEP 24 Hz
data{4} = powerData{refType}{rhythmIDs(4)}; % SSVEP 32 Hz
data{5} = powerData{refType}{rhythmIDs(5)}; % Slow Gamma Unipolar Ref
data{6} = powerData{refType}{rhythmIDs(6)}; % Fast Gamma Unipolar Ref


refType = 2;
data{7} = powerData{refType}{rhythmIDs(5)}; % Slow Gamma Bipolar Ref
data{8} = powerData{refType}{rhythmIDs(6)}; % Fast Gamma Bipolar Ref

attendLocs = [1 2]; % AttendLoc; 1- Right; 2-Left
ssvepFreqs = [1 2]; % SSVEPFreq; 1- 24 Hz; 2- 32 Hz


for iCount = 1:length(attendLocs)*length(ssvepFreqs)
    switch iCount
        case 1
            attLoc = 2; ign_AttLoc = 1; att_TF = 2; ign_AttTF = 3; elecNums = elecsRight;
        case 2
            attLoc = 1; ign_AttLoc = 2; att_TF = 2; ign_AttTF = 3; elecNums = elecsLeft;
        case 3
            attLoc = 2; ign_AttLoc = 1; att_TF = 3; ign_AttTF = 2; elecNums = elecsRight;
        case 4
            attLoc = 1; ign_AttLoc = 2; att_TF = 3; ign_AttTF = 2; elecNums = elecsLeft;
    end
    
    for iDataType = 1: length(data)
        if iDataType == 7 || iDataType == 8
            elecs = elecNums{2};
        else
            elecs = elecNums{1};
        end
        attDataTMP{iDataType}(iCount,:,:) = squeeze(data{iDataType}(subjectIdx,elecs,eotCodeIdx,attLoc,att_TF));
        ignDataTMP{iDataType}(iCount,:,:) = squeeze(data{iDataType}(subjectIdx,elecs,eotCodeIdx,ign_AttLoc,ign_AttTF));
        
    end
end

for iDataType = 1: length(data)
    attDataTMP{iDataType}(1+length(attendLocs)*length(ssvepFreqs),:,:) = squeeze(mean(attDataTMP{iDataType},1,nanFlag));
    ignDataTMP{iDataType}(1+length(attendLocs)*length(ssvepFreqs),:,:) = squeeze(mean(ignDataTMP{iDataType},1,nanFlag));
end

attData = attDataTMP;
ignData = ignDataTMP;

% combining SSVEP Freq

refType = 1;
count = 1;
for iCount = 1:length(attendLocs)*length(ssvepFreqs)
    switch(iCount)
        case 1
            attLoc = 2; ign_AttLoc = 1; att_TF = 2; ign_AttTF = 3; elecNums = elecsRight;
            dataTMP = powerData{refType}{rhythmIDs(3)};
            
        case 2
            attLoc = 1; ign_AttLoc = 2; att_TF = 2; ign_AttTF = 3; elecNums = elecsLeft;
            dataTMP = powerData{refType}{rhythmIDs(3)};
            
        case 3
            attLoc = 2; ign_AttLoc = 1; att_TF = 3; ign_AttTF = 2; elecNums = elecsRight;
            dataTMP = powerData{refType}{rhythmIDs(4)};

        case 4
            attLoc = 1; ign_AttLoc = 2; att_TF = 3; ign_AttTF = 2; elecNums = elecsLeft;
            dataTMP = powerData{refType}{rhythmIDs(4)};
    end
    
    elecs = elecNums{1};
    att_SSVEP_all(iCount,:,:) = squeeze(dataTMP(subjectIdx,elecs,eotCodeIdx,attLoc,att_TF));
    ign_SSVEP_all(iCount,:,:) = squeeze(dataTMP(subjectIdx,elecs,eotCodeIdx,ign_AttLoc,ign_AttTF));
end


attData{length(data)+1}(1,:,:) = squeeze(attData{1,3}(1,:,:));
attData{length(data)+1}(2,:,:) = squeeze(attData{1,3}(2,:,:));
attData{length(data)+1}(3,:,:) = squeeze(attData{1,4}(3,:,:));
attData{length(data)+1}(4,:,:) = squeeze(attData{1,4}(4,:,:));
attData{length(data)+1}(5,:,:) = squeeze(mean(att_SSVEP_all,1,nanFlag));


ignData{length(data)+1}(1,:,:) = squeeze(ignData{1,3}(1,:,:));
ignData{length(data)+1}(2,:,:) = squeeze(ignData{1,3}(2,:,:));
ignData{length(data)+1}(3,:,:) = squeeze(ignData{1,4}(3,:,:));
ignData{length(data)+1}(4,:,:) = squeeze(ignData{1,4}(4,:,:));
ignData{length(data)+1}(5,:,:) = squeeze(mean(ign_SSVEP_all,1,nanFlag));

end


function mirrored_topoData = mirrorTopoplotData(data,refType)
if refType ==1
    mirror_elecNums = [2 1	7	6	5	4	3	11	10	9	8	16	15	14 ...
        13	12	22	21	20	19	18	17	27	26	25	24	23	32	31	30	29 ...
        28	36	35	34	33	40	39	38	37	46	45	44	43	42	41	50	49 ...
        48	47	55	54	53	52	51	59	58	57	56	64	63	62	61	60];
elseif refType ==2
    mirror_elecNums = [ 4	3	2	1	6	5	14	13	12	11	10	9	8	7 ...
        22	21	20	19	18	17	16	15	30	29	28	27	26	25	24	23	38	...
        37	36	35	34	33	32	31	46	45	44	43	42	41	40	39	54	53	...
        52	51	50	49	48	47	63	62	61	60	59	58	57	56	55	73	72	...
        71	70	69	68	67	66	65	64	82	81	80	79	78	77	76	75	74	...
        90	89	88	87	86	85	84	83	99	98	97	96	95	94	93	92	91	...
        103	102	101	100	110	109	108	107	106	105	104	112	111];
end


mirrored_topoData = data(:,mirror_elecNums,:,:,:);
% for i = 1:size(data,1)
%         mirrored_topoData2(i,:) = data(i,mirror_elecNums);
% end
%
% for i = 1:size(data,1)
%     for j = 1:size(data,2)
%         mirrored_topoData(i,j) = data(i,mirror_elecNums(j));
%     end
% end

end

function plotStimDisks(hPlot,attLoc,ssvepFreqs)
stimDiskDistanceFromMidline = 0.01;
textStartPosGapFromMidline = 0.001;
ellipseYGap = 0.135;
ellipseWidth = 0.015;
ellipseHeight = 0.012;
textYGap = 0.145;
textWidth = 0.04;
textHeight = 0.0241;


AttendPlotPos = get(hPlot,'Position');
AttendPlotMidline = AttendPlotPos(1)+ AttendPlotPos(3)/2;
% YLine = annotation('line',[AttendPlotMidline AttendPlotMidline],[0.5 1]);
% YLine = annotation('line',[AttendPlotMidline- stimDiskDistanceFromMidline AttendPlotMidline- stimDiskDistanceFromMidline],[0.5 1]);
% YLine = annotation('line',[AttendPlotMidline+ stimDiskDistanceFromMidline AttendPlotMidline+ stimDiskDistanceFromMidline],[0.5 1]);
elpsL = annotation('ellipse',[AttendPlotMidline-ellipseWidth- stimDiskDistanceFromMidline AttendPlotPos(2)+ellipseYGap ellipseWidth ellipseHeight],'units','normalized');
elpsR = annotation('ellipse',[AttendPlotMidline + stimDiskDistanceFromMidline AttendPlotPos(2)+ellipseYGap ellipseWidth ellipseHeight]);

if attLoc==1
    elpsL.FaceColor = 'k'; elpsR.FaceColor = 'none';
elseif attLoc==2
    elpsL.FaceColor = 'none'; elpsR.FaceColor = 'k';
end

if ~isempty(ssvepFreqs)
annotation('textbox',[AttendPlotMidline-(textWidth+textStartPosGapFromMidline) AttendPlotPos(2)+textYGap textWidth textHeight],...
    'EdgeColor','none','String',[num2str(ssvepFreqs(1)) ' Hz'],'fontSize',10,'EdgeColor','none','FitBoxToText','on',...
    'HorizontalAlignment','center');

annotation('textbox',[AttendPlotMidline+textStartPosGapFromMidline AttendPlotPos(2)+textYGap textWidth textHeight],...
    'EdgeColor','none','String',[num2str(ssvepFreqs(2)) ' Hz'],'fontSize',10,...
    'EdgeColor','none','FitBoxToText','on','HorizontalAlignment','center');
end



end
