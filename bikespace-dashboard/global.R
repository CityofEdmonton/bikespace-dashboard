library("shiny")
library("shinydashboard")
library("RCurl")
library("jsonlite")
library("igraph")
library("highcharter")
library("rvest")
library("purrr")
library("tidyr")
library("dplyr")
library("stringr")
library("leaflet")
library("htmltools")
library("stringr")
library("RColorBrewer")
library("rmarkdown")
library("webshot")
library("shinyBS")
library("shinyjs")
library("shinyWidgets")
library("ggplot2")
library("Hmisc")
library("httr")

##-- Retrieve and clean data --##

# Data from API
getData <- function() {
       url <- "https://bikespace.edmonton.ca/api/dashboarddata"
       doc <- getURL(url)
       api_data <- as.data.frame(fromJSON(doc, flatten = TRUE))

       survey_data <- api_data[, c("dashboard.id","dashboard.problem","dashboard.latitude","dashboard.longitude",
                                   "dashboard.intersection","dashboard.comments","dashboard.duration", "dashboard.time", 
                                   "dashboard.pic")]
}

transformBikespace <- function(data) {
       # TEMPORARY SOLUTION FOR DURATION, CHANGE WHEN UX SET
       # Issue is that there are multiple values for duration, should be mutually exclusive
       # Exclude entries with multiple duration values (n=7)
       cat(file=stderr(), "transformBikespace")
       data$dashboard.duration <- unlist(data$dashboard.duration)[1:nrow(data)]
       data <-data[!grepl(",", data$dashboard.duration), ]

       # Also old duration categories in the data
       data$dashboard.duration <- if_else(grepl("hour", data$dashboard.duration), "hours", data$dashboard.duration)

       data$dashboard.duration <- capitalize(data$dashboard.duration)

       # Extract date and time from datetime variable
       data$date <- substr(data$dashboard.time,1,10)
       data$time <- substr(data$dashboard.time,12,19)

       # Format date and time variables
       data$date <- as.Date(strptime(data$date, "%Y-%m-%d"))
       data$time <- strptime(data$time, "%H:%M:%S")

       # Drop dashboard.time variables
       data <- data[, !(colnames(data) %in% c("dashboard.time"))]

       # Clean problem_type field so that lists (multiple problem types) in the field are
       # strings
       data$problem_type_collapse <- sapply(data$dashboard.problem, paste, collapse="; ")

       # Also replace commas with semi-colons for CSV export
       data$problem_type_collapse <- gsub(",", ";", data$problem_type_collapse)

       # Capitalize each problem type in field using function
       maketitle = function(txt){
       theletters = strsplit(txt,'')[[1]]
       wh = c(1,which(theletters  == ' ') + 1)
       theletters[wh] = toupper(theletters[wh])
       paste(theletters,collapse='')
       }

       data$problem_type_collapse <- sapply(data$problem_type_collapse, maketitle)

       # Replace 'Badly' with 'Abandonded'
       data$problem_type_collapse <- gsub("Badly", "Abandoned", data$problem_type_collapse)

       # Drop NA (n=1)
       data <- data[!grepl("NA", data$problem_type_collapse),]

       # Create date, weekday and hour variables
       data$weekday <- weekdays(data$date, abbreviate = TRUE)
       data$hour <- as.numeric(format(data$time, format="%H"))

       data$time_group <- ifelse(data$hour %in% c(7,8,9), "07-10",
                                   ifelse(data$hour %in% c(10,11,12), "10-13",
                                          ifelse(data$hour %in% c(13,14,15), "13-16",
                                                 ifelse(data$hour %in% c(16,17,18), "16-19",
                                                        ifelse(is.na(data$hour), NA,"19-07")))))

       # Rename variables
       colnames(data) <- c("id","problem_type", "problem_lat","problem_long","intersection",
                            "comment","duration","pic","date", "time","problem_type_collapse", 
                            "weekday", "hour", "time_group")

       # Drop report time variable
       data <- data[, !(colnames(data) %in% c("time"))]
}

rawLoadedData <- getData()
survey_data <- transformBikespace(rawLoadedData)

enableBookmarking(store = "url")