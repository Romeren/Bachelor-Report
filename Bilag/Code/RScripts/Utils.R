DEFAULT_DATE_FORMAT = "%Y-%m-%d %H:%M:%S";
DB_CONNECTION <- NA;
HOLIDAYS <- NA;

SETTING_HOLIDAYS <- "holidays";

initNewDbConnection <- function() {
  if(!is.na(DB_CONNECTION)) {
    closeDbConnection();
  }
  drv <- dbDriver("PostgreSQL")
  DB_CONNECTION <<- dbConnect(drv, dbname = dbnam, host = hostIP, port = portNr, user = usernam, password = passwrd);
  return(DB_CONNECTION);
}

closeDbConnection <- function() {
  dbDisconnect(conn = DB_CONNECTION);
  DB_CONNECTION <<- NA;
}

getDbConnection <- function() {
  return (DB_CONNECTION);
}

getDBFormattedTimeString <- function(date = Sys.time(), dateFormat = DEFAULT_DATE_FORMAT, tz = "GMT") {
  return (easyPaste("'",getFormattedTimeString(date,dateFormat,tz),"'::TIMESTAMP"));
}

getFormattedTimeString <- function(date = Sys.time(), dateFormat = DEFAULT_DATE_FORMAT, tz = "GMT") {
  return (format(date, format=dateFormat, tz = tz));
}

getDateFromString <- function(date, dateFormat = DEFAULT_DATE_FORMAT, tz = "GMT") {
  return (as.POSIXct(date, format=dateFormat, tz = tz));
}

updateSetting <- function(key, value) {
  executeSQL("DELETE FROM w_settings WHERE settingKey='",key,"'", isQuery = FALSE);
  executeSQL("INSERT INTO w_settings VALUES('",key,"','", value,"')", isQuery = FALSE);
}

retrieveSetting <- function(key) {
  setting <- executeSQL("SELECT settingValue FROM w_settings WHERE settingKey='",key,"'");
  
  if(nrow(setting) < 1) {
    return(NA);
  } else {
    return (setting$settingvalue[1]);
  }
}

easyPaste <- function(... , collapse="") {
  return (paste(c(...), collapse = collapse));
}

debugPrint <- function(..., type = PRINT_DEBUG, collapse = "") {
  if(type %in% TO_PRINT) {
    print(easyPaste(..., collapse = collapse));
  }
}
progressPrint <- function(..., collapse="") {
  debugPrint(..., type = PRINT_PROGRESS, collapse = collapse);
}
sqlPrint <- function(..., collapse="") {
  debugPrint(..., type = PRINT_SQL, collapse = collapse);
}
infoPrint <- function(..., collapse="") {
  debugPrint(..., type = PRINT_INFO, collapse = collapse);
}
errorPrint <- function(..., collapse="") {
  debugPrint(..., type = PRINT_ERROR, collapse = collapse);
}

executeSQL <- function(... , collapse = "", isQuery = TRUE, print = TRUE) {
  sql <- easyPaste(..., collapse = collapse);
  sqlPrint(sql);
  
  if(isQuery) {
    return(dbGetQuery(conn = getDbConnection(), statement = sql));
  }
  else if(!fakeDb) {
    dbSendQuery(conn = getDbConnection(), statement = sql);
  }
}

getDbStringFromVector <- function(x, decimals = 2) {
  return(easyPaste("'{", easyPaste(as.character(round(x, decimals)), collapse=","), "}'"));
}

getVectorFromDbString <-function(x) {
  return (unlist(strsplit(substring(x, 2, nchar(x) -1),",")));
}

getNumVectorFromDbString <-function(x) {
  return (as.numeric(getVectorFromDbString(x)));
}

getConsumptionTypeName <- function(type) {
  return (switch(type,"energy","energy_meter","in_temp","out_temp","flow","flow_meter","electricity","water"));
}

getHolidays <- function() {
  if(any(is.na(HOLIDAYS))) {
    HOLIDAYS <<- as.Date(getVectorFromDbString(retrieveSetting(SETTING_HOLIDAYS)));  
  }
  return(HOLIDAYS);
}

getDayOfWeek <- function(dayDates, accountForHolidays = TRUE) {  
  dayOfWeek <- ((wday(dayDates) + 5) %% 7) + 1;
  if(accountForHolidays) {
    dayOfWeek[which(!is.na(match(as.Date.POSIXct(dayDates), getHolidays())))] <- 7;
  }
  return(dayOfWeek);
}