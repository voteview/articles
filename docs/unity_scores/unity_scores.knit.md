---
title: "Party Unity Scores"
author: "Jeff Lewis"
original_date: "2018-07-09"
date: "September 08, 2021" # Do not modify this
output: html_document
update_delta: 31
description: Provides updated versions the classic Voteview calculations of party unity scores. Figures and the underlying data are available for download. 
tags:
  - blog # Valid tags are: blog, help, data. You may use multiple tags for a post
  - data
---





## Overview

Here I describe how we create and continue the Party Unity Scores that Keith Poole previously posted [here](https://legacy.voteview.com/Party_Unity.htm).   We produce both member- and Congress-level unity data.  I also include a figures showing the change in the scores over time and also comparing these new scores to the ones previously produced by Poole.

## Two-party systems 

Poole provided party unity scores for all Congresses in which there were two dominant parties.  Those are the first through the 17th, the 19th through the 30th and the 35th through the present.  Poole describes the two earlier two-party systems on the web page linked above as follows:

>The files below are the same as those posted above only now the Jeffersonian-Republican/Federalist (Congresses 1 - 17, 1789 - 1822) and the Democrat/Whig (Congresses 19 - 30, 1825 - 1848) systems are also included in the files. For Congresses 1 - 3 party code 4000 (Anti-Administration) was treated as Jeffersonian-Republican and party code 5000 (Pro-Administration) was treated as Federalist. For Congresses 19 and 20 party code 555 (Jackson) was treated as Democrat and party code 22 (Adams) was treated as Whig. For Congresses 21 - 24 party code 1275 (Anti-Jackson) was treated as Whig (party code 555 also used for Democrat during this period).

## Loading the data

We begin by loading the most recent roll call data from Voteview.com. 


```r
suppressMessages(library(tidyverse))
vote_dat <- read_csv("https://voteview.com/static/data/out/votes/HSall_votes.csv")
```

```
## 
## ── Column specification ────────────────────────────────────────────────────────────────────────────────────────────────────
## cols(
##   congress = col_double(),
##   chamber = col_character(),
##   rollnumber = col_double(),
##   icpsr = col_double(),
##   cast_code = col_double(),
##   prob = col_character()
## )
```

These data include every vote cast by every member in either chamber over the entire history of congress.  That's 25026059 votes.  The file is over 500 megabytes.

I also load the most recent member data so that I can append parties to the roll call voting data.


```r
member_dat <- read_csv("https://voteview.com/static/data/out/members/HSall_members.csv")
```

```
## 
## ── Column specification ────────────────────────────────────────────────────────────────────────────────────────────────────
## cols(
##   .default = col_double(),
##   chamber = col_character(),
##   state_abbrev = col_character(),
##   bioname = col_character(),
##   bioguide_id = col_character(),
##   conditional = col_logical()
## )
## ℹ Use `spec()` for the full column specifications.
```
I then merge the two datsets together.


```r
all_dat <- left_join(vote_dat, member_dat, by = c("congress", "chamber", "icpsr"))
```

I only need the members of the two major parties in each Congress and Chamber.  The following query creates a data frame that has a record for every major party that existed in every chamber and congress.  


```r
big_party <- member_dat %>%
                filter(chamber != "President" &  
                       !(congress %in% c(18, 31:34))) %>%
                group_by(congress, chamber, party_code) %>%
                summarize(num=n()) %>%
                group_by(congress, chamber) %>%
                top_n(2, num) %>%
                dplyr::select(-num)
```

```
## `summarise()` has grouped output by 'congress', 'chamber'. You can override using the `.groups` argument.
```

We can then use this dataframe to subset the master data down to just the votes cast by major party members.


```r
major_dat <- right_join(all_dat, big_party)
```

```
## Joining, by = c("congress", "chamber", "party_code")
```


```r
vote_code <- c(1,1,1,2,2,2,0,0,0)
unity_votes <- major_dat %>% 
                  transform(cast_code = vote_code[cast_code]) %>%
                  filter(cast_code != 0) %>%
                  group_by(congress, chamber, rollnumber, party_code, cast_code) %>%
                  summarize(n=n()) %>%
                  group_by(congress, chamber, rollnumber, party_code) %>%
                  filter(n()==1 | n>min(n)) %>%  
                  group_by(congress, chamber, rollnumber) %>%
                  summarize(unity = min(cast_code) != max(cast_code))
```

```
## `summarise()` has grouped output by 'congress', 'chamber', 'rollnumber', 'party_code'. You can override using the `.groups` argument.
```

```
## `summarise()` has grouped output by 'congress', 'chamber'. You can override using the `.groups` argument.
```



```r
unity_votes_by_congress <- unity_votes %>%
                            group_by(chamber, congress) %>%
                            summarize(unity_votes = sum(unity),
                                      total_votes = n()) %>%
                            mutate(percent_unity = unity_votes/total_votes) %>%
                            gather(fld,val,-chamber,-congress) %>%
                            unite(chamber_fld, chamber, fld) %>%
                            spread(chamber_fld, val) %>%
                            rename_all(tolower)
```

```
## `summarise()` has grouped output by 'chamber'. You can override using the `.groups` argument.
```

```r
write_csv(path="party_unity_by_congress.csv", unity_votes_by_congress)
head(unity_votes_by_congress) 
```

```
## # A tibble: 6 × 7
##   congress house_percent_unity house_total_votes house_unity_votes senate_percent_unity senate_total_votes senate_unity_vot…
##      <dbl>               <dbl>             <dbl>             <dbl>                <dbl>              <dbl>             <dbl>
## 1        1               0.596               109                65                0.536                 97                52
## 2        2               0.735               102                75                0.490                 51                25
## 3        3               0.797                69                55                0.722                 79                57
## 4        4               0.663                83                55                0.767                 86                66
## 5        5               0.839               155               130                0.723                202               146
## 6        6               0.854                96                82                0.75                 120                90
```

### Comparing the new results to Poole's scores

Now let's compare what we find using the new data to the scores last reported by Poole.  I begin by loading Poole's party unity scores from the legacy voteview webpage. 


```r
poole_unity_by_congress <- read_table("https://legacy.voteview.com/k7ftp/partyunity_house_senate_1-113.dat",
                                       col_names=c("congress", "year", "house_total_votes", 
                                                  "house_unity_votes", "house_percent_unity", 
                                                  "house_prop_maj_fwr", "house_prop_maj_jd", 
                                                  "senate_total_votes", "senate_unity_votes",
                                                  "senate_percent_unity", "senate_prop_maj_fwr", 
                                                  "senate_prop_maj_jd"))
```

```
## 
## ── Column specification ────────────────────────────────────────────────────────────────────────────────────────────────────
## cols(
##   congress = col_double(),
##   year = col_double(),
##   house_total_votes = col_double(),
##   house_unity_votes = col_double(),
##   house_percent_unity = col_double(),
##   house_prop_maj_fwr = col_double(),
##   house_prop_maj_jd = col_double(),
##   senate_total_votes = col_double(),
##   senate_unity_votes = col_double(),
##   senate_percent_unity = col_double(),
##   senate_prop_maj_fwr = col_double(),
##   senate_prop_maj_jd = col_double()
## )
```

Then I stack the old and the new scores.


```r
library(ggplot2)

firstup <- function(x) {
   substr(x, 1, 1) <- toupper(substr(x, 1, 1))
   x
}

ubc <- bind_rows(unity_votes_by_congress %>% mutate(version="New"),
                 poole_unity_by_congress %>% 
                      mutate(version="Poole") %>% 
                      filter(!(congress %in%c(18,31:34)))) %>%
       select(contains("percent"), congress, version) %>%
       gather(chamber, percent,-congress, -version) %>%
       mutate(chamber = firstup(sapply(str_split(chamber, "\\_"), function(x) x[[1]])))
```


Finally, I make the plot to compare the two sets of unity scores.


```r
ggplot(ubc,
       aes(x=congress*2 + 1787, 
           y=percent*100,
           group=version,
           color=version
           )) +
   facet_wrap(~chamber) +
   geom_line(alpha=0.75) + 
   ylab("Percent Party Unity Rollcalls") + 
   scale_x_continuous("Year", breaks=seq(1790,2022,by=20)) +
   theme_minimal() + 
   theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

<img src="/Users/jeffreylewis/Dropbox/VoteView/articles/docs/unity_scores/unity_scores_files/figure-html/unnamed-chunk-10-1.png" width="672" />

Overall, the two sets of scores line up very closely. The orange line for the new scores is often hidden behind the green line for Poole's scores.  It appears that when the scores differ, the new scores are slightly higher and that the differences are more common in the Senate than in the House.  We are not sure what accounts for these differences.  We have cleaned up a number of errors in the data in constructed the new Voteview.  There could also be differences in the exact criteria used for establishing whether a vote was a unity vote.  


## Member voting on unity votes

Poole provided data on the rate at which each member voted with their party on party unity votes.  I will reproduce and continue those data here.

First, we limit the votes to just those that are party unity votes as determined above.









