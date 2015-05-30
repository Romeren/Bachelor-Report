detectFaults <- function(timesequence, consumption, building_id, consumption_type) {
  comparisons <<- list();
  
  delay <- as.numeric(retrieveSetting(SETTING_DATADELAY_HOURS));
  
  x <- cbind(matrix(tail(consumption, delay), ncol = 24, byrow=TRUE), 
             matrix(tail(timesequence, delay), ncol = 24, byrow=TRUE)[,2]);
  
  #Find dates that already have an alarm :
  existingAlarmDates <- executeSQL("SELECT oddDate::VARCHAR 
                                   FROM w_alarms_odd_consumption 
                                   WHERE obsType=", consumption_type, " AND building=",building_id);
  
  existingAlarmDates <- if(length(existingAlarmDates) > 0) getDateFromString(unlist(existingAlarmDates)) else NA;
  
  #First remove those days which already has alarms
  if(!any(is.na(existingAlarmDates))) {
    x <- x[is.na(match(as.Date.POSIXct(x[,25]), existingAlarmDates)),];  
  }
  
  #Remove rows containing NA
  x <- x[rowSums(is.na(x)) == 0,];
  
  if(length(x) < 24) {
    debugPrint("Skipping fault detection for ", getConsumptionTypeName(consumption_type)," on ", building_id, " not enough usable data");
    return();
  }
  
  profiles <- executeSQL("SELECT * FROM w_consumption_profiles WHERE building=",building_id," AND consumption_type=",consumption_type);
  if(length(profiles) == 0) {
    debugPrint("Skipping fault detection for ", getConsumptionTypeName(consumption_type)," on ", building_id, " no consumption profiles found");
    return();
  }
  
  for(i in 1:(length(x)/24)) {
    day <- NA;
    if(length(x) == 24) {
      day <- getFeaturesForSingleDay(x[1:24], as.Date.POSIXct(x[25]));
    } else {
      day <- getFeaturesForSingleDay(x[i,1:24],  as.Date.POSIXct(x[i,25]));  
    }
    day <- day[-FEATURE_RAW_CONSUMPTION];
    testResults <- rep(0, length(profiles));
    for(j in 1:nrow(profiles)) {
      n <- sum(as.numeric(getVectorFromDbString(profiles[j,]$daycount)));
      profileMean <- as.numeric(getVectorFromDbString(profiles[j,]$mean))[-FEATURE_RAW_CONSUMPTION];
      profileSd <- as.numeric(getVectorFromDbString(profiles[j,]$sd))[-FEATURE_RAW_CONSUMPTION];
      
      #idx <- dayNotNA & !is.na(profileMean);
      debugPrint("profileMeans: ", profileMean, collapse = ",");
      debugPrint("profileSd: ", profileSd, collapse = ",");
      
      z = (profileMean - day)/(profileSd/sqrt(n));
      debugPrint("z: ", z, collapse = ",");
      
      pvals = 2 * pnorm(z);
      
      p <- prod(pvals, na.rm=TRUE);
      
      debugPrint("pvals: ", pvals, collapse = ",");
      debugPrint("p: ",p);
      
      comparisons <<- rbind(comparisons, list(profileMean, profileSd, round(day,2), round(pvals, 2)));
      
      #plot(profileMean[1:24], type="l", main= easyPaste("pvalue =", p));
      #lines(day[1:24], col="red");
    }
  }
}