library("aws.s3")
library("readr")
library("dplyr")
library("tidyr")
library("rgeolocate")
library("httr")


# globals
bucket <- "packages.ropensci.org"
region <- "us-west-2"

############## Downloading ###################################################
download_logs <- function(){
  ## Loop over getbucket to list all files
  contents <- list()
  marker <- NULL
  continue <- TRUE
  while(continue){  # not working yet, so just do first 1000
    b <- aws.s3::get_bucket(bucket = "", path = bucket, marker = marker, region = region, prefix="logs/")
    continue <- as.logical(b$IsTruncated)
    marker <- b[[length(b)]]$Key ## Seems to be ignored...
    contents <- c(contents, b[-1:-5])
    message(sprintf("Marker at %s, continue is %s", marker, as.character(continue)))
    continue
  }  
  if(!dir.exists("logs")) 
    dir.create("logs")
  ## Loop over getobject to download all files
  files <- sapply(contents, function(x) x$Key)
  for(f in files){
    p <- aws.s3::get_object(bucket = "", object = paste0(bucket, "/", f), region = region)
    bin <- httr::content(p, "raw")
    writeBin(bin, f)
  }
}

columns = c('Bucket_Owner', 'Bucket', 'Time', 'Timezone', 'Remote_IP', 'Requester',
            'Request_ID', 'Operation', 'Key', 'Request_URI', 'HTTP_status',
            'Error_Code', 'Bytes_Sent', 'Object_Size', 'Total_Time',
            'Turn_Around_Time', 'Referrer', 'User_Agent', 'Version_Id')
################## Parsing ####################################################
parse_logs <- function(){
  # format: http://docs.aws.amazon.com/AmazonS3/latest/dev/LogFormat.html
  # based on: http://ferrouswheel.me/2010/01/python_tparse-fields-in-s3-logs/
  # includes extra Timzone column that gets falsely parsed as separate from Time, due to the use of a space.
  
  col_types = paste0(rep("c", length(columns)), collapse="")
  log_path <- 'logs/'
  log_list <- list.files(log_path, recursive = TRUE) 
  
  
  entries <- 
    lapply(log_list, function(log){  
      r <- readr::read_delim(paste0(log_path, log), delim=' ', 
                             quote='"', col_names = columns, na="-",
                             col_types = col_types) ## SegFaults with "invalid permissions"
    ## Fix broken date column
    r[[3]] <- paste(r[[3]], r[[4]])
    r <- r[-4]
    r  
  })
  
  log_entries <- do.call(dplyr::bind_rows, entries) %>%
    dplyr::mutate(Time = lubridate::dmy_hms(Time))
  
  
  
  return(log_entries)
}

append_and_update <- function(log_entries){
  # Download previously parsed records.  
  p <- aws.s3::get_object(bucket = "", object = paste(bucket, 'logs', 'log.csv', sep='/'), region = region, parse_response = FALSE)
  if(httr::status_code(p) == 200){
    bin <- httr::content(p, "raw")
    writeBin(bin, "logs/log.csv")
  }
  ## Append previously parsed records to newly parsed ones.  Assumes we are deleting parsed records from S3
  if(file.exists("logs/log.csv")){
    col_types = paste0(rep("c", length(columns)), collapse="")
    prev_logs <- readr::read_csv("logs/log.csv",
                                 col_types =  paste0(rep("c", 18), collapse=""))
    
    log_entries <- dplyr::mutate(log_entries, Time = as.character(Time))
    
    
    log_entries <- dplyr::bind_rows(prev_logs, log_entries)
  }
  # Write out for records.
  readr::write_csv(log_entries, "logs/log.csv")
  ## Upload updated logs to S3
  aws.s3::put_object(object = paste(bucket, 'logs', 'log.csv', sep='/'), file = "logs/log.csv", bucket = "" ,region = region)

  log_entries
}
  
delete_logs <- function(){  
  ## Remove old log files from S3.  This avoids parsing bottle-necks.
  log_path = "logs/"
  log_list <- list.files(log_path, recursive = TRUE) 
  
  for(f in log_list){
    p <- aws.s3::delete_object(bucket = "", object = paste0(bucket, "/", log_path,f), region = region)
  }
}



## Format as RStudio CRAN logs
tidy_logs <- function(log_entries){
  pkgname <- function(key){
      pattern <- "src/contrib/(.*)_(.*)\\.tar\\.gz"
      gsub(pattern, "\\1", key)
  }
  pkgvers <- function(key){
      pattern <- "src/contrib/(.*)_(.*)\\.tar\\.gz"
      gsub(pattern, "\\2", key)
  }
  maxmind_data <- system.file("extdata","GeoLite2-Country.mmdb", package = "rgeolocate")
  # Desired columns: date, time, size, r_version, r_arch, r_os, package, version, country, ip_id,
  
  log_entries %>%
    ## Filter out anything that doesn't come from an R user-agent (e.g. mostly internal operations updating the drat repo and logs
    dplyr::filter(grepl("^R ", User_Agent)) %>%
    dplyr::select(Time, Remote_IP, Key, User_Agent, size = Bytes_Sent, Error_Code) %>%
    dplyr::filter(is.na(Error_Code)) %>%
    ## Parse User_Agent into r_version, r_arch, r_os 
    dplyr::mutate(User_Agent = gsub("\\(|\\)", "", User_Agent)) %>%
    tidyr::separate(User_Agent, c("R", "r_version", "cpu", "r_arch", "r_os"), sep = " ") %>% 
    dplyr::select(-R, -cpu, -Error_Code) %>%
    ## Parse Key into package, version
    dplyr::filter(!grepl("src/contrib/PACKAGES.gz", Key)) %>%
    dplyr::mutate(package = pkgname(Key), version = pkgvers(Key)) %>% 
    dplyr::select(-Key) %>%
    ## Anonymize IP and convert to RStudio log format: (slow!)
    dplyr::mutate(country = rgeolocate::maxmind(Remote_IP, maxmind_data, "country_code")[[1]]) %>%
    dplyr::mutate(ip_id = as.integer(as.factor(Remote_IP)))  %>% 
    dplyr::arrange(Time) %>% dplyr::select(-Remote_IP) %>%
    ## Date and time separate, though not sure that's a good idea... Maybe for vis of diurnal patterns.
    tidyr::separate(Time, c("date", "time"), sep = " ") -> 
    downloads
  downloads 
}


publish_logs <- function(downloads){
  ## Write anonymized, publishable data
  file <- "downloads.csv"
  readr::write_csv(downloads, file)
  ## Push downloads table to Amazon S3 for future use
  p <- aws.s3::put_object(file = file, object = paste0(bucket, "/", file), bucket = "", region = region)
}


################################### Run  ##############


download_logs()
log_entries <- parse_logs()
log_entries <- append_and_update(log_entries)
delete_logs()
downloads <- tidy_logs(log_entries)
publish_logs(downloads)


# Show total download counts by package
totals <- sort(table(downloads$package))
write.csv(totals, "total_downloads.csv")
totals