################################################################################
################################################################################
## Title: Fit model
## Author: Steve Lane
## Date: Monday, 22 May 2017
## Synopsis: Fit the AFL abilities model
## Time-stamp: <2017-05-22 21:14:50 (slane)>
################################################################################
################################################################################
library(dplyr)
library(rstan)
scores <- readRDS("../data/afl-2000.rds")
teams <- readRDS("../data/team-lookups.rds")
## Restrict to the 2016 season to begin with, then use that as priors (somehow)
## for the 2017 season.
scores2016 <- scores %>%
    filter(date >= as.Date("2016-01-01"),
           date < as.Date("2017-01-01")) %>%
    mutate(scoreDiff = homeScore - awayScore)
rounds <- data_frame(round = unique(scores2016$round),
                     roundInt = seq_len(length(unique(scores2016$round))))
scores2016 <- left_join(scores2016, rounds)
################################################################################
################################################################################

################################################################################
################################################################################
## Begin Section: Compile and fit model to all data
################################################################################
################################################################################
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
model <- stan_model("../stan/basic-model.stan")
stanData <- with(scores2016,
                 list(nteams = max(homeInt), ngames = nrow(scores2016),
                      nrounds = max(roundInt), roundNo = roundInt,
                      home = homeInt, away = awayInt, scoreDiff = scoreDiff))
modOutput <- sampling(model, data = stanData, iter = 500)
a <- extract(modOutput, pars = "a")$a
## Check ability after round 23 (before finals)
aSum <- t(apply(a[, 23, ], 2, quantile, probs = c(0.25, 0.5, 0.75))) %>%
    as_data_frame() %>% bind_cols(., teams) %>%
    arrange(desc(`50%`))
## That looks pretty reasonable...
## What about some of the parameters?
print(modOutput, digits = 2, pars = c("hga", "tau_a", "nu", "sigma_y"))
print(modOutput, digits = 2, pars = c("sigma_a"))
## Seems fine as well...
################################################################################
################################################################################

################################################################################
################################################################################
## Begin Section: Loop through the data to refit after each round...
################################################################################
################################################################################
## Just test round 1
round1 <- scores2016 %>% filter(roundInt == 1)
stanData1 <- with(round1,
                  list(nteams = max(homeInt, awayInt), ngames = nrow(round1),
                       nrounds = max(roundInt), roundNo = roundInt,
                       home = homeInt, away = awayInt, scoreDiff = scoreDiff))
modOutput1 <- sampling(model, data = stanData1, iter = 1000)
aR1 <- extract(modOutput1, pars = "a")$a
## Check ability after round 23 (before finals)
aSumR1 <- t(apply(aR1[, 1, ], 2, quantile, probs = c(0.25, 0.5, 0.75))) %>%
    as_data_frame() %>% bind_cols(., teams) %>%
    arrange(desc(`50%`))
## That looks pretty reasonable...
## What about some of the parameters?
print(modOutput1, digits = 2, pars = c("hga", "tau_a", "nu", "sigma_y"))
print(modOutput1, digits = 2, pars = c("sigma_a"))
## Seems fine as well...
## Difference in scores (need hga)
hgaR1 <- extract(modOutput1, pars = "hga")$hga
hgaR1 <- matrix(rep(hgaR1, 9), ncol = 9)
diffR1 <- hgaR1 + aR1[, , round1$homeInt] - aR1[, , round1$awayInt]
diffSumR1 <- t(apply(diffR1, 2, quantile, probs = c(0.25, 0.5, 0.75))) %>%
    as_data_frame() %>%
    bind_cols(., data_frame(home = round1$home)) %>%
    bind_cols(., data_frame(away = round1$away)) %>%
    arrange(desc(`50%`)) %>%
    left_join(round1 %>% select(home, actualDiff = scoreDiff))
## That looks pretty good as well!
################################################################################
################################################################################
