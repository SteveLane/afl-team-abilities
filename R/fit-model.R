################################################################################
################################################################################
## Title: Fit model
## Author: Steve Lane
## Date: Monday, 22 May 2017
## Synopsis: Fit the AFL abilities model
## Time-stamp: <2017-05-24 20:40:57 (steve)>
################################################################################
################################################################################
library(dplyr)
library(rstan)
library(ggplot2)
source("../R/functions.R")
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
                      home = homeInt, away = awayInt, scoreDiff = scoreDiff,
                      preSeasonAbility = rep(0, max(homeInt))))
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
                       home = homeInt, away = awayInt, scoreDiff = scoreDiff,
                       preSeasonAbility = rep(0, max(homeInt, awayInt))))
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
    rename(low25 = `25%`, mid = `50%`, up75 = `75%`) %>%
    bind_cols(., data_frame(home = round1$home)) %>%
    bind_cols(., data_frame(away = round1$away)) %>%
    arrange(desc(mid)) %>%
    left_join(round1 %>% select(home, actualDiff = scoreDiff))
## That looks pretty good as well!
################################################################################
################################################################################

## Merge on predicted differences looks fine.
test <- left_join(scores2016, diffSumR1)

## Evolution of abilities
ability2016 <- tibble(teamName = character(),
                      roundNo = integer(),
                      low25 = numeric(),
                      mid = numeric(),
                      up75 = numeric())
abilities <- t(apply(aR1[, 1, c(round1$homeInt, round1$awayInt)], 2,
                     quantile, probs = c(0.25, 0.5, 0.75))) %>%
    as_data_frame() %>%
    rename(low25 = `25%`, mid = `50%`, up75 = `75%`) %>%
    mutate(homeInt = c(round1$homeInt, round1$awayInt), roundNo = 1) %>%
    left_join(., teams) %>%
    rename(teamName = home) %>%
    arrange(desc(mid))
ability2016 <- bind_rows(ability2016, abilities)

################################################################################
################################################################################
## Begin Section: Redo after round 2, then put into a function...
################################################################################
################################################################################
## Just test round 2
round2 <- scores2016 %>% filter(roundInt <= 2)
stanData2 <- with(round2,
                  list(nteams = max(homeInt, awayInt), ngames = nrow(round2),
                       nrounds = max(roundInt), roundNo = roundInt,
                       home = homeInt, away = awayInt, scoreDiff = scoreDiff,
                       preSeasonAbility = rep(0, max(homeInt, awayInt))))
modOutput2 <- sampling(model, data = stanData2, iter = 1000)
aR2 <- extract(modOutput2, pars = "a")$a
## Check ability after round 23 (before finals)
aSumR2 <- t(apply(aR2[, 2, ], 2, quantile, probs = c(0.25, 0.5, 0.75))) %>%
    as_data_frame() %>% bind_cols(., teams) %>%
    arrange(desc(`50%`))
## That looks pretty reasonable...
## What about some of the parameters?
print(modOutput2, digits = 2, pars = c("hga", "tau_a", "nu", "sigma_y"))
print(modOutput2, digits = 2, pars = c("sigma_a"))
## Seems fine as well...
## Difference in scores (need hga)
hgaR2 <- extract(modOutput2, pars = "hga")$hga
hgaR2 <- matrix(rep(hgaR2, 9), ncol = 9)
diffR2 <- hgaR2 + aR2[, 2, round2$homeInt[round2$roundInt == 2]] -
    aR2[, 2, round2$awayInt[round2$roundInt == 2]]
diffSumR2 <- t(apply(diffR2, 2, quantile, probs = c(0.25, 0.5, 0.75))) %>%
    as_data_frame() %>%
    rename(low25 = `25%`, mid = `50%`, up75 = `75%`) %>%
    bind_cols(., data_frame(home = round2$home[round2$roundInt == 2])) %>%
    bind_cols(., data_frame(away = round2$away[round2$roundInt == 2])) %>%
    arrange(desc(mid)) %>%
    left_join(round2 %>% filter(roundInt == 2) %>%
              select(home, actualDiff = scoreDiff))
## That looks pretty good as well!
test <- left_join(test, diffSumR2)

## Evolution of abilities
abilities <- t(apply(aR2[, 2, c(round2$homeInt[round2$roundInt == 2],
                                round2$awayInt[round2$roundInt == 2])], 2,
                     quantile, probs = c(0.25, 0.5, 0.75))) %>%
    as_data_frame() %>%
    rename(low25 = `25%`, mid = `50%`, up75 = `75%`) %>%
    mutate(homeInt = c(round2$homeInt[round2$roundInt == 2],
                       round2$awayInt[round2$roundInt == 2])) %>%
    left_join(., teams) %>%
    rename(teamName = home) %>%
    arrange(desc(mid))
ability2016 <- bind_rows(ability2016, abilities)

################################################################################
################################################################################

## Test the function
test1 <- fitToRound(1, scores2016, teams, rep(0, 18), model)
test2 <- fitToRound(2, scores2016, teams, rep(0, 18), model)
test3 <- fitToRound(3, scores2016, teams, rep(0, 18), model)
test4 <- fitToRound(4, scores2016, teams, rep(0, 18), model)
test5 <- fitToRound(5, scores2016, teams, rep(0, 18), model)
ability2016 <- tibble(teamName = character(),
                      roundNo = integer(),
                      low25 = numeric(),
                      mid = numeric(),
                      up75 = numeric())
predDiff2016 <- tibble(home = character(),
                       away = character(),
                       roundInt = integer(),
                       actualDiff = integer(),
                       mid = numeric(),
                       low25 = numeric(),
                       up75 = numeric())
allFits <- sapply(seq_len(max(scores2016$roundInt)), function(gm){
    fit <- fitToRound(gm, scores2016, teams, rep(0, 18), model)
    fit
})

ability2016 <- bind_rows(
    ability2016,
    test1$abilities,
    test2$abilities,
    test3$abilities,
    test4$abilities,
    test5$abilities
)
plAbility <- ggplot(ability2016, aes(x = roundNo, y = mid)) +
    geom_line() +
    facet_wrap(~ teamName, ncol = 5)

predScores <- bind_rows(
    test1$diffSum,
    test2$diffSum,
    test3$diffSum,
    test4$diffSum,
    test5$diffSum
)

## Preds don't work, as need by both teams...
predScores <- left_join(scores2016, predScores)
plPreds <- ggplot(predScores, aes(x = roundInt, y = scoreDiff)) +
    geom_point() +
    geom_line(aes(y = mid), colour = "red") +
    facet_wrap(~ home, ncol = 5)

## This gives us the last round each team played (i.e. last update to ability).
lastRound <- left_join(
    scores2016 %>% group_by(home) %>% summarise(m1 = max(roundInt)),
    scores2016 %>% group_by(home = away) %>% summarise(m2 = max(roundInt))
) %>% mutate(roundInt = pmax(m1, m2)) %>%
    arrange(roundInt, home) %>%
    left_join(., teams)
