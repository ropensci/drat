# rOpenSci drat Repository

[![Circle CI](https://circleci.com/gh/ropensci/drat/tree/gh-pages.svg?style=svg)](https://circleci.com/gh/ropensci/drat/tree/gh-pages)


Welcome to the rOpenSci drat repository.  This repository contains the latest nightly builds from the master branch of all rOpenSci packages currently on GitHub, along with the development versions of common dependencies, which include many packages from Hadley Wickham.

This allows users to install development versions of our software without specialized functions such as `install_github()`, allows
dependencies not hosted on CRAN to still be resolved automatically, and permits the use of `update.packages()`. 


## Download Logs

The rOpenSci packages repository publishes anonymous download statistics of packages pulled from the repository, using the same [format used by RStudio's CRAN mirror](http://cran-logs.rstudio.com/).  These can be found in a unified file at <http://packages.ropensci.org/downloads.csv>.  These may not be up to date.


## Quick Start

To use, simply add
`packages.ropensci.org` to your existing list of R repos, such as:

```r
options(repos = c("http://packages.ropensci.org", getOption("repos")))
```

(If you don't have any default CRAN mirrors selected yet by `getOption("repos")`, you may want to add one now). You can also include this line in specific `install.packages()` requests:

```r
install.packages("taxize", repos = c("http://packages.ropensci.org", "http://cran.rstudio.com"))
```

## Details

This is made possible by the excellent tools provided in Dirk Eddelbuettel's [drat](https://github.com/eddelbuettel/drat) package and Rich FitzJohn's [drat.builder](https://github.com/richfitz/drat.builder). Nightly
builds are performed using [CircleCi](https://circleci.com) and packages are served through an Amazon S3 static site. Configuration details
and scripts necessary for this can be found in our GitHub repo, [ropensci/drat](https://github.com/ropensci/drat). The list of rOpenSci packages included in
on the nightly builds of this repository is automatically generated using [ropensci/ropkgs](https://github.com/ropensci/ropkgs).  Once a package has been onboarded to our domain, 
there is no need to manually add it here to ensure it is included and updated. The list of third-party packages provided by this repo is found
in `packages.txt`.


This includes the following files:

- `circle.yml` CI file telling Circle how to build packages (running `build.R`) and deploy them (by running `deploy_S3.R`).
- `build.R` Main script file for generating the drat repo.
- `deploy_s3.R` deploy to Amazon S3 using [cloudyr/aws.s3](https://github.com/cloudyr/aws.s3) package (alpha).
- `parse_s3_logs.R` a script to parse Amazon S3 download logs into the same anonomous download summary csv format provided by RStudio's own CRAN mirror. 
- `packages.txt` A plain-text list of third party dependencies provided by the package.  Use this script to add additional packages to the repo that are not hosted on rOpenSci GitHub account.  

Other files:

- `ropensci.R` a script used by `build.R` which uses `ropkgs` to generate a list of all ropensci packages to be added to the drat repo (via writing an `ropensci.txt` file)
- `packages.json`, `ropensci.json` metadata files created by `drat.builder` to avoid rebuilding packages with no new commits.

### 


Please report any [issues here](https://github.com/ropensci/drat/issues).

License: BSD-2

[![ropensci footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)
