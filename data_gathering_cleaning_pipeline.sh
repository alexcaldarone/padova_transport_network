#!/bin/bash
cd "$(dirname "$0")"

# if data directory does not exist, create it
if [ ! -d "data" ]; then
    mkdir data
fi

# create raw data directory
if [ ! -d "data/raw" ]; then
    mkdir data/raw/
fi

# create directory extraurbani_pdf
if [ ! -d "data/raw/extraurbani_pdf" ]; then
    mkdir data/raw/extraurbani_pdf
fi

# script scraper.py
echo "Downloading bus timetables..."
python3 src/data_gathering/scraper.py
echo "Finished downloading"

# deleting malformed file
echo "Deleting a malformed file..."
rm data/raw/extraurbani_pdf/LineaE019_1.pdf
echo "Done"

# creating clean data directory
if [ ! -d "data/clean" ]; then
    mkdir data/clean
fi

# script pdf_reader.py
echo "Reading data from pdf files..."
python3 src/data_gathering/pdf_reader.py
echo "Done"

# script json_cleaner.py
echo "Cleaning data in json files..."
python3 src/data_gathering/json_cleaner.py
echo "Finished"

echo "The finished edge list is in data/clean/edge_list.csv"