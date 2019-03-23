#!/usr/bin/Rscript
library(ggplot2)
library(plyr)

default_filename <- 'data/cat_20190205_flower_E6.csv'
out_dir <- 'E6_learning_curves'

# accept a filename as an optional command-line argument
args <- commandArgs(trailingOnly=T)
if (length(args) < 1) {
    args <- c(default_filename)
}

learning_curve <- function(trials, feature=NULL, value=NULL) {
    # subset the data
    fname <- paste(out_dir, 'curve', sep='/')
    if (!is.null(feature)) {
        fname <- paste(fname, '-', feature, sep='')
        trials <- subset(trials, featureLearned==feature)
        if (!is.null(value)) {
            fname <- paste(fname, '-', value, sep='')
            trials <- subset(trials, valueLearned==value)
        }
    }

    nSubj <- length(unique(trials$subject))
    nTrials <- nrow(subset(trials, subject==trials$subject[1]))
    trials$trialNum <- rep(1:nTrials, times=nSubj)

    
    
    png(paste(fname, '.png', sep=''), height=500, width=1000)
    print(ggplot(ddply(trials, c("trialNum", "isInstructed"), summarise, N=length(wasCorrect),
                       rate=mean(wasCorrect), sd=sd(wasCorrect), se=(sd/sqrt(N)))) +
          aes(x=trialNum, y=rate, color=isInstructed,group=isInstructed,fill=isInstructed) +
          stat_smooth(method="loess", span=0.1, se=TRUE, alpha=0.3) + theme_classic() +
          xlab('Trial') + ylab('Categorization Accuracy') +
          theme(axis.text=element_text(size=12),
                axis.title=element_text(size=24),
                legend.title=element_blank()))
    dev.off()
}

# analyze data from each file
for (i in 1:length(args)) {
    filename <- args[i]
    writeLines(args[i])
    
    # import the data
    trials.test <- subset(read.csv(filename, header=T), task=='test', select=c('subject', 'RT'))
    trials.learn <- subset(read.csv(filename, header=T), task=='learn' & isPracticed,
                           select=c('subject', 'isInstructed', 'featureLearned', 'valueLearned',
                                    'wasCorrect', 'RT'))
    
    # exclude subjects based on 3 sd's from the RT
    exclude.test = (trials.test$RT > (mean(trials.test$RT) + 3*sd(trials.test$RT))) |
        (trials.test$RT < (mean(trials.test$RT)-3*sd(trials.test$RT)))
    exclude.learn = (trials.learn$RT > (mean(trials.learn$RT)+3*sd(trials.learn$RT))) |
        (trials.learn$RT < (mean(trials.learn$RT)-3*sd(trials.learn$RT)))
    excludedSubjects = unique(c(trials.test$subject[exclude.test],
                                trials.learn$subject[exclude.learn]))
    trials.learn <- trials.learn[!(trials.learn$subject %in% excludedSubjects),]
    trials.learn$isInstructed <- as.factor(sapply(trials.learn$isInstructed,
                                                  function (i) {
                                                      if (i) ' Instructed'
                                                      else ' Not Instructed'
                                                  }))

    
    learning_curve(trials.learn)
    for (feature in unique(trials.learn$featureLearned)) {
        learning_curve(trials.learn, feature)
        for (value in unique(subset(trials.learn, featureLearned==feature)$valueLearned))
            learning_curve(trials.learn, feature, value)
    }
    
}
