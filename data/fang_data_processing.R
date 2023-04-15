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


# Step 1: Clean all_communities_china data to select for city and municipal district
# isolating Wuhan and Wuchang for the analysis
all_communities_china <- read_excel("all_communities_china.xlsx")
all_communities_china_relevant <- subset(all_communities_china, select = -c(province, management_fee, parking, floor_ratio, greenery_rate, developer, management, school, info))
wh_communities <- all_communities_china_relevant[all_communities_china_relevant$city == '武汉市',]
wuchang_communities <- wh_communities[wh_communities$district == '武昌',]


# Step 2: Clean secondhand house data
wh_secondhand <- read.csv("whfang_secondhandhouse_march.csv")
# extract the region in second hand listings
wh_secondhand$address_region <- sapply(strsplit(wh_secondhand$address, '-'), `[`, 1)
# get all unique region identifiers
wh_address_regions <- unique(wh_secondhand$address_region) 
# select the ones that definitely and those that fuzzily belong to Wuchang district
regions_in_wuchang <- c('积玉桥', '中北路', '徐家棚', '水果湖', '中南丁字桥', '东湖东亭', '武昌核心')
regions_in_wuchang_fuzzy <- c('南湖花园', '白沙洲', '徐东', '武泰闸烽火')
regions_check <- c(regions_in_wuchang, regions_in_wuchang_fuzzy)
wuchang_secondhand <- wh_secondhand[wh_secondhand$address_region %in% regions_check,]


# Step 3: Clean new house data
wh_newhouse <- read.csv("whfang_newhouse_march.csv")
wuchang_newhouse <- subset(wh_newhouse, trimws(municipal_district) == '武昌')
wuchang_newhouse$community_name <- trimws(wuchang_newhouse$community_name)
wuchang_newhouse$listing_title <- trimws(wuchang_newhouse$listing_title)
wuchang_newhouse$price <- trimws(wuchang_newhouse$price)
wuchang_newhouse$price <- gsub(",", "", wuchang_newhouse$price)
wuchang_newhouse$price <- gsub("(单价)", "", wuchang_newhouse$price)
wuchang_newhouse$price <- gsub("总价", "", wuchang_newhouse$price)
wuchang_newhouse$price <- gsub("起", "", wuchang_newhouse$price)
wuchang_newhouse$price <- gsub("[()]", "", wuchang_newhouse$price)


# Step 4: Save new house and second hand data
write.csv(wuchang_communities, "wc_communities.csv", row.names = FALSE)
write.csv(wuchang_secondhand, "wc_secondhand.csv", row.names = FALSE)
write.csv(wuchang_newhouse, "wc_newhouse.csv", row.names = FALSE)



