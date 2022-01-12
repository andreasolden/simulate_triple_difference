#renv::init()
renv::restore()

# Simulate all
options(scipen=999)

#Load relevant packages ####
library(foreach); library(doParallel); library(doRNG)
library(here); library(tidyverse)
library(fixest)

df_strip <- read_rds(here("r_scripts/data/cleaned_data", "df_strip.rds"))
states = unique(df_strip$state)

# Uniform sampling of nstates states
# Uniform sampling over years 1985-1995
# Run regressions, calculate standard errors, see more at https://cran.r-project.org/web/packages/fixest/vignettes/standard_errors.html
# Rerun nrepl times

# Simulation 1 - 25 treated

start_time = Sys.time()

cl <- makeCluster(detectCores())
registerDoParallel(cl)
registerDoRNG(seed = 2211)

nrepl = 10000
nstates = 25

# Start simulation

montesim <-
  foreach(irepl=1:nrepl, .combine=rbind, .packages=c("fixest", "dplyr", "tidyr") ) %dorng% {
    
    # NO EFFECT ESTIMATIONS 

    # Gen data
    treatmentstates = sample(states, nstates, replace = FALSE) # uniform sampling of #nstates states
    treatmentyear = sample(1985:1995, 1)
    
    df = df_strip %>% mutate(
      treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
      treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
      treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
    )
    
    # INDIVIDUAL DATA 
    # DiD female regression (subset on female)
    didf = feols(luearnwk ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1 = as.numeric(pvalue(didf, se ="standard")["treat"])
    p2 = as.numeric(pvalue(didf, se ="hetero")["treat"])
    p3 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p4 = as.numeric(pvalue(trip, se ="standard")["treatstates:treatyears:female"])
    p5 = as.numeric(pvalue(trip, se ="hetero")["treatstates:treatyears:female"])
    p6 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # AGGREGATE DATA
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p7 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p8 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p9 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)

    # GENERATE DATA WITH EFFECT
    ###########################
    
    df = df %>% mutate(
      uearnwk1 = ifelse( (treat==1 & female == 1 ), (uearnwk + 0.02*mean(uearnwk[treatyears==0 & female == 1 ]) ), uearnwk),
      luearnwk1 = log(uearnwk1),
      uearnwk2 = ifelse( (treat==1 & female == 1 ), (uearnwk + 0.05*mean(uearnwk[treatyears==0 & female == 1 ]) ), uearnwk),
      luearnwk2 = log(uearnwk2)
    )

    # 2 PERCENT EFFECT
    
    # DiD female regression (subset on female)
    didf = feols(luearnwk1 ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk1 ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p2w2 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # aggregate data
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk1)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p3w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p4w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p5w2 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    # 5 PERCENT EFFECT

    # DiD female regression (subset on female)
    didf = feols(luearnwk2 ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk2 ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p2w5 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # aggregate data
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk2)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p3w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p4w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p5w5 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    #naming convention: Effect size, Estimator, data level, standard error
    
    #OUT
    c(did_ind_s = p1, did_ind_w = p2, did_ind_c = p3, 
      trip_ind_s = p4, trip_ind_w = p5, trip_ind_c = p6,
      did_agg_c = p7, rel_agg_c = p8, trip_agg_c = p9,
      w2_did_ind_c = p1w2, w2_trip_ind_c = p2w2, w2_did_agg_c = p3w2, w2_rel_agg_c = p4w2, w2_trip_agg_c = p5w2, 
      w5_did_ind_c = p1w5, w5_trip_ind_c = p2w5, w5_did_agg_c = p3w5, w5_rel_agg_c = p4w5, w5_trip_agg_c = p5w5
    )
  }

stopCluster(cl)
end_time = Sys.time()
tot_time_25 = start_time - end_time

saveRDS(montesim, file = here("r_scripts/sim_res", "sim_25.rds"))

# Simulation 2 - 5 treated

start_time = Sys.time()

cl <- makeCluster(detectCores())
registerDoParallel(cl)
registerDoRNG(seed = 2211)

nrepl = 10000
nstates = 5

# Start simulation

montesim <-
  foreach(irepl=1:nrepl, .combine=rbind, .packages=c("fixest", "dplyr", "tidyr") ) %dorng% {
    
    # NO EFFECT ESTIMATIONS 
    
    # Gen data
    treatmentstates = sample(states, nstates, replace = FALSE) # uniform sampling of #nstates states
    treatmentyear = sample(1985:1995, 1)
    
    df = df_strip %>% mutate(
      treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
      treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
      treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
    )
    
    # INDIVIDUAL DATA 
    # DiD female regression (subset on female)
    didf = feols(luearnwk ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1 = as.numeric(pvalue(didf, se ="standard")["treat"])
    p2 = as.numeric(pvalue(didf, se ="hetero")["treat"])
    p3 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p4 = as.numeric(pvalue(trip, se ="standard")["treatstates:treatyears:female"])
    p5 = as.numeric(pvalue(trip, se ="hetero")["treatstates:treatyears:female"])
    p6 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # AGGREGATE DATA
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p7 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p8 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p9 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    # GENERATE DATA WITH EFFECT
    ###########################
    
    df = df %>% mutate(
      uearnwk1 = ifelse( (treat==1 & female == 1 ), (uearnwk + 0.02*mean(uearnwk[treatyears==0 & female == 1 ]) ), uearnwk),
      luearnwk1 = log(uearnwk1),
      uearnwk2 = ifelse( (treat==1 & female == 1 ), (uearnwk + 0.05*mean(uearnwk[treatyears==0 & female == 1 ]) ), uearnwk),
      luearnwk2 = log(uearnwk2)
    )
    
    # 2 PERCENT EFFECT
    
    # DiD female regression (subset on female)
    didf = feols(luearnwk1 ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk1 ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p2w2 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # aggregate data
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk1)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p3w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p4w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p5w2 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    # 5 PERCENT EFFECT
    
    # DiD female regression (subset on female)
    didf = feols(luearnwk2 ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk2 ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p2w5 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # aggregate data
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk2)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p3w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p4w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p5w5 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    #naming convention: Effect size, Estimator, data level, standard error
    
    #OUT
    c(did_ind_s = p1, did_ind_w = p2, did_ind_c = p3, 
      trip_ind_s = p4, trip_ind_w = p5, trip_ind_c = p6,
      did_agg_c = p7, rel_agg_c = p8, trip_agg_c = p9,
      w2_did_ind_c = p1w2, w2_trip_ind_c = p2w2, w2_did_agg_c = p3w2, w2_rel_agg_c = p4w2, w2_trip_agg_c = p5w2, 
      w5_did_ind_c = p1w5, w5_trip_ind_c = p2w5, w5_did_agg_c = p3w5, w5_rel_agg_c = p4w5, w5_trip_agg_c = p5w5
    )
  }

stopCluster(cl)
end_time = Sys.time()
tot_time_5 = start_time - end_time

saveRDS(montesim, file = here("r_scripts/sim_res", "sim_5.rds"))

# Simulation 3 - 2 treated

start_time = Sys.time()

cl <- makeCluster(detectCores())
registerDoParallel(cl)
registerDoRNG(seed = 2211)

nrepl = 10000
nstates = 2

# Start simulation

montesim <-
  foreach(irepl=1:nrepl, .combine=rbind, .packages=c("fixest", "dplyr", "tidyr") ) %dorng% {
    
    # NO EFFECT ESTIMATIONS 
    
    # Gen data
    treatmentstates = sample(states, nstates, replace = FALSE) # uniform sampling of #nstates states
    treatmentyear = sample(1985:1995, 1)
    
    df = df_strip %>% mutate(
      treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
      treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
      treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
    )
    
    # INDIVIDUAL DATA 
    # DiD female regression (subset on female)
    didf = feols(luearnwk ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1 = as.numeric(pvalue(didf, se ="standard")["treat"])
    p2 = as.numeric(pvalue(didf, se ="hetero")["treat"])
    p3 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p4 = as.numeric(pvalue(trip, se ="standard")["treatstates:treatyears:female"])
    p5 = as.numeric(pvalue(trip, se ="hetero")["treatstates:treatyears:female"])
    p6 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # AGGREGATE DATA
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p7 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p8 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p9 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    # GENERATE DATA WITH EFFECT
    ###########################
    
    df = df %>% mutate(
      uearnwk1 = ifelse( (treat==1 & female == 1 ), (uearnwk + 0.02*mean(uearnwk[treatyears==0 & female == 1 ]) ), uearnwk),
      luearnwk1 = log(uearnwk1),
      uearnwk2 = ifelse( (treat==1 & female == 1 ), (uearnwk + 0.05*mean(uearnwk[treatyears==0 & female == 1 ]) ), uearnwk),
      luearnwk2 = log(uearnwk2)
    )
    
    # 2 PERCENT EFFECT
    
    # DiD female regression (subset on female)
    didf = feols(luearnwk1 ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk1 ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p2w2 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # aggregate data
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk1)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p3w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p4w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p5w2 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    # 5 PERCENT EFFECT
    
    # DiD female regression (subset on female)
    didf = feols(luearnwk2 ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk2 ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p2w5 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # aggregate data
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk2)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p3w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p4w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p5w5 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    #naming convention: Effect size, Estimator, data level, standard error
    
    #OUT
    c(did_ind_s = p1, did_ind_w = p2, did_ind_c = p3, 
      trip_ind_s = p4, trip_ind_w = p5, trip_ind_c = p6,
      did_agg_c = p7, rel_agg_c = p8, trip_agg_c = p9,
      w2_did_ind_c = p1w2, w2_trip_ind_c = p2w2, w2_did_agg_c = p3w2, w2_rel_agg_c = p4w2, w2_trip_agg_c = p5w2, 
      w5_did_ind_c = p1w5, w5_trip_ind_c = p2w5, w5_did_agg_c = p3w5, w5_rel_agg_c = p4w5, w5_trip_agg_c = p5w5
    )
  }

stopCluster(cl)
end_time = Sys.time()
tot_time_2 = start_time - end_time

saveRDS(montesim, file = here("r_scripts/sim_res", "sim_2.rds"))

# Simulation 4 - 1 treated

start_time = Sys.time()

cl <- makeCluster(detectCores())
registerDoParallel(cl)
registerDoRNG(seed = 2211)

nrepl = 10000
nstates = 1

# Start simulation

montesim <-
  foreach(irepl=1:nrepl, .combine=rbind, .packages=c("fixest", "dplyr", "tidyr") ) %dorng% {
    
    # NO EFFECT ESTIMATIONS 
    
    # Gen data
    treatmentstates = sample(states, nstates, replace = FALSE) # uniform sampling of #nstates states
    treatmentyear = sample(1985:1995, 1)
    
    df = df_strip %>% mutate(
      treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
      treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
      treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
    )
    
    # INDIVIDUAL DATA 
    # DiD female regression (subset on female)
    didf = feols(luearnwk ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1 = as.numeric(pvalue(didf, se ="standard")["treat"])
    p2 = as.numeric(pvalue(didf, se ="hetero")["treat"])
    p3 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p4 = as.numeric(pvalue(trip, se ="standard")["treatstates:treatyears:female"])
    p5 = as.numeric(pvalue(trip, se ="hetero")["treatstates:treatyears:female"])
    p6 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # AGGREGATE DATA
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p7 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p8 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p9 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    # GENERATE DATA WITH EFFECT
    ###########################
    
    df = df %>% mutate(
      uearnwk1 = ifelse( (treat==1 & female == 1 ), (uearnwk + 0.02*mean(uearnwk[treatyears==0 & female == 1 ]) ), uearnwk),
      luearnwk1 = log(uearnwk1),
      uearnwk2 = ifelse( (treat==1 & female == 1 ), (uearnwk + 0.05*mean(uearnwk[treatyears==0 & female == 1 ]) ), uearnwk),
      luearnwk2 = log(uearnwk2)
    )
    
    # 2 PERCENT EFFECT
    
    # DiD female regression (subset on female)
    didf = feols(luearnwk1 ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk1 ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p2w2 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # aggregate data
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk1)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p3w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p4w2 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p5w2 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    # 5 PERCENT EFFECT
    
    # DiD female regression (subset on female)
    didf = feols(luearnwk2 ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    p1w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(luearnwk2 ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    p2w5 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip)
    
    # aggregate data
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk2)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    p3w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    p4w5 = as.numeric(pvalue(didf, cluster = 'state')["treat"])
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    p5w5 = as.numeric(pvalue(trip, cluster = 'state')["treatstates:treatyears:female"])
    rm(trip, dflong, dfwide)
    
    #naming convention: Effect size, Estimator, data level, standard error
    
    #OUT
    c(did_ind_s = p1, did_ind_w = p2, did_ind_c = p3, 
      trip_ind_s = p4, trip_ind_w = p5, trip_ind_c = p6,
      did_agg_c = p7, rel_agg_c = p8, trip_agg_c = p9,
      w2_did_ind_c = p1w2, w2_trip_ind_c = p2w2, w2_did_agg_c = p3w2, w2_rel_agg_c = p4w2, w2_trip_agg_c = p5w2, 
      w5_did_ind_c = p1w5, w5_trip_ind_c = p2w5, w5_did_agg_c = p3w5, w5_rel_agg_c = p4w5, w5_trip_agg_c = p5w5
    )
  }

stopCluster(cl)
end_time = Sys.time()
tot_time_1 = start_time - end_time

saveRDS(montesim, file = here("r_scripts/sim_res", "sim_1.rds"))

###############################################################################################################
# NOBS
###############################################################################################################

start_time = Sys.time()

cl <- makeCluster(detectCores())
registerDoParallel(cl)
registerDoRNG(seed = 2211)

nrepl = 10000
nstates = 25

# Start simulation

montesim <-
  foreach(irepl=1:nrepl, .combine=rbind, .packages=c("fixest", "dplyr", "tidyr") ) %dorng% {

    nstates = 25
    
    states = unique(df_strip$state)
    
    # Gen data
    treatmentstates = sample(states, nstates, replace = FALSE) # uniform sampling of #nstates states
    treatmentyear = sample(1985:1995, 1)
    
    df = df_strip %>% mutate(
      treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
      treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
      treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
    )
    
    # INDIVIDUAL DATA 
    # DiD female regression (subset on female)
    didf = feols(luearnwk ~ treat | state + year, df[df$female==1,], notes=FALSE) 
    
    n1 = didf$nobs
    
    rm(didf)
    
    # Triple
    trip = feols(luearnwk ~ treatstates*treatyears*female + female | state + year, df, notes=FALSE)
    
    n2 = trip$nobs
    
    rm(trip)
    
    # AGGREGATE DATA
    dflong = df %>% group_by(state, year, female) %>% summarise(meanearn = mean(uearnwk)) %>% ungroup() %>%
      mutate(
        treatstates = ifelse(state %in% treatmentstates, 1, 0), # gen dummy variable treatstates
        treatyears = ifelse( (year>= treatmentyear ) , 1, 0 ), # gen dummy variable treatyears
        treat = ifelse(treatstates== 1 & treatyears == 1, 1, 0)  # gen dummy of interaction of the two above
      )
    
    dfwide = dflong %>% mutate(genderwagelabel = ifelse(female==1, "wageF", "wageM")) %>%
      select(-female) %>% pivot_wider(names_from = genderwagelabel, values_from = meanearn)
    
    # DiD female regression
    didf = feols( log(wageF) ~ treat | state + year, dfwide, notes=FALSE) 
    
    n3 = didf$nobs
    
    
    # DiD female-male relative outcome 
    didf = feols( log(wageF) - log(wageM) ~ treat | state + year, dfwide, notes=FALSE) 
    
    n4 = didf$nobs
    
    rm(didf)
    
    # Triple
    trip = feols(log(meanearn) ~ treatstates*treatyears*female + female | state + year, dflong, notes=FALSE)
    
    n5 = trip$nobs
    rm(trip, dflong, dfwide)
    
    
    #OUT
    c("DID female individual data"=n1, "Triple difference individual data"=n2, "DiD female aggregated data"=n3, "Triple as DID aggregated data"=n4, "Triple diff aggreagted data"=n5)
  }

stopCluster(cl)
end_time = Sys.time()
tot_time_nobs = start_time - end_time

df_nobs = as.data.frame(montesim)


saveRDS(df_nobs, file = here("r_scripts/sim_res", "df_nobs.rds"))
