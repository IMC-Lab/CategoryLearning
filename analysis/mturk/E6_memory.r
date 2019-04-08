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
    print(summary(lmer(dprime ~ isInstructed*isPracticed*isTarget*isFoil
                       + (1|subject), data=sdtData)))
    
    # analyze bias (c)
    writeLines('\n\nBias (C)')
    print(summary(lmer(c ~ isInstructed*isPracticed*isTarget*isFoil
                       + (1|subject), data=sdtData)))
    
    return(sdtData)
}

analyze <- function(data) {
    # Run the LME as 2x2x2x2 (isLearnedxisFoilxIsPracticedxisInstructed)
    m <- glmer(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil
               + (1|subject), data=data, family=binomial(link='logit'))
    print(summary(m))
    writeLines('Odds Ratios: ')
    print(exp(fixef(m)))
}

# analyze data from each file
for (i in 1:length(args)) {
    filename <- args[i]
    writeLines(args[i])
    
    memData <- subset(read.csv(filename, header=T), task=='test')
    learnData <- subset(read.csv(filename, header=T), task=='learn' & isPracticed==1)
    endAcc <- aggregate(wasCorrect~subject, learnData, function (trials) mean(tail(trials, 20)))
    writeLines(sprintf('Total number of subjects: %d', length(unique(memData$subject))))
<<<<<<< Updated upstream

    testRT <- aggregate(RT ~ subject, memData, mean)
    learnRT <- aggregate(RT ~ subject, learnData, mean)
    
    # exclude subjects with high RT or low learning accuracy
    writeLines(sprintf('Mean Test RT+3SD: %f', (mean(memData$RT)+3*sd(memData$RT)) / 1000))
    writeLines(sprintf('Mean Learning RT+3SD: %f', (mean(learnData$RT)+3*sd(learnData$RT)) / 1000))
    excluded = unique(c(#memData$subject[memData$RT > (mean(memData$RT)+3*sd(memData$RT))],
    #                    learnData$subject[learnData$RT > (mean(learnData$RT)+3*sd(learnData$RT))],
        learnRT$subject[learnRT$RT > (mean(learnRT$RT) + 3*sd(learnRT$RT))],
        testRT$subject[testRT$RT > (mean(testRT$RT) + 3*sd(testRT$RT))],
        endAcc$subject[endAcc$wasCorrect < 0.85]))

=======

    testRT <- aggregate(RT ~ subject, memData, mean)
    learnRT <- aggregate(RT ~ subject, learnData, mean)
    
    # exclude subjects with high RT or low learning accuracy
    writeLines(sprintf('Mean Test RT+3SD: %f', (mean(memData$RT)+3*sd(memData$RT)) / 1000))
    writeLines(sprintf('Mean Learning RT+3SD: %f', (mean(learnData$RT)+3*sd(learnData$RT)) / 1000))
    excluded = unique(c(#memData$subject[memData$RT > (mean(memData$RT)+3*sd(memData$RT))],
    #                    learnData$subject[learnData$RT > (mean(learnData$RT)+3*sd(learnData$RT))],
        learnRT$subject[learnRT$RT > (mean(learnRT$RT) + 3*sd(learnRT$RT))],
        testRT$subject[testRT$RT > (mean(testRT$RT) + 3*sd(testRT$RT))],
        endAcc$subject[endAcc$wasCorrect < 0.85]))
    
>>>>>>> Stashed changes
    excludedTrials <- which(testRT$RT %in% boxplot(testRT$RT, plot=F)$out)
    print(min(testRT$RT))
    print(max(testRT$RT))
    print(mean(testRT$RT))
    print(mean(testRT$RT) + 3*sd(testRT$RT))
    print('')
    print(min(learnRT$RT))
    print(max(learnRT$RT))
    print(mean(learnRT$RT))
    print(mean(learnRT$RT) + 3*sd(learnRT$RT))
    
<<<<<<< Updated upstream
    
    #writeLines(sprintf('Max RT- %f', min(memData$RT[excludedTrials])))
    #writeLines(sprintf('Excluded Trials: %d', length(excludedTrials)))
    #memData <- memData[-excludedTrials,]
    
=======
>>>>>>> Stashed changes
    memData <- memData[!(memData$subject %in% excluded),]
    learnData <- learnData[!(learnData$subject %in% excluded),]
    writeLines(sprintf('After exclusion: %d', length(unique(memData$subject))))
    
    startAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                          function (trials) mean(head(trials, 10)))
    endAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                        function (trials) mean(tail(trials, 10)))
    writeLines(sprintf('Instructed: %f -> %f', mean(subset(startAcc, isInstructed==1)$wasCorrect),
                       mean(subset(endAcc, isInstructed==1)$wasCorrect)))
    writeLines(sprintf('Not Instructed: %f -> %f', mean(subset(startAcc, isInstructed==0)$wasCorrect),
                       mean(subset(endAcc, isInstructed==0)$wasCorrect)))

    
    #print(aggregate(subject~isPracticed+isInstructed, memData, function (s) length(unique(s))))
    #print(aggregate(subject~featureLearned+valueLearned+featureFoil+valueFoil, memData, function (s) length(unique(s))))
    writeLines('\n\nRT')
    print(summary(lmer(RT ~ isPracticed*isInstructed*isTarget*isFoil
                       + (1|subject), data=memData)))
    
    hits <- subset(memData, isOld==1)
    FAs  <- subset(memData, isOld==0)
    FAs$wasCorrect <- 1-FAs$wasCorrect
    
    writeLines('\n\nHits')
    analyze(hits)
    writeLines('\n\nFAs')
    analyze(FAs)

    sdtData <- runSDT(memData)
    writeLines('\n\n\n\n\n')
    write.csv(sdtData, 'sdt.csv')
    
    # plot interaction plots
    png('E6_RT.png', height=500, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(memData, c('subject'), summarise, subjAvg=mean(RT))
    condAvgs <- ddply(memData, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(RT))
    memData$RT <- apply(memData, 1, function (x) as.numeric(x['RT'])
                        - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                        + subset(condAvgs, isPracticed == x['isPracticed']
                                 & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(memData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(RT), rt=mean(RT), sd=sd(RT), ci=1.96*(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=rt, color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=rt-ci, ymax=rt+ci), width=.2) +
          geom_line(size=2) + theme_classic() + ylab('Reaction Time') +
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
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(hits, c('subject'), summarise, subjAvg=mean(wasCorrect))
    condAvgs <- ddply(hits, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(wasCorrect))
    hits$wasCorrect <- apply(hits, 1, function (x) as.numeric(x['wasCorrect'])
                             - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                             + subset(condAvgs, isPracticed == x['isPracticed']
                                      & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(hits, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(wasCorrect), hits=mean(wasCorrect), sd=sd(wasCorrect),
                       ci=1.96*(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=hits, color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=hits-ci, ymax=hits+ci), width=.2) +
          geom_line(size=2) + theme_classic() + ylab('Hit Rate') +
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
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(FAs, c('subject'), summarise, subjAvg=mean(wasCorrect))
    condAvgs <- ddply(FAs, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(wasCorrect))
    FAs$wasCorrect <- apply(FAs, 1, function (x) as.numeric(x['wasCorrect'])
                            - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                            + subset(condAvgs, isPracticed == x['isPracticed']
                                     & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(FAs, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(wasCorrect), FAs=mean(wasCorrect),
                       sd=sd(wasCorrect), ci=1.96*(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=FAs, color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=FAs-ci, ymax=FAs+ci), width=.2) +
          geom_line(size=2) + theme_classic() + ylab('FA Rate') +
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
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(sdtData, c('subject'), summarise, subjAvg=mean(dprime))
    condAvgs <- ddply(sdtData, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(dprime))
    sdtData$dprime <- apply(sdtData, 1, function (x) as.numeric(x['dprime'])
                            - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                            + subset(condAvgs, isPracticed == x['isPracticed']
                                     & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(sdtData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(dprime), sensitivity=mean(dprime), sd=sd(dprime),
                       ci=1.96*(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=sensitivity,
              color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=sensitivity-ci, ymax=sensitivity+ci), width=.2) +
          geom_line(size=2) + theme_classic() +
          ylab(expression(paste('Sensitivity (', d*minute, ')'))) +
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
    # remove individual differences (for within-subject studies)
    subjAvgs <- ddply(sdtData, c('subject'), summarise, subjAvg=mean(c))
    condAvgs <- ddply(sdtData, c('isPracticed', 'isInstructed'), summarise, condAvg=mean(c))
    sdtData$c <- apply(sdtData, 1, function (x) as.numeric(x['c'])
                       - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                       + subset(condAvgs, isPracticed == x['isPracticed']
                                & isInstructed == x['isInstructed'])$condAvg)
    print(ggplot(ddply(sdtData, c("isPracticed", "isInstructed", "isTarget", "isFoil"), summarise,
                       N=length(c), bias=mean(c), sd=sd(c), ci=1.96*(sd/sqrt(N)))) +
          aes(x=interaction(isFoil, isTarget), y=bias,
              color=interaction(isPracticed, isInstructed),
              group=interaction(isPracticed, isInstructed)) +
          geom_errorbar(aes(ymin=bias-ci, ymax=bias+ci), width=.2) +
          geom_line(size=2) + theme_classic() + ylab('Bias (C)') +
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
