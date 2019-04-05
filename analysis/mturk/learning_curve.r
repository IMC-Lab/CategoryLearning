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
    trials.test <- subset(read.csv(filename, header=T), task=='test')
    trials.learn <- subset(read.csv(filename, header=T), task=='learn' & isPracticed)
    endAcc <- aggregate(wasCorrect~subject, trials.learn, function (trials) mean(tail(trials, 20)))

    testRT <- aggregate(RT ~ subject, trials.test, mean)
    learnRT <- aggregate(RT ~ subject, trials.learn, mean)
        
    # exclude subjects based on 3 sd's from the RT
    excluded = unique(c(#trials.test$subject[trials.test$RT >
                        #                    (mean(trials.test$RT)+3*sd(trials.test$RT))],
                        #trials.learn$subject[trials.learn$RT >
                        #                     (mean(trials.learn$RT)+3*sd(trials.learn$RT))],
                        learnRT$subject[learnRT$RT > (mean(learnRT$RT) + 3*sd(learnRT$RT))],
                        testRT$subject[testRT$RT > (mean(testRT$RT) + 3*sd(testRT$RT))],
                        endAcc$subject[endAcc$wasCorrect < 0.85]))
    trials.test <- trials.test[!(trials.test$subject %in% excluded),]
    trials.learn <- trials.learn[!(trials.learn$subject %in% excluded),]
    
    trials.learn$isInstructed <- as.factor(sapply(trials.learn$isInstructed,
                                                  function (i) {
                                                      if (i) ' Instructed'
                                                      else ' Not Instructed'
                                                  }))

    
    learning_curve(trials.learn)
    quit()
    for (feature in unique(trials.learn$featureLearned)) {
        learning_curve(trials.learn, feature)
        for (value in unique(subset(trials.learn, featureLearned==feature)$valueLearned))
            learning_curve(trials.learn, feature, value)
    }
    
}
