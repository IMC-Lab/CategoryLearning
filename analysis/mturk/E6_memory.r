#!/usr/bin/Rscript
library(psycho)  # used for SDT analysis
library(ggplot2)
library(lmerTest)
library(plyr)
library(dplyr)

source('summary.r')

default_filename <- 'data/cat_20190205_flower_E6.csv'

# accept a filename as an optional command-line argument
args <- commandArgs(trailingOnly=T)
if (length(args) < 1) {
    args <- c(default_filename)
}

# estimates SDT measures of sensitivity & bias for each subject/condition
runSDT <- function(data) {
    # count the number of correct/incorrect trials for each condition
    nIncorrect <- aggregate(wasCorrect ~ subject+isInstructed+isPracticed+isTarget+isFoil+isOld,
                            data, function(x) sum(x==0))$wasCorrect
    data <- aggregate(wasCorrect ~ subject+isInstructed+isPracticed+isTarget+isFoil+isOld, data, sum)
    data$nCorrect <- data$wasCorrect
    data$nIncorrect <- nIncorrect
    
    # group the old/new stimuli by subject and condition
    data <- merge(subset(data, isOld==1), subset(data, isOld==0), sort=F,
                  by=c('subject', 'isInstructed', 'isPracticed', 'isTarget', 'isFoil'),
                  suffixes=c('.old', '.new'))
    
    # get sensitivty & bias for each subject on each condition
    indices <- psycho::dprime(data$nCorrect.old, data$nIncorrect.new,
                              data$nIncorrect.old, data$nCorrect.new)
    sdtData <- cbind(data, indices)
    
    # analyze sensitivity (dprime)
    writeLines('\n\nSensitivity (dprime)')
    #print(summary(lmer(dprime ~ isInstructed*isPracticed*isTarget*isFoil + (1|subject),
    #                   contrasts=list(isPracticed=contr.sum, isInstructed=contr.sum,
    #                                  isTarget=contr.sum, isFoil=contr.sum),
    #                   data=sdtData)))
    
    # analyze bias (c)
    writeLines('\n\nBias (C)')
    #print(summary(lmer(c ~ isInstructed*isPracticed*isTarget*isFoil + (1|subject),
    #                   contrasts=list(isPracticed=contr.sum, isInstructed=contr.sum,
    #                          isTarget=contr.sum, isFoil=contr.sum),
    #                   data=sdtData)))
    
    return(sdtData)
}

analyze <- function(data) {
    # Run the LME as 2x2x2x2 (isLearnedxisFoilxIsPracticedxisInstructed)
    m <- glmer(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil
               + (1|subject), data=data,
               contrasts=list(isPracticed=contr.sum, isInstructed=contr.sum,
                              isTarget=contr.sum, isFoil=contr.sum),
               family=binomial(link='logit'))
    print(summary(m))
    writeLines('Odds Ratios: ')
    print(exp(fixef(m)))
}

# analyze data from each file
for (i in 1:length(args)) {
    filename <- args[i]
    writeLines(filename)
    
    memData <- subset(read.csv(filename, header=T), task=='test')
    memData$response <- ifelse(memData$wasCorrect, memData$isOld, 1 - memData$isOld)
    memData$RT <- memData$RT / 1000
    memData$isPracticed <- as.factor(memData$isPracticed)
    memData$isInstructed <- as.factor(memData$isInstructed)
    memData$isTarget <- as.factor(memData$isTarget)
    memData$isFoil <- as.factor(memData$isFoil)
    memData$isOld <- as.factor(memData$isOld)
    
    writeLines(sprintf('Total number of subjects: %d', length(unique(memData$subject))))
    
    ## exclude subjects with or low learning accuracy
    learnData <- subset(read.csv(filename, header=T), task=='learn' & isPracticed==1)
    endAcc <- aggregate(wasCorrect~subject, learnData, function (trials) mean(tail(trials, 20)))
    excluded = endAcc$subject[endAcc$wasCorrect < 0.85]
    memData <- memData[!(memData$subject %in% excluded),]
    learnData <- learnData[!(learnData$subject %in% excluded),]
    writeLines(sprintf('After exclusion: %d', length(unique(memData$subject))))
    
    ## exclude trials with high RT
    writeLines(sprintf('Mean RT+3SD: %f', mean(memData$RT) + 3*sd(memData$RT)))
    memData <- memData[memData$RT >= mean(memData$RT) - 3*sd(memData$RT) &
                       memData$RT <= mean(memData$RT) + 3*sd(memData$RT),]    
    
    startAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                          function (trials) mean(head(trials, 10)))
    endAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                        function (trials) mean(tail(trials, 10)))
    writeLines(sprintf('Instructed: %f -> %f', mean(subset(startAcc, isInstructed==1)$wasCorrect),
                       mean(subset(endAcc, isInstructed==1)$wasCorrect)))
    writeLines(sprintf('Not Instructed: %f -> %f', mean(subset(startAcc, isInstructed==0)$wasCorrect),
                       mean(subset(endAcc, isInstructed==0)$wasCorrect)))
    
    print(aggregate(subject~isPracticed+isInstructed, memData, function (s) length(unique(s))))
    ##print(aggregate(subject~featureLearned+valueLearned+featureFoil+valueFoil, memData, function (s) length(unique(s))))
    
    writeLines('\n\nRT')



    png('E6_RT2.png', height=500, width=1000)    
    print(ggplot(memData) +
          aes(x=interaction(isFoil, isTarget, isPracticed, isInstructed), y=RT,
              color=interaction(isFoil, isTarget, isPracticed, isInstructed),
              group=interaction(isFoil, isTarget, isPracticed, isInstructed)) +
          geom_violin() +
          theme_classic() + ylab('Reaction Time') +
          #scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
                legend.title=element_blank(),
                legend.text=element_text(size=20),
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
    quit()



    
    #print(summary(lmer(RT ~ isPracticed*isInstructed*isTarget*isFoil
    #                   + (1|subject), data=memData,
    #                   contrasts=list(isPracticed=contr.sum, isInstructed=contr.sum,
    #                                  isTarget=contr.sum, isFoil=contr.sum),)))
    
    hits <- subset(memData, isOld==1)
    FAs  <- subset(memData, isOld==0)
    FAs$wasCorrect <- 1-FAs$wasCorrect
    
    writeLines('\n\nHits')
    #analyze(hits)

    writeLines('\n\nFAs')
    #analyze(FAs)
    
    sdtData <- runSDT(memData)
    #writeLines('\n\n\n\n\n')
    #write.csv(sdtData, 'sdt.csv')

    # remove individual differences (for repeated measures)
    normRT <- summarySEwithin(memData, 'RT', betweenvars=c('isPracticed', 'isInstructed'),
                              withinvars=c('isTarget', 'isFoil'), idvar='subject')
    normRT$RT_norm <- NULL
    names(normRT) <- c('Practice', 'Instruction', 'Learned', 'NotLearned',
                       'nRT', 'RT', 'sdRT', 'seRT', 'ciRT')
    print(normRT)
    
    normHits <- summarySEwithin(hits, 'wasCorrect', betweenvars=c('isPracticed', 'isInstructed'),
                                withinvars=c('isTarget', 'isFoil'), idvar='subject')
    normHits$wasCorrect_norm <- NULL
    names(normHits) <- c('Practice', 'Instruction', 'Learned', 'NotLearned',
                         'nHits', 'Hits', 'sdHits', 'seHits', 'ciHits')
    print(normHits)

    normFAs <- summarySEwithin(FAs, 'wasCorrect', betweenvars=c('isPracticed', 'isInstructed'),
                               withinvars=c('isTarget', 'isFoil'), idvar='subject')
    normFAs$wasCorrect_norm <- NULL
    names(normFAs) <- c('Practice', 'Instruction', 'Learned', 'NotLearned',
                        'nFAs', 'FAs', 'sdFAs', 'seFAs', 'ciFAs')
    print(normFAs)
    
    normDPrime <- summarySEwithin(sdtData, 'dprime', betweenvars=c('isPracticed', 'isInstructed'),
                                  withinvars=c('isTarget', 'isFoil'), idvar='subject')
    normDPrime$dprime_norm <- NULL
    names(normDPrime) <- c('Practice', 'Instruction', 'Learned', 'NotLearned',
                           'nDPrime', 'DPrime', 'sdDPrime', 'seDPrime', 'ciDPrime')
    print(normDPrime)

    normC <- summarySEwithin(sdtData, 'c', betweenvars=c('isPracticed', 'isInstructed'),
                             withinvars=c('isTarget', 'isFoil'), idvar='subject')
    normC$c_norm <- NULL
    names(normC) <- c('Practice', 'Instruction', 'Learned', 'NotLearned',
                      'nC', 'C', 'sdC', 'seC', 'ciC')
    print(normC)





    
    normedData <- merge(merge(merge(merge(normRT, normHits), normFAs), normDPrime), normC)
    write.csv(normedData, "summary.csv")
    
    ## plot interaction plots    
    png('E6_RT.png', height=500, width=1000)    
    print(ggplot(normedData) +
          aes(x=interaction(NotLearned, Learned), y=RT,
              color=interaction(Practice, Instruction),
              group=interaction(Practice, Instruction)) +
          geom_errorbar(aes(ymin=RT - ciRT, ymax=RT + ciRT), width=.2,
                        position=position_dodge(width=.5)) +
          geom_point(size=5, position=position_dodge(width=.5)) +
          theme_classic() + ylab('Reaction Time') +
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
                legend.title=element_blank(),
                legend.text=element_text(size=20),
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()

    png('E6_hits.png', height=500, width=1000)
    print(ggplot(normedData) +
          aes(x=interaction(NotLearned, Learned), y=Hits,
              color=interaction(Practice, Instruction),
              group=interaction(Practice, Instruction)) +
          geom_errorbar(aes(ymin=Hits - ciHits, ymax=Hits + ciHits), width=.2,
                        position=position_dodge(width=.5)) +
          geom_point(size=5, position=position_dodge(width=.5))
          + theme_classic() + ylab('Hit Rate') +
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
                legend.title=element_blank(),
                legend.text=element_text(size=20),
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()   
    
    png('E6_FAs.png', height=500, width=1000)
    print(ggplot(normedData) +
          aes(x=interaction(NotLearned, Learned), y=FAs,
              color=interaction(Practice, Instruction),
              group=interaction(Practice, Instruction)) +
          geom_errorbar(aes(ymin=FAs - ciFAs, ymax=FAs + ciFAs), width=.2,
                        position=position_dodge(width=.5)) +
          geom_point(size=5, position=position_dodge(width=.5)) +
          theme_classic() + ylab('FA Rate') +
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
                legend.title=element_blank(),
                legend.text=element_text(size=20),
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
    
    png('E6_sensitivity.png', height=500, width=1000)
    print(ggplot(normedData) +
          aes(x=interaction(NotLearned, Learned), y=DPrime,
              color=interaction(Practice, Instruction),
              group=interaction(Practice, Instruction)) +
          geom_errorbar(aes(ymin=DPrime - ciDPrime, ymax=DPrime + ciDPrime), width=.2,
                        position=position_dodge(width=.5)) +
          geom_point(size=5, position=position_dodge(width=.5)) +
          theme_classic() + ylab(expression(paste('Sensitivity (', d*minute, ')'))) +
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
                legend.title=element_blank(),
                legend.text=element_text(size=20),
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
    
    png('E6_bias.png', height=500, width=1000)
    print(ggplot(normedData) +
          aes(x=interaction(NotLearned, Learned), y=C,
              color=interaction(Practice, Instruction),
              group=interaction(Practice, Instruction)) +
          geom_errorbar(aes(ymin=C - ciC, ymax=C + ciC), width=.2,
                        position=position_dodge(width=.5)) +
          geom_point(size=5, position=position_dodge(width=.5)) +
          theme_classic() + ylab('Bias (C)') +
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
                legend.title=element_blank(),
                legend.text=element_text(size=20),
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
}
