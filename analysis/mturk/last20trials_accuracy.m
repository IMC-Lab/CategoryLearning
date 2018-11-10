function isExpertRate = last20trials_accuracy(dataFiles,isPlot)
whichstage = 1;
if ischar(dataFiles)
    dataFiles = {dataFiles};
end
    
for index = length(dataFiles)
    dataFile = dataFiles{index};
    thisT = categ_data_extraction(dataFile,whichstage);
    numSub = max(thisT.subject);
    last20AccVec = nan(1,numSub);
    for ss = 1:numSub
        thisSubT = thisT(thisT.subject==ss,:);
        last20AccVec(1,ss)=sum(thisSubT.wasCorrect(end-19:end))/20;
    end
    
    if isPlot == 1
        if index==1
            figure(1);
        end
        
        subplot(2,2,index)
        histogram(last20AccVec)
        set(gca,'FontSize',15)
        if index == 1
            title('flower1 - last 20 trials')
        elseif index == 2
            title('insect2')
        elseif index == 3
            title('insect1')
        elseif index == 4
            title('flower2')
        end
    end
end

if ~isempty(dataFiles)
    isExpertRate = last20AccVec';
end