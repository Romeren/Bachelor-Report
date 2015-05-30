library("RPostgreSQL")

#Library for easier manipulation with dates
library("lubridate")

#Used for interpolation and working with timeseries
library("zoo")
library("xts")

#library containing the pcout function used to detect outliers, mvoutlier requires sgeostat
library("mvoutlier")

#Used for the pamk method which detects optimal no of clusters
library('fpc')

OS <- Sys.info()[['sysname']];
WORKDIR = switch(OS,
                 Windows= "C:/bachelor/Smack-my-lazy-ass-stallion-R-script/linux/",
                 Linux  = "/home/folderlistener/RScripts/");

SETTING_DATADELAY_HOURS <- "dataDelayHours";

#-----------------------------------
# DBconnection:
#-----------------------------------
fakeDb <- TRUE; #When this is true all non query statements will just be printed to the console
usernam <- "power_user";
passwrd <- "smackthatstallion";
portNr <- 5432;
hostIP <- switch(OS, Windows= "52.11.127.152", Linux  = "localhost");
dbnam <- "template1";

# Set to zero if number of loaded buildings should not be limited
LIMIT_BUILDINGS = 1;
FORCE_UPDATE_PROFILES = FALSE;

PRINT_ERROR = 0;
PRINT_PROGRESS = 1;
PRINT_SQL = 2;
PRINT_INFO = 3;
PRINT_DEBUG = 4;

#Add all the kind of information that should be printed 
TO_PRINT = c(PRINT_ERROR, PRINT_PROGRESS, PRINT_DEBUG);

sourceFiles <- c("Utils.R", "DataLoader.R", "w_consumption_updater.R", "w_consumption_profiles_updater.R", "FeatureExtractor.R", "FaultDetector.R");
for(file in sourceFiles) { source(paste(c(WORKDIR, file), collapse = "")); }

######################### DO THE MAGIC #########################
initNewDbConnection();

# Copy newest data from db into w_consumption
updateDataArrays();

closeDbConnection();
####################### QUIT APPLICATION ########################
#quit(save = "no", status = 0, runLast = TRUE);