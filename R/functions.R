################################################################################
################################################################################
## Title: Functions
## Author: Steve Lane
## Date: Tuesday, 23 May 2017
## Synopsis: Contains function definitions for afl abilities modelling.
## Time-stamp: <2017-05-23 21:18:45 (steve)>
################################################################################
################################################################################

################################################################################
################################################################################
## Begin Section: Function to fit abilities model up to round X
################################################################################
################################################################################
fitToRound <- function(roundNo, allData, teams, preSeasonAbility, model){
    allRound <- allData %>% filter(roundInt <= roundNo)
    oneRound <- allData %>% filter(roundInt == roundNo)
    stanData <- with(allRound,
                     list(nteams = max(homeInt, awayInt),
                          ngames = nrow(allRound),
                          nrounds = max(roundInt), roundNo = roundInt,
                          home = homeInt, away = awayInt, scoreDiff = scoreDiff,
                          preSeasonAbility = preSeasonAbility))
    modOutput <- sampling(model, data = stanData, iter = 2000,
                          control = list(adapt_delta = 0.9))
    a <- extract(modOutput, pars = "a")$a
    hga <- extract(modOutput, pars = "hga")$hga
    hga <- matrix(rep(hga, 9), ncol = 9)
    diffOut <- hga + a[, roundNo, oneRound$homeInt] -
        a[, roundNo, oneRound$awayInt]
    diffSum <- t(apply(diffOut, 2, quantile, probs = c(0.25, 0.5, 0.75))) %>%
        as_data_frame() %>%
        rename(low25 = `25%`, mid = `50%`, up75 = `75%`) %>%
        bind_cols(., data_frame(home = oneRound$home)) %>%
        bind_cols(., data_frame(away = oneRound$away)) %>%
        mutate(roundInt = roundNo) %>%
        arrange(desc(mid)) %>%
        left_join(., oneRound %>%
                     select(home, actualDiff = scoreDiff))
    abilities <- t(apply(a[, roundNo, c(oneRound$homeInt, oneRound$awayInt)], 2,
                         quantile, probs = c(0.25, 0.5, 0.75))) %>%
        as_data_frame() %>%
        rename(low25 = `25%`, mid = `50%`, up75 = `75%`) %>%
        mutate(homeInt = c(oneRound$homeInt, oneRound$awayInt),
               roundNo = roundNo) %>%
        left_join(., teams) %>%
        rename(teamName = home) %>%
        arrange(desc(mid))
    list(diffSum = diffSum, abilities = abilities)
}
################################################################################
################################################################################
