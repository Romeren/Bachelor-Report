var parseApplicationId ="mhotCOzzaw3YxCjf8qEPtq9k9XuSY41khplEUinE";
var parseJavaScriptKey = "6PSIFUGP1ZNwCzkVgzmBAw4x1oujTeknblkn4jZk";

function BuildingItem(building_info){
//	console.log(building_info);
	this.building_id 		= building_info.attributes.building_id;
	this.building_name		= building_info.attributes.building_name;
	this.street				= building_info.attributes.Bbr.attributes.street;
	this.zip_code =5000;
	this.districtname ="Odense";
	this.building_subtype 	= building_info.attributes.Building_Subtype.attributes.name;
	this.building_supertype;
	this.built_area			= building_info.attributes.Bbr.attributes.built_area;
	this.building_area		= building_info.attributes.Bbr.attributes.building_area;
	this.heated_area		= building_info.attributes.Bbr.attributes.heated_area;
	this.total_area			= building_info.attributes.Bbr.attributes.total_area;
	this.attic				= building_info.attributes.Bbr.attributes.attic;
	this.cellar_area		= building_info.attributes.Bbr.attributes.cellar_area;
	this.total_recidence	= building_info.attributes.Bbr.attributes.total_recidence;
	this.site_area			= building_info.attributes.Bbr.attributes.site_area;
	this.rank = 10;
}
var card_options = {
    valueNames:['building_id','building_name','street','zip_code', 'districtname','building_subtype',
    			'building_supertype','built_area','building_area','heated_area','total_area',
    			'attic','cellar_area','total_recidence','site_area', 'rank'],
    item:'card-item'
};
var building_list = new List('searchResultContent', card_options);


$(document).ready(function(){
	Parse.initialize(parseApplicationId, parseJavaScriptKey);

	var Building = Parse.Object.extend("Buildings");
	var query    = new Parse.Query(Building);
	query.include("Building_Subtype");  
	query.include("Bbr");
	query.find({
        success: function(results) {
            initializeBuildingOnLoad(results)
        },
        error: function(error) {
            alert("Error: " + error.code + " " + error.message);
        }
    });

});

function initializeBuildingOnLoad(loadedInfo){

	for(var i = 0 ; i < loadedInfo.length; i++){

		var building = new BuildingItem(loadedInfo[i]);
		building_list.add(building);


	}


}