var isFirstloaded = true;
var numberOfBuildings = 7;
var rel_card_options = {
    valueNames:['building_id','building_name','street','zip_code', 'districtname','building_subtype',
    			'building_supertype','built_area','building_area','heated_area','total_area',
    			'attic','cellar_area','total_recidence','site_area', 'rank', 'data_quality', 'validatedAt'],
    item:'card-item'
};

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
var relatedBuildings_list = new List('relatedBuildingsCarousel', rel_card_options);

var parseArrayRecord = function(recordVal){
	if(recordVal == undefined){
		console.log('!-------parseArrayRecord ' + ' can not parse NOTHING----!' )
	}

	return String.trim(recordVal)
									.replace('{','')
									.replace('}','')
									.split(',')
									.map(function(e){
										if(e == -1) return null; 
										return parseFloat(e);
									});	
}


function initializeBuildingOnLoad(loadedInfo){
	if(loadedInfo.record){

		loadedInfo.record.forEach(function(entry){
			
			var building = new BuildingItem(entry);
			
			relatedBuildings_list.add(building);
			
			building.initBuildingItem(numberOfBuildings, relatedBuildings_list);
			
			if(isFirstloaded){
				isFirstloaded=false;
				var name =relatedBuildings_list.get('building_id', building.building_id)[0].elm.className + ' active';
				relatedBuildings_list.get('building_id', building.building_id)[0].elm.className = name;
			}
			numberOfBuildings = numberOfBuildings+1;
	
		});
	}

	initPieChartPage(20,100,1500, colours);
}


var Consumption_type = function(consumption, meanArray, sdArray, daysArray){
	this.consumption_type = consumption;
	this.mean = meanArray;
	this.sd = sdArray;
	this.days = daysArray;
}

var ProfilData = function(tableData, pName){
	this.consumption_types = [];
	this.profileName = pName;
	//features:
	this.feature_mean;
	this.feature_peak;
	this.feature_min;
	this.feature_time_of_day;
	this.feature_hours_above_mean;
	this.feature_mean_over_max;

	if(tableData != null)
	for (var i = tableData.length - 1; i >= 0; i--) {
		this.consumption_types.push(new consumption_type(tableData[i]));
	};
};

var getEnergyProfiles = function(buildingId){
	//for test
		//buildingId = 3209;
	
	if(buildingId == undefined) return;
		
	window.df.apis.postgres.getRecords({'table_name':'w_consumption_profiles', 
									'filter':'building='+buildingId +' AND consumption_type in(1,7,8)', 
									'fields':'consumption_type,mean, sd, daycount'
									}, 
	function(response) {
		var heatProfileData= new ProfilData(null, 'Heat');
		var waterProfileData= new ProfilData(null, 'Water');
		var electricityProfileData= new ProfilData(null, 'Electricity');

		var recordNr = 0;

		dataEntry = response.record[recordNr];
		while(dataEntry != undefined){
			//parsing days
			var parsedDays = parseArrayRecord(dataEntry.daycount);
			var days = days = [];
       		days.push({'letter':'MO' , 'occurens':parsedDays[0]});
       		days.push({'letter':'TU' , 'occurens':parsedDays[1]});
       		days.push({'letter':'WE' , 'occurens':parsedDays[2]});
       		days.push({'letter':'TH' , 'occurens':parsedDays[3]});
       		days.push({'letter':'FR' , 'occurens':parsedDays[4]});
       		days.push({'letter':'SA' , 'occurens':parsedDays[5]});
       		days.push({'letter':'SU' , 'occurens':parsedDays[6]});
	       		

	       	var parsedMeanData = parseArrayRecord(dataEntry.mean);
     		
     		//parsing means:
			var parsedMeans = parsedMeanData.slice(0,24);
			//parsing standard diviation:
			var parsedSd = parseArrayRecord(dataEntry.sd);
			//init DO
			var consumption_type = new Consumption_type(dataEntry.consumption_type, parsedMeans, parsedSd, days);	
			
			//Extracting features:
			consumption_type.feature_mean = parsedMeanData[25];
			consumption_type.feature_peak = parsedMeanData[26];
			consumption_type.feature_min = parsedMeanData[27];
			consumption_type.feature_time_of_day = parsedMeanData[35];
			consumption_type.feature_hours_above_mean = parsedMeanData[36];
			consumption_type.feature_mean_over_max = parsedMeanData[32];

			if(dataEntry.consumption_type == 1){
				heatProfileData.consumption_types.push(consumption_type);
			}else if(dataEntry.consumption_type == 7){
				electricityProfileData.consumption_types.push(consumption_type);
			}else{
				waterProfileData.consumption_types.push(consumption_type);
			}
			
			recordNr++;
			dataEntry = response.record[recordNr];
 		}

	    var hobj = getTemplate('energyProfiles-panel', heatProfileData, 'energyProfilesLocation');		
	    hobj.find('.panel-heading').addClass('red-bg');
	    hobj.find('.area').attr('style','fill: url("#red-gradient")');		
	    hobj.find('.bar').attr('style','fill: url("#red-gradient"); stroke: #f68484;');		
	    hobj.find('.sdminline').attr('style', 'stroke: red; stroke-dasharray: 3, 3;');	
	   	hobj.find('.sdmaxline').attr('style', 'stroke: red; stroke-dasharray: 3, 3;');	

	    var wobj = getTemplate('energyProfiles-panel', waterProfileData, 'energyProfilesLocation');		
	    wobj.find('.panel-heading').addClass('blue-bg');
	    wobj.find('.area').attr('style','fill: url("#blue-gradient")');		
	    wobj.find('.bar').attr('style','fill: url("#blue-gradient"); stroke: #75b9e6;');		
	    wobj.find('.sdminline').attr('style', 'stroke: blue; stroke-dasharray: 3, 3;');	
	   	wobj.find('.sdmaxline').attr('style', 'stroke: blue; stroke-dasharray: 3, 3;');	
	    
	    var eobj = getTemplate('energyProfiles-panel', electricityProfileData, 'energyProfilesLocation');		
	    eobj.find('.panel-heading').addClass('yellow-bg');
	    eobj.find('.area').attr('style','fill: url("#yellow-gradient")');	
	    eobj.find('.bar').attr('style','fill: url("#yellow-gradient"); stroke: #ffcc66;');			
	    eobj.find('.sdminline').attr('style', 'stroke: yellow; stroke-dasharray: 3, 3;');	
	   	eobj.find('.sdmaxline').attr('style', 'stroke: yellow; stroke-dasharray: 3, 3;');	
	    eobj.addClass('active');
 });
}

var getConsumption = function(buildingId){
	//test
		//buildingId = 3209;
	//test end 
	
	if(buildingId == undefined) return;
	
	window.df.apis.postgres.getRecords({'table_name':'w_consumptions', 
										'filter':'building_Id='+buildingId + ' AND consumption_type in (1, 8, 7)', 
										'fields':'consumption_type, consumption'
										}, 
			function(response) {

			//console.log(response);

			var hObj, wObj, eObj;
			var takenConT = [];
			var dataparsed = [1,2,3]
			for (var i =0; i < 3; i++) {
				dataEntry = response.record[i];

				if(dataEntry != undefined)
				{
					var consumpT = dataEntry.consumption_type;
					takenConT.push(consumpT);

					var parsedData =parseArrayRecord(dataEntry.consumption);

					if(consumpT ==  1){
						dataparsed[0] = parsedData;
					}else if(consumpT == 8){
						dataparsed[1] = parsedData;
					}else{
						dataparsed[2] = parsedData;
					}
        		}
        		else{
        			var parsedData = null;
        			if(-1 == ($.inArray(1, takenConT))){
						takenConT.push(1);
						dataparsed[0] = parsedData;

					}else if(-1 == ($.inArray(8, takenConT))){
						takenConT.push(8);
						dataparsed[1] = parsedData;
						
					}else{
						takenConT.push(7);
						dataparsed[2] = parsedData;
						
					}
        		}
			};

			hObj = getTemplate('consumption-panel', dataparsed[0], 'consumptionPanelLocation');
			hObj.addClass('red-bg');
			hObj.find('.panel-heading').addClass('red-bg');	
			hObj.find('.panel-footer').addClass('red-bg');		
			wObj = getTemplate('consumption-panel', dataparsed[1], 'consumptionPanelLocation');
			wObj.addClass('blue-bg');
			wObj.find('.panel-heading').addClass('blue-bg');
			wObj.find('.panel-footer').addClass('blue-bg');
			eObj = getTemplate('consumption-panel', dataparsed[2], 'consumptionPanelLocation');
			eObj.addClass('yellow-bg');
			eObj.addClass('active');	
			eObj.find('.panel-heading').addClass('yellow-bg');
			eObj.find('.panel-footer').addClass('yellow-bg');
        		
	});
}

var getSeasonality = function(buildingId){
	//test
		//buildingId = 3278;
	//test end 
	if(buildingId == undefined) return;
	
	window.df.apis.postgres.getRecords({'table_name':'w_feature', 
									'filter':'building='+buildingId +' AND feature_type = 27 AND consumption_type in (1,7,8) ', 
									'fields':'consumption_type, feature_data'
									}, 
		function(response) {
		
		var hObj, wObj, eObj;
		var conTyps = window.consumptiontypes;
		var takenConT = [];
		var dataparsed = [1,2,3]
		for (var i = 0; i < 3; i++) {
			var dataEntry = response.record[i];

			if(dataEntry != undefined){
				var consumpT = dataEntry.consumption_type;
				takenConT.push(consumpT);
				
				var parsedData = parseArrayRecord(dataEntry.feature_data);
				hest = parsedData;
				if(consumpT == 1){
					dataparsed[0] = parsedData;
				}else if(consumpT == 8){
					dataparsed[1] = parsedData;
				}else{
					dataparsed[2] = parsedData;
				}


			}else{
				var parsedData = null;
       			if(-1 == ($.inArray(1, takenConT))){
					takenConT.push(1);
					dataparsed[0] = parsedData;
				}else if(-1 == ($.inArray(8, takenConT))){
					takenConT.push(8);
					dataparsed[1] = parsedData;
					
				}else{
					takenConT.push(7);
					dataparsed[2] = parsedData;					
				}
			}
		};


		hObj = getTemplate('seasonality-panel', dataparsed[0], 'seasonalityPanelLocation');
		hObj.find('.panel-heading').addClass('red-bg');	
		hObj.find('.panel-footer').addClass('red-bg');
		hObj.find('.area').attr('style','fill: url("#red-gradient")');		
		
		wObj = getTemplate('seasonality-panel', dataparsed[1], 'seasonalityPanelLocation');
		wObj.find('.panel-heading').addClass('blue-bg');
		wObj.find('.panel-footer').addClass('blue-bg');
		wObj.find('.area').attr('style','fill: url("#blue-gradient")');		

		eObj = getTemplate('seasonality-panel', dataparsed[2], 'seasonalityPanelLocation');
		eObj.addClass('active');	
		eObj.find('.panel-heading').addClass('yellow-bg');
		eObj.find('.panel-footer').addClass('yellow-bg');
		eObj.find('.area').attr('style','fill: url("#yellow-gradient")');		

		}
	);
}

var getConsumptionHeader = function(){
	
	var dataObj = new Object();
	dataObj.activeConsumption = window.activeConsumption;
	dataObj.location = 'consumptionHeaderLocation';
	getTemplate('consumptionType-header', dataObj, 'consumptionHeaderLocation');
}


var getAlarms = function(buildingId){
	//for test:
	//buildingId = 6028;
	

	//get panel:
	var panel_obj = getTemplate('alarm-panel', null, 'alarmsPanelLocation');	

	//initialize list object:
	var listId = panel_obj.find('.panel-body div').attr('id');
	alarms_list = new List(listId, alarms_card_options);
	
	
	//  get data:
	var id = buildingId;
	window.df.apis.postgres.getRecords({'table_name':'w_alarms_odd_consumption', 
									'filter':'building='+buildingId +' AND obstype in (1,7,8)', 
									'fields':'obstype, raiseddate, handleddate, odddate, expectedvalues,observedvalues, sds, oddfeatures, likelihood'
									}, 
		function(response) {
			var parsedData = [];

			var noOfRecords = 0;
			dataEntry = response.record[noOfRecords];
			while(dataEntry != undefined){
				//parsing data:
				var info = new Object();
				info.alarm_id = noOfRecords; //add a primary key..!
				info.building_Id 	= id;
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

var initRelatedBuildingsPanel = function(building_id){
		//loading buildings:
	window.df.apis.postgres.getRecords({'table_name':'w_simmilar', 'filter': 'building =' + building_id, 'fields': 'simmilar'}, 
		function(tableRows){
			var loadedBuildings = [];
			for (var i = tableRows.record.length - 1; i >= 0; i--) {
				var parsedData = parseArrayRecord(tableRows.record[i].simmilar);

				var buildingsToLoad = [];
				parsedData.forEach(function(buildingNr){
					if(loadedBuildings.indexOf(buildingNr) == -1){
						buildingsToLoad.push(buildingNr);
						loadedBuildings.push(buildingNr);
					}
				});

				if(buildingsToLoad[0] == undefined)
					continue;

				window.df.apis.postgres.getRecords({'table_name':'w_lookup_building', 'filter': 'building_id IN(' + String(buildingsToLoad) +')'}, function(response){
					initializeBuildingOnLoad(response);

						//init and control the building relation panel:
					$('#relatedBuildingsCarousel').carousel({
				    	interval: 4000
					});
				
					// handles the carousel thumbnails
					$('[id^=carousel-selector-]').click( function(){
						var id_selector = $(this).attr("id");
						var id = id_selector.substr(id_selector.length -1);
						id = parseInt(id);
						$('#relatedBuildingsCarousel').carousel(id);
						$('[id^=carousel-selector-]').removeClass('selected');
						$(this).addClass('selected');
					});
				
					// when the carousel slides, auto update
					$('#relatedBuildingsCarousel').on('slid', function (e) {
						var id = $('.item.active').data('slide-number');
						id = parseInt(id);
						$('[id^=carousel-selector-]').removeClass('selected');
						$('[id=carousel-selector-'+id+']').addClass('selected');
					});
				});
			};
		});
}

var getSummerizedStatistics = function( building_id){

	window.df.apis.postgres.getRecords({'table_name':'w_feature_type',  
									'fields':'name'
									}, 
			function(response) {

				var fresponse = new Object();
				var numberOfFeatures = response.record.length;
				var contypes = [1,7,8];
				for (var i = response.record.length - 1; i >= 0; i--) {
					fresponse[i] = response.record[i].name;
				};

				window.df.apis.postgres.getRecords({'table_name':'w_building_profiles',  
									'fields':'consumption_type, mean',
									'filter':'building ='+ building_id,
									'order': 'consumption_type'
									}, 
					function(dresponse){
						
						for (var i = 0; i < 3; i++) {
							var currentBP = dresponse.record[i];
							var subdataObj = [];		
							
							var mean = currentBP == undefined ? -1 : parseArrayRecord(currentBP.mean);
							for(var j = 0 ; j < numberOfFeatures; j ++){
							  
							  subdataObj.push({'feature': fresponse[j], 
				 							 'data': mean == -1 ? '-' : mean[j], 
				 							 'consumption_type': currentBP == undefined ? contypes[i] : currentBP.consumption_type
				 							});
							};
							
							var tempobj = getTemplate('summerized-panel', subdataObj,'summerizedStatPanelLocation');
							var colorClass;
							if(i == 0){
								colorClass = 'red-bg';
							}else if(i == 1){
								colorClass = 'yellow-bg active';
								tempobj.addClass('active');
							}else{
								colorClass = 'blue-bg';
							}
							tempobj.find('.panel-heading').addClass(colorClass);
							
						};
				 	});
			});


}


$(document).ready(function(){

	getConsumptionHeader();

	//test
		//window.activebuilding = new Object();
		//window.activebuilding.building_id = 3244;
	//Test end
	

	if(window.activebuilding == undefined) return;

	 getTemplate('bbr-panel', window.activebuilding, 'brrPanelLocation');

	 getSummerizedStatistics(window.activebuilding.building_id);

	 getSeasonality(window.activebuilding.building_id);

	 //init and controll energy profiles panel:
	 getEnergyProfiles(window.activebuilding.building_id);
	 
	 //init alarms panel:
	 getAlarms(window.activebuilding.building_id);
	
	 getConsumption(window.activebuilding.building_id);

	 initRelatedBuildingsPanel(window.activebuilding.building_id);
});