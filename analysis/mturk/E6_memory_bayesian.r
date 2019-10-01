#!/usr/bin/Rscript
library(ggplot2)
library(plyr)
library(dplyr)
library(brms)
library(gplots)

filename <- 'data/cat_20190205_flower_E6.csv'

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

writeLines(sprintf('Mean RT+3SD: %f', mean(memData$RT) + 3*sd(memData$RT)))
memData <- memData[memData$RT >= mean(memData$RT) - 3*sd(memData$RT) &
                   memData$RT <= mean(memData$RT) + 3*sd(memData$RT),]

writeLines(sprintf('After exclusion: %d', length(unique(memData$subject))))

startAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                      function (trials) mean(head(trials, 10)))
endAcc <- aggregate(wasCorrect~subject+isInstructed, learnData,
                    function (trials) mean(tail(trials, 10)))
writeLines(sprintf('Instructed: %f -> %f', mean(subset(startAcc, isInstructed==1)$wasCorrect),
                   mean(subset(endAcc, isInstructed==1)$wasCorrect)))
writeLines(sprintf('Not Instructed: %f -> %f', mean(subset(startAcc, isInstructed==0)$wasCorrect),
                   mean(subset(endAcc, isInstructed==0)$wasCorrect)))



writeLines('\n\nRT')
mRT <- brm(bf(RT ~ isPracticed*isInstructed*isTarget*isFoil*isOld +
                  (1+isOld*isTarget*isFoil || subject),
              beta ~ isPracticed*isInstructed*isTarget*isFoil*isOld +
                  (1+isOld*isTarget*isFoil || subject)),
           family=exgaussian(link="identity"), init_r = 0.99, sample_prior=TRUE,
           chains=5, cores=5, iter=2500, warmup=1000, file='brms_RT_exgaussian', data=memData)
print(summary(mRT))
pdf('RT.pdf')
plot(mRT)
pp_check(mRT) + theme_bw()
marginal_effects(mRT)
dev.off()

writeLines('\n\nHits')
hits <- subset(memData, isOld==1)
FAs  <- subset(memData, isOld==0)
FAs$wasCorrect <- 1-FAs$wasCorrect

mHits <- brm(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil + (1+isTarget*isFoil||subject),
             family="bernoulli", prior=c(set_prior('normal (0, 4)')), sample_prior=TRUE,
             chains=5, iter=2500, warmup=1000, cores=5, file='brms_hits', data=hits)
print(summary(mHits))

pdf('hits.pdf')
plot(mHits)
pp_check(mHits) + theme_bw()
marginal_effects(mHits)
dev.off()
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
mFAs <- brm(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil + (1+isTarget*isFoil||subject),
            family="bernoulli", prior=c(set_prior('normal (0, 4)')), sample_prior=TRUE,
            chains=5, iter=2500, warmup=1000, cores=5, file='brms_FAs', data=FAs)
print(summary(mFAs))
pdf('FAs.pdf')
plot(mFAs)
pp_check(mFAs) + theme_bw()
marginal_effects(mFAs)
dev.off()

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

writeLines('\n\nSDT')
mSDT <- brm(response ~ isPracticed*isInstructed*isTarget*isFoil*isOld
            + (1 + isOld*isTarget*isFoil || subject),
            family=bernoulli(link='probit'), file='brms_sdt',
            prior=set_prior('normal (0, 2)'), sample_prior=TRUE,
            chains=5, iter=2500, warmup=1000, cores=5, data=memData)
print(summary(mSDT))
pdf('SDT.pdf')
plot(mSDT)
pp_check(mSDT) + theme_bw()
marginal_effects(mSDT)
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


    
##samples <- posterior_samples(mSDT)
##hist2d(x=samples$b_isOld1, y=samples$b_Intercept, FUN=function(x) log(length(x)))
##hist2d(x=samples$b_isTarget1, y=samples$b_isFoil1, FUN=function(x) log(length(x)))
##hist2d(x=samples$b_isTarget1, y=samples$b_isOld1, FUN=function(x) log(length(x)))
##hist2d(x=samples$b_isFoil1, y=samples$b_isOld1, FUN=function(x) log(length(x)))
##hist2d(x=samples$b_isTarget1, y=samples$b_Intercept, FUN=function(x) log(length(x)))
##hist2d(x=samples$b_isFoil1, y=samples$b_Intercept, FUN=function(x) log(length(x)))
