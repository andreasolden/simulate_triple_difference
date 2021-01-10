# simulate_triple_difference
Simulation of rejection rates in did and triple difference as in our paper. 

The raw data is available in data_based/data/raw_data. 

To reproduce our results, open and run the following scripts, in sequential order: 
* simulate_triple_difference.Rproj
* 0_merge.rmd 
* 1_wrangle.rmd
* 2_simulate.R
* 3_results.rmd

Note that this can take several days. 

For convenience we have therefore included the data and results from all steps of the procedure: 
* 0_merge.rmd produces df_merged.rds (needs to be unzipped, included as df_merged.7z in data/cleaned_data)
* 1_wrangle.rmd produces df_strip.rds (needs to be unzipped, included as df_strip.7z in data/cleaned_data)
* 2.simulate.R creates 4 files, also included in the folder sim_res


