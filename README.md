---
contributors:
  - Andreas Olden
  - Jarle Møen
---

# Template README and Guidance

Overview
--------

The code in this replication package reproduces the rejection rates simulations of our paper on the triple difference estimator (Olden & Møen, 2021). It takes raw data from the Population Survey in their fourth interview month, in the Merged Outgoing Rotation Group, from 1979 to 1999, merge it, and simulate treatment effects of varying sizes and differing number of treatment clusters as described in appendix B. This produces all results and table of our paper. This can take several days on a standard desktop. 

To reproduce our results, open and run the following scripts (in folder r_scripts), in sequential order: 

* simulate_triple_difference.Rproj
* 0_merge.rmd 
* 1_wrangle.rmd
* 2_simulate.R
* 3_results.rmd

Make especially sure that you always open the Rproj file first to ensure that the relative file paths work. Since running the code can take several days, we have for your convenience included the data and results (in folder r_scripts) from all steps of the procedure: 

* 0_merge.rmd produces df_merged.rds (needs to be unzipped, included as df_merged.7z in data/cleaned_data)
* 1_wrangle.rmd produces df_strip.rds (needs to be unzipped, included as df_strip.7z in data/cleaned_data)
* 2.simulate.R creates 4 files, also included in the folder sim_res
* The raw data is available in data_based/data/raw_data. 

To ensure reproducibility of the packages/enviroment we use the package 'renv'. Documentation is available at: https://cran.r-project.org/web/packages/renv/vignettes/renv.html

Note: 

* The first time you run renv it might take some time 
* Each script/rmd-file calls renv to ensure reproducibility also if you only reproduce parts of the process. 
* DoRNG is used to ensure reproducibility with parallel computing 

Reproducibility has been checked across Windows platforms. We have also taken steps to ensure across platform reproducibility, but due to different backends under parallelization between windows and linux/ios user mights still encounter issues.Please contact the authors at andreasolden@gmail.com if you face such issues. 


Data Availability and Provenance Statements
----------------------------

The data is the Population Survey in their fourth interview month, in the Merged Outgoing Rotation Group, from 1979 to 1999. The data can be accessed, with descriptions, from https://www.nber.org/research/data/current-population-survey-cps-data-nber. The data was downloaded 19 November 2020 from: https://data.nber.org/morg/annual/. A copy of the data is provided as part of this archive

Datafiles:  `morg79.dta`-`morg99.dta`

### Statement about Rights

- [x] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript. 
- [x] I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. 

### Summary of Availability

- [X] All data **are** publicly available.
- [ ] Some data **cannot be made** publicly available.
- [ ] **No data can be made** publicly available.



### Controlled Randomness

> INSTRUCTIONS: Some estimation code uses random numbers, almost always provided by pseudorandom number generators (PRNGs). For reproducibility purposes, these should be provided with a deterministic seed, so that the sequence of numbers provided is the same for the original author and any replicators. While this is not always possible, it is a requirement by many journals' policies. The seed should be set once, and not use a time-stamp. If using parallel processing, special care needs to be taken. If using multiple programs in sequence, care must be taken on how to call these programs, ideally from a main program, so that the sequence is not altered.

- [registerDoRNG(seed = 2211)] Random seed is set at line 26 of 2_simulate.R
- [registerDoRNG(seed = 2211)] Random seed is set at line 195 of 2_simulate.R
- [registerDoRNG(seed = 2211)] Random seed is set at line 364 of 2_simulate.R
- [registerDoRNG(seed = 2211)] Random seed is set at line 533 of 2_simulate.R

### Memory and Runtime Requirements

> INSTRUCTIONS: Memory and compute-time requirements may also be relevant or even critical. Some example text follows. It may be useful to break this out by Table/Figure/section of processing. For instance, some estimation routines might run for weeks, but data prep and creating figures might only take a few minutes.

#### Summary

Approximate time needed to reproduce the analyses on a standard (CURRENT YEAR) desktop machine:

- [ ] <10 minutes
- [ ] 10-60 minutes
- [ ] 1-8 hours
- [ ] 8-24 hours
- [x] 1-3 days
- [ ] 3-14 days
- [ ] > 14 days
- [ ] Not feasible to run on a desktop machine, as described below.

#### Details

The simulations ran for about 4 hours using 24 cores (max by default in the code) on: 

Microsoft Windows Server 2016 Standard
Intel(R) Xeon(R) CPU E5-2660 v2 @ 2.60GHz, 64 RAM, w X Virtual? cores
R version 4.0.3 (2020-10-10) -- "Bunny-Wunnies Freak Out"
x86_64-w64-mingw32/x64 (64-bit)

Rstudio Version 1.3.1093
"Apricot Nasturtium" (aee44535, 2020-09-17) for Windows


Description of programs/code
----------------------------

To reproduce our results, open and run the following scripts (in folder r_scripts), in sequential order: 

- 'simulate_triple_difference.Rproj' is the project file and ensures a consistent path structure
- '0_merge.rmd' takes the original morgXX.dta files and combines them into a single file. It reads data from r_scripts/data/raw and saves it to r_scripts/data/cleaned_data/df_merged.rds
- '1_wrangle.rmd' recodes variables. It reads the r_scripts/data/cleaned_data/df_merged.rds transforms the data to a more stripped and simulation friendly format and saves it to df_strip.rds at the same location. 
- '2_simulate.R' runs the simulations by first loading the df_strip.rds data frame. 
- '3_results.rmd' creates the tables of the paper in both html format that can be viewed in the rmd file itself and raw latex code. 

All rmd files have accompanying html files to be viewed in any browser. 


List of tables and programs
---------------------------

The provided code reproduces:

- [x] All numbers provided in text in the paper
- [ ] All tables and figures in the paper
- [x] Selected tables and figures in the paper, as explained and justified below.

It contains all numeric tables. The remainding tables are bibliographies and lists over articles referencing the triple difference estimator. 

- Table 4 of the paper is reproduced in 3_results.rmd at line 38
- Table 5 of the paper is reproduced in 3_results.rmd at line 76
- Table 6 of the paper is reproduced in 3_results.rmd at line 115


## References

> INSTRUCTIONS: As in any scientific manuscript, you should have proper references. For instance, in this sample README, we cited "Ruggles et al, 2019" and "DESE, 2019" in a Data Availability Statement. The reference should thus be listed here, in the style of your journal:

Steven Ruggles, Steven M. Manson, Tracy A. Kugler, David A. Haynes II, David C. Van Riper, and Maryia Bakhtsiyarava. 2018. "IPUMS Terra: Integrated Data on Population and Environment: Version 2 [dataset]." Minneapolis, MN: *Minnesota Population Center, IPUMS*. https://doi.org/10.18128/D090.V2

Department of Elementary and Secondary Education (DESE), 2019. "Student outcomes database [dataset]" *Massachusetts Department of Elementary and Secondary Education (DESE)*. Accessed January 15, 2019.

U.S. Bureau of Economic Analysis (BEA). 2016. “Table 30: "Economic Profile by County, 1969-2016.” (accessed Sept 1, 2017).

Inglehart, R., C. Haerpfer, A. Moreno, C. Welzel, K. Kizilova, J. Diez-Medrano, M. Lagos, P. Norris, E. Ponarin & B. Puranen et al. (eds.). 2014. World Values Survey: Round Six - Country-Pooled Datafile Version: http://www.worldvaluessurvey.org/WVSDocumentationWV6.jsp. Madrid: JD Systems Institute.
