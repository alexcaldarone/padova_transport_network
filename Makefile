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

compile_report: scrape_data
	Rscript -e "rmarkdown::render('src/technical_report.Rmd')"

show_report: compile_report
	@xdg-open src/technical_report.html || open src/technical_report.html

# Commands to execute from docker
DOCKER_IMAGE = msbd-project

docker_scrape_data:
	docker run $(DOCKER_IMAGE) make scrape_data

docker_eda: docker_scrape_data
	docker run $(DOCKER_IMAGE) make eda

docker_models: docker_scrape_data
	docker run $(DOCKER_IMAGE) make models

docker_compile_report: docker_scrape_data
	docker run -v $(PWD):/project $(DOCKER_IMAGE) make compile_report

# Command to open the generated report from the Docker image
docker_show_report: docker_compile_report
	docker run -d -p 8000:8000 -v $(PWD):/project $(DOCKER_IMAGE) python3 -m http.server 8000
	@sleep 2
	@xdg-open http://localhost:8000/src/technical_report.html || open http://localhost:8000/src/technical_report.html
