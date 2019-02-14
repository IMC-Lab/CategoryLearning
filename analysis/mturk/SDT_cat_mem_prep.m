function sortedStruct = SDT_cat_mem_prep(dataFile, rawData, versionIdx, needExperts, plot)
% prepare datasets for SDT fitting
% INPUT: rawData - retrieval matrix
%        versionIdx - Bayesian SDT model versions
%        needExperts - only include Ps whose last trial accuracy is above
%        75%
% OUTPUT: four columns are hit, false alarm, miss, and correct rejection rates for each
% subject. Each line is one subject.

if isempty(versionIdx)
   versionIdx = 1; 
end

if needExperts == 1
    isPlot = 0;
    isExpertRate = last20trials_accuracy(dataFile,isPlot);
    expertCrit   = 0.80;
    numSub = max(rawData.subject);
    tmpT = [];
    for i=1:numSub
        
        
        if isExpertRate(i)>=expertCrit
        tmpT = [tmpT;rawData(rawData.subject==i,:)];
        end
        
    end
    rawData = tmpT;
    numSub = sum(isExpertRate>=0.80);
    subIdx = find(isExpertRate>=0.80);
else
    numSub = max(rawData.subject);
    subIdx = 1:numSub;
end

numSub
% pre-allocation
learnedHits   = nan(numSub, 1);
learnedMisses = nan(numSub, 1);
learnedFAs    = nan(numSub, 1);
learnedCRs    = nan(numSub, 1);
unlearnedHits   = nan(numSub, 1);
unlearnedMisses = nan(numSub, 1);
unlearnedFAs    = nan(numSub, 1);
unlearnedCRs     = nan(numSub, 1);
neitherHits   = nan(numSub, 1);
neitherMisses = nan(numSub, 1);
neitherFAs    = nan(numSub, 1);
neitherCRs    = nan(numSub, 1);
bothHits    = nan(numSub, 1);
bothMisses  = nan(numSub, 1);
bothFAs     = nan(numSub, 1);
bothCRs     = nan(numSub, 1);

for ss = 1:numSub
    thisT = rawData(rawData.subject == subIdx(ss),:);
    
    learnedHits(ss)   = sum(thisT.isTarget == 1 & thisT.isFoil == 0 & thisT.isOld == 1 & thisT.wasCorrect == 1);
    learnedMisses(ss) = sum(thisT.isTarget == 1 & thisT.isFoil == 0 & thisT.isOld == 1 & thisT.wasCorrect == 0);
    learnedFAs(ss)    = sum(thisT.isTarget == 1 & thisT.isFoil == 0 & thisT.isOld == 0 & thisT.wasCorrect == 0);
    learnedCRs(ss)    = sum(thisT.isTarget == 1 & thisT.isFoil == 0 & thisT.isOld == 0 & thisT.wasCorrect == 1);
 
    unlearnedHits(ss)   = sum(thisT.isTarget == 0 & thisT.isFoil == 1 & thisT.isOld == 1 & thisT.wasCorrect == 1);
    unlearnedMisses(ss) = sum(thisT.isTarget == 0 & thisT.isFoil == 1 & thisT.isOld == 1 & thisT.wasCorrect == 0);
    unlearnedFAs(ss)    = sum(thisT.isTarget == 0 & thisT.isFoil == 1 & thisT.isOld == 0 & thisT.wasCorrect == 0);
    unlearnedCRs(ss)     = sum(thisT.isTarget == 0 & thisT.isFoil == 1 & thisT.isOld == 0 & thisT.wasCorrect == 1);
    
    neitherHits(ss)   = sum(thisT.isTarget == 0 & thisT.isFoil == 0 & thisT.isOld == 1 & thisT.wasCorrect == 1);
    neitherMisses(ss) = sum(thisT.isTarget == 0 & thisT.isFoil == 0 & thisT.isOld == 1 & thisT.wasCorrect == 0);
    neitherFAs(ss)    = sum(thisT.isTarget == 0 & thisT.isFoil == 0 & thisT.isOld == 0 & thisT.wasCorrect == 0);
    neitherCRs(ss)    = sum(thisT.isTarget == 0 & thisT.isFoil == 0 & thisT.isOld == 0 & thisT.wasCorrect == 1);
    
    bothHits(ss)    = sum(thisT.isTarget == 1 & thisT.isFoil == 1 & thisT.isOld == 1 & thisT.wasCorrect == 1);
    bothMisses(ss)  = sum(thisT.isTarget == 1 & thisT.isFoil == 1 & thisT.isOld == 1 & thisT.wasCorrect == 0);
    bothFAs(ss)     = sum(thisT.isTarget == 1 & thisT.isFoil == 1 & thisT.isOld == 0 & thisT.wasCorrect == 0);
    bothCRs(ss)     = sum(thisT.isTarget == 1 & thisT.isFoil == 1 & thisT.isOld == 0 & thisT.wasCorrect == 1);
end

sortedStruct.learnedHits = learnedHits;
sortedStruct.learnedMisses = learnedMisses;
sortedStruct.learnedFAs = learnedFAs;
sortedStruct.learnedCRs = learnedCRs;
sortedStruct.unlearnedHits = unlearnedHits;
sortedStruct.unlearnedMisses = unlearnedMisses;
sortedStruct.unlearnedFAs = unlearnedFAs;
sortedStruct.unlearnedCRs = unlearnedCRs;
sortedStruct.neitherHits = neitherHits;
sortedStruct.neitherMisses = neitherMisses;
sortedStruct.neitherFAs = neitherFAs;
sortedStruct.neitherCRs = neitherCRs;
sortedStruct.bothHits = bothHits;
sortedStruct.bothMisses = bothMisses;
sortedStruct.bothFAs = bothFAs;
sortedStruct.bothCRs = bothCRs;

if versionIdx == 2
    save('/Users/Saoirse/Dropbox/Duke/De Brigard lab/[2]Categorization/Data/SDT_sortedData.mat',...
        'learnedSet','unlearnedSet','neitherSet','bothSet');
end

%% plot hit and FA rates
font_size = 15;
line_width = 1.7;

datasetLabels = {'Learned','Unlearned','Neither','Both'};

% hit rate = # hits / (# hits + # misses)
% FA rate = # FAs / (# FAs + # correct rejections)
learnedHitRates = learnedHits./(learnedHits+learnedMisses);
learnedFARates  = learnedFAs./(learnedFAs+learnedCRs);

unlearnedHitRates = unlearnedHits./(unlearnedHits+unlearnedMisses);
unlearnedFARates  = unlearnedFAs./(unlearnedFAs+unlearnedCRs);

neitherHitRates = neitherHits./(neitherHits+neitherMisses);
neitherFARates  = neitherFAs./(neitherFAs+neitherCRs);

bothHitRates = bothHits./(bothHits+bothMisses);
bothFARates  = bothFAs./(bothFAs+bothCRs);

sortedStruct.learnedHitRate = learnedHitRates;
sortedStruct.learnedFARate = learnedFARates;
sortedStruct.unlearnedHitRate = unlearnedHitRates;
sortedStruct.unlearnedFARate = unlearnedFARates;
sortedStruct.neitherHitRate = neitherHitRates;
sortedStruct.neitherFARate = neitherFARates;
sortedStruct.bothHitRate = bothHitRates;
sortedStruct.bothFARate = bothFARates;

if plot
    figure;
    subplot(1,2,1)
    % HIT
    meanVec = [mean(learnedHitRates),mean(unlearnedHitRates),mean(neitherHitRates),mean(bothHitRates)];
    errorVec = [std(learnedHitRates),std(unlearnedHitRates),std(neitherHitRates),std(bothHitRates)]./sqrt(numSub);
    errorbar(meanVec,errorVec,'k.','LineWidth',line_width)
    hold on
    bar(meanVec)
    xticks(1:4)
    xticklabels(datasetLabels)
    xtickangle(45)
    ylim([0 0.8])
    title('Hit rate')
    set(gca,'FontSize',font_size)

    subplot(1,2,2)
    % False alarm
    meanVec = [mean(learnedFARates),mean(unlearnedFARates),mean(neitherFARates),mean(bothFARates)];
    errorVec = [std(learnedFARates),std(unlearnedFARates),std(neitherFARates),std(bothFARates)]./sqrt(numSub);
    errorbar(meanVec,errorVec,'k.','LineWidth',line_width)
    hold on
    bar(meanVec)
    xticks(1:4)
    xticklabels(datasetLabels)
    xtickangle(45)
    ylim([0 0.8])
    title('False alarm rate')
    set(gca,'FontSize',font_size)
end
