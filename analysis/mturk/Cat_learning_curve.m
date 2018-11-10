whichstage = 1;
numLrnTrs = 72;
dataFiles = {'cat_20181110_flower_E5.csv', 'cat_20181110_insect_E5.csv'};

figure;

for index = 1:length(dataFiles)
    dataFile = dataFiles{index};
    lrnT = categ_data_extraction(dataFile,whichstage);
    
    numSub = max(lrnT.subject);
    learnRates = nan(1,numLrnTrs);
    for tr = 1:numLrnTrs
        thisPhase = lrnT(tr:numLrnTrs:end,:);
        learnRates(1,tr) = sum(thisPhase.wasCorrect)./numSub;
    end
    
    subplot(2,1,index)
    plot(learnRates,'k','LineWidth',1.7)
    xlim([1 numLrnTrs])
    ylim([0 1])
    set(gca,'FontSize',15)
    title(dataFile, 'Interpreter', 'none')
end