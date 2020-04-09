#!/usr/local/bin/Rscript
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
          theme(axis.text=element_text(size=20),
                axis.title.x=element_text(size=36, margin=margin(t=0.5, unit='cm')),
                axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
                legend.title=element_blank(),
                legend.text=element_text(size=20),
                plot.margin=margin(t=1, b=1, unit='cm')))
    dev.off()
}

# analyze data from each file
for (i in 1:length(args)) {
    filename <- args[i]
    writeLines(args[i])
    
    # import the data
    memData <- subset(read.csv(filename, header=T), task=='test')
    memData$RT <- memData$RT / 1000
    
    writeLines(sprintf('Total number of subjects: %d', length(unique(memData$subject))))
    
    ## exclude subjects with or low learning accuracy
    learnData <- subset(read.csv(filename, header=T), task=='learn' & isPracticed==1)
    endAcc <- aggregate(wasCorrect~subject, learnData, function (trials) mean(tail(trials, 20)))
    excluded = endAcc$subject[endAcc$wasCorrect < 0.85]
    memData <- memData[!(memData$subject %in% excluded),]
    learnData <- learnData[!(learnData$subject %in% excluded),]
    writeLines(sprintf('After exclusion: %d', length(unique(memData$subject))))
    
    learnData$isInstructed <- as.factor(sapply(learnData$isInstructed,
                                               function (i) {
                                                   if (i) ' Instructed'
                                                   else ' Not Instructed'
                                               }))
    
    
    learning_curve(learnData)

    for (feature in unique(learnData$featureLearned)) {
        learning_curve(learnData, feature)
        for (value in unique(subset(learnData, featureLearned==feature)$valueLearned))
            learning_curve(learnData, feature, value)
    }
    
}
