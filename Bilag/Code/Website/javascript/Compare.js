//margins:
var margin_left = 20,
	margin_right = 20,
	margin_top = 20,
	margin_bottom = 40;

var width = 700,
	height = 400;

var graphItemsCount = 0;

var feature_list =  new List('featurelist', feature_card_options);

var graphItem_list = new List('legend-footer', legend_card_options); // for legend objects



//---------------------------------------------------------------------------------------
//                         UTILITY FUNCTIONS:
//---------------------------------------------------------------------------------------

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

var loadFeatures = function(){
	window.df.apis.postgres.getRecords({'table_name':'w_feature_type',  
									'fields':'id, name'
									}, 
			function(response) {
				 for (var i = 0 ;  i < response.record.length; i++) {
				 	var featureItem = new FeatureItem(response.record[i].id, response.record[i].name);
                    feature_list.add(featureItem);
                    featureItem.initFeatureItem(feature_list);
				 };
			});
}

//						UTILITY END!
//----------------------------------------------------------------------------------------

var getConsumptionHeader = function(){
	
	var dataObj = new Object();
	dataObj.activeConsumption = window.activeConsumption;
	dataObj.location = 'consumptionHeaderLocation';
	getTemplate('consumptionType-header', dataObj, 'consumptionHeaderLocation');
}



//---------------------------------------------------------------------------------------
//--                        PLOTTING STUFF START:                                      --
//---------------------------------------------------------------------------------------

var min_x,
	min_y,
	max_x ,
	max_y;

var fallBack_min_x = new Date(Date.now().setFullYear(2014)),
    fallBack_max_x = Date.now();
    fallBack_min_y = 0,
    fallBack_max_y = 10;

var xAxis;
var yAxis;

var svgObj; //"Root" element..!
var graphObj; //element holding everything drawn on the graph

var currentXScale = 1; //variables holding the scale 1:x
var currentYScale = 1; //variables holding the scale 1:y
var currentViewPos_x =width/2; //x position of viewpoint
var currentViewPos_y =height/2; //y position of viewpoint


//init SCALE functions: 
	//note that the domain is NOT jet assigned:
var xScaleFunction;
var yScaleFunction;


//DRAWING functions:
//defining how a line is drawn:
var lineFunction;


//defining how the area under the graph looks like:
var areaFunction;


//-----------------------------------------------------------------------------------------
//									EVENTS...!  
var draw = function(){
    initGraph();
	
    graphObj.select("g.x.axis").call(xAxis);
    graphObj.select("g.y.axis").call(yAxis);


    graphItem_list.items.forEach(function(item){
        for (var i = item._values.graphitems.length - 1; i >= 0; i--) {       
            if(parseInt(item._values.graphitems[i].consumption_type) != window.activeConsumption) continue; // dont paint inactive consumption types!
            
            if(getActiveFeatures().indexOf(item._values.graphitems[i].feature_type) == -1 ) continue; // dont paint inactive features.!

            if(item._values.graphitems[i].isLine){
                addLineToGraph(item._values.graphitems[i].data, item._values.graphitems[i].name, item._values.itemColor);
                graphObj.select('.' + item._values.graphitems[i].name).attr("d",  lineFunction(item._values.graphitems[i].data));
            }else{
                addAreaToGraph(item._values.graphitems[i].data, item._values.graphitems[i].name, item._values.itemColor);
                graphObj.select('.' + item._values.graphitems[i].name).attr("d",  areaFunction(item._values.graphitems[i].data));
            }
        };
    });

}



function zoomed() {
	currentViewPos_x = d3.event.translate[0];
	currentViewPos_y = d3.event.translate[1];	
    graphObj.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
}

function zoomWithSliderVertical(scale, event) {
    if(scale == undefined){ return;}
        
    currentYScale = scale;
    handelViewPoint();
}
function zoomWithSliderHorizontal(scale, event) {
    if(scale == undefined){ return;}
        
	currentXScale = scale
	handelViewPoint();
}

var setPageColors = function(){
    var activate = window.activeConsumption;
              
    var panel = $('#comparisonPanel');
    if(activate == 1){
      panel.find('.panel-footer').attr('class', '.panel-footer red-bg');
      panel.find('.panel-heading').attr('class', 'panel-heading red-bg');
    }else if(activate== 8){
      panel.find('.panel-footer').attr('class', '.panel-footer blue-bg');
      panel.find('.panel-heading').attr('class', 'panel-heading blue-bg');
    }else{
      panel.find('.panel-footer').attr('class', '.panel-footer yellow-bg');
      panel.find('.panel-heading').attr('class', 'panel-heading yellow-bg');
    }
}

//listen on feature clicked events:
document.addEventListener('onFeatureClicked', function(e){

    //if the box becomes unchecked we only want to re draw, since the draw function "undraws" inactive features:
    if(!e.detail.isChecked){
        // if feature is unchecked it is posible that a new max_y needs to be calculated therefore we find max:
        max_y = 0;
        graphItem_list.items.forEach(function(item){
            for (var i = item._values.graphitems.length - 1; i >= 0; i--) {
                // check for consumption_type and active features:
                if(item._values.graphitems[i].consumption_type == window.activeConsumption && getActiveFeatures().indexOf(item._values.graphitems[i].feature_type) > -1){    
                    max_y = max_y > item._values.graphitems[i].max_y ? max_y : item._values.graphitems[i].max_y;  
                }
            };    
        });
        

        draw();
        return;
    }

    var clickedFeature = e.detail.feature_id;
    
    //load "new" feature data:
    graphItem_list.items.forEach(function(item){
        var isLoaded = false;
        for (var i = item._values.graphitems.length - 1; i >= 0; i--) {
             // check if consumption_type and feature type matches:
            if(item._values.graphitems[i].consumption_type == window.activeConsumption && item._values.graphitems[i].feature_type== clickedFeature){
                //.log('is loaded');
                max_y = max_y > item._values.graphitems[i].max_y ? max_y : item._values.graphitems[i].max_y;  
                isLoaded = true;
                break;
            }
        };
        if(!isLoaded) {
            //load data associated with item:
            if(item._values.item_type == 0){
                loadASubType(item._values.item_id, item._values)
            }else if(item._values.item_type == 1){

            }else if(item._values.item_type == 2){
                loadAFeature(item._values.item_id, item._values);
            }
        }else{
            draw();
        }
    });

},false
);



//listen on click on elements in the sidebar...
document.addEventListener("buildingtype_clicked", function (e) {
            
            var elementType = 0;
            //get element:
            var text = e.explicitOriginalTarget.textContent;
            var sender = type_list.get('name', text); // get element from our lists:
            if(sender[0] == undefined){ 
                sender= buildingSidebar_list.get('name', text);
                if(sender[0] != undefined &&  !sender[0]._values.clicked && e.detail[0]._values.super_type == -1){
                    sender[0]._values.setClasses(buildingSidebar_list);
                }
                elementType = 1;
            }
            if(sender[0] == undefined){ 
                sender= categories_list.get('name', text);
                elementType = 2;
            }
            if(sender[0] == undefined) return;
            
            sender = sender[0];

            var tempItem = graphItem_list.get('item_id', sender._values.item_id);
            if(tempItem[0] == null || tempItem[0] == undefined){ // add element if not exists
                //create legend element:
                tempItem = new LegendItem(sender._values.name, 
                                            sender._values.super_type, 
                                            sender._values.item_id, 
                                            graphItemsCount,
                                            sender._values.item_type);
                graphItemsCount++;
                
                
                //load data associated with element:
                if(elementType == 0){            
                    tempItem.type_data = sender._values.type_data;
                    loadASubType(sender._values.item_id, tempItem);
                }
                else if(elementType == 1){ 
                    loadAFeature(sender._values.item_id, tempItem);
                }

                graphItem_list.add(tempItem);

                //add a color to element:
                tempItem.setColor(graphItem_list);
                draw();

            }else{ // remove elements previously added:
                graphItem_list.remove('item_id', tempItem[0]._values.item_id);

                //calculate new max_y value for sclale if there is one:
                max_y = 0;
                graphItem_list.items.forEach(function(item){
                    for (var i = item._values.graphitems.length - 1; i >= 0; i--) {
                        // check for consumption_type and active features:
                        if(item._values.graphitems[i].consumption_type == window.activeConsumption && getActiveFeatures().indexOf(item._values.graphitems[i].feature_type) > -1){    
                            max_y = max_y > item._values.graphitems[i].max_y ? max_y : item._values.graphitems[i].max_y;  
                        }
                    };    
                });

                draw(); // and redraw..
            }

            
          }, false);

    
document.addEventListener("consumptiontypeChanged", function (e) {
    setPageColors();

    max_y = 0; 
    // if consumptiontype changes, load data associated with new consumption
    graphItem_list.items.forEach(function(element){
        
        var isLoaded = false;
        // check if the consumption type is allready loaded:
        
        for (var i = element._values.graphitems.length - 1; i >= 0; i--) {
            if(element._values.graphitems[i].consumption_type == window.activeConsumption){
                if(getActiveFeatures().indexOf(element._values.graphitems[i].feature_type == -1)){
                    
                    // set max_y:
                    max_y = max_y > element._values.graphitems[i].max_y ? max_y : element._values.graphitems[i].max_y;

                    isLoaded = true;
                    break;
                }
            }
        };

        if(!isLoaded) {
            //load data associated with element:
            if(element._values.item_type == 0){
                loadASubType(element._values.item_id, element._values);
            }else if(element._values.item_type ==1){

            }else if(element._values.item_type ==2){
                loadAFeature(element._values.item_id, element._values);
            }



        }else{
            draw(); // redraw the graph.. :)
        }

    });

}, false);

//-----------------------------------------------------------------------------------------
//							INITIAL STUFF AND METHODS:

var initGraph = function(){
    clearGraph();
    initScales();
    initAxises();
}

var clearGraph = function(){
    while (graphObj[0][0].firstChild) {
        graphObj[0][0].removeChild(graphObj[0][0].firstChild);
    }
}

var handelViewPoint = function(){
	var svg = d3.select('svg');
	var container = svg.select("g");
	// Note: works only on the <g> element and not on the <svg> element
    // which is a common mistake
	container.attr("transform",
        "translate(" + currentViewPos_x + ", " + currentViewPos_y + ") " +
        "scale(" + currentXScale + ", " + currentYScale +") " +
        "translate(" + -currentViewPos_x + ", " + -currentViewPos_y + ")");
}


var initScales = function(){
  var using_min_y,
      using_max_y,
      using_min_x,
      using_max_x;

 using_min_y = min_y == undefined ? fallBack_min_y : min_y;
 using_max_y = max_y == undefined ? fallBack_max_y : max_y;

 using_min_x = min_x == undefined ? fallBack_min_x : min_x;
 using_max_x = max_x == undefined ? fallBack_max_x : max_x;


  xScaleFunction = d3.time.scale().domain([using_min_x, using_max_x]) // note that this axis needs to be inverted..!
                            .range([margin_left, width- margin_right]);

  yScaleFunction = d3.scale.linear().domain([using_min_y , using_max_y]) 
                            .range([height-margin_bottom, margin_top]);  

  initDrawingFunctions();
}

var initDrawingFunctions = function(){
    lineFunction =d3.svg.line()
                .interpolate("linear") // type of line... what to fill in between x/y points
                .x(function(d) { return xScaleFunction(d.x) ;}) // the mapping from value to px coordinates
                .y(function(d) { return yScaleFunction(d.y); }); 
    areaFunction = d3.svg.area()
                .interpolate("linear") // defining the border interpolation between points
                .x(function(d) {  return xScaleFunction(d.x); }) // mapping
                .y1(function(d) { return yScaleFunction(d.y); })
                .y0(yScaleFunction(0));
}



var initsvg = function(){
    
    //get svg element:
    var svg = d3.select('.svgWrapper')
                        .append("svg:svg")
                        .attr("width", width)
                        .attr("height", height);
   svgObj = svg;


   //defining zoom function:
   var zoom = d3.behavior.zoom().center([width / 2, height / 2])
               .scaleExtent([1, 10])
               .on("zoom", zoomed);
   
   //add group element for zooming
   svgObj = svg.append("g")
           .attr("transform", "translate(" + margin_left + "," + margin_top + ")")
           .call(zoom);


    //add element which holds the view point on the graph
    var rect = svgObj.append("rect")
                .attr("width", width)
                .attr("height", height)
                .style("fill", "white")
                .style("pointer-events", "all");

    
    //init vertical slider:
    d3.select('.d3-slider-vertical').style({'height': height - margin_top - margin_bottom + 'px'});
    var vslider = d3.select('.d3-slider-vertical')
                            .call(d3.slider()
                                .value(0)
                                .max(10)
                                .min(0)
                                .orientation("vertical")
                                .on("slide", 
                                    function(event, ui){
                                            zoomWithSliderVertical(1 +ui/11, event); 
                                            }));

    
    // init horizontal slider:
    d3.select('.d3-slider-horizontal').style({'width': width -margin_left - margin_right + 'px'});
	var hslider = d3.select('.d3-slider-horizontal')
                            .call(d3.slider()
                                .value(0)
                                .max(10)
                                .min(0)
                                .orientation("horizontal")
                                .on("slide", 
                                    function(event, ui){
                                            zoomWithSliderHorizontal(1 +ui/11, event); 
                                            }));
    graphObj = svgObj.append('g');

}

var initAxises = function(){
	// setting up the axises for the graph:
	xAxis = d3.svg.axis().scale(xScaleFunction).orient("bottom");
	yAxis = d3.svg.axis().scale(yScaleFunction).orient("right"); 
	

    //create axises html elements:
    graphObj.append("g").attr('class','.x .axis')
						.attr("transform", "translate(0," + (height - margin_bottom) + ")") //moveaxis to bottom
						.style({'stroke': 'black', 
								'fill':'none', 
								'shape-rendering': 'crispEdges'})
						.call(xAxis);

	graphObj.append("g").attr('class','.y .axis')
						.style({'stroke': 'black', 
								'fill':'none', 
                                'shape-rendering': 'crispEdges'})
                        .call(yAxis);
}



//-----------------------------------------------------------------------------------------
//                          HANDEL LINES and AREAS:
var calculateGraph = function(data){
    var returnobject = new Object(); 
    var d1 = [];
    if(window.epochTime == undefined) console.log('EPOCH IS UNDEFINED!');
    if(window.epochTime != undefined && min_x == undefined) min_x = new Date(window.epochTime);
    

    returnobject.max_y = 0;
    if(min_y == undefined) min_y = 1000000000;
    if(max_y == undefined) max_y =0;
    for(i=0 ; i < data.length; i++){
            d1.push({"x": new Date(window.epochTime).addDays(i), "y": data[i]});
            max_y = max_y < data[i] ? data[i] : max_y;
            if(data[i] != null) min_y = min_y > data[i] ? data[i] : min_y;
            if(data[i] != null) returnobject.max_y = returnobject.max_y < data[i] ? data[i] : returnobject.max_y; 
    }

    if(window.epochTime != undefined && max_x == undefined) max_x = new Date(window.epochTime);
    if(window.epochTime != undefined) max_x = max_x < d1[data.length-1].x ? d1[data.length-1].x : max_x; 

    graphItem_list.items.forEach(function(grapItem){
        if(grapItem._values.item_type == 0){
            grapItem._values.graphitems.forEach(function(feature){
                feature.data[1].x = max_x;
            });
        }
    });

    returnobject.d1 = d1;
    return returnobject;
}

var calculateStraightLine = function(y){
    var returnobject = new Object();
    returnobject.d1 = [];
    
    if(window.epochTime == undefined) console.log('EPOCH IS UNDEFINED!');
    if(window.epochTime != undefined && min_x == undefined) min_x = new Date(window.epochTime);

    returnobject.max_y = 0;
    if(y == null || y == undefined)
        return returnobject;

    if(min_y == undefined) min_y = y -5;
    if(max_y == undefined) max_y =0;

    if(window.epochTime != undefined && max_x == undefined) max_x = new Date(window.epochTime).addDays(100);
    max_y = max_y < y ? y : max_y;
    returnobject.d1.push({"x": min_x, "y": y});
    returnobject.d1.push({"x": max_x, "y": y});
    returnobject.max_y = returnobject.max_y < y ? y : returnobject.max_y; 

    return returnobject;
}

var addLineToGraph = function(data, name, colorClass){
    var dataset = data;
	//creating the graph line for the standard diviations:
	graphObj.append('path')
//                    .attr("stroke", "black")
                    .attr("stroke-width", 1)
                    .attr("fill", "none")
                    .attr("class", name + " " +  colorClass + " linear active");
    //adding data to graph object
    graphObj.select("path."+name).data([data]);
}

var addAreaToGraph = function(data, name, colorClass){

	//creating the graph line for the standard diviations:
	graphObj.append('path')
//                    .attr("stroke", "black")
                    .attr("stroke-width", 1)
                    .attr("fill", "gray")
                    .attr("class", name + " " +  colorClass + " area active");
    //adding data to graph object
    graphObj.select("path."+name).data([dataset]);
}


//-----------------------------------------------------------------------------------------
//						PLOTTING END...!
//-----------------------------------------------------------------------------------------

var getActiveFeatures = function(){
    var activeFeatures = [];
    feature_list.items.forEach(function(e){
        if (e._values.isChecked) activeFeatures.push(e._values.feature_id);
    });
    return activeFeatures;
}

var loadAFeature = function(buildingid, item){

    //get active features:
    var activeFeatures = getActiveFeatures();

    if(activeFeatures[0] == undefined) return;
    
    var graphitemsnumbercount = -1;
    //check if one or more features is loaded, so they dont get loaded again:
        // and get max graph number of allready loaded graphs:
    item.graphitems.forEach(function(feature){
        if(activeFeatures.indexOf(feature.feature_type) > -1 && feature.consumption_type == window.activeConsumption){
            //remove feature from load:
            activeFeatures.splice(activeFeatures.indexOf(feature.feature_type), 1);
        } 
        graphitemsnumbercount = graphitemsnumbercount > feature.graphItemNumber ? graphitemsnumbercount : feature.graphItemNumber;
    });    

    var buildingId = buildingid;    
    //load feature for building
    window.df.apis.postgres.getRecords({'table_name':'w_feature',  
                                    'filter': 'building = ' + buildingId + ' AND consumption_type = ' + 
                                        window.activeConsumption + ' AND feature_type IN(' + String(activeFeatures) + ')',
                                    'fields':'feature_type, feature_data, consumption_type'
                                    }, function(response) {
                 for (var i = response.record.length - 1; i >= 0; i--) {
                    var dataEntry = response.record[i];
                    //parse a feature:
                    var parsedData = parseArrayRecord(dataEntry.feature_data);
                    // convert to graph data:
                    parsedData = calculateGraph(parsedData);
                    //item.parsedData = undefined;
                    graphitemsnumbercount++; // count one up...
                    //add to list:
                    var name = 'item' + buildingId + 'path' + graphitemsnumbercount;
                    item.graphitems.push({'name' : name, 
                                          'isLine': true,
                                          'data':parsedData.d1, 
                                          'consumption_type': dataEntry.consumption_type,
                                          'feature_type': dataEntry.feature_type,
                                          'graphItemNumber': graphitemsnumbercount,
                                          'max_y': parsedData.max_y
                                      });
                 };
                 draw();
            });
}


var loadASubType = function(buildingid, item){
    

    //get active features:
    var activeFeatures = getActiveFeatures();

    if(activeFeatures[0] == undefined) return;
    
    var graphitemsnumbercount = -1;
    //check if one or more features is loaded, so they dont get loaded again:
        // and get max graph number of allready loaded graphs:
    item.graphitems.forEach(function(feature){
        if(activeFeatures.indexOf(feature.feature_type) > -1 && feature.consumption_type == window.activeConsumption){
            //remove feature from load:
            activeFeatures.splice(activeFeatures.indexOf(feature.feature_type), 1);
        } 
        graphitemsnumbercount = graphitemsnumbercount > feature.graphItemNumber ? graphitemsnumbercount : feature.graphItemNumber;
    });    

    var buildingId = buildingid;    
    //load feature for building
    for (var i = item.type_data.length - 1; i >= 0; i--) {
        
        var dataEntry = item.type_data[i];
        
        if(dataEntry.consumption_type != window.activeConsumption)
            continue;

        //parse all features:
        var parsedData = parseArrayRecord(dataEntry.mean);
        activeFeatures.forEach(
            function(feature){
                var dataPoint = parsedData[feature -25];

                // convert to STRAIGHT LINE graph data:
                parsedData = calculateStraightLine(dataPoint);
                
                graphitemsnumbercount++; // count one up...
                
                //remove all spaces:
                str = buildingid.trim().substring(0,3).trim();

                //add to list:
                var name = 'item' + str + 'path' + graphitemsnumbercount;

                item.graphitems.push({'name' : name, 
                                                  'isLine': true,
                                                  'data':parsedData.d1, 
                                                  'consumption_type': dataEntry.consumption_type,
                                                  'feature_type': feature,
                                                  'graphItemNumber': graphitemsnumbercount,
                                                  'max_y': parsedData.max_y
                                              });
            }
            );
        
    };

    draw();
}

//-----------------------------------------------------------------------------------------
//					READY READY READY RUN STUFF..!
$(document).ready(function(){
	getConsumptionHeader();
    setPageColors();

    //initAxises();
    loadFeatures();

	window.loadSidebar();
    
    initsvg();
    
    initGraph();

});