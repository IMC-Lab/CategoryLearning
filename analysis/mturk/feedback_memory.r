#!/usr/bin/Rscript
library(psycho)  # used for SDT analysis
library(ggplot2)
library(dplyr)
library(lmerTest)

default_filename <- 'data/cat_20190321_turtle_feedback.csv'

# accept a filename as an optional command-line argument
args <- commandArgs(trailingOnly=T)
if (length(args) < 1) {
    args <- c(default_filename)
}

# estimates SDT measures of sensitivity & bias for each subject/condition
runSDT <- function(data) {
    # count the number of correct/incorrect trials for each condition
    nIncorrect <- aggregate(wasCorrect ~ subject+condition+isTarget+isFoil+isOld, data,
                            function(x) sum(x==0))$wasCorrect
    data <- aggregate(wasCorrect ~ subject+condition+isTarget+isFoil+isOld, data, sum)
    data$nCorrect <- data$wasCorrect
    data$nIncorrect <- nIncorrect
    
    # group the old/new stimuli by subject and condition
    data <- merge(subset(data, isOld==1), subset(data, isOld==0), sort=F,
                  by=c('subject', 'condition', 'isTarget', 'isFoil'),
                  suffixes=c('.old', '.new'))
    write.csv(data, 'sdt.csv')
    
    # get sensitivty & bias for each subject on each condition
    indices <- psycho::dprime(data$nCorrect.old, data$nIncorrect.new,
                              data$nIncorrect.old, data$nCorrect.new)
    sdtData <- cbind(data, indices)
    
    # analyze sensitivity (dprime)
    writeLines('\n\nSensitivity (dprime)')
    print(summary(lmer(dprime ~ condition*isTarget*isFoil + (1|subject), data=sdtData)))
    
    # analyze bias (c)
    writeLines('\n\nBias (C)')
    print(summary(lmer(c ~ condition*isTarget*isFoil + (1|subject), data=sdtData)))
    return(sdtData)
}

# analyze data from each file
for (i in 1:length(args)) {
    filename <- args[i]
    writeLines(args[i])

    memData <- subset(read.csv(filename, header=T), task=='test')
    memData$condition <- as.factor(memData$condition)
    memData$isTarget <- as.factor(memData$isTarget)
    memData$isFoil <- as.factor(memData$isFoil)
    learnData <- subset(read.csv(filename, header=T), task=='learn')
    endAcc <- aggregate(wasCorrect~subject, learnData, function (trials) mean(tail(trials, 20)))
    testRT <- aggregate(RT ~ subject, memData, mean)
    learnRT <- aggregate(RT ~ subject, learnData, mean)
    writeLines(sprintf('Total number of subjects: %d', length(unique(memData$subject))))

    # exclude subjects with high RT or low learning accuracy
    writeLines(sprintf('Mean Test RT+3SD: %f', (mean(memData$RT)+3*sd(memData$RT)) / 1000))
    writeLines(sprintf('Mean Learning RT+3SD: %f', (mean(learnData$RT)+3*sd(learnData$RT)) / 1000))
    excluded = unique(c(learnRT$subject[learnRT$RT > (mean(learnRT$RT) + 3*sd(learnRT$RT))],
                        testRT$subject[testRT$RT > (mean(testRT$RT) + 3*sd(testRT$RT))],
                        endAcc$subject[endAcc$wasCorrect < 0.85]))
    memData <- memData[!(memData$subject %in% excluded),]
    learnData <- learnData[!(learnData$subject %in% excluded),]
    writeLines(sprintf('After exclusion: %d', length(unique(memData$subject))))

    print(aggregate(subject~condition, memData, function (s) length(unique(s))))
    
    writeLines('\n\nRT')
    print(summary(lmer(RT ~ condition*isTarget*isFoil + (1|subject), data=memData)))
    
    hits <- subset(memData, isOld==1)
    FAs  <- subset(memData, isOld==0)
    FAs$wasCorrect <- 1-FAs$wasCorrect  # we want FA rate, not CR rate
    
    writeLines('\n\nHits')
    print(summary(glmer(wasCorrect ~ condition*isTarget*isFoil + (1|subject),
                        data=hits, family=binomial(link='logit'))))
    writeLines('\n\nFAs')
    print(summary(glmer(wasCorrect ~ condition*isTarget*isFoil + (1|subject),
                        data=FAs, family=binomial(link='logit'))))

    sdtData <- runSDT(memData)
    writeLines('\n\n\n\n\n')
    write.csv(sdtData, 'sdt.csv')
    
    # plot interaction plots
    png('feedback_RT.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- memData %>% group_by(subject) %>% summarise(subjAvg=mean(RT))
    condAvgs <- memData %>% group_by(condition) %>% summarise(condAvg=mean(RT))
    memData$RT <- apply(memData, 1, function (x) as.numeric(x['RT'])
                        - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                        + subset(condAvgs, condition == x['condition'])$condAvg)
    print(ggplot(memData %>% group_by(condition, isTarget, isFoil) %>%
                 summarise(N=length(RT), rt=mean(RT), sd=sd(RT), ci=(1.96*sd/sqrt(N)))) +
<<<<<<< Updated upstream
          aes(x=interaction(isFoil, isTarget), y=rt, color=condition, group=condition) +
          geom_errorbar(aes(ymin=rt-ci, ymax=rt+ci), width=.2) +
          geom_line(size=2) + theme_classic() + ylab('Reaction Time') +
=======
          aes(x=interaction(isFoil, isTarget), y=rt, fill=isTarget) +
          geom_col(size=2) + theme_classic() + ylab('Reaction Time') +
          geom_errorbar(aes(ymin=rt-ci, ymax=rt+ci), width=.2) +
          facet_wrap(~condition, strip.position='bottom') +
>>>>>>> Stashed changes
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
<<<<<<< Updated upstream
                legend.title=element_blank(),
                legend.text=element_text(size=20),
=======
                legend.position='none',
                strip.background=element_blank(),
                strip.placement='outside',
                strip.text=element_text(size=36),
>>>>>>> Stashed changes
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
    
    png('feedback_hits.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- hits %>% group_by(subject) %>% summarise(subjAvg=mean(wasCorrect))
    condAvgs <- hits %>% group_by(condition) %>% summarise(condAvg=mean(wasCorrect))
    hits$wasCorrect <- apply(hits, 1, function (x) as.numeric(x['wasCorrect'])
                             - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                             + subset(condAvgs, condition == x['condition'])$condAvg)
    print(ggplot(hits %>% group_by(condition, isTarget, isFoil) %>%
                 summarise(N=length(wasCorrect), hits=mean(wasCorrect),
                           sd=sd(wasCorrect), ci=(1.96*sd/sqrt(N)))) +
<<<<<<< Updated upstream
          aes(x=interaction(isFoil, isTarget), y=hits, color=condition, group=condition) +
          geom_errorbar(aes(ymin=hits-ci, ymax=hits+ci), width=.2) +
          geom_line(size=2) + theme_classic() + ylab('Hit Rate') +
=======
          aes(x=interaction(isFoil, isTarget), y=hits, fill=isTarget) +
          geom_col(size=2) + theme_classic() + ylab('Hit Rate') +
          geom_errorbar(aes(ymin=hits-ci, ymax=hits+ci), width=.2) +
          facet_wrap(~condition, strip.position='bottom') +
>>>>>>> Stashed changes
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
<<<<<<< Updated upstream
                legend.title=element_blank(),
                legend.text=element_text(size=20),
=======
                legend.position='none',
                strip.background=element_blank(),
                strip.placement='outside',
                strip.text=element_text(size=36),
>>>>>>> Stashed changes
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
        
    png('feedback_FAs.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- FAs %>% group_by(subject) %>% summarise(subjAvg=mean(wasCorrect))
    condAvgs <- FAs %>% group_by(condition) %>% summarise(condAvg=mean(wasCorrect))
    FAs$wasCorrect <- apply(FAs, 1, function (x) as.numeric(x['wasCorrect'])
                            - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                            + subset(condAvgs, condition == x['condition'])$condAvg)
    print(ggplot(FAs %>% group_by(condition, isTarget, isFoil) %>%
                 summarise(N=length(wasCorrect), FAs=mean(wasCorrect),
                           sd=sd(wasCorrect), ci=(1.96*sd/sqrt(N)))) +
<<<<<<< Updated upstream
          aes(x=interaction(isFoil, isTarget), y=FAs, color=condition, group=condition) +
          geom_errorbar(aes(ymin=FAs-ci, ymax=FAs+ci), width=.2) +
          geom_line(size=2) + theme_classic() + ylab('FA Rate') +
=======
          aes(x=interaction(isFoil, isTarget), y=FAs, fill=isTarget) +
          geom_col(size=2) + theme_classic() + ylab('FA Rate') +
          geom_errorbar(aes(ymin=FAs-ci, ymax=FAs+ci), width=.2) +
          facet_wrap(~condition, strip.position='bottom') +
>>>>>>> Stashed changes
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
<<<<<<< Updated upstream
                legend.title=element_blank(),
                legend.text=element_text(size=20),
=======
                legend.position='none',
                strip.background=element_blank(),
                strip.placement='outside',
                strip.text=element_text(size=36),
>>>>>>> Stashed changes
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
    
    png('feedback_sensitivity.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- sdtData %>% group_by(subject) %>% summarise(subjAvg=mean(dprime))
    condAvgs <- sdtData %>% group_by(condition) %>% summarise(condAvg=mean(dprime))
    sdtData$dprime <- apply(sdtData, 1, function (x) as.numeric(x['dprime'])
                            - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                            + subset(condAvgs, condition == x['condition'])$condAvg)
    print(ggplot(sdtData %>% group_by(condition, isTarget, isFoil) %>%
                 summarise(N=length(dprime), sensitivity=mean(dprime),
                           sd=sd(dprime), ci=(1.96*sd/sqrt(N)))) +
<<<<<<< Updated upstream
          aes(x=interaction(isFoil, isTarget), y=sensitivity, color=condition, group=condition) +
          geom_errorbar(aes(ymin=sensitivity-ci, ymax=sensitivity+ci), width=.2) +
          geom_line(size=2) + theme_classic() +
=======
          aes(x=interaction(isFoil, isTarget), y=sensitivity, fill=isTarget) +
          geom_col(size=2) + theme_classic() +
          geom_errorbar(aes(ymin=sensitivity-ci, ymax=sensitivity+ci), width=.2) +
          facet_wrap(~condition, strip.position='bottom') +
>>>>>>> Stashed changes
          ylab(expression(paste('Sensitivity (', d*minute, ')'))) +
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
<<<<<<< Updated upstream
                legend.title=element_blank(),
                legend.text=element_text(size=20),
=======
                legend.position='none',
                strip.background=element_blank(),
                strip.placement='outside',
                strip.text=element_text(size=36),
>>>>>>> Stashed changes
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
    
    png('feedback_bias.png', height=1000, width=1000)
    # remove individual differences (for within-subject studies)
    subjAvgs <- sdtData %>% group_by(subject) %>% summarise(subjAvg=mean(c))
    condAvgs <- sdtData %>% group_by(condition) %>% summarise(condAvg=mean(c))
    sdtData$c <- apply(sdtData, 1, function (x) as.numeric(x['c'])
                       - subset(subjAvgs, subject==as.numeric(x['subject']))$subjAvg
                       + subset(condAvgs, condition == x['condition'])$condAvg)
    print(ggplot(sdtData %>% group_by(condition, isTarget, isFoil) %>%
                 summarise(N=length(c), bias=mean(c), sd=sd(c), ci=(1.96*sd/sqrt(N)))) +
<<<<<<< Updated upstream
          aes(x=interaction(isFoil, isTarget), y=bias, color=condition, group=condition) +
          geom_errorbar(aes(ymin=bias-ci, ymax=bias+ci), width=.2) +
          geom_line(size=2) + theme_classic() + ylab('Bias (C)') +
=======
          aes(x=interaction(isFoil, isTarget), y=bias, fill=isTarget) +
          geom_col(size=2) + theme_classic() + ylab('Bias (C)') +
          geom_errorbar(aes(ymin=bias-ci, ymax=bias+ci), width=.2) +
          facet_wrap(~condition, strip.position='bottom') +
>>>>>>> Stashed changes
          scale_x_discrete(labels=c('Neither', 'Not Learned', 'Learned', 'Both')) +
          theme(axis.text=element_text(size=20),
                axis.title.x=element_blank(),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
<<<<<<< Updated upstream
                legend.title=element_blank(),
                legend.text=element_text(size=20),
=======
                legend.position='none',
                strip.background=element_blank(),
                strip.placement='outside',
                strip.text=element_text(size=36),
>>>>>>> Stashed changes
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
}
