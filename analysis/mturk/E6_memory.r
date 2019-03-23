#!/usr/bin/Rscript
library(psycho)  # used for SDT analysis
library(ggplot2)
library(plyr)
library(lmerTest)

default_filename <- 'data/cat_20190205_flower_E6.csv'

# accept a filename as an optional command-line argument
args <- commandArgs(trailingOnly=T)
if (length(args) < 1) {
    args <- c(default_filename)
}

# estimates SDT measures of sensitivity & bias for each subject/condition
runSDT <- function(data) {
    # count the number of correct/incorrect trials for each condition
    nIncorrect <- aggregate(wasCorrect ~ subject+isInstructed+isPracticed+isTarget+isFoil+isOld, data,
                            function(x) sum(x==0))$wasCorrect
    data <- aggregate(wasCorrect ~ subject+isInstructed+isPracticed+isTarget+isFoil+isOld, data, sum)
    data$nCorrect <- data$wasCorrect
    data$nIncorrect <- nIncorrect
    
    # group the old/new stimuli by subject and condition
    data <- merge(subset(data, isOld==1), subset(data, isOld==0), sort=F,
                  by=c('subject', 'isInstructed', 'isPracticed', 'isTarget', 'isFoil'),
                  suffixes=c('.old', '.new'))
    write.csv(data, 'sdt.csv')
    
    # get sensitivty & bias for each subject on each condition
    indices <- psycho::dprime(data$nCorrect.old, data$nIncorrect.new,
                              data$nIncorrect.old, data$nCorrect.new)
    sdtData <- cbind(data, indices)
    
    # analyze sensitivity (dprime)
    writeLines('\n\nSensitivity (dprime)')
    #print(ddply(sdtData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
    #            N=length(dprime), sensitivity=mean(dprime), sd=sd(dprime), se=(sd/sqrt(N))))
    #print(ddply(sdtData, c("isPracticed", "isInstructed"), summarise,
    #            N=length(dprime), sensitivity=mean(dprime), sd=sd(dprime), se=(sd/sqrt(N))))
    #print(ddply(sdtData, c("isTarget", "isFoil"), summarise,
    #            N=length(dprime), sensitivity=mean(dprime), sd=sd(dprime), se=(sd/sqrt(N))))
    print(summary(lmer(dprime ~ isInstructed*isPracticed*isTarget*isFoil + (1|subject), data=sdtData)))
    
    # analyze bias (c)
    writeLines('\n\nBias (C)')
    #print(ddply(sdtData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
    #            N=length(c), bias=mean(c), sd=sd(c), se=(sd/sqrt(N))))
    #print(ddply(sdtData, c("isPracticed", "isInstructed"), summarise,
    #            N=length(c), bias=mean(c), sd=sd(c), se=(sd/sqrt(N))))
    #print(ddply(sdtData, c("isTarget", "isFoil"), summarise,
    #            N=length(c), bias=mean(c), sd=sd(c), se=(sd/sqrt(N))))
    print(summary(lmer(c ~ isInstructed*isPracticed*isTarget*isFoil + (1|subject), data=sdtData)))
    
    return(sdtData)
}

analyze <- function(data) {
    # Run the ANOVA as 2x2 (isLearned x isFoil)
    #print(ddply(data, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
    #            N=length(wasCorrect), mean=mean(wasCorrect), sd=sd(wasCorrect), se=(sd/sqrt(N))))
    #print(ddply(data, c("isPracticed", "isInstructed"), summarise,
    #            N=length(wasCorrect), mean=mean(wasCorrect), sd=sd(wasCorrect), se=(sd/sqrt(N))))
    #print(ddply(data, c("isTarget", "isFoil"), summarise,
    #            N=length(wasCorrect), mean=mean(wasCorrect), sd=sd(wasCorrect), se=(sd/sqrt(N))))
    print(summary(glmer(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil
                        + (1|subject), data=data, family=binomial(link='logit'))))
}

# analyze data from each file
for (i in 1:length(args)) {
    filename <- args[i]
    writeLines(args[i])
    
    memData <- subset(read.csv(filename, header=T), task=='test',
                      select=c('subject', 'isPracticed', 'isInstructed',
                               'isTarget', 'isFoil', 'isOld', 'wasCorrect', 'RT'))
    print(length(unique(memData$subject)))
    meanRT = mean(memData$RT)
    sdRT = sd(memData$RT)
    exclude = (memData$RT > (meanRT+3*sdRT)) | (memData$RT < (meanRT-3*sdRT))
    #memData <- memData[!exclude,]
    excludedSubjects = unique(memData$subject[exclude])
    memData <- memData[!(memData$subject %in% excludedSubjects),]
    print(length(unique(memData$subject)))
    #quit()
    
    # exclude subjects with low learning accuracy
    learnData <- subset(read.csv(filename, header=T), task=='learn' & isPracticed==1)
    nTrials <- nrow(subset(learnData, subject==learnData$subject[1]))
    nSubj <- length(unique(learnData$subject))
    learnData$trialNum <- rep(1:nTrials, times=nSubj)
    startAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                         function (trials) mean(head(trials, 20)))
    endAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                         function (trials) mean(tail(trials, 20)))
    print(mean(subset(startAcc, isInstructed==1)$wasCorrect))
    print(mean(subset(endAcc, isInstructed==1)$wasCorrect))
    print(mean(subset(startAcc, isInstructed==0)$wasCorrect))
    print(mean(subset(endAcc, isInstructed==0)$wasCorrect))
    
    excludedSubjects <- unique(endAcc$subject[endAcc$wasCorrect < 0.85])
    memData <- memData[!(memData$subject %in% excludedSubjects),]
        
    print(length(unique(memData$subject)))
    #quit()
    writeLines('\n\nRT')
    #print(ddply(memData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
    #            mean=mean(RT), sd=sd(RT), se=(sd/sqrt(length(RT)))))
    #print(ddply(memData, c("isPracticed", "isInstructed"), summarise,
    #            mean=mean(RT), sd=sd(RT), se=(sd/sqrt(length(RT)))))
    #print(ddply(memData, c("isTarget", "isFoil"), summarise,
    #            mean=mean(RT), sd=sd(RT), se=(sd/sqrt(length(RT)))))
    print(summary(lmer(RT ~ isPracticed*isInstructed*isTarget*isFoil + (1|subject), data=memData)))
    
    hits <- subset(memData, isOld==1)
    FAs  <- subset(memData, isOld==0)   
    writeLines('\n\nHits')
    analyze(hits)
    writeLines('\n\nFAs')
    analyze(FAs)

    sdtData <- runSDT(memData)
    writeLines('\n\n\n\n\n')
    write.csv(sdtData, 'sdt.csv')
    
    # plot interaction plots
    png('E6_RT.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(memData, c('subject'), summarise, subjAvg=mean(RT))
    condAvgs <- ddply(memData, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(RT))
    memData$RT <- apply(memData, 1, function (x) as.numeric(x['RT'])
                        - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                        + subset(condAvgs, isPracticed == x['isPracticed']
                                 & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(memData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(RT), rt=mean(RT), sd=sd(RT), se=(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=rt, color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=rt-se, ymax=rt+se), width=.2) +
          geom_line(size=2) + theme_classic())
    dev.off()
    
    png('E6_hits.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(hits, c('subject'), summarise, subjAvg=mean(wasCorrect))
    condAvgs <- ddply(hits, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(wasCorrect))
    hits$wasCorrect <- apply(hits, 1, function (x) as.numeric(x['wasCorrect'])
                             - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                             + subset(condAvgs, isPracticed == x['isPracticed']
                                      & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(hits, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(wasCorrect), hits=mean(wasCorrect), sd=sd(wasCorrect), se=(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=hits, color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=hits-se, ymax=hits+se), width=.2) +
          geom_line(size=2) + theme_classic())
    dev.off()
    
    
    png('E6_FAs.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    FAs$wasCorrect <- 1-FAs$wasCorrect
    subjAvgs <- ddply(FAs, c('subject'), summarise, subjAvg=mean(wasCorrect))
    condAvgs <- ddply(FAs, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(wasCorrect))
    FAs$wasCorrect <- apply(FAs, 1, function (x) as.numeric(x['wasCorrect'])
                            - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                            + subset(condAvgs, isPracticed == x['isPracticed']
                                     & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(FAs, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(wasCorrect), FAs=mean(wasCorrect),
                       sd=sd(wasCorrect), se=(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=FAs, color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=FAs-se, ymax=FAs+se), width=.2) +
          geom_line(size=2) + theme_classic())
    dev.off()
    
    png('E6_sensitivity.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(sdtData, c('subject'), summarise, subjAvg=mean(dprime))
    condAvgs <- ddply(sdtData, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(dprime))
    sdtData$dprime <- apply(sdtData, 1, function (x) as.numeric(x['dprime'])
                            - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                            + subset(condAvgs, isPracticed == x['isPracticed']
                                     & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(sdtData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(dprime), sensitivity=mean(dprime), sd=sd(dprime), se=(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=sensitivity,
              color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=sensitivity-se, ymax=sensitivity+se), width=.2) +
          geom_line(size=2) + theme_classic())
    dev.off()
    
    png('E6_bias.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(sdtData, c('subject'), summarise, subjAvg=mean(c))
    condAvgs <- ddply(sdtData, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(c))
    sdtData$c <- apply(sdtData, 1, function (x) as.numeric(x['c'])
                       - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                       + subset(condAvgs, isPracticed == x['isPracticed']
                                & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(sdtData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(c), bias=mean(c), sd=sd(c), se=(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=bias,
              color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=bias-se, ymax=bias+se), width=.2) +
          geom_line(size=2) + theme_classic())
    dev.off()
}
