# simulate_triple_difference

Simulation of rejection rates in did and triple difference as in our paper. 

To reproduce our results, open and run the following scripts (in folder r_scripts), in sequential order: 

* simulate_triple_difference.Rproj
* 0_merge.rmd 
* 1_wrangle.rmd
* 2_simulate.R
* 3_results.rmd

#### Make especially sure that you always open the Rproj file first to ensure that the relative file paths work. 

#### Note that this can take several days. 

For convenience we have therefore included the data and results (in folder r_scripts) from all steps of the procedure: 

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

The simulations are run using 24 cores (max by default in the code) on: 

Microsoft Windows Server 2016 Standard
Intel(R) Xeon(R) CPU E5-2660 v2 @ 2.60GHz, 64 RAM, w X Virtual? cores
R version 4.0.3 (2020-10-10) -- "Bunny-Wunnies Freak Out"
x86_64-w64-mingw32/x64 (64-bit)

Rstudio Version 1.3.1093
"Apricot Nasturtium" (aee44535, 2020-09-17) for Windows
