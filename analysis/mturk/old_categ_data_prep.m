function old_categ_data_prep(dataFolderPrefix)

numExperiments = 1;
currDate = datestr(datetime('today'),'yyyymmdd');
dataPath = 'data/raw/';
outPath = 'data/';

%% open file
catlog = fopen([outPath,'cat_',currDate,'_',dataFolderPrefix,'_old.csv'],'w');
if contains(dataFolderPrefix, 'flower', 'IgnoreCase', true)
    featureSet = {'numPetal', 'petalColor', 'centerShape', 'centerColor', 'numSepal'};
    featVStr = '%d,%s,%s,%s,%d,';
    fprintf(catlog,'subject,experimentNumber,task,featureLearned,valueLearned,featureFoil,valueFoil,numPetal,petalColor,centerShape,centerColor,numSepal,isTarget,isFoil,wasCorrect,RT,isOld\n');
elseif contains(dataFolderPrefix, 'insect','IgnoreCase',true)
    featVStr = '%d,%s,%s,%d,%s,';
    featureSet = {'segment_count', 'segment_shape', 'wing_color', 'antennae_count', 'antennae_color'};
    fprintf(catlog,'subject,experimentNumber,task,featureLearned,valueLearned,featureFoil,valueFoil,segmentCount,segmentShape,wingColor,antennaeCount,antennaeColor,isTarget,isFoil,wasCorrect,RT,isOld\n');
end

subjectNum = 1;
for expNum = 1:numExperiments
    %% read in data
    dataFolder = [dataFolderPrefix, '_', num2str(expNum)];
    catlisting = dir([dataPath, dataFolder, '/*.txt']);
    numSub = length(catlisting);
    %% extract data
    for sbj = 1:numSub
        filename = catlisting(sbj).name;
        datafile = fileread([dataPath, dataFolder, '/', filename]);
        catS     = jsondecode(datafile);

        if isfield(catS,{'itemsForCategorization'})
        %     expOrder
        numCat = length(catS.itemsForCategorization);
        numEnc = length(catS.itemsForEncoding);
        numRet = length(catS.itemsForRetrieval);
        totTrs = numCat + numEnc + numRet;

        for tr = 1:totTrs
            if tr <= numCat
                taskStr = 'learn';
                for fIdx = 1:length(featureSet)
                    eval(['fV',num2str(fIdx),' = catS.itemsForCategorization(catS.orderCategorization(tr)+1).object.',featureSet{fIdx},';']);
                end
                thisIsTaget = catS.itemsForCategorization(catS.orderCategorization(tr)+1).isTarget;
                thisIsFoil  = catS.itemsForCategorization(catS.orderCategorization(tr)+1).isFoil;
                thisWasCorrect = catS.itemsForCategorization(catS.orderCategorization(tr)+1).wasCorrect;
                thisRT      = catS.itemsForCategorization(catS.orderCategorization(tr)+1).RT;
                thisIsOld   = -1;
            elseif tr > numCat && tr <= (numCat + numEnc)
                taskStr = 'study';
                for fIdx = 1:length(featureSet)
                    eval(['fV',num2str(fIdx),' = catS.itemsForEncoding(catS.orderEncoding(tr-numCat)+1).object.',featureSet{fIdx},';']);
                end
                thisIsTaget = catS.itemsForEncoding(catS.orderEncoding(tr-numCat)+1).isTarget;
                thisIsFoil  = catS.itemsForEncoding(catS.orderEncoding(tr-numCat)+1).isFoil;
                thisWasCorrect = -1;
                thisRT      = -1;
                thisIsOld   = -1;
            else
                taskStr = 'test';
                for fIdx = 1:length(featureSet)
                    eval(['fV',num2str(fIdx),' = catS.itemsForRetrieval{catS.orderRetrieval(tr-numCat-numEnc)+1,1}.object.',featureSet{fIdx},';']);
                end
                thisIsTaget = catS.itemsForRetrieval{catS.orderRetrieval(tr-numCat-numEnc)+1,1}.isTarget;
                thisIsFoil  = catS.itemsForRetrieval{catS.orderRetrieval(tr-numCat-numEnc)+1,1}.isFoil;
                thisWasCorrect = catS.itemsForRetrieval{catS.orderRetrieval(tr-numCat-numEnc)+1,1}.wasCorrect;
                thisRT      = catS.itemsForRetrieval{catS.orderRetrieval(tr-numCat-numEnc)+1,1}.RT;
                thisIsOld   = catS.itemsForRetrieval{catS.orderRetrieval(tr-numCat-numEnc)+1,1}.isOld;
            end

            if contains(dataFolder, 'flower','IgnoreCase',true)
                fV1 = str2double(fV1);
                fV5 = str2double(fV5);
            elseif contains(dataFolder, 'insect','IgnoreCase',true)
                fV1 = str2double(fV1);
                fV4 = str2double(fV4);
            end

            fprintf(catlog,['%d,%d,%s,%d,%d,%d,%d,',featVStr,'%d,%d,%d,%d,%d\n'],...
                subjectNum,expNum,taskStr,catS.featuredLearned,catS.valueLearned,catS.featureFoil,catS.valueFoil,...
                fV1,fV2,fV3,fV4,fV5,thisIsTaget,thisIsFoil,thisWasCorrect,thisRT,thisIsOld);

        end
        end
        subjectNum = subjectNum + 1;
    end
end
fclose(catlog)
