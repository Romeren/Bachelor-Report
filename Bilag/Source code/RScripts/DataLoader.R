loadRawData <- function(type = "All", 
                        onlyLiveMeters = FALSE, 
                        onlyBillingMeters = TRUE,
                        removeNonHourly = TRUE,
                        startTime, 
                        endTime = Sys.time(), 
                        buildingLimit = 0, 
                        minObservations = 0) {
    
  #Design where statement based on parameters
  where <- " WHERE b.measurement_serie_id NOTNULL";
  
  if(type != "All") {
    where <- easyPaste(where," AND b.meter_type = '", type , "'");
  }
  if(onlyBillingMeters) {
    where <- easyPaste(where, " AND b.isbillingmeter");  
  }
  
  #Put it all together in an SQL query
  sql <- easyPaste("SELECT DISTINCT building, measurement_serie_id, meter_type, isbillingmeter FROM meter b", where); 
  if(onlyLiveMeters) {
    sql <- easyPaste("SELECT DISTINCT a.building, b.measurement_serie_id, b.meter_type, b.isbillingmeter 
                   FROM usableBuildings a LEFT OUTER JOIN meter b ON a.measurement_serie_id = b.measurement_serie_id", where);
  }
    
  buildingsAndMeters <- executeSQL(sql);
  
  #Create a timesequence with hourly frequency from the beginning date to the end date
  startDate <- round(startTime, units="days");
  endDate <- startDate + days(round(difftime(endTime,startDate, units="days"))) - hours(1);
  timesequence <- seq.POSIXt(from = startDate, to = endDate, by = 'hours');
  
  result <- list();
  result[[1]] <- timesequence;
  
  dataLoaderTimesequence <<- timesequence;
  
  uniqueBuildings <- unique(buildingsAndMeters$building)
  
  #init the buildingindex at 2 so we dont overwrite the timesequence
  buildingIndex <- 2;
  for(building_id in uniqueBuildings) {
    if(buildingLimit != 0 && buildingIndex -1 > buildingLimit){
      break;
    }

    progressPrint("Load building ", buildingIndex-1, "/" ,length(uniqueBuildings));
    
    #Create the list that will contain the results for this building
    #The results are first a building id, and then lists of all observations for the building
    buildingData <- list(building_id);
    
    #Now lets first load the ids of the timeseries that exist for this building
    seriesIds <- buildingsAndMeters[buildingsAndMeters$building == building_id,]$measurement_serie_id;
    if(length(seriesIds) > 0) {
      allTimeSeriesForBuilding <- loadTotalSerieFromSeries(timeSerieIds = seriesIds, from = startDate, to = endDate);
      
      obsType_index <- 2;
      for(obsType in unique(allTimeSeriesForBuilding$obs_type)) {
        #Pull out the timeserie for this particular obstype
        timeserie <- allTimeSeriesForBuilding[allTimeSeriesForBuilding$obs_type == obsType,];
        if(length(timeserie$start_time) < minObservations || is.na(obsType)) {
          next;
        }
        
        #convert the char vectors to timestamps of type POSIXct as they are the smallest in size
        # TODO currently assuming dates are noted in GMT
        timeserie$start_time <- getDateFromString(timeserie$start_time);
        timeserie$end_time <- getDateFromString(timeserie$end_time);
        
        savedTimeserieVefore <<- timeserie;
        
        #Remove all measurements that arent hourly
        if(removeNonHourly) {
          timeserie <- timeserie[as.integer(difftime(timeserie$end_time, timeserie$start_time, units="hours")) == 1,];
        }
        
        savedTimeserieAfter <<- timeserie;
        
        #Now create a vector of obsvals that contain the index matching the timesequence
        obsValsVector <- rep(NA, length(timesequence));
        idx <- match(timeserie$start_time, timesequence);
        obsValsVector[idx[!is.na(idx)]] <- timeserie$obs_val;
        
        buildingData[[obsType_index]] <- list(obsType, obsValsVector);
        obsType_index <- obsType_index + 1;
      }
    }
    
    #Do not insert in final results if nothing came in for this building
    if(length(buildingData) > 1) {
      result[[buildingIndex]] <- buildingData;
      buildingIndex <- buildingIndex + 1;
    }
  }
  
  return(result);
}

#LOADS THE SUM OF OBSERVATION FOR EACH OBSERVATIONTIME
loadTotalSerieFromSeries <- function(timeSerieIds, from, to) {
  
  if(is.null(timeSerieIds)){ return(list());}
  
  commaSepSeries <- paste(timeSerieIds, collapse=",");
  subQuery <- easyPaste("select * from observationtimes where measurement_serie_id in(",commaSepSeries,")");
  
  if(!missing(from)) {
    subQuery <- easyPaste(subQuery, " AND START_TIME BETWEEN ",getDBFormattedTimeString(from)," AND ",getDBFormattedTimeString(to));
  }
  
  sql <- easyPaste("select ot.start_time::VARCHAR, ot.end_time::VARCHAR, sum(obs.obs_val) as obs_val, obs_type ",
                   "FROM (",subQuery,") ot ",
                   "INNER JOIN observations obs on obs.measurement_id=ot.measurement_id ",
                   "GROUP BY ot.start_time, ot.end_time, obs_type");
    
  return(executeSQL(sql))
}