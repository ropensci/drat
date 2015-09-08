#!/bin/bash
set -e

{
  git pull 
} > /dev/null 2>&1

git config --global user.email 'carl@ropensci.org' && git config --global user.name 'Carl Boettiger'
echo $(date) > date.txt
#git add *.json 
git add date.txt
git commit -m 'built and deployed from circle [ci skip]' 
{ 
  git push https://cboettig:$GH_TOKEN@github.com/ropensci/drat gh-pages 
} &> /dev/null 2>&1


