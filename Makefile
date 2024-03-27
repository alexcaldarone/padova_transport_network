scrape_data:
    ifeq ($(wildcard data/clean/edge_list.csv),)
        ./data_gathering_cleaning_pipeline.sh
    endif

