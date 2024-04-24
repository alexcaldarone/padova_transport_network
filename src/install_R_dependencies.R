# File to be called from command line to install the 
# necessary libraries before any analysis takes place
# usage: Rscript install_R_dependencies.R [text file with libraries]

# Define function to install libraries
install_libraries_from_file <- function(file_path) {
  libs <- scan(file_path, what = character())
  install.packages(libs)
}

# Check if command-line argument is given
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript install_libraries.R <libraries_file>")
}

# Get path to libraries file
libraries_file <- args[1]

# install libraries
install_libraries_from_file(libraries_file)