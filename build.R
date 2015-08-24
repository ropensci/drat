#!/usr/bin/Rscript
#devtools::install_github("cboettig/drat.builder")
library("drat.builder")
options(repos=c("http://cran.rstudio.com",
                "http://www.omegahat.org/R",
                "http://packages.ropensci.org",
                getOption("repos")))
## Don't commit if using S3 to deploy
build("packages.txt", install=TRUE, no_build_vignettes = TRUE, no_commit = TRUE)
source("ropensci.R")
build("ropensci.txt", install=TRUE, no_build_vignettes = TRUE, no_commit = TRUE)


