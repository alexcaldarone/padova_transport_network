FROM python:3.10.12
WORKDIR /project
COPY . /project
RUN pip install -r requirements.txt
# Install R
RUN apt-get update && apt-get install -y \
    r-base \
    r-base-dev
# Install Java Runtime Environment
RUN apt-get install -y default-jre
RUN Rscript src/install_R_dependencies.R ./R-requirements.txt