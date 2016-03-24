#!/usr/bin/Rscript
#devtools::install_github("cboettig/drat.builder")

## Use the latest PACKAGES, PACKAGES.gz files
library("downloader")
path <- c("src/contrib/PACKAGES", "src/contrib/PACKAGES.gz")
files <- paste0("http://packages.ropensci.org/", path)
for(i in 1:length(files)) 
  downloader::download(files[i], path[i])



library("drat.builder")
options(repos=c("http://cran.rstudio.com",
                "http://www.omegahat.net/R",
                "http://packages.ropensci.org",
                getOption("repos")))
## Don't commit if using S3 to deploy
build("packages.txt", install=TRUE, no_build_vignettes = TRUE, no_commit = TRUE)
source("ropensci.R")
build("ropensci.txt", install=TRUE, no_build_vignettes = TRUE, no_commit = TRUE)


