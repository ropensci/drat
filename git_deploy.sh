#!/bin/bash

git config --global user.email 'carl@ropensci.org' && git config --global user.name 'Carl Boettiger'
git add *.json && git commit -m 'built and deployed from circle [ci skip]' && git push https://cboettig:${GH_TOKEN}@github.com/cboettig/drat gh-pages 

