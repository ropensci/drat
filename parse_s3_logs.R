library("aws.s3")
library("readr")
library("dplyr")
library("tidyr")
library("rgeolocate")

############## Downloading ###################################################

bucket <- "packages.ropensci.org"
## DOWNLOADING LOGS ISN'T WORKING YET
## Loop over getbucket to list all files
contents <- list()
marker <- NULL
continue <- TRUE
while(continue){
  b <- aws.s3::getbucket(bucket, marker = marker, region="us-west-2", 
                         key = Sys.getenv("AWS_ACCESS_KEY_ID"), 
                         secret = Sys.getenv("AWS_SECRET_ACCESS_KEY"))
  continue <- as.logical(b$IsTruncated)
  marker <- b[[length(b)]]$Key ## Seems to be ignored...
  contents <- c(contents, b[-1:-5])
}  
## Loop over getobject to download all files
files <- sapply(contents, function(x) x$Key)
for(f in files){
  p <- aws.s3::getobject(bucket, f)
}


################## Parsing ####################################################

# format: http://docs.aws.amazon.com/AmazonS3/latest/dev/LogFormat.html
# includes extra Timzone column that gets falsely parsed as separate from Time, due to the use of a space.
columns = c('Bucket_Owner', 'Bucket', 'Time', 'Timezone', 'Remote_IP', 'Requester',
            'Request_ID', 'Operation', 'Key', 'Request_URI', 'HTTP_status',
            'Error_Code', 'Bytes_Sent', 'Object_Size', 'Total_Time',
            'Turn_Around_Time', 'Referrer', 'User_Agent', 'Version_Id')
log_path <- 'logs/'
# parsing code: http://ferrouswheel.me/2010/01/python_tparse-fields-in-s3-logs/
log_entries = NULL
log_list <- list.files(log_path, recursive = TRUE) 

r <- read.delim(paste0(log_path, log_list[[1]]), sep = ' ', quote = '"', header = FALSE, col.names = columns, stringsAsFactors = FALSE)
classes <- sapply(r, class)

## This could probably be made faster?  The python version is quite fast here
## Might store list of already-processed files to avoid re-parsing them?
for(log in log_list){
  r <- read.delim(paste0(log_path, log), sep = ' ', quote = '"', header = FALSE, col.names = columns, stringsAsFactors = FALSE, na.strings = "-", colClasses = classes)
#  r <- readr::read_delim(paste0(log_path, log), delim=' ', quote='"', col_names = columns, na="-") ## SegFaults with "invalid permissions"
  r[[3]] <- paste(r[[3]], r[[4]])
  r <- r[-4]
  log_entries <- dplyr::bind_rows(log_entries, r)
}

# Format time as time
log_entries <- dplyr::mutate(log_entries, Time = lubridate::dmy_hms(Time))

# Write out for records.
readr::write_csv(log_entries, "log.csv")



## Format as RStudio CRAN logs
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
  dplyr::filter(grepl("R", User_Agent)) %>%
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
  


## Write anonymized, publishable data
readr::write_csv(downloads, "downloads.csv")

# Show total download counts by package
sort(table(downloads$package))
