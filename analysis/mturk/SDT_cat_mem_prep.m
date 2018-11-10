function sortedStruct = SDT_cat_mem_prep(dataFile,rawData,versionIdx,needExperts)

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

% preallocation
learnedSet   = nan(numSub,4);
unlearnedSet = nan(numSub,4);
neitherSet   = nan(numSub,4);
bothSet      = nan(numSub,4);

for ss = 1:numSub
    thisT = rawData(rawData.subject == subIdx(ss),:);
    
    learnedSet(ss,1) = sum(thisT.isTarget == 1 & thisT.isFoil == 0 & thisT.isOld == 1 & thisT.wasCorrect == 1);% hit
    learnedSet(ss,2) = sum(thisT.isTarget == 1 & thisT.isFoil == 0 & thisT.isOld == 1 & thisT.wasCorrect == 0);% miss
    learnedSet(ss,3) = sum(thisT.isTarget == 1 & thisT.isFoil == 0 & thisT.isOld == 0 & thisT.wasCorrect == 0);% false alarm
    learnedSet(ss,4) = sum(thisT.isTarget == 1 & thisT.isFoil == 0 & thisT.isOld == 0 & thisT.wasCorrect == 1);% correct rejection
 
    unlearnedSet(ss,1) = sum(thisT.isTarget == 0 & thisT.isFoil == 1 & thisT.isOld == 1 & thisT.wasCorrect == 1);% hit
    unlearnedSet(ss,2) = sum(thisT.isTarget == 0 & thisT.isFoil == 1 & thisT.isOld == 1 & thisT.wasCorrect == 0);% miss
    unlearnedSet(ss,3) = sum(thisT.isTarget == 0 & thisT.isFoil == 1 & thisT.isOld == 0 & thisT.wasCorrect == 0);% false alarm
    unlearnedSet(ss,4) = sum(thisT.isTarget == 0 & thisT.isFoil == 1 & thisT.isOld == 0 & thisT.wasCorrect == 1);% correct rejection
    
    neitherSet(ss,1) = sum(thisT.isTarget == 0 & thisT.isFoil == 0 & thisT.isOld == 1 & thisT.wasCorrect == 1);% hit
    neitherSet(ss,2) = sum(thisT.isTarget == 0 & thisT.isFoil == 0 & thisT.isOld == 1 & thisT.wasCorrect == 0);% miss
    neitherSet(ss,3) = sum(thisT.isTarget == 0 & thisT.isFoil == 0 & thisT.isOld == 0 & thisT.wasCorrect == 0);% false alarm
    neitherSet(ss,4) = sum(thisT.isTarget == 0 & thisT.isFoil == 0 & thisT.isOld == 0 & thisT.wasCorrect == 1);% correct rejection
    
    bothSet(ss,1) = sum(thisT.isTarget == 1 & thisT.isFoil == 1 & thisT.isOld == 1 & thisT.wasCorrect == 1);% hit
    bothSet(ss,2) = sum(thisT.isTarget == 1 & thisT.isFoil == 1 & thisT.isOld == 1 & thisT.wasCorrect == 0);% miss
    bothSet(ss,3) = sum(thisT.isTarget == 1 & thisT.isFoil == 1 & thisT.isOld == 0 & thisT.wasCorrect == 0);% false alarm
    bothSet(ss,4) = sum(thisT.isTarget == 1 & thisT.isFoil == 1 & thisT.isOld == 0 & thisT.wasCorrect == 1);% correct rejection
end

sortedStruct.learnedSet = learnedSet;
sortedStruct.unlearnedSet = unlearnedSet;
sortedStruct.neitherSet = neitherSet;
sortedStruct.bothSet = bothSet;

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
learnedHitRates = learnedSet(:,1)./(learnedSet(:,1)+learnedSet(:,2));
learnedFARates  = learnedSet(:,3)./(learnedSet(:,3)+learnedSet(:,4));

unlearnedHitRates = unlearnedSet(:,1)./(unlearnedSet(:,1)+unlearnedSet(:,2));
unlearnedFARates  = unlearnedSet(:,3)./(unlearnedSet(:,3)+unlearnedSet(:,4));

neitherHitRates = neitherSet(:,1)./(neitherSet(:,1)+neitherSet(:,2));
neitherFARates  = neitherSet(:,3)./(neitherSet(:,3)+neitherSet(:,4));

bothHitRates = bothSet(:,1)./(bothSet(:,1)+bothSet(:,2));
bothFARates  = bothSet(:,3)./(bothSet(:,3)+bothSet(:,4));

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

