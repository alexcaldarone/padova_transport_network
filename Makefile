scrape_data:
	ifeq ($(wildcard data/clean/edge_list.csv),)
		./data_gathering_cleaning_pipeline.sh
	endif

eda:
	Rscript src/analysis/eda.R

models:
	Rscript src/analysis/modelling.R
