#library('rrcovHD')
#library('robust')
#library('recommenderlab')
SETTING_START_WINTHER = "startWintherTime";
SETTING_END_WINTHER = "endWintherTime";

HOURS_PR_DAY = 24;
DAYS_PR_WEEK = 7;
HOURS_PR_WEEK = HOURS_PR_DAY * DAYS_PR_WEEK;

MIN_SIZE_OF_CLUSTERS = 3;
MIN_COMPARISON_VARIABLES = 10;
DISCRETIZE_INTERVAL = 6;

#These functions can round up or down to nearest number divisable by m.
roundUp <- function(x,m = 24) m*ceiling(x / m)
roundDown <- function(x,m = 24) m*floor(x / m)

updateConsumptionProfiles <- function(epochHourlySeq, 
                                      consumption,
                                      building_id,
                                      consumption_type,
                                      plot = FALSE, 
                                      sensitivity = 0.05, 
                                      removeSeasonality = TRUE, 
                                      accountForWinther = FALSE, 
                                      removeBeforeClusteringOutliers = FALSE, 
                                      removeWithinClusterOutliers = TRUE) {
  
  progressPrint("Calculating ",getConsumptionTypeName(consumption_type)," profiles for ", building_id);
  debugPrint("Consumption length at input is ", length(consumption));
  
  #Clean out old profiles :
  executeSQL("DELETE FROM w_consumption_profiles WHERE building=",building_id," AND consumption_type=",consumption_type, isQuery = FALSE);  
  
  if(length(which(!is.na(consumption))) < MIN_SIZE_OF_CLUSTERS * 24) {
    progressPrint("1: Will skip calculating ",getConsumptionTypeName(consumption_type)," for building ",building_id," because to few usable days");
    return();
  }
  
  set.seed(1);
  
  #Will assume that data is interpolated and missing values are encoded as NA
  #Crop of leading and trailing NA because large amout in the begining and in the end can be NA
  #Also use the roundUp/Down functions to make sure we have a whole amount of days
  seriesStart <- roundUp(min(which(!is.na(consumption)))) + 1;
  seriesEnd <- roundDown(max(which(!is.na(consumption))));
  
  consumption <- consumption[seriesStart:seriesEnd];
  epochHourlySeq <- epochHourlySeq[seriesStart:seriesEnd];
  
  debugPrint("Consumption length after removing leading/trailing NA's  ", length(consumption));
  
  if(accountForWinther) {
    startWintherTime = getDateFromString(retrieveSetting(SETTING_START_WINTHER));
    endWintherTime = getDateFromString(retrieveSetting(SETTING_START_WINTHER));
    
    #Finding the indexes of winther hours
    wintherHours <- match(seq.POSIXt(from = startWintherTime, to = endWintherTime, by = 'hours'), epochHourlySeq);
    wintherHours <- wintherHours[!is.na(wintherHours)];
    
    consumption[wintherHours] <- consumption[wintherHours + 1];
  }
  
  #### Use this method to extract the various features from each day ###
  seriesMatrix <- extractFeatures(consumption, epochHourlySeq);
  
  if(length(seriesMatrix) / 25 < MIN_SIZE_OF_CLUSTERS) {
    progressPrint("2: Will skip calculating ",getConsumptionTypeName(consumption_type)," for building ",building_id," because to few usable days");
    return();
  }

  if(removeSeasonality) {
    for(row in 1:nrow(seriesMatrix)) {
      seriesMatrix[row,1:24] <- seriesMatrix[row,1:24] - seriesMatrix[row, FEATURE_MIN];
    }
  }
  
  #### OUTLIERS ######
  # First round of removing outliers #
  if(removeBeforeClusteringOutliers) {
    outliers <- findOutliers(data = seriesMatrix[,1:24], sensitivity, plot, default = 1);
    seriesMatrix <- seriesMatrix[outliers == 1,];
    
    infoPrint("Removed outliers: ", length(outliers[outliers==0]));        
  }
  
  #### CLUSTERING ####
  n <- nrow(seriesMatrix);
  krange <- min(5, max(n-3, 1)):min(10,n-1);
  
  infoPrint("Will attempt clustering with n=", n,", krange=", min(krange), " to ", max(krange));
  
  optimalNumberOfClusters <- pamk(data = seriesMatrix[,1:24], krange = krange)$nc;
  clusterData <- kmeans(x = seriesMatrix[,1:24], centers = optimalNumberOfClusters, iter.max = 50);
  clusters <- levels(factor(clusterData$cluster));
  
  infoPrint("Sucessfully created clusters ", clusters);
  
  for(cluster in clusters) {
    rows <- which(clusterData$cluster == cluster);
      
    if(removeWithinClusterOutliers && length(rows) > MIN_SIZE_OF_CLUSTERS) {
      outliers <- findOutliers(data = seriesMatrix[rows, 1:24], sensitivity, plot, default = 1);
      rows <- rows[outliers == 1];

      infoPrint("Removed ", length(outliers[outliers==0]), " outliers from cluster ", cluster);       
    }
    
    clusterSize <- length(rows);
    infoPrint("Size of cluster ", cluster, " is ", length(rows));
    
    if(clusterSize < MIN_SIZE_OF_CLUSTERS) {
      infoPrint("Will skip cluster ",cluster," because to few usable days");
      next;
    }
    
    #Calculate the data for entire day
    means <- colMeans(seriesMatrix[rows,1:37], na.rm = TRUE);
    means[!is.finite(means)] <- -1;
    
    sds <- apply(seriesMatrix[rows,1:37], 2, function(x) { sd(x, na.rm=TRUE) });
    sds[!is.finite(sds)] <- -1;
    
    daysCount <- sapply(1:7, function(day) { length(which(seriesMatrix[rows,FEATURE_DAY_OF_WEEK] == day))});
    
    # Insert into the database
    values <- easyPaste(building_id, consumption_type, cluster, getDbStringFromVector(means), getDbStringFromVector(sds), getDbStringFromVector(daysCount), collapse = ",");
    executeSQL("INSERT INTO w_consumption_profiles VALUES(",values,")", isQuery = FALSE);
  }
}

findOutliers <- function(data, sensitivity, plot, default = 0) {
  outliers <- rep(x = default, times = trunc(length(data)/24));
  
  if(length(outliers) < MIN_SIZE_OF_CLUSTERS) {
    return (outliers);
  } 
  else {
    #Select only the colums in which there is not 50% or more equal values 
    cols <- which(apply(data, 2, function(col) { mad(col) != 0}));
    
    if(length(cols) >= MIN_COMPARISON_VARIABLES) {
      infoPrint(length(cols)," cols will be used for pcout");
      outliers <- pcout(x = data[,cols], outbound = sensitivity, makeplot = plot)$wfinal01;
    }
    return (outliers);
  }
}