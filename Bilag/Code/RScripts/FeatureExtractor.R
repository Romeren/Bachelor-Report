FEATURE_RAW_CONSUMPTION <- 1:24;

#Consumptionfigures
FEATURE_MEAN <- 25;
FEATURE_PEAK <- 26;
FEATURE_MIN <- 27;

FEATURE_NIGHT <- 28;
FEATURE_MORNING <- 29;
FEATURE_AFTERNOON <- 30;
FEATURE_EVENING <- 31;
#Ratios
FEATURE_MEAN_OVER_MAX <- 32;
FEATURE_MIN_OVER_MEAN <- 33;
FEATURE_NIGHT_OVER_DAY <- 34;
#Temporal properties
FEATURE_TIME_DAILY_MAX <- 35;
FEATURE_HOURS_ABOVE_MEAN <- 36;
#Statistical properties
FEATURE_NO_OF_PEAKS <- 37;

FEATURE_DAY_OF_WEEK <- 38;

extractFeatures <- function(x, timesequence) {
  #This matrix will have cols for each feature, and a row for each day
  x <- matrix(x, ncol = 24, byrow=TRUE);
  
  #Calculate day of week feature but do not add it yet
  dayOfWeek <- getDayOfWeek(timesequence[seq(1, length(timesequence), 24)]);
  
  #find and only use the rows that have no NA values
  idx <- rowSums(is.na(x)) == 0;
  x <- x[idx, ];
  dayOfWeek <- dayOfWeek[idx];
  
  debugPrint("NA rows omitted = ", length(which(!idx)));
  
  #Attach mean, max, min of each day
  x2 <- cbind(x, rowMeans(x));
  x2 <- cbind(x2, apply(x, 1, max));
  x2 <- cbind(x2, apply(x, 1, min));
  
  #Attach night, morning, afternoon and evening
  x2 <- cbind(x2, rowMeans(x[,1:6]));
  x2 <- cbind(x2, rowMeans(x[,6:12]));
  x2 <- cbind(x2, rowMeans(x[,13:18]));
  x2 <- cbind(x2, rowMeans(x[,19:24]));
  
  #Attach ratio features
  x2 <- cbind(x2, apply(x2, 1, function(row) { row[FEATURE_MEAN]/row[FEATURE_PEAK] }));
  x2 <- cbind(x2, apply(x2, 1, function(row) { row[FEATURE_MIN]/row[FEATURE_MEAN] }));
  x2 <- cbind(x2, apply(x2, 1, function(row) { 
    (row[FEATURE_MORNING]+row[FEATURE_AFTERNOON]) / (row[FEATURE_EVENING]+row[FEATURE_NIGHT]) }));
  
  x2 <- cbind(x2, apply(x, 1, function(row) { which.max(row) }));
  x2 <- cbind(x2, apply(x2, 1, function(row) { length(which(row[FEATURE_RAW_CONSUMPTION] > row[FEATURE_MEAN])) }));
  x2 <- cbind(x2, apply(x, 1, getAmountOfPeaks ));
  
  #Attach the day of week feature
  x2 <- cbind(x2, dayOfWeek);
  
  #Correct if divide by 0 has occured
  x2[!is.finite(x2)] <- NA;
  
  return(x2);
}

getFeaturesForSingleDay <- function(x, date) {
    
  debugPrint("x: ", x, collapse = ",");
  debugPrint("length x: ", length(x), collapse = ",");
  
  #Attach mean, max, min of each day
  x2 <- c(x, mean(x));
  x2 <- c(x2, max(x));
  x2 <- c(x2, min(x));
  
  #Attach night, morning, afternoon and evening
  x2 <- c(x2, mean(x[1:6]));
  x2 <- c(x2, mean(x[6:12]));
  x2 <- c(x2, mean(x[13:18]));
  x2 <- c(x2, mean(x[19:24]));
  
  #Attach ratio features
  x2 <- c(x2, x2[FEATURE_MEAN]/x2[FEATURE_PEAK]);
  x2 <- c(x2, x2[FEATURE_MIN]/x2[FEATURE_MEAN]);
  x2 <- c(x2, (x2[FEATURE_MORNING]+x2[FEATURE_AFTERNOON])/(x2[FEATURE_EVENING]+x2[FEATURE_NIGHT]));
  
  x2 <- c(x2, which.max(x));
  x2 <- c(x2, length(which(x2[FEATURE_RAW_CONSUMPTION] > x2[FEATURE_MEAN])));
  x2 <- c(x2, getAmountOfPeaks(x));
  
  debugPrint("PRINT 1: x2: ", x2);
  
  #Attach the day of week feature
  x2 <- c(x2, getDayOfWeek(date));
  
  #Correct if divide by 0 has occured
  x2[!is.finite(x2)] <- NA;
  
  debugPrint("PRINT 2: x2: ", x2);
  
  return(x2);
}

getAmountOfPeaks <- function(x) {
  r <- rle(x)
  peaks <- which(rep(x = diff(sign(diff(c(-Inf, r$values, -Inf)))) == -2, times = r$lengths));
  return(length(peaks));
}