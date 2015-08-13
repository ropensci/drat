
library("aws.s3")
s3copy <- function(path, bucket, recursive = FALSE, ...){
  who <- list.files(path = path, recursive = recursive)
  lapply(who, function(f){
    putobject(
      file = paste(path, f, sep="/"),
      bucket = bucket, 
      object = paste(path, f, sep="/"),
      ...)
  })
}
status <- s3copy("src", "packages.ropensci.org", recursive = TRUE, region="us-west-2", 
       key = Sys.getenv("AWS_ACCESS_KEY_ID"), secret = Sys.getenv("AWS_SECRET_ACCESS_KEY"))

