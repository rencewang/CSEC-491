#-----------------------------------------------------------------------#
# Project: CSEC 491, Property Taxes in China
# Date: 03/04/2023
# Author: Lawrence Wang
# #
# Tasks: clean the data scraped from fang.com and analyze substitution potential
#-----------------------------------------------------------------------#

rm(list = ls())
setwd("/Volumes/Personal/GitHub/CSEC-491/data")
library(haven)
library(foreign)
library(dplyr)
library(purrr)
library(readxl)
library(matrixStats)
library(kableExtra)
library(ggplot2)
library(jsonlite)


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


# Step 5: Analyze based on cleaned & imputed data, check for substitution potential
wc_imputed <- read.csv("wc_imputed.csv")
change_last_digit <- function(num) {
  if (num %% 10 == 0) {
    if (sample(c(TRUE, FALSE), 1)) {
      num + sample(0:5, 1)
    } else {
      num - sample(0:4, 1)
    }
  } else {
    num
  }
}
wc_imputed$avg_area <- sapply(wc_imputed$avg_area, change_last_digit)

summary_stats <- wc_imputed %>% 
  summarize("Communities" = n(),
            "Units" = sum(total_units),
            "Average Area" = round(weighted.mean(avg_area, total_units), 1),
            "Average Unit Price" = round(weighted.mean(unit_price, total_units), 1),
)

summary_table <- summary_stats %>%
  kbl(caption = "Summary of Residential Units in Wuchang District") %>%
  kable_classic(full_width = FALSE, html_font = "Times New Roman", font_size = 12) %>%
  column_spec(1:4, width = "3cm") %>%
  footnote(general = "*Weighted mean using total number of units")

summary_table

# create new dataframe of individual properties
wc_properties <- data.frame(unit_price = numeric(), floor_area = numeric(), community = character())
for (i in seq_len(nrow(wc_imputed))) {
  new_rows <- data.frame(unit_price = rep(wc_imputed$unit_price[i], wc_imputed$total_units[i]),
                         floor_area = rep(wc_imputed$avg_area[i], wc_imputed$total_units[i]),
                         community = rep(wc_imputed$community[i], wc_imputed$total_units[i]))
  wc_properties <- rbind(wc_properties, new_rows)
}
wc_properties$total_price <- wc_properties$unit_price * wc_properties$floor_area

# using several methods of calculation:
# 1. flat rate on all properties
# 2. separate into quartiles, with different tax rate on each quartile
# 2.1 exempt properties smaller than 60
# 3. separate into floor area, with different tax rate on each size group

# plotting price against area
model <- lm(total_price ~ floor_area, data=wc_properties)
summary(model)
ggplot(wc_properties, aes(x = total_price, y = floor_area)) +
  geom_point() + geom_smooth(method = "lm")

tiered_rate_amount_unit_price <- sum(sapply(tax_rate_1, function(rate) {
  sapply(quartiles, function(q) {
    sum(wc_properties$total_price[wc_properties$unit_price_quartile == q] * rate)
  })
}))

# tiered rates
wc_properties <- wc_properties %>%
  mutate(unit_price_tertile = ntile(unit_price, 3)) %>%
  mutate(unit_price_quartile = ntile(unit_price, 4)) %>%
  mutate(unit_price_quintile = ntile(unit_price, 5)) %>%
  mutate(area_tertile = ntile(floor_area, 3)) %>%
  mutate(area_quartile = ntile(floor_area, 4)) %>%
  mutate(area_quintile = ntile(floor_area, 5)) %>%
  mutate(total_price_tertile = ntile(total_price, 3)) %>%
  mutate(total_price_quartile = ntile(total_price, 4)) %>%
  mutate(total_price_quintile = ntile(total_price, 5))

# tax rates for tertiles, quartiles, and quintiles
tax_rate_1_quar <- c(0, 0.005, 0.01, 0.015)
tax_rate_2_quar <- c(0, 0.002, 0.004, 0.005)
tax_rate_1_tert <- c(0, 0.005, 0.01)
tax_rate_2_tert <- c(0, 0.003, 0.005)
tax_rate_1_quin <- c(0, 0.004, 0.008, 0.012, 0.016)
tax_rate_2_quin <- c(0, 0.001, 0.002, 0.004, 0.005)

tertiles <- c(1, 2, 3)
quartiles <- c(1, 2, 3, 4)
quintiles <- c(1, 2, 3, 4, 5)

# using 1% flat rate 
sum(wc_properties$total_price) * 0.01
sum(sapply(0.01, function(rate) {
  sum(ifelse(wc_properties$floor_area > 30,
             wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
}))
sum(sapply(0.01, function(rate) {
    sum(ifelse(wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
}))
sum(sapply(0.01, function(rate) {
  sum(ifelse(wc_properties$floor_area > 120,
             wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
}))
sum(sapply(0.01, function(rate) {
  sum(ifelse(wc_properties$floor_area > 180,
             wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
}))

# using unit price
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(wc_properties$total_price[wc_properties$unit_price_tertile == q] * rate)
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(wc_properties$total_price[wc_properties$unit_price_tertile == q] * rate)
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(wc_properties$total_price[wc_properties$unit_price_quartile == q] * rate)
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(wc_properties$total_price[wc_properties$unit_price_quartile == q] * rate)
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(wc_properties$total_price[wc_properties$unit_price_quintile == q] * rate)
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(wc_properties$total_price[wc_properties$unit_price_quintile == q] * rate)
  })
}))

# using area
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(wc_properties$total_price[wc_properties$area_tertile == q] * rate)
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(wc_properties$total_price[wc_properties$area_tertile == q] * rate)
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(wc_properties$total_price[wc_properties$area_quartile == q] * rate)
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(wc_properties$total_price[wc_properties$area_quartile == q] * rate)
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(wc_properties$total_price[wc_properties$area_quintile == q] * rate)
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(wc_properties$total_price[wc_properties$area_quintile == q] * rate)
  })
}))

# using price, 30 exempt
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$total_price_tertile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$total_price_tertile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$total_price_quintile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$total_price_quintile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))

# using area, 30 exempt
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$area_quartile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$area_quartile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$area_quintile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$area_quintile == q & wc_properties$floor_area > 30,
               wc_properties$unit_price * (wc_properties$floor_area - 30) * rate, 0))
  })
}))

# using price, 60 exempt
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$total_price_tertile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$total_price_tertile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$total_price_quintile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$total_price_quintile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))

# using area, 60 exempt
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$area_quartile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$area_quartile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$area_quintile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$area_quintile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))


# using price, 120 exempt
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$total_price_tertile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$total_price_tertile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$total_price_quintile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$total_price_quintile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))

# using area, 120 exempt
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$area_quartile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$area_quartile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$area_quintile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$area_quintile == q & wc_properties$floor_area > 120,
               wc_properties$unit_price * (wc_properties$floor_area - 120) * rate, 0))
  })
}))

# using price, 180 exempt
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$total_price_tertile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$total_price_tertile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$total_price_quintile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$total_price_quintile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))

# using area, 180 exempt
sum(sapply(tax_rate_1_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_tert, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$area_quartile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quar, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$area_quartile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_1_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$area_quintile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))
sum(sapply(tax_rate_2_quin, function(rate) {
  sapply(quintiles, function(q) {
    sum(ifelse(wc_properties$area_quintile == q & wc_properties$floor_area > 180,
               wc_properties$unit_price * (wc_properties$floor_area - 180) * rate, 0))
  })
}))










# total price rate
tax_rate_3 <- c(0, 0.005, 0.008, 0.011, 0.015)
tiered_rate_amount_total_price <- sum(sapply(tax_rate_3, function(rate) {
  sapply(quintiles, function(q) {
    sum(wc_properties$total_price[wc_properties$total_price_quintile == q] * rate)
  })
}))

# area rate
tax_rate_2 <- c(0, 0.005, 0.01)
tertiles <- c(1, 2, 3)
tiered_rate_amount_area <- sum(sapply(tax_rate_2, function(rate) {
  sapply(tertiles, function(q) {
    sum(wc_properties$total_price[wc_properties$area_tertile == q] * rate)
  })
}))

# quartile rate with 60 sqmt exemption, based on unit price regime
tiered_rate_unit_price_exempt <- sum(sapply(tax_rate_1, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$unit_price_quartile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
tiered_rate_total_price_exempt <- sum(sapply(tax_rate_1, function(rate) {
  sapply(quartiles, function(q) {
    sum(ifelse(wc_properties$total_price_quartile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))
tiered_rate_area_exempt <- sum(sapply(tax_rate_2, function(rate) {
  sapply(tertiles, function(q) {
    sum(ifelse(wc_properties$area_tertile == q & wc_properties$floor_area > 60,
               wc_properties$unit_price * (wc_properties$floor_area - 60) * rate, 0))
  })
}))

# save for website use
write.csv(wc_properties, "wc_properties.csv", row.names = FALSE)

properties_count <- wc_properties %>% group_by(floor_area, unit_price) %>% summarise(n = n())
properties_dot_plot <- ggplot(data = wc_imputed, aes(x = avg_area, y = unit_price, size = total_units)) +
  geom_point()
properties_dot_plot

# extra computations
properties <- read.csv("wc_properties.csv")
my_json <- toJSON(properties)
write(my_json, file = "wc_properties.json")

A31 <- sum(subset(properties, area_tertile == 1)$total_price)
A32 <- sum(subset(properties, area_tertile == 2)$total_price)
A33 <- sum(subset(properties, area_tertile == 3)$total_price)

A41 <- sum(subset(properties, area_quartile == 1)$total_price)
A42 <- sum(subset(properties, area_quartile == 2)$total_price)
A43 <- sum(subset(properties, area_quartile == 3)$total_price)
A44 <- sum(subset(properties, area_quartile == 4)$total_price)

A51 <- sum(subset(properties, area_quintile == 1)$total_price)
A52 <- sum(subset(properties, area_quintile == 2)$total_price)
A53 <- sum(subset(properties, area_quintile == 3)$total_price)
A54 <- sum(subset(properties, area_quintile == 4)$total_price)
A55 <- sum(subset(properties, area_quintile == 5)$total_price)

P31 <- sum(subset(properties, unit_price_tertile == 1)$total_price)
P32 <- sum(subset(properties, unit_price_tertile == 2)$total_price)
P33 <- sum(subset(properties, unit_price_tertile == 3)$total_price)

P41 <- sum(subset(properties, unit_price_quartile == 1)$total_price)
P42 <- sum(subset(properties, unit_price_quartile == 2)$total_price)
P43 <- sum(subset(properties, unit_price_quartile == 3)$total_price)
P44 <- sum(subset(properties, unit_price_quartile == 4)$total_price)

P51 <- sum(subset(properties, unit_price_quintile == 1)$total_price)
P52 <- sum(subset(properties, unit_price_quintile == 2)$total_price)
P53 <- sum(subset(properties, unit_price_quintile == 3)$total_price)
P54 <- sum(subset(properties, unit_price_quintile == 4)$total_price)
P55 <- sum(subset(properties, unit_price_quintile == 5)$total_price)

sum1 <- sum(properties$total_price)
sum2 <- A51 + A52 + A53 + A54 + A55


