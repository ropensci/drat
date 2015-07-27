
library("aws.s3")
s3copy <- function(path, bucket, recursive = FALSE, ...){
  who <- list.files(path = path, recursive = recursive)
  for(f in who){
    p <- putobject(
      file = f,
      bucket = bucket, 
      object = basename(f),
      ...)
  }
}
s3copy("src", "drat", recursive = TRUE, region="us-west-2", key = Sys.getenv("AWS_ACCESS_KEY_ID"), secret = Sys.getenv("AWS_SECRET_ACCESS_KEY"))
