whichstage = 1;
numLrnTrs = [72];
conditions = [0, 6000];
dataFiles = {'cat_20190321_turtle_feedback.csv'};

figure;

for index = 1:length(dataFiles)
    dataFile = dataFiles{index};
    lrnT = categ_data_extraction(dataFile,whichstage);
        
    for condition = 1:2
        disp(condition)
        data = lrnT(lrnT.condition == conditions(condition),:);
        numSub = length(unique(data.subject));
        learnRates = nan(1,numLrnTrs(index));
        
        for tr = 1:numLrnTrs(index)
            thisPhase = data(tr:numLrnTrs(index):end,:);
            learnRates(1,tr) = sum(thisPhase.wasCorrect)./numSub;
        end
        
        subplot(2,1,condition)
        plot(learnRates,'k','LineWidth',1.7)
        xlim([1 numLrnTrs(index)])
        ylim([0 1])
        set(gca,'FontSize',15)
        
        str = 'Delay = 0s';
        if condition > 1
            str = 'Delay = 6s';
        end
        title(str, 'Interpreter', 'none')
    end
end
