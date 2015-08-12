# rOpenSci drat Repository

[![Circle CI](https://circleci.com/gh/ropensci/drat/tree/gh-pages.svg?style=svg)](https://circleci.com/gh/ropensci/drat/tree/gh-pages)


Welcome to the rOpenSci drat repository.  This repository contains the latest nightly builds from the master branch of all rOpenSci packages currently on GitHub, along with the development versions of common dependencies, which include many packages from Hadley Wickham.

This allows users to install development versions of our software without specialized functions such as `install_github()`, allows
dependencies not hosted on CRAN to still be resolved automatically, and permits the use of `update.packages()`. 


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
on the nightly builds of this repository is automatically generated using [ropensci/ropkgs]().  Once a package has been onboarded to our domain, 
there is no need to manually add it here to ensure it is included and updated. The list of third-party packages provided by this repo is found
in `packages.txt`.


This includes the following files:

- `circle.yml` CI file telling Circle how to build packages (running `build.R`) and deploy them (by running `deploy_S3.R`).
- `build.R` Main script file for generating the drat repo.
- `deploy.R` deploy to Amazon S3 using [clodyr/aws.s3]() package (alpha).
- `packages.txt` A plain-text list of third party dependencies provided by the package.
- `packages.json`, `ropensci.json` metadata files created by `drat.builder` to avoid rebuilding packages with no new commits.


Please report any [issues here](https://github.com/ropensci/drat/issues).

License: BSD-2

[![ropensci footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)
