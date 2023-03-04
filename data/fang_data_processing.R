#-----------------------------------------------------------------------#
# Project: CSEC 491, Property Taxes in China
# Date: 03/04/2023
# Author: Lawrence Wang
# #
# Tasks: clean the data scraped from fang.com
# a) 
#-----------------------------------------------------------------------#

rm(list = ls())
setwd("/Volumes/Personal/GitHub/CSEC-491/data")
library(haven)
library(foreign)
library(dplyr)
library(purrr)
library(readxl)


# Clean all_communities_china data to select for city
all_communities_china <- read_excel("all_communities_china.xlsx")
all_communities_china_relevant <- subset(all_communities_china, select = -c(province, management_fee, parking, floor_ratio, greenery_rate, developer, management, school, info))
wh_communities <- all_communities_china_relevant[all_communities_china_relevant$city == '武汉市',]
wuchang_communities <- wh_communities[wh_communities$district == '武昌',]

# Clean secondhand house data
wh_secondhand <- read.csv("whfang_secondhandhouse_march.csv")


# Clean new house data
wh_newhouse <- read.csv("whfang_newhouse_march.csv")
