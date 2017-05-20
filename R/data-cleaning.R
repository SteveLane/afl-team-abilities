################################################################################
################################################################################
## Title: Data Cleaning
## Author: Steve Lane
## Date: Friday, 19 May 2017
## Synopsis: Script cleans the data into a tidy format.
## Time-stamp: <2017-05-20 13:55:40 (slane)>
################################################################################
################################################################################
library(dplyr)
library(tidyr)
if(!file.exists("../data-raw/bg3.txt")){
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
    separate(homeScore, c("homePoints", "homeGoals", "homeScore"), sep = ".")
