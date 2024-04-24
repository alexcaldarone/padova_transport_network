# Commands to execute locally
scrape_data:
	@echo "Checking if edge_list.csv exists..."
	@if [ -e data/clean/edge_list.csv ]; then \
		echo "File exists."; \
	else \
		echo "File does not exist. Running data_gathering_cleaning_pipeline.sh..."; \
		./data_gathering_cleaning_pipeline.sh; \
	fi

eda: scrape_data
	Rscript src/analysis/eda.R

models: scrape_data
	Rscript src/analysis/modelling.R

report: scrape_data
	Rscript -e "rmarkdown::render('src/technical_report.Rmd')"

# Commands to execute from docker
