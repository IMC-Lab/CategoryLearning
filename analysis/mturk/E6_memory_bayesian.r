#!/usr/bin/Rscript
library(ggplot2)
library(plyr)
library(dplyr)
library(stringr)
library(brms)
library(emmeans)
library(tidybayes)
library(modelr)
library(bayestestR)

filename <- 'data/cat_20190205_flower_E6.csv'

memData <- subset(read.csv(filename, header=T), task=='test')
memData$response <- ifelse(memData$wasCorrect, memData$isOld, 1 - memData$isOld)
memData$RT <- memData$RT / 1000
memData$isPracticed <- as.factor(memData$isPracticed)
memData$isInstructed <- as.factor(memData$isInstructed)
memData$isTarget <- as.factor(memData$isTarget)
memData$isFoil <- as.factor(memData$isFoil)
memData$isOld <- as.factor(memData$isOld)

writeLines(sprintf('Total number of subjects: %d (%d trials)',
                   length(unique(memData$subject)),
                   nrow(memData)))

## exclude subjects with low learning accuracy
learnData <- subset(read.csv(filename, header=T), task=='learn' & isPracticed==1)
endAcc <- aggregate(wasCorrect~subject, learnData,
                    function (trials) mean(tail(trials, 20)))
excluded = endAcc$subject[endAcc$wasCorrect < 0.85]
memData <- memData[!(memData$subject %in% excluded),]
learnData <- learnData[!(learnData$subject %in% excluded),]

## exclude trials with high RT
writeLines(sprintf('Mean RT+3SD: %f', mean(memData$RT) + 3*sd(memData$RT)))
memData <- memData[memData$RT >= mean(memData$RT) - 3*sd(memData$RT) &
                   memData$RT <= mean(memData$RT) + 3*sd(memData$RT),]

writeLines(sprintf('After exclusion: %d subjects (%d trials)',
                   length(unique(memData$subject)),
                   nrow(memData)))

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

memData %>% select(isPracticed, isInstructed, subject) %>%
    group_by(isPracticed, isInstructed) %>%
    summarise(N=length(unique(subject)))



mRT <- brm(bf(RT ~ isPracticed*isInstructed*isTarget*isFoil*isOld +
                  (1+isOld*isTarget*isFoil || subject),
              beta ~ isPracticed*isInstructed*isTarget*isFoil*isOld +
                  (1+isOld*isTarget*isFoil || subject),
              sigma ~ (1 || subject)),
           prior=c(set_prior('normal (0, 2.5)'),
                   set_prior('normal (0, 1)', dpar='beta')),
           family=exgaussian(link="identity"), inits="0", sample_prior=TRUE,
           chains=5, cores=5, iter=4000, warmup=1000, thin=3,
           control=list(adapt_delta=0.9),
           file='brms_RT_exgaussian', data=memData)
posteriorRT <- describe_posterior(mRT, ci=0.95, rope_ci=0.95)
print(posteriorRT)
posteriorRT %>%
    mutate(Parameter=str_replace(str_replace(str_replace(str_replace(str_replace(
               str_remove_all(Parameter, '\\d|b_'),
               'isInstructed', 'I'),
               'isPracticed', 'P'),
               'isTarget', 'L'),
               'isFoil', 'NL'),
               'isOld', 'O'),
           Median=sprintf('%1.2f', Median),
           HDI=sprintf('[%1.2f, %1.2f]', CI_low, CI_high),
           pd=sprintf('%1.2f', pd),
           ROPE=sprintf('[%1.2f, %1.2f]', ROPE_low, ROPE_high),
           ROPE_Percentage=sprintf('%1.2f', ROPE_Percentage)) %>%
    select(Parameter, Median, HDI, pd, ROPE, ROPE_Percentage) %>%
    write.csv('E6_RT_posterior.csv')


#####################################################################################
#####################################################################################


writeLines('\n\nHits')
hits <- subset(memData, isOld==1)
FAs  <- subset(memData, isOld==0)
FAs$wasCorrect <- 1-FAs$wasCorrect

mHits <- brm(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil +
                 (1+isTarget*isFoil||subject),
             family="bernoulli", prior=c(set_prior('normal (0, 4)')),
             sample_prior=TRUE,
             chains=5, iter=2500, warmup=1000, cores=5, file='brms_hits', data=hits)
posteriorHits <- describe_posterior(mHits, ci=0.95, rope_ci=0.95,
                                    rope_range=c(-0.15, 0.15))
print(posteriorHits)
posteriorHits %>%
    mutate(Parameter=str_replace(str_replace(str_replace(str_replace(
               str_remove_all(Parameter, '\\d|b|_'),
               'isInstructed', 'I'),
               'isPracticed', 'P'),
               'isTarget', 'L'),
               'isFoil', 'NL'),
           Median=sprintf('%1.2f', Median),
           HDI=sprintf('[%1.2f, %1.2f]', CI_low, CI_high),
           pd=sprintf('%1.2f', pd),
           ROPE=sprintf('[%1.2f, %1.2f]', ROPE_low, ROPE_high),
           ROPE_Percentage=sprintf('%1.2f', ROPE_Percentage)) %>%
    select(Parameter, Median, HDI, pd, ROPE, ROPE_Percentage) %>%
    write.csv('E6_hits_posterior.csv')

eHits <- hits %>%
    data_grid(isPracticed, isInstructed, isTarget, isFoil) %>%
    add_fitted_draws(mHits, re_formula=NA) %>%
    rename(Practice=isPracticed, Instruction=isInstructed,
           Learned=isTarget, NotLearned=isFoil) %>%
    median_hdi()

png('E6_hits_fit.png', height=500, width=1000)
ggplot(eHits, aes(x=interaction(NotLearned, Learned), y=.value,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=.lower, ymax=.upper), width=.2,
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


#####################################################################################
#####################################################################################


writeLines('\n\nFAs')
mFAs <- brm(wasCorrect ~ isPracticed*isInstructed*isTarget*isFoil +
                (1+isTarget*isFoil||subject),
            family="bernoulli", prior=c(set_prior('normal (0, 4)')),
            sample_prior=TRUE,
            chains=5, iter=2500, warmup=1000, cores=5, file='brms_FAs', data=FAs)
posteriorFAs <- describe_posterior(mFAs, ci=0.95, rope_ci=0.95,
                                   rope_range=c(-0.15, 0.15))
print(posteriorFAs)
posteriorFAs %>%
    mutate(Parameter=str_replace(str_replace(str_replace(str_replace(
               str_remove_all(Parameter, '\\d|b|_'),
               'isInstructed', 'I'),
               'isPracticed', 'P'),
               'isTarget', 'L'),
               'isFoil', 'NL'),
           Median=sprintf('%1.2f', Median),
           HDI=sprintf('[%1.2f, %1.2f]', CI_low, CI_high),
           pd=sprintf('%1.2f', pd),
           ROPE=sprintf('[%1.2f, %1.2f]', ROPE_low, ROPE_high),
           ROPE_Percentage=sprintf('%1.2f', ROPE_Percentage)) %>%
    select(Parameter, Median, HDI, pd, ROPE, ROPE_Percentage) %>%
    write.csv('E6_FAs_posterior.csv')

eFAs <- FAs %>%
    data_grid(isPracticed, isInstructed, isTarget, isFoil) %>%
    add_fitted_draws(mFAs, re_formula=NA) %>%
    rename(Practice=isPracticed, Instruction=isInstructed,
           Learned=isTarget, NotLearned=isFoil) %>%
    median_hdi()

png('E6_FAs_fit.png', height=500, width=1000)
ggplot(eFAs, aes(x=interaction(NotLearned, Learned), y=.value,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=.lower, ymax=.upper), width=.2,
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


#####################################################################################
#####################################################################################


writeLines('\n\nSDT')
mSDT <- brm(response ~ isPracticed*isInstructed*isTarget*isFoil*isOld
            + (1 + isOld*isTarget*isFoil || subject),
            family=bernoulli(link='probit'), file='brms_sdt',
            prior=set_prior('normal (0, 2)'), sample_prior=TRUE,
            chains=5, iter=2500, warmup=1000, cores=5, data=memData)
posteriorSDT <- describe_posterior(mSDT, ci=0.95, rope_ci=0.95,
                                   rope_range=c(-0.075, 0.075))
print(posteriorSDT)
posteriorSDT %>%
    mutate(Parameter=str_replace(str_replace(str_replace(str_replace(str_replace(
               str_remove_all(Parameter, '\\d|b_'),
               'isInstructed', 'I'),
               'isPracticed', 'P'),
               'isTarget', 'L'),
               'isFoil', 'NL'),
               'isOld', 'O'),
           Median=sprintf('%1.2f', Median),
           HDI=sprintf('[%1.2f, %1.2f]', CI_low, CI_high),
           pd=sprintf('%1.2f', pd),
           ROPE=sprintf('[%1.2f, %1.2f]', ROPE_low, ROPE_high),
           ROPE_Percentage=sprintf('%1.2f', ROPE_Percentage)) %>%
    select(Parameter, Median, HDI, pd, ROPE, ROPE_Percentage) %>%
    write.csv('E6_SDT_posterior.csv')

sdt.fit <- memData %>% data_grid(isPracticed, isInstructed,
                                 isTarget, isFoil, isOld) %>%
    add_fitted_draws(mSDT, re_formula=NA, scale='linear') %>%
    rename(Practice=isPracticed, Instruction=isInstructed,
           Learned=isTarget, NotLearned=isFoil)

eC <- sdt.fit %>% subset(isOld==0) %>% mutate(.value=-1*.value) %>% median_hdi()
eDPrime <- sdt.fit %>% compare_levels(.value, by=isOld) %>% median_hdi()

png('E6_sensitivity_fit.png', height=500, width=1000)
ggplot(eDPrime,
       aes(x=interaction(NotLearned, Learned), y=.value,
           group=interaction(Practice, Instruction),
           color=interaction(Practice, Instruction))) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=.lower, ymax=.upper), width=.2,
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
ggplot(eC,
       aes(x=interaction(NotLearned, Learned), y=.value,
           group=interaction(Practice, Instruction),
           color=interaction(Practice, Instruction))) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=.lower, ymax=.upper), width=.2,
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


#####################################################################################
#####################################################################################

writeLines('\n\nRT')
mRT <- brm(bf(RT ~ isPracticed*isInstructed*isTarget*isFoil*isOld +
                  (1+isOld*isTarget*isFoil || subject),
              beta ~ isPracticed*isInstructed*isTarget*isFoil*isOld +
                  (1+isOld*isTarget*isFoil || subject),
              sigma ~ (1 || subject)),
           prior=c(set_prior('normal (0, 2.5)'),
                   set_prior('normal (0, 1)', dpar='beta')),
           family=exgaussian(link="identity"), inits="0", sample_prior=TRUE,
           chains=5, cores=5, iter=4000, warmup=1000, thin=3,
           control=list(adapt_delta=0.9),
           file='brms_RT_exgaussian', data=memData)
posteriorRT <- describe_posterior(mRT, ci=0.95, rope_ci=0.95)
print(posteriorRT)
posteriorRT %>%
    mutate(Parameter=str_replace(str_replace(str_replace(str_replace(str_replace(
               str_remove_all(Parameter, '\\d|b_'),
               'isInstructed', 'I'),
               'isPracticed', 'P'),
               'isTarget', 'L'),
               'isFoil', 'NL'),
               'isOld', 'O'),
           Median=sprintf('%1.2f', Median),
           HDI=sprintf('[%1.2f, %1.2f]', CI_low, CI_high),
           pd=sprintf('%1.2f', pd),
           ROPE=sprintf('[%1.2f, %1.2f]', ROPE_low, ROPE_high),
           ROPE_Percentage=sprintf('%1.2f', ROPE_Percentage)) %>%
    select(Parameter, Median, HDI, pd, ROPE, ROPE_Percentage) %>%
    write.csv('E6_RT_posterior.csv')

eRT <- memData %>%
    data_grid(isPracticed, isInstructed, isTarget, isFoil, isOld) %>%
    add_fitted_draws(mRT, re_formula=NA, dpar='beta') %>%
    rename(Practice=isPracticed, Instruction=isInstructed,
           Learned=isTarget, NotLearned=isFoil) %>%
    mutate(mu=.value-beta) %>%  ## get the mean of the normal component
    median_hdi()

png('E6_RT_fit.png', height=500, width=1000)
ggplot(eRT, aes(x=interaction(NotLearned, Learned), y=.value,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    facet_grid( ~ isOld, labeller=label_both) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=.value.lower, ymax=.value.upper), width=.2,
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

png('E6_RT_mu_fit.png', height=500, width=1000)
ggplot(eRT, aes(x=interaction(NotLearned, Learned), y=mu,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    facet_grid( ~ isOld, labeller=label_both) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=mu.lower, ymax=mu.upper), width=.2,
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

png('E6_RT_beta_fit.png', height=500, width=1000)
ggplot(eRT, aes(x=interaction(NotLearned, Learned), y=beta,
                      group=interaction(Practice, Instruction),
                      color=interaction(Practice, Instruction))) +
    facet_grid( ~ isOld, labeller=label_both) +
    geom_point(size=5, position=position_dodge(width=.5)) +
    geom_errorbar(aes(ymin=beta.lower, ymax=beta.upper), width=.2,
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






##  Save posterior summaries
eRT <- eRT %>% mutate(RT=sprintf('%1.2f [%1.2f, %1.2f]',
                                 .value, .value.lower, .value.upper)) %>%
    select(-c(.value.lower, .value.upper)) %>%
    write.csv('posteriors_RT.csv')
eHits <- eHits %>% mutate(Hits=sprintf('%0.2f [%0.2f, %0.2f]',
                                       .value, .lower, .upper)) %>%
    select(-c(.lower, .upper)) %>%
    write.csv('posteriors_hits.csv')
eFAs <- eFAs %>% mutate(FAs=sprintf('%0.2f [%0.2f, %0.2f]',
                                  .value, .lower, .upper)) %>%
    select(-c(.lower, .upper)) %>%
    write.csv('posteriors_FAs.csv')
eDPrime <- eDPrime %>% mutate(DPrime=sprintf('%0.2f [%0.2f, %0.2f]',
                                             .value, .lower, .upper)) %>%
    select(-c(.lower, .upper)) %>%
    write.csv('posteriors_DPrime.csv')
eC <- eC %>% mutate(C=sprintf('%0.2f [%0.2f, %0.2f]',
                              .value, .lower, .upper)) %>%
    select(-c(.lower, .upper)) %>%
    write.csv('posteriors_C.csv')
write.csv(merge(merge(merge(eHits, eFAs), eDPrime), eC), 'posteriors_memory.csv')
