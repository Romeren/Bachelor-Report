MAX_GAP_LINEAR_INTERPOLATION = 5;
SETTING_EPOCH <- "epoch";
SETTING_LAST_UPDATE <- "lastUpdate";
SETTING_LAST_PROFILE_UPDATE <- "lastProfileUpdate";
SETTING_PROFILE_UPDATE_FREQ_DAYS <- "profileUpdateFreqDays";

updateDataArrays <- function(buildingData, timeSequence) {
  
  epoch <- getDateFromString(retrieveSetting(SETTING_EPOCH));
  
  lastUpdate <- retrieveSetting(SETTING_LAST_UPDATE);
  lastUpdate <- if(is.na(lastUpdate)) epoch else getDateFromString(lastUpdate);
  dataDelayHours <- as.numeric(retrieveSetting(SETTING_DATADELAY_HOURS));
  
  rawData <- loadRawData(startTime = lastUpdate - hours(dataDelayHours), buildingLimit = LIMIT_BUILDINGS);
  timeSequence <- rawData[[1]];
  
  #Get shift between epoch timesequence and loaded timesequence
  epochTimeSequence <- seq.POSIXt(from = epoch, to = max(timeSequence), by = 'hours');
  idx <- match(timeSequence, epochTimeSequence);
  idx <- idx[!is.na(idx)];
  
  #Sequence of days used for seasonality
  epochDaySequence <- as.Date(seq.POSIXt(from = epoch, to = max(timeSequence), by = 'days'));
  
  
  profileUpdateFreq <- as.numeric(retrieveSetting(SETTING_PROFILE_UPDATE_FREQ_DAYS));
  lastProfileUpdate <- getDateFromString(retrieveSetting(SETTING_LAST_PROFILE_UPDATE));
  doUpdateProfiles <- (FORCE_UPDATE_PROFILES || ((lastProfileUpdate + days(profileUpdateFreq)) < Sys.time())); 
  
  for(BUILDING_INDEX in 2:length(rawData)) {
    progressPrint("Processing building ",BUILDING_INDEX, " of ", length(rawData));
    
    building <- rawData[[BUILDING_INDEX]];
    building_id <- building[[1]];
    
    for(SERIE_INDEX in 2:length(building)) {
      serie <- building[[SERIE_INDEX]];
      consumption_type <- serie[[1]];
      consumption <- serie[[2]];
      
      result <- executeSQL("SELECT building_id,consumption_type,consumption FROM w_consumptions WHERE building_id=",building_id," AND consumption_type=",consumption_type);
      if(nrow(result) != 0) {
        dbConsumption <- getNumVectorFromDbString(result[[1,3]]);
        dbConsumption[idx] <- consumption[1:length(idx)];
        consumption <- dbConsumption;
        
        #Remove the old row as a new will be inserted
        executeSQL("DELETE FROM w_consumptions WHERE building_id=",building_id," AND consumption_type=",consumption_type, isQuery = FALSE);
      }
      
      #SKIP if less than 5 values in whole serie
      if(sum(!is.na(consumption)) < 5) {
        next;
      }
      
      # Trying interpolation
      consumption[consumption == -1] <- NA
      consumption <- na.approx(consumption, maxgap=MAX_GAP_LINEAR_INTERPOLATION, na.rm = FALSE);
      
      #Calculate the seasonality
      seasonality <- rep(x = NA, times = length(epochDaySequence));
      for(i in 1:length(epochDaySequence)) {
        values <- consumption[match(as.Date(epochTimeSequence), epochDaySequence) == i];
        values <- values[!is.na(values)];
        if(length(values) > 20) {
          seasonality[i] <- min(values);
        }
      }
      if(sum(!is.na(seasonality)) > 5) {
        seasonality <- na.approx(seasonality, maxgap=MAX_GAP_LINEAR_INTERPOLATION, na.rm = FALSE);  
      }
      
      #Updating consumption profiles
      if(doUpdateProfiles) {    
        updateConsumptionProfiles(epochTimeSequence, consumption, building_id, consumption_type)  
      }
      
      #Detect faults
      detectFaults(epochTimeSequence, consumption, building_id, consumption_type);
      
      #Convert to database readable array
      consumption[is.na(consumption)] <- - 1;
      consumption <- getDbStringFromVector(consumption);
      
      seasonality[is.na(seasonality)] <- - 1;
      seasonality <- getDbStringFromVector(seasonality);
      
      values <- easyPaste(building_id, consumption_type, consumption,seasonality, collapse=",");
      executeSQL("INSERT INTO w_consumptions VALUES(",values,")", isQuery = FALSE);
    }
  }
  
  #Update database with new last update times
  updateSetting(SETTING_LAST_UPDATE, getFormattedTimeString());
  if(doUpdateProfiles) {
    updateSetting(SETTING_LAST_PROFILE_UPDATE, getFormattedTimeString());
  }
}