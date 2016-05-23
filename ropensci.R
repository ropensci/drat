#devtools::install_github("ropensci/ropkgs")
library("ropkgs")
out <- ro_pkgs()
good <- out$packages$status == "good"
installable <- out$packages$installable
exclude <- readLines("exclude.txt")
blacklist <- out$packages$name %in% exclude
pkgs <- gsub("https://github.com/", "", out$packages$url)[installable & good & !blacklist]
root <- out$packages$root[installable & good & !blacklist]

writeLines(paste(pkgs, root, sep="/"), "ropensci.txt")
