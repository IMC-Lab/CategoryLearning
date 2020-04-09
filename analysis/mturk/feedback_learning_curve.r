#!/usr/bin/Rscript
library(ggplot2)
library(plyr)

default_filename <- 'data/cat_20190321_turtle_feedback.csv'
out_dir <- 'feedback_learning_curves'

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

    
    
    png(paste(fname, '.png', sep=''), height=1000, width=1000)
    print(ggplot(ddply(trials, c("trialNum", "condition"), summarise, N=length(wasCorrect),
                       rate=mean(wasCorrect), sd=sd(wasCorrect), se=(sd/sqrt(N)))) +
          aes(x=trialNum, y=rate, color=condition,group=condition,fill=condition) +
          stat_smooth(method="loess", span=0.1, se=TRUE, alpha=0.3) + theme_classic())
    dev.off()
}

# analyze data from each file
for (i in 1:length(args)) {
    filename <- args[i]
    writeLines(args[i])
    
    # import the data
    trials.test <- subset(read.csv(filename, header=T), task=='test', select=c('subject', 'RT'))
    trials.learn <- subset(read.csv(filename, header=T), task=='learn')
    testRT <- aggregate(RT ~ subject, trials.test, mean)
    learnRT <- aggregate(RT ~ subject, trials.learn, mean)
    endAcc <- aggregate(wasCorrect~subject, trials.learn, function (trials) mean(tail(trials, 20)))
    
    # exclude subjects based on 3 sd's from the RT
    excluded = unique(c(learnRT$subject[learnRT$RT > (mean(learnRT$RT) + 3*sd(learnRT$RT))],
                        testRT$subject[testRT$RT > (mean(testRT$RT) + 3*sd(testRT$RT))],
                        endAcc$subject[endAcc$wasCorrect < 0.85]))
    trials.test <- trials.test[!(trials.test$subject %in% excluded),]
    trials.learn <- trials.learn[!(trials.learn$subject %in% excluded),]
    trials.learn$condition <- as.factor(trials.learn$condition)
    
    learning_curve(trials.learn)
    for (feature in unique(trials.learn$featureLearned)) {
        learning_curve(trials.learn, feature)
        for (value in unique(subset(trials.learn, featureLearned==feature)$valueLearned))
            learning_curve(trials.learn, feature, value)
    }
    
}
