#!/usr/bin/Rscript
library(ggplot2)
library(plyr)
library(dplyr)
library(stringr)
library(brms)

filename <- 'data/cat_20190205_flower_E6.csv'

##
## Helper function to return the estimated SDT coefficients (d' or C)
## given the condition. If summary=TRUE, return median and 95% CIs. Else
## return all samples.
##
coef <- function(samples, Practice, Instruction, Learned, NotLearned, summary=TRUE) {
    ## convert to logical
    Practice <- as.logical(as.numeric(as.character(Practice)))
    Instruction <- as.logical(as.numeric(as.character(Instruction)))
    Learned <- as.logical(as.numeric(as.character(Learned)))
    NotLearned <- as.logical(as.numeric(as.character(NotLearned)))

    if (summary) {
        out <- data.frame(estimate=numeric(), lower=numeric(), upper=numeric())
    } else {
        out <- data.frame(Practice=logical(), Instruction=logical(),
                          Learned=logical(), NotLearned=logical(),
                          estimate=numeric())
    }
    
    for (i in 1:length(Practice)) {
        ## start out with the intercept
        e <- samples$b_Intercept
        
        ## add the coefficients according to the condition
        for (c in colnames(samples)) {
            if ((!str_detect(c, ':') &&
                 (Practice[i] && str_detect(c, 'isPracticed') ||
                  Instruction[i] && str_detect(c, 'isInstructed') ||
                  Learned[i] && str_detect(c, 'isTarget') ||
                  NotLearned[i] && str_detect(c, 'isFoil'))) ||
                (str_detect(c, ':') && 
                 Practice[i] == str_detect(c, 'isPracticed') &&
                 Instruction[i] == str_detect(c, 'isInstructed') &&
                 Learned[i] == str_detect(c, 'isTarget') &&
                 NotLearned[i] == str_detect(c, 'isFoil'))) {
                e <- e + samples[[c]]
            }
        }
        
        if (summary) {
            out[i, ] <- c(median(e),
                          quantile(e, probs=c(0.025), names=FALSE),
                          quantile(e, probs=c(0.975), names=FALSE))
        } else {
            out <- rbind(out, data.frame(Practice=Practice[i], Instruction=Instruction[i],
                                         Learned=Learned[i], NotLearned=NotLearned[i],
                                         estimate=e))
        }
    }
    
    return(out)
}



memData <- subset(read.csv(filename, header=T), task=='test')
memData$response <- ifelse(memData$wasCorrect, memData$isOld, 1 - memData$isOld)
memData$RT <- memData$RT / 1000
memData$isPracticed <- as.factor(memData$isPracticed)
memData$isInstructed <- as.factor(memData$isInstructed)
memData$isTarget <- as.factor(memData$isTarget)
memData$isFoil <- as.factor(memData$isFoil)
memData$isOld <- as.factor(memData$isOld)

writeLines(sprintf('Total number of subjects: %d', length(unique(memData$subject))))

## exclude subjects with low learning accuracy
learnData <- subset(read.csv(filename, header=T), task=='learn' & isPracticed==1)
endAcc <- aggregate(wasCorrect~subject, learnData, function (trials) mean(tail(trials, 20)))
excluded = endAcc$subject[endAcc$wasCorrect < 0.85]
memData <- memData[!(memData$subject %in% excluded),]
learnData <- learnData[!(learnData$subject %in% excluded),]

## exclude trials with high RT
writeLines(sprintf('Mean RT+3SD: %f', mean(memData$RT) + 3*sd(memData$RT)))
memData <- memData[memData$RT >= mean(memData$RT) - 3*sd(memData$RT) &
                   memData$RT <= mean(memData$RT) + 3*sd(memData$RT),]

writeLines(sprintf('After exclusion: %d', length(unique(memData$subject))))

startAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                      function (trials) mean(head(trials, 10)))
endAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                    function (trials) mean(tail(trials, 10)))
writeLines(sprintf('Instructed: %f -> %f',
                   mean(subset(startAcc, isInstructed==1)$wasCorrect),
                   mean(subset(endAcc, isInstructed==1)$wasCorrect)))
writeLines(sprintf('Not Instructed: %f -> %f',
                   mean(subset(startAcc, isInstructed==0)$wasCorrect),
                   mean(subset(endAcc, isInstructed==0)$wasCorrect)))




writeLines('\n\nRT')
mRT <- brm(bf(RT ~ isPracticed*isInstructed*isTarget*isFoil*isOld +
                  (1+isOld*isTarget*isFoil || subject),
              beta ~ isPracticed*isInstructed*isTarget*isFoil*isOld +
                  (1+isOld*isTarget*isFoil || subject),
              sigma ~ (1 || subject)),
           prior=c(set_prior('normal (0, 2.5)'), set_prior('normal (0, 1)', dpar='beta')),
           family=exgaussian(link="identity"), inits="0", sample_prior=TRUE,
           chains=5, cores=5, iter=4000, warmup=1000, thin=3, control=list(adapt_delta=0.9),
           file='brms_RT_exgaussian', data=memData)

print(summary(mRT, priors=TRUE, prob=0.99))
pdf('RT.pdf')
plot(mRT)
pp_check(mRT) + theme_bw()
dev.off()

eRT <- marginal_effects(mRT, effects=c('isPracticed:isInstructed'),
                        conditions=make_conditions(mRT, c('isTarget', 'isFoil', 'isOld'))
                        )[['isPracticed:isInstructed']] %>%
    select(-c(cond__, RT, subject, effect1__, effect2__, se__)) %>%
    rename(Practice=isPracticed, Instruction=isInstructed,
           Learned=isTarget, NotLearned=isFoil, Old=isOld,
           RT=estimate__, RTLower=lower__, RTUpper=upper__)

print(hypothesis(mRT, c('isPracticed1 = 0',
                        'isInstructed1 = 0',
                        'isTarget1 = 0',
                        'isFoil1 = 0',
                        'isOld1 = 0',
                        'isPracticed1:isInstructed1 = 0',
                        'isPracticed1:isTarget1 = 0',
                        'isPracticed1:isFoil1 = 0',
                        'isPracticed1:isOld1 = 0',
                        'isInstructed1:isTarget1 = 0',
                        'isInstructed1:isFoil1 = 0',
                        'isInstructed1:isOld1 = 0',
                        'isTarget1:isFoil1 = 0',
                        'isTarget1:isOld1 = 0',
                        'isFoil1:isOld1 = 0',
                        'isPracticed1:isInstructed1:isTarget1 = 0',
                        'isPracticed1:isInstructed1:isFoil1 = 0',
                        'isPracticed1:isInstructed1:isOld1 = 0',
                        'isPracticed1:isTarget1:isFoil1 = 0',
                        'isPracticed1:isTarget1:isOld1 = 0',
                        'isPracticed1:isFoil1:isOld1 = 0',
                        'isInstructed1:isTarget1:isFoil1 = 0',
                        'isInstructed1:isTarget1:isOld1 = 0',
                        'isInstructed1:isFoil1:isOld1 = 0',
                        'isTarget1:isFoil1:isOld1 = 0',
                        'isPracticed1:isInstructed1:isTarget1:isFoil1 = 0',
                        'isPracticed1:isInstructed1:isTarget1:isOld1 = 0',
                        'isPracticed1:isInstructed1:isFoil1:isOld1 = 0',
                        'isPracticed1:isTarget1:isFoil1:isOld1 = 0',
                        'isInstructed1:isTarget1:isFoil1:isOld1 = 0',
                        'isPracticed1:isInstructed1:isTarget1:isFoil1:isOld1 = 0',
                        'beta_isPracticed1 = 0',
                        'beta_isInstructed1 = 0',
                        'beta_isTarget1 = 0',
                        'beta_isFoil1 = 0',
                        'beta_isOld1 = 0',
                        'beta_isPracticed1:isInstructed1 = 0',
                        'beta_isPracticed1:isTarget1 = 0',
                        'beta_isPracticed1:isFoil1 = 0',
                        'beta_isPracticed1:isOld1 = 0',
                        'beta_isInstructed1:isTarget1 = 0',
                        'beta_isInstructed1:isFoil1 = 0',
                        'beta_isInstructed1:isOld1 = 0',
                        'beta_isTarget1:isFoil1 = 0',
                        'beta_isTarget1:isOld1 = 0',
                        'beta_isFoil1:isOld1 = 0',
                        'beta_isPracticed1:isInstructed1:isTarget1 = 0',
                        'beta_isPracticed1:isInstructed1:isFoil1 = 0',
                        'beta_isPracticed1:isInstructed1:isOld1 = 0',
                        'beta_isPracticed1:isTarget1:isFoil1 = 0',
                        'beta_isPracticed1:isTarget1:isOld1 = 0',
                        'beta_isPracticed1:isFoil1:isOld1 = 0',
                        'beta_isInstructed1:isTarget1:isFoil1 = 0',
                        'beta_isInstructed1:isTarget1:isOld1 = 0',
                        'beta_isInstructed1:isFoil1:isOld1 = 0',
                        'beta_isTarget1:isFoil1:isOld1 = 0',
                        'beta_isPracticed1:isInstructed1:isTarget1:isFoil1 = 0',
                        'beta_isPracticed1:isInstructed1:isTarget1:isOld1 = 0',
                        'beta_isPracticed1:isInstructed1:isFoil1:isOld1 = 0',
                        'beta_isPracticed1:isTarget1:isFoil1:isOld1 = 0',
                        'beta_isInstructed1:isTarget1:isFoil1:isOld1 = 0',
                        'beta_isPracticed1:isInstructed1:isTarget1:isFoil1:isOld1 = 0'), alpha=0.05),
      digits=10)                    

hypothesis(mRT, c('beta_isPracticed1 = 0',
                  'beta_isInstructed1 = 0',
                  'beta_isFoil1 = 0',
                  'beta_isPracticed1 + beta_isInstructed1 = 0',
                  'beta_isPracticed1 + beta_isFoil1 = 0',
                  'beta_isInstructed1 + beta_isFoil1 = 0',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 = 0',
                  
                  'beta_isPracticed1 = beta_isInstructed1',
                  'beta_isPracticed1 = beta_isFoil1',
                  'beta_isInstructed1 = beta_isFoil1',

                  'beta_isPracticed1 = beta_isPracticed1 + beta_isInstructed1',
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isFoil1',
                  'beta_isPracticed1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isFoil1',
                  'beta_isInstructed1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isInstructed1 + beta_isFoil1',
                  
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isPracticed1 + beta_isFoil1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 + beta_isFoil1 = beta_isPracticed1 + beta_isFoil1',

                  'beta_isPracticed1 + beta_isInstructed1 = beta_isPracticed1 + isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 + beta_isInstructed1 = beta_isPracticed1 + isInstructed1 + beta_isFoil1',
                  'beta_isFoil1 + beta_isInstructed1 = beta_isPracticed1 + isInstructed1 + beta_isFoil1'))


hypothesis(mRT, c('beta_isInstructed1 = 0',
                  'beta_isTarget1 = 0',
                  'beta_isFoil1 = 0',
                  'beta_isInstructed1 + beta_isTarget1 = 0',
                  'beta_isInstructed1 + beta_isFoil1 = 0',
                  'beta_isTarget1 + beta_isFoil1 = 0',
                  'beta_isInstructed1 + beta_isTarget1 + beta_isFoil1 = 0',
                  
                  'beta_isInstructed1 = beta_isTarget1',
                  'beta_isInstructed1 = beta_isFoil1',
                  'beta_isTarget1 = beta_isFoil1',

                  'beta_isInstructed1 = beta_isInstructed1 + beta_isTarget1',
                  'beta_isInstructed1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 = beta_isTarget1 + beta_isFoil1',
                  'beta_isTarget1 = beta_isInstructed1 + beta_isTarget1',
                  'beta_isTarget1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isTarget1 = beta_isTarget1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isInstructed1 + beta_isTarget1',
                  'beta_isFoil1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isTarget1 + beta_isFoil1',
                  
                  'beta_isInstructed1 = beta_isInstructed1 + beta_isTarget1 + beta_isFoil1',
                  'beta_isTarget1 = beta_isInstructed1 + beta_isTarget1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isInstructed1 + beta_isTarget1 + beta_isFoil1',
                  
                  'beta_isInstructed1 + beta_isTarget1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 + beta_isTarget1 = beta_isTarget1 + beta_isFoil1',
                  'beta_isTarget1 + beta_isFoil1 = beta_isInstructed1 + beta_isFoil1',

                  'beta_isInstructed1 + beta_isTarget1 = beta_isInstructed1 + isTarget1 + beta_isFoil1',
                  'beta_isTarget1 + beta_isTarget1 = beta_isInstructed1 + isTarget1 + beta_isFoil1',
                  'beta_isFoil1 + beta_isTarget1 = beta_isInstructed1 + isTarget1 + beta_isFoil1'))


hypothesis(mRT, c('beta_isPracticed1 = 0',
                  'beta_isInstructed1 = 0',
                  'beta_isFoil1 = 0',
                  'beta_isOld1 = 0',
                  'beta_isPracticed1 + beta_isInstructed1 = 0',
                  'beta_isPracticed1 + beta_isFoil1 = 0',
                  'beta_isPracticed1 + beta_isOld1 = 0',
                  'beta_isInstructed1 + beta_isFoil1 = 0',
                  'beta_isInstructed1 + beta_isOld1 = 0',
                  'beta_isFoil1 + beta_isOld1 = 0',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 = 0',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isOld1 = 0',
                  'beta_isPracticed1 + beta_isFoil1 + beta_isOld1 = 0',
                  'beta_isInstructed1 + beta_isFoil1 + beta_isOld1 = 0',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1 = 0',
                  'beta_isPracticed1 = beta_isInstructed1',
                  'beta_isPracticed1 = beta_isFoil1',
                  'beta_isPracticed1 = beta_isOld1',
                  'beta_isInstructed1 = beta_isFoil1',
                  'beta_isInstructed1 = beta_isOld1',
                  'beta_isFoil1 = beta_isOld1',
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isInstructed1',
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isFoil1',
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isOld1',
                  'beta_isPracticed1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isPracticed1 = beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 = beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isFoil1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isOld1',
                  'beta_isInstructed1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 = beta_isInstructed1 + beta_isOld1',
                  'beta_isInstructed1 = beta_isFoil1 + beta_isOld1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isOld1',
                  'beta_isFoil1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isInstructed1 + beta_isOld1',
                  'beta_isFoil1 = beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isFoil1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isPracticed1 + beta_isFoil1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isPracticed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isPracticed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isOld1 = beta_isInstructed1 + beta_isFoil1',
                  'beta_isPracticed1 + beta_isOld1 = beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isOld1 = beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isFoil1 = beta_isInstructed1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isFoil1 = beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isOld1 = beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isPracticed1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isOld1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isOld1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 + beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isFoil1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isFoil1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isInstructed1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isOld1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isOld1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isFoil1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1',
                  'beta_isFoil1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isFoil1 + beta_isOld1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isFoil1 + beta_isOld1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isFoil1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isOld1 = beta_isPracticed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isOld1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 + beta_isOld1 = beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isInstructed1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isPracticed1 + beta_isFoil1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1',
                  'beta_isInstructed1 + beta_isFoil1 + beta_isOld1 = beta_isPracticed1 + beta_isInstructed1 + beta_isFoil1 + beta_isOld1'))

writeLines('\n\nHits')
hits <- subset(memData, isOld==1)
FAs  <- subset(memData, isOld==0)
FAs$wasCorrect <- 1-FAs$wasCorrect

mHits <- brm(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil +
                 (1+isTarget*isFoil||subject),
             family="bernoulli", prior=c(set_prior('normal (0, 4)')), sample_prior=TRUE,
             chains=5, iter=2500, warmup=1000, cores=5, file='brms_hits', data=hits)
print(summary(mHits))

pdf('hits.pdf')
plot(mHits)
pp_check(mHits) + theme_bw()
dev.off()

eHits <- marginal_effects(mHits, effects=c('isPracticed:isInstructed'),
                          conditions=make_conditions(mRT, c('isTarget', 'isFoil'))
                          )[['isPracticed:isInstructed']] %>%
    select(-c(cond__, wasCorrect, subject, effect1__, effect2__, se__)) %>%
    rename(Practice=isPracticed, Instruction=isInstructed,
           Learned=isTarget, NotLearned=isFoil,
           Hits=estimate__, HitsLower=lower__, HitsUpper=upper__)
marginal_effects(mHits, 'isTarget')$isTarget %>% select(isTarget, Hits=estimate__, Lower=lower__, Upper=upper__)



##writeLines('Odds Ratios: ')
##print(exp(fixef(mHits)))

print(hypothesis(mHits, c('isPracticed1 = 0',
                          'isInstructed1 = 0',
                          'isTarget1 = 0',
                          'isFoil1 = 0',
                          'isPracticed1:isInstructed1 = 0',
                          'isPracticed1:isTarget1 = 0',
                          'isPracticed1:isFoil1 = 0',
                          'isInstructed1:isTarget1 = 0',
                          'isInstructed1:isFoil1 = 0',
                          'isTarget1:isFoil1 = 0',
                          'isPracticed1:isInstructed1:isTarget1 = 0',
                          'isPracticed1:isInstructed1:isFoil1 = 0',
                          'isPracticed1:isTarget1:isFoil1 = 0',
                          'isInstructed1:isTarget1:isFoil1 = 0',
                          'isPracticed1:isInstructed1:isTarget1:isFoil1 = 0')), digits=10)


writeLines('\n\nFAs')
mFAs <- brm(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil +
                (1+isTarget*isFoil||subject),
            family="bernoulli", prior=c(set_prior('normal (0, 4)')), sample_prior=TRUE,
            chains=5, iter=2500, warmup=1000, cores=5, file='brms_FAs', data=FAs)
print(summary(mFAs))
pdf('FAs.pdf')
plot(mFAs)
pp_check(mFAs) + theme_bw()
dev.off()

eFAs <- marginal_effects(mFAs, effects=c('isPracticed:isInstructed'),
                         conditions=make_conditions(mFAs, c('isTarget', 'isFoil'))
                         )[['isPracticed:isInstructed']] %>%
    select(-c(cond__, wasCorrect, subject, effect1__, effect2__, se__)) %>%
    rename(Practice=isPracticed, Instruction=isInstructed,
           Learned=isTarget, NotLearned=isFoil,
           FAs=estimate__, FAsLower=lower__, FAsUpper=upper__)
marginal_effects(mFAs, 'isTarget')$isTarget %>% select(isTarget, FAs=estimate__, Lower=lower__, Upper=upper__)


##writeLines('Odds Ratios: ')
##print(exp(fixef(mFAs)))
print(hypothesis(mFAs, c('isPracticed1 = 0',
                         'isInstructed1 = 0',
                         'isTarget1 = 0',
                         'isFoil1 = 0',
                         'isPracticed1:isInstructed1 = 0',
                         'isPracticed1:isTarget1 = 0',
                         'isPracticed1:isFoil1 = 0',
                         'isInstructed1:isTarget1 = 0',
                         'isInstructed1:isFoil1 = 0',
                         'isTarget1:isFoil1 = 0',
                         'isPracticed1:isInstructed1:isTarget1 = 0',
                         'isPracticed1:isInstructed1:isFoil1 = 0',
                         'isPracticed1:isTarget1:isFoil1 = 0',
                         'isInstructed1:isTarget1:isFoil1 = 0',
                         'isPracticed1:isInstructed1:isTarget1:isFoil1 = 0')), digits=10)

hypothesis(mRT, c('isPracticed1 = 0',
                  'isInstructed1 = 0',
                  'isFoil1 = 0',
                  'isPracticed1 + isInstructed1 = 0',
                  'isPracticed1 + isFoil1 = 0',
                  'isInstructed1 + isFoil1 = 0',
                  'isPracticed1 + isInstructed1 + isFoil1 = 0',
                  
                  'isPracticed1 = isInstructed1',
                  'isPracticed1 = isFoil1',
                  'isInstructed1 = isFoil1',

                  'isPracticed1 = isPracticed1 + isInstructed1',
                  'isPracticed1 = isPracticed1 + isFoil1',
                  'isPracticed1 = isInstructed1 + isFoil1',
                  'isInstructed1 = isPracticed1 + isInstructed1',
                  'isInstructed1 = isPracticed1 + isFoil1',
                  'isInstructed1 = isInstructed1 + isFoil1',
                  'isFoil1 = isPracticed1 + isInstructed1',
                  'isFoil1 = isPracticed1 + isFoil1',
                  'isFoil1 = isInstructed1 + isFoil1',
                  
                  'isPracticed1 = isPracticed1 + isInstructed1 + isFoil1',
                  'isInstructed1 = isPracticed1 + isInstructed1 + isFoil1',
                  'isFoil1 = isPracticed1 + isInstructed1 + isFoil1',
                  
                  'isPracticed1 + isInstructed1 = isPracticed1 + isFoil1',
                  'isPracticed1 + isInstructed1 = isInstructed1 + isFoil1',
                  'isInstructed1 + isFoil1 = isPracticed1 + isFoil1',

                  'isPracticed1 + isInstructed1 = isPracticed1 + isInstructed1 + isFoil1',
                  'isInstructed1 + isInstructed1 = isPracticed1 + isInstructed1 + isFoil1',
                  'isFoil1 + isInstructed1 = isPracticed1 + isInstructed1 + isFoil1'))


writeLines('\n\nSDT')
mSDT <- brm(response ~ isPracticed*isInstructed*isTarget*isFoil*isOld
            + (1 + isOld*isTarget*isFoil || subject),
            family=bernoulli(link='probit'), file='brms_sdt',
            prior=set_prior('normal (0, 2)'), sample_prior=TRUE,
            chains=5, iter=2500, warmup=1000, cores=5, data=memData)
print(summary(mSDT))

marginal_effects(mSDT, 'isOld')$isOld %>% select(isOld, SaysOld=estimate__, Lower=lower__, Upper=upper__)
marginal_effects(mSDT, 'isTarget')$isTarget %>% select(isTarget, SaysOld=estimate__, Lower=lower__, Upper=upper__)


pdf('SDT.pdf')
plot(mSDT)
pp_check(mSDT) + theme_bw()
marginal_effects(mSDT, effects=c('isPracticed:isInstructed'),
                 conditions=make_conditions(mRT, c('isTarget', 'isFoil', 'isOld')))
dev.off()

print(hypothesis(mSDT, c('isPracticed1 = 0',
                         'isInstructed1 = 0',
                         'isTarget1 = 0',
                         'isFoil1 = 0',
                         'isOld1 = 0',
                         'isPracticed1:isInstructed1 = 0',
                         'isPracticed1:isTarget1 = 0',
                         'isPracticed1:isFoil1 = 0',
                         'isPracticed1:isOld1 = 0',
                         'isInstructed1:isTarget1 = 0',
                         'isInstructed1:isFoil1 = 0',
                         'isInstructed1:isOld1 = 0',
                         'isTarget1:isFoil1 = 0',
                         'isTarget1:isOld1 = 0',
                         'isFoil1:isOld1 = 0',
                         'isPracticed1:isInstructed1:isTarget1 = 0',
                         'isPracticed1:isInstructed1:isFoil1 = 0',
                         'isPracticed1:isInstructed1:isOld1 = 0',
                         'isPracticed1:isTarget1:isFoil1 = 0',
                         'isPracticed1:isTarget1:isOld1 = 0',
                         'isPracticed1:isFoil1:isOld1 = 0',
                         'isInstructed1:isTarget1:isFoil1 = 0',
                         'isInstructed1:isTarget1:isOld1 = 0',
                         'isInstructed1:isFoil1:isOld1 = 0',
                         'isTarget1:isFoil1:isOld1 = 0',
                         'isPracticed1:isInstructed1:isTarget1:isFoil1 = 0',
                         'isPracticed1:isInstructed1:isTarget1:isOld1 = 0',
                         'isPracticed1:isInstructed1:isFoil1:isOld1 = 0',
                         'isPracticed1:isTarget1:isFoil1:isOld1 = 0',
                         'isInstructed1:isTarget1:isFoil1:isOld1 = 0',
                         'isPracticed1:isInstructed1:isTarget1:isFoil1:isOld1 = 0')),
      digits=10)

sDPrime <- posterior_samples(mSDT) %>%
    select(starts_with('b_')) %>%
    select(contains('isOld')) %>%
    rename_all(function(s) str_remove(s, ':isOld1')) %>%
    rename(b_Intercept=b_isOld1)

conds <- aggregate(subject ~ isPracticed + isInstructed + isTarget + isFoil, memData, mean) %>%
    select(-c('subject')) %>%
    rename(Practice=isPracticed, Instruction=isInstructed,
           Learned=isTarget, NotLearned=isFoil)

eDPrime <- conds %>%
    cbind(coef(sDPrime, conds$Practice, conds$Instruction, conds$Learned, conds$NotLearned)) %>%
    rename(DPrime=estimate, DPrimeLower=lower, DPrimeUpper=upper)
#eDPrime <- coef(sDPrime, conds$Practice, conds$Instruction, conds$Learned, conds$NotLearned) %>%
#    rename(DPrime=estimate)

sC <- posterior_samples(mSDT) %>%
    select(starts_with('b_')) %>%
    select(-contains('isOld'))

eC <- conds %>%
    cbind(coef(sC, conds$Practice, conds$Instruction, conds$Learned, conds$NotLearned)) %>%
    rename(C=estimate, CLower=lower, CUpper=upper) %>%
    mutate(C=-C, CLower=-CLower, CUpper=-CUpper)
#eC <- coef(sC, conds$Practice, conds$Instruction, conds$Learned, conds$NotLearned) %>%
#    rename(C=estimate)





##  Generate plots and save posterior summaries
png('E6_RT_fit.png', height=500, width=1000)
ggplot(eRT, aes(x=interaction(NotLearned, Learned), y=RT,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    facet_grid( ~ Old, labeller=label_both) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=RTLower, ymax=RTUpper), width=.2,
                  position=position_dodge(width=.5)) +
    theme_classic() + ylab('Reaction Time') +
    scale_x_discrete(labels=c('Neither', 'NotLearned', 'Learned', 'Both')) +
    scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
    theme(axis.text=element_text(size=20),
          axis.title.x=element_blank(),
          axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
          legend.title=element_blank(),
          legend.text=element_text(size=20),
          plot.margin=margin(t=1, b=1, unit='cm'))
dev.off()

png('E6_hits_fit.png', height=500, width=1000)
ggplot(eHits, aes(x=interaction(NotLearned, Learned), y=Hits,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=HitsLower, ymax=HitsUpper), width=.2,
                  position=position_dodge(width=.5)) +
    theme_classic() + ylab('Hit Rate') +
    scale_x_discrete(labels=c('Neither', 'NotLearned', 'Learned', 'Both')) +
    scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
    theme(axis.text=element_text(size=20),
          axis.title.x=element_blank(),
          axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
          legend.title=element_blank(),
          legend.text=element_text(size=20),
          plot.margin=margin(t=1, b=1, unit='cm'))
dev.off()

png('E6_FAs_fit.png', height=500, width=1000)
ggplot(eFAs, aes(x=interaction(NotLearned, Learned), y=FAs,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=FAsLower, ymax=FAsUpper), width=.2,
                  position=position_dodge(width=.5)) +
    theme_classic() + ylab('FA Rate') +
    scale_x_discrete(labels=c('Neither', 'NotLearned', 'Learned', 'Both')) +
    scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
    theme(axis.text=element_text(size=20),
          axis.title.x=element_blank(),
          axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
          legend.title=element_blank(),
          legend.text=element_text(size=20),
          plot.margin=margin(t=1, b=1, unit='cm'))
dev.off()

png('E6_sensitivity_fit.png', height=500, width=1000)
ggplot(eDPrime, aes(x=interaction(NotLearned, Learned), y=DPrime,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=DPrimeLower, ymax=DPrimeUpper), width=.2,
                  position=position_dodge(width=.5)) +
    theme_classic() + ylab('Sensitivity (d\')') +
    scale_x_discrete(labels=c('Neither', 'NotLearned', 'Learned', 'Both')) +
    scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
    theme(axis.text=element_text(size=20),
          axis.title.x=element_blank(),
          axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
          legend.title=element_blank(),
          legend.text=element_text(size=20),
          plot.margin=margin(t=1, b=1, unit='cm'))
dev.off()

png('E6_bias_fit.png', height=500, width=1000)
ggplot(eC, aes(x=interaction(NotLearned, Learned), y=C,
               group=interaction(Practice, Instruction),
               color=interaction(Practice, Instruction))) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=CLower, ymax=CUpper), width=.2,
                  position=position_dodge(width=.5)) +
    theme_classic() + ylab('Bias (C)') +
    scale_x_discrete(labels=c('Neither', 'NotLearned', 'Learned', 'Both')) +
    scale_color_discrete(labels=c('Neither', 'Practiced', 'Instructed', 'Both')) +
    theme(axis.text=element_text(size=20),
          axis.title.x=element_blank(),
          axis.title.y=element_text(size=36, margin=margin(r=0.5, unit='cm')),
          legend.title=element_blank(),
          legend.text=element_text(size=20),
          plot.margin=margin(t=1, b=1, unit='cm'))
dev.off()

eRT <- eRT %>% mutate(RT=sprintf('%1.2f [%1.2f, %1.2f]', RT, RTLower, RTUpper)) %>%
    select(-c(RTLower, RTUpper)) %>%
    write.csv('posteriors_RT.csv')
eHits <- eHits %>% mutate(Hits=sprintf('%0.2f [%0.2f, %0.2f]', Hits, HitsLower, HitsUpper)) %>%
    select(-c(HitsLower, HitsUpper)) %>%
    write.csv('posteriors_hits.csv')
eFAs <- eFAs %>% mutate(FAs=sprintf('%0.2f [%0.2f, %0.2f]', FAs, FAsLower, FAsUpper)) %>%
    select(-c(FAsLower, FAsUpper)) %>%
    write.csv('posteriors_FAs.csv')
eDPrime <- eDPrime %>% mutate(DPrime=sprintf('%0.2f [%0.2f, %0.2f]', DPrime, DPrimeLower, DPrimeUpper)) %>%
    select(-c(DPrimeLower, DPrimeUpper)) %>%
    write.csv('posteriors_DPrime.csv')
eC <- eC %>% mutate(C=sprintf('%0.2f [%0.2f, %0.2f]', C, CLower, CUpper)) %>%
    select(-c(CLower, CUpper)) %>%
    write.csv('posteriors_C.csv')
write.csv(merge(merge(merge(eHits, eFAs), eDPrime), eC), 'posteriors_memory.csv')
