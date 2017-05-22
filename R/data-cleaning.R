################################################################################
################################################################################
## Title: Data Cleaning
## Author: Steve Lane
## Date: Friday, 19 May 2017
## Synopsis: Script cleans the data into a tidy format.
## Time-stamp: <2017-05-22 20:34:27 (slane)>
################################################################################
################################################################################
library(dplyr)
library(tidyr)
if(!file.exists("../data-raw/bg3.txt")){
    dir.create("../data-raw")
    download.file("http://afltables.com/afl/stats/biglists/bg3.txt",
                  "../data-raw/bg3.txt")
}

## Data is in fixed width format...
scores <- read.fwf("../data-raw/bg3.txt", widths = c(7, 17, 5, 18, 17, 18, 18),
                   skip = 2,
                   col.names = c("gameNo", "date", "round", "home", "homeScore",
                                 "away", "awayScore"))

## Trim whitespace from data.
scores <- scores %>%
    mutate(date = trimws(date, "right"),
           round = trimws(round, "right"),
           home = trimws(home, "right"),
           homeScore = trimws(homeScore, "right"),
           away = trimws(away, "right"),
           awayScore = trimws(awayScore, "right")
           )

## Restrict to 2000+
scores <- scores %>%
    mutate(date = as.Date(date, format = "%d-%B-%Y")) %>%
    filter(date > as.Date("2000-01-01"))

## Split scores
scores <- scores %>%
    separate(homeScore, c("homeGoals", "homePoints", "homeScore"),
             sep = "\\.") %>%
    separate(awayScore, c("awayGoals", "awayPoints", "awayScore"),
             sep = "\\.") %>%
    mutate(homePoints = as.integer(homePoints),
           homeGoals = as.integer(homeGoals),
           homeScore = as.integer(homeScore),
           homeCalc = homePoints + 6 * homeGoals,
           homeDiff = (homeScore != homeCalc),
           awayPoints = as.integer(awayPoints),
           awayGoals = as.integer(awayGoals),
           awayScore = as.integer(awayScore),
           awayCalc = awayPoints + 6 * awayGoals,
           awayDiff = (awayScore != awayCalc)
           )

## Rename Kangaroos to North Melbourne
scores <- scores %>%
    mutate(home = ifelse(home == "Kangaroos", "North Melbourne", home),
           away = ifelse(away == "Kangaroos", "North Melbourne", away)
           )

## Lookup table for teamnames (so they're in some sort of order)
homeLookup <- data_frame(home = c("Adelaide", "Brisbane Lions", "Carlton",
                                  "Collingwood", "Essendon", "Fremantle",
                                  "Geelong", "Hawthorn", "Melbourne",
                                  "North Melbourne", "Port Adelaide",
                                  "Richmond", "St Kilda", "Sydney",
                                  "West Coast", "Western Bulldogs",
                                  "Gold Coast", "GW Sydney"),
                         homeInt = 1:18)
awayLookup <- data_frame(away = c("Adelaide", "Brisbane Lions", "Carlton",
                                  "Collingwood", "Essendon", "Fremantle",
                                  "Geelong", "Hawthorn", "Melbourne",
                                  "North Melbourne", "Port Adelaide",
                                  "Richmond", "St Kilda", "Sydney",
                                  "West Coast", "Western Bulldogs",
                                  "Gold Coast", "GW Sydney"),
                         awayInt = 1:18)
scores <- left_join(scores, homeLookup) %>%
    left_join(., awayLookup)

## Save the data
if(!dir.exists("../data/")) dir.create("../data/")
saveRDS(scores, "../data/afl-2000.rds")
saveRDS(homeLookup, "../data/team-lookups.rds")
