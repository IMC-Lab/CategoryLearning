#!/usr/bin/Rscript
library(psycho)  # used for SDT analysis
library(lme4)

# both blocks of flowers/insects
flowerFile <- 'data/flower_E5_old_first.csv'
insectFile <- 'data/insect_E5_old_first.csv'

args <- commandArgs(trailingOnly=T)
if (length(args) < 1) {
    args <- c(flowerFile, insectFile)
}

categoryName <- function(isTarget, isFoil) {
    if (isTarget & isFoil) {
        return('both')
    } else if (isTarget) {
        return('learned')
    } else if (isFoil) {
        return('unlearned')
    } else {
        return('neither')
    }
}

memoryData <- function(filename) {
    # read the raw data from the csv
    data <- subset(read.csv(filename, header=T),
		   task=='test', select=c(subject, isTarget, isFoil, isOld, wasCorrect))

    # count the number of correct/incorrect trials for each condition
    nCorrect <- aggregate(wasCorrect ~ subject + isTarget + isFoil + isOld, data, sum)$wasCorrect
    nIncorrect <- aggregate(wasCorrect ~ subject + isTarget + isFoil + isOld, data,
                            function(x) sum(x==0))$wasCorrect
    
    # average performance for each subject for each trial type
    data <- aggregate(wasCorrect ~ subject + isTarget + isFoil + isOld, data, mean)
    data$wasIncorrect <- apply(data, 1, function(x) 1-x['wasCorrect']);
    data$nCorrect <- nCorrect
    data$nIncorrect <- nIncorrect        
    
    data$isTarget <- as.numeric(data$isTarget)
    data$isFoil <- as.numeric(data$isFoil)
    data$isOld <- as.numeric(data$isOld)
    
    # rate is for hits (on old trials) and FAs (on new trials)
    data$rate <- apply(data, 1, function(x) ifelse(x['isOld'], x['wasCorrect'], x['wasIncorrect']))
    data$category <- as.factor(apply(data, 1, function(x) categoryName(x['isTarget'], x['isFoil'])))
    data$subject <- as.factor(data$subject)
    data$isTarget <- as.factor(data$isTarget)
    data$isFoil <- as.factor(data$isFoil)
    
    return(data)
}

# estimates SDT measures of sensitivity & bias for each subject/condition
runSDT <- function(data) {    
    # group the old/new stimuli by subject and condition
    data <- merge(subset(data, isOld==1),
                  subset(data, isOld==0),
                  sort=F,
                  by=c('subject', 'isTarget', 'isFoil'),
                  suffixes=c('.old', '.new'))
    write.csv(data, 'sdt.csv')
    
    # get sensitivty & bias for each subject on each condition
    indices <- psycho::dprime(data$nCorrect.old, data$nIncorrect.new,
                              data$nIncorrect.old, data$nCorrect.new)
    sdtData <- cbind(data, indices)
    
    # analyze sensitivity (dprime)
    writeLines('\n\nSensitivity (dprime)')
    print(tapply(sdtData$dprime, list(sdtData$isTarget, sdtData$isFoil), mean))
    print(summary(aov(dprime ~ isTarget * isFoil + Error(subject/(isTarget*isFoil)), data=sdtData)))

    # analyze bias (c)
    writeLines('\n\nBias (C)')
    print(tapply(sdtData$c, list(sdtData$isTarget, sdtData$isFoil), mean))
    print(summary(aov(c ~ isTarget * isFoil + Error(subject/(isTarget*isFoil)), data=sdtData)))
    
    return(sdtData)
}

analyze <- function(data) {
    # Run the ANOVA as 2x2 (isLearned x isFoil)
    print(tapply(data$rate, list(data$isTarget, data$isFoil), mean))
    print(summary(aov(rate ~ isTarget * isFoil + Error(subject/(isTarget*isFoil)), data=data)))
}


# analyze data from each file
for (i in 1:length(args)) {
    filename <- args[i]
    writeLines(args[i])

    memData <- subset(read.csv(filename, header=T), task=='test' & isOld==0,
                      select=c('subject', 'isTarget', 'isFoil', 'wasCorrect', 'isOld'))
    memData$subject <- factor(memData$subject)
    memData$isTarget <- factor(memData$isTarget)
    memData$isFoil <- factor(memData$isFoil)
    memData$wasCorrect <- factor(memData$wasCorrect)
    
    print(head(memData))
    model <- glmer(wasCorrect ~ isTarget * isFoil
                   + (1 + isTarget|subject) + (1 + isFoil|subject),
                   data=memData, family=binomial(link='logit'))
    print(summary(model))
    quit()
    
    #data <- memoryData(filename)    
    #hits <- subset(data, isOld==1)
    #FAs  <- subset(data, isOld==0)   
    #writeLines('\n\nHits')
    #analyze(hits)
    #writeLines('\n\nFAs')
    #analyze(FAs)

    #sdtData <- runSDT(data)
    #writeLines('\n\n\n\n\n')
    #write.csv(sdtData, 'sdt.csv')
}
