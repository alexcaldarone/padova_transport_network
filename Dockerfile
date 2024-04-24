FROM python:3.10.12
WORKDIR /project
COPY . /project
RUN pip install -r requirements.txt
# Install R
RUN apt-get update && apt-get install -y \
    r-base \
    r-base-dev
# Install Java Runtime Environment (needed for tabula-py)
RUN apt-get install -y default-jre
# Installing two packages needed by lpSolveAPI in R (ergm dependency)
RUN apt-get install liblapack-dev libblas-dev
# installing pandoc to render R-markdown file to html
RUN apt-get install pandoc 
RUN Rscript src/install_R_dependencies.R ./R-requirements.txt