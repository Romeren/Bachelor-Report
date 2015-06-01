
var alarms_card_options = {
	valueNames: ['alarm_id',
				'building_id',
				'consumptiontype',
				'raiseddate',
				'handleddate',
				'odddate',
				'expectedvalues',
				'observedvalues',
				'sds',
				'oddfeatures',
				'likelihood'],
	item:'alarm-item'
};

var alarms_list;

var parseArrayRecord = function(recordVal){
	return String.trim(recordVal)
									.replace('{','')
									.replace('}','')
									.split(',')
									.map(function(e){
										if(e == -1) return null; 
										return parseFloat(e);
									});	
}



var getConsumptionHeader = function(){
	
	var dataObj = new Object();
	dataObj.activeConsumption = window.activeConsumption;
	dataObj.location = 'consumptionHeaderLocation';
	getTemplate('consumptionType-header', dataObj, 'consumptionHeaderLocation');
}

var getAlarms = function(){
	//get panel:
	var panel_obj = getTemplate('alarm-panel', null, 'alarmsPanelLocation');	

	//initialize list object:
	var listId = panel_obj.find('.panel-body div').attr('id');
	alarms_list = new List(listId, alarms_card_options);
	
	
	//  get data:
	window.df.apis.postgres.getRecords({'table_name':'w_alarms_odd_consumption', 
									'filter':'obstype in (1,7,8)', 
									'fields':'building, obstype, raiseddate, handleddate, odddate, expectedvalues,observedvalues, sds, oddfeatures, likelihood'
									}, 
		function(response) {
			var parsedData = [];

			var noOfRecords = 0;
			dataEntry = response.record[noOfRecords];
			while(dataEntry != undefined){
				//parsing data:
				var info = new Object();
				info.alarm_id = noOfRecords;
				info.building_Id 	= dataEntry.building;
				info.consumptiontype= dataEntry.obstype;
				info.raiseddate     = dataEntry.raiseddate;
				info.handleddate    = dataEntry.handleddate;
				info.odddate        = dataEntry.odddate;
				info.likelihood     = dataEntry.likelihood;

				//parsing arrays:
				info.expectedvalues = parseArrayRecord(dataEntry.expectedvalues);
				info.observedvalues = parseArrayRecord(dataEntry.observedvalues);
				info.sds            = parseArrayRecord(dataEntry.sds);
				info.oddfeatures    = parseArrayRecord(dataEntry.oddfeatures);

				//init alarm obj:
				var alarmItem = new AlarmItem(info);
				alarms_list.add(alarmItem);
				alarmItem.initAlarmItem(alarms_list);

				noOfRecords++;
				dataEntry = response.record[noOfRecords];
			}
		});
}






$(document).ready(function(){
	window.unloadSideBar();
	getConsumptionHeader();
	getAlarms();
});