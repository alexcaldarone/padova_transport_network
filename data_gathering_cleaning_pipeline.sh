#!/bin/bash
cd "$(dirname "$0")"

# if data directory does not exist, create it
if [ ! -d "data" ]; then
    mkdir data
fi

if [ ! -d "data/raw" ]; then
    mkdir data/raw/
fi

# create directory extraurbani_pdf
if [ ! -d "data/raw/extraurbani_pdf" ]; then
    mkdir data/raw/extraurbani_pdf
fi

# avvia script scraper.py (rendi generale directory anziché tenere directory del mio computer)
echo "Downloading bus timetables..."
python3 scripts/data_gathering/scraper.py
echo "Finished downloading"

# elimina file corrispondente a linea19_1
echo "Deleting a malformed file..."
rm data/raw/extraurbani_pdf/LineaE019_1.pdf
echo "Done"

if [ ! -d "data/clean" ]; then
    mkdir data/clean
fi

# avvia script pdf_reader.py
echo "Reading data from pdf files..."
python3 scripts/data_gathering/pdf_reader.py
echo "Done"

# avvia script json_cleaner.py (cambia output in csv anzichè txt)
echo "Cleaning data in json files..."
python3 scripts/data_gathering/json_cleaner.py
echo "Finished"

echo "The finished edge list is in data/clean/edge_list.csv"