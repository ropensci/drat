library("aws.s3")


s3copy <- function(path, bucket, recursive = FALSE, ...){
  who <- list.files(path = path, recursive = recursive)
  sapply(who, function(f){
    p <- putobject(
      file = paste(path, f, sep="/"),
      bucket = bucket, 
      object = paste(path, f, sep="/"),
      ...)
    closeAllConnections()
    if(!is.logical(p)){
      warning(paste("uploading", f, "failed:", p$Message))
    }
  })
}

## Upload packages to S3
status <- s3copy("src", "packages.ropensci.org", 
                 recursive = TRUE, 
                 region="us-west-2", 
                 key = Sys.getenv("AWS_ACCESS_KEY_ID"), 
                 secret = Sys.getenv("AWS_SECRET_ACCESS_KEY"))
warnings()

## Parse the download logs, update the log summary, delete the raw log files
source("parse_s3_logs.R")


