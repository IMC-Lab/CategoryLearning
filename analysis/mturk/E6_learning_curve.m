whichstage = 1;
numLrnTrs = [72];
dataFiles = {'cat_20190205_flower_E6.csv'};

figure;

for index = 1:length(dataFiles)
    dataFile = dataFiles{index};
    lrnT = categ_data_extraction(dataFile,whichstage);
    
    % only take trials for participants that practiced during learning
    lrnT = lrnT(lrnT.isPracticed == 1,:);
    
    for instructed = 0:1
        disp(instructed)
        data = lrnT(lrnT.isInstructed == instructed,:);
        numSub = length(unique(data.subject));
        learnRates = nan(1,numLrnTrs(index));
        
        for tr = 1:numLrnTrs(index)
            thisPhase = data(tr:numLrnTrs(index):end,:);
            learnRates(1,tr) = sum(thisPhase.wasCorrect)./numSub;
        end
        
        subplot(2,1,instructed+1)
        plot(learnRates,'k','LineWidth',1.7)
        xlim([1 numLrnTrs(index)])
        ylim([0 1])
        set(gca,'FontSize',15)
        
        str = 'instructed_';
        if instructed == 0
            str = 'not_instructed_';
        end
        title([str, dataFile], 'Interpreter', 'none')
    end
end
