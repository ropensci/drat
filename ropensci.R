#devtools::install_github("ropensci/ropkgs")
library("ropkgs")
out <- ro_pkgs()
good <- out$packages$status == "good"
installable <- out$packages$installable
pkgs <- out$packages$name[installable & good]
root <- out$packages$root[installable & good]

writeLines(paste("ropensci", pkgs, root, sep="/"), "ropensci.txt")
