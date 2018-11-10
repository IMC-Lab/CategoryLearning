function categ_data_prep(dataFolder)

expOrder = -1; %!!!!change accordingly!!!%
numFeature = 5;
currDate = datestr(datetime('today'),'yyyymmdd');
dataPath = 'data/raw/';
outPath = 'data/';

%% read in data
catlisting = dir([dataPath, dataFolder, '/*.txt']);
numSub = length(catlisting);

%% open file
catlog = fopen([outPath,'cat_',currDate,'_',dataFolder,'.csv'],'w');
if contains(dataFolder, 'flower', 'IgnoreCase', true)
    featureSet = {'numPetal', 'petalColor', 'centerShape', 'centerColor', 'numSepal'};
    featVStr = '%d\t %s\t %s\t %s\t %d\t ';
    fprintf(catlog,'subject\t expOrder\t task\t featureLearned\t valueLearned\t featureFoil\t valueFoil\t numPetal\t petalColor\t centerShape\t centerColor\t numSepal\t isTarget\t isFoil\t wasCorrect\t RT\t isOld\n');
elseif contains(dataFolder, 'insect','IgnoreCase',true)
    featVStr = '%d\t %s\t %s\t %d\t %s\t ';
    featureSet = {'segment_count', 'segment_shape', 'wing_color', 'antennae_count', 'antennae_color'};
    fprintf(catlog,'subject\t expOrder\t task\t featureLearned\t valueLearned\t featureFoil\t valueFoil\t segmentCount\t segmentShape\t wingColor\t antennaeCount\t antennaeColor\t isTarget\t isFoil\t wasCorrect\t RT\t isOld\n');
end

%% extract data
for sbj = 1:numSub
    
    filename = catlisting(sbj).name;
    datafile = fileread([dataPath, dataFolder, '/', filename]);
    catS     = jsondecode(datafile);
    
    if isfield(catS,{'itemsForLearning'})
    %     expOrder
    numCat = length(catS.itemsForLearning);
    numEnc = length(catS.itemsForStudy);
    numRet = length(catS.itemsForTest);
    totTrs = numCat + numEnc + numRet;
    
    for tr = 1:totTrs
        if tr <= numCat
            taskStr = 'learn';
            for fIdx = 1:numFeature
                eval(['fV',num2str(fIdx),' = catS.itemsForLearning(tr).object.',featureSet{fIdx},';']);
            end
            thisIsTaget = catS.itemsForLearning(tr).isTarget;
            thisIsFoil  = catS.itemsForLearning(tr).isFoil;
            thisWasCorrect = catS.itemsForLearning(tr).wasCorrect;
            thisRT      = catS.itemsForLearning(tr).RT;
            thisIsOld   = -1;
        elseif tr > numCat && tr <= (numCat + numEnc)
            taskStr = 'study';
            for fIdx = 1:numFeature
                eval(['fV',num2str(fIdx),' = catS.itemsForStudy(tr-numCat).object.',featureSet{fIdx},';']);
            end
            thisIsTaget = catS.itemsForStudy(tr-numCat).isTarget;
            thisIsFoil  = catS.itemsForStudy(tr-numCat).isFoil;
            thisWasCorrect = -1;
            thisRT      = -1;
            thisIsOld   = -1;
        else
            taskStr = 'test';
            for fIdx = 1:numFeature
                eval(['fV',num2str(fIdx),' = catS.itemsForTest{tr-numCat-numEnc,1}.object.',featureSet{fIdx},';']);
            end
            thisIsTaget = catS.itemsForTest{tr-numCat-numEnc,1}.isTarget;
            thisIsFoil  = catS.itemsForTest{tr-numCat-numEnc,1}.isFoil;
            thisWasCorrect = catS.itemsForTest{tr-numCat-numEnc,1}.wasCorrect;
            thisRT      = catS.itemsForTest{tr-numCat-numEnc,1}.RT;
            thisIsOld   = catS.itemsForTest{tr-numCat-numEnc,1}.isOld;
        end
        
        if contains(dataFolder, 'flower','IgnoreCase',true)
            fV1 = str2double(fV1);
            fV5 = str2double(fV5);
        elseif contains(dataFolder, 'insect','IgnoreCase',true)
            fV1 = str2double(fV1);
            fV4 = str2double(fV4);
        end
        
        fprintf(catlog,['%d\t %d\t %s\t %s\t %s\t %s\t %s\t ',featVStr,'%d\t %d\t %d\t %d\t %d\n'],...
            sbj,expOrder,taskStr,catS.featuredLearned,catS.valueLearned,catS.featureFoil,catS.valueFoil,...
            fV1,fV2,fV3,fV4,fV5,thisIsTaget,thisIsFoil,thisWasCorrect,thisRT,thisIsOld);
        
    end
    end
end
fclose(catlog)
