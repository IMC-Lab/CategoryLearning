whichstage = 1;
numLrnTrs = [54];
dataFiles = {'cat_20190118_flower_E6.csv'};

figure;

for index = 1:length(dataFiles)
    dataFile = dataFiles{index};
    lrnT = categ_data_extraction(dataFile,whichstage);
    
    numSub = max(lrnT.subject);
    learnRates = nan(1,numLrnTrs(index));
    for tr = 1:numLrnTrs(index)
        thisPhase = lrnT(tr:numLrnTrs(index):end,:);
        learnRates(1,tr) = sum(thisPhase.wasCorrect)./numSub;
    end
    disp(learnRates)
%     subplot(1,1,index)
    plot(learnRates,'k','LineWidth',1.7)
    xlim([1 numLrnTrs(index)])
    ylim([0 1])
    set(gca,'FontSize',15)
    title(dataFile, 'Interpreter', 'none')
end