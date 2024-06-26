# Network Analysis of Padova's Public Transport System

The goal of this project, carried out as part of the University of Padua's Statistical Methods for Big Data course (Department of Statistics), is to use statistical methods to analyse the public transport system of the city and province of Padua.

In particular we will be considering the data available for the bus and tram lines operated by [BusItalia Veneto](https://www.fsbusitalia.it/content/fsbusitalia/it/veneto.html). 


## 1. Project outline (scraping, analysis, models)
This project allows the user to see the whole process of a data analysis project. Here you will find all the code needed to scrape and clean the data from the internet, to generate the graphs resulting from the exploratory data analysis and to fit the models. 

With all of this in mind, we also want the project to be easily reproducible. This is achieved through the use of a Makefile. Once the user has built the docker image (or installed the dependencies locally) all that is needed to reproduce all of the results is one simple command.

Leaving the technical details aside, this project has the goal to analyze the network generated by analysing the data regarding the bus stops in the province of Padova (you can find the websites from which the data was scraped [here](https://www.fsbusitalia.it/content/fsbusitalia/it/veneto/orari-e-linee/urbani-padova-e-linee-colli-dal-13-settembre-2023.html) and [here](https://www.fsbusitalia.it/content/fsbusitalia/it/veneto/orari-e-linee/extraurbani-padova-dal-13-settembre-2023.html)). Once the data is scraped, cleaned and saved in and edge-list, the structure obtained is that of a multigraph (an undirected graph where multiple edges between two nodes are allowed to exit). During the exploratory data analysis we wish to verify whether the network is _scale-free_ and _small-world_. 

Subsequently, we try to estimate some ERGMs (_Exponential Random Graph Models_) to describe the struture of the network. In order to do this we move from a multigraph representation of the network to that of a weighted graph (the weight of an edge is equal to the number of edges that were previously present between two nodes). Finally, we estimate a Poisson model to try to describe the weight of the edges in the network as a function of some variables about the adjacent nodes to those edges.

The analysis and the models estimated are all available in the technical report which the user can generate automatically (instructions below).

### 1.1 Folder structure
```
├──  data
    ├── raw   # raw data from scraping
    └── clean # cleaned data
├── images
    ├── eda   # images generated during analysis
    └──  gephi # images imported from gephi
├── src
    ├── analysis  # folder with code used for modelling and analysis
    ├── data_gathering    # folder with code used to scrape/clean data
    ├── technical_report.Rmd # R-markdown file to generate technical report
    └──  install_R_dependencies.R # file to install R libraries
├── data_gathering_cleaning_pipeline.sh # scraping pipeline
├── Dockerfile
├── LICENSE
├── Makefile
├── README.md
├── R-requirements.txt
└── requirements.txt
```

## 2. How to replicate

In order to replicate the results of this project, you will have to first clone the repository. After that you can decide whether to build the corresponding Docker image (recommended) or run the project locally.

```
git clone https://github.com/alexcaldarone/padova_transport_network.git
cd padova_transport_network
```

### 2.1 Using Docker (recommended)
_(While it is recommended to run the project using Docker, beware of the fact that the image built will have size exceeding one gigabyte because of the various dependencies needed)_

To build the docker image of the project run the following command:
```
docker build -t msbd-project .
```
**Please note that installing (and compiling) the required R libraries may take _several_ minutes**

After the container has been built, you can automatically generate the report using the following commad:
```
make docker_show_report
```

### 2.2 Local
If you do not want to build the Docker image for the project, once you have cloned the repo you will have to install the necessary Python and R dependencies needed for the code to run.

In order to reproduce the project you will need the following software:
- Python 3
- R
- Pandoc
- Java Runtime Environment
- The libraries LAPACK and BLAS (needed fot the `ergm` R libary)

```
pip install -r requirements.txt
Rscript src/install_R_dependencies.R ./R-requirements.txt
```
**Please note that installing (and compiling) the required R libraries may take _several_ minutes**

After having installed the necessary dependencies, you can automatically generate the technical report using the following command:
```
make show-report
```

### 2.3 Other Makefile commands

If you do not want to replicate the technical report, but are just interested in the exploratory data analysis or the modelling, you can run the following commands

- **Using the Docker image**
    - To run the exploratory data analysis: 
        ```
        make docker_eda
        ``` 
        The plots generated by this file will be saved in the `images/eda` folder.
    - To run the file containing the models
        ```
        make docker_models
        ```
- **Locally**
    - To run the exploratory data analysis: 
        ```
        make eda
        ``` 
        The plots generated by this file will be saved in the `images/eda` folder.
    - To run the file containing the models
        ```
        make models
        ```

These commands will run the corresponding R files containing the code to generate the plots of the exploratory data analysis or to fit the models used. Of course, this code is included in the technical report, so we recommend you just execute the command to create that (see sections 2.1 and 2.2).

---
### Authors
- Alex John Caldarone
- Patrick Lazzarin