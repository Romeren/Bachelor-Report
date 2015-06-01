var numberOfBuildings = 1;



var card_options = {
    valueNames:['building_id','building_name','street','zip_code', 'districtname','building_subtype',
    			'building_supertype','built_area','building_area','heated_area','total_area',
    			'attic','cellar_area','total_recidence','site_area', 'rank', 'data_quality'],
    page: 15,
    plugins: [
                 ListPagination({})
                ],
    item:'card-item'

};

var buildingFuzzyOption = {
  searchClass: "inputfieldSearch",
  location: 0,
  distance: 100,
  threshold: 0.4,
  multiSearch: true
};
var build_pagination_option = {
       paginationClass: "buildingpagination",
};

var building_list; 

function initializeBuildingOnLoad(loadedInfo){

    var options = card_options;
        options.plugins[0] = ListPagination(build_pagination_option);
        options.plugins[1] = ListFuzzySearch(buildingFuzzyOption);
    
    building_list = new List('searchResultContent', card_options);


	if(loadedInfo.record){
		loadedInfo.record.forEach(function(entry){
			var building = new BuildingItem(entry);
			building_list.add(building);
			building.initBuildingItem(numberOfBuildings, building_list);
			numberOfBuildings = numberOfBuildings+1;
	
		});
	}
	
	initPieChartPage(20,100,1500, colours);
}



$(document).ready(function(){
  window.unloadSideBar();
  

    initChartLib();
//Setting up tabs on page:
$('.tab-links a').on('click', function(e)  {
        var currentAttrValue = $(this).attr('href');
 
        // Show/Hide Tabs
        $('.tabs ' + currentAttrValue).show().siblings().hide();
 
        // Change/remove current tab to active
        $(this).parent('li').addClass('active').siblings().removeClass('active');
 
        e.preventDefault();
    });


  //loading buildings:
    window.df.apis.postgres.getRecords({'table_name':'w_lookup_building'}, 
      function(response) {
        //console.log("response");
        //console.log(response);
        initializeBuildingOnLoad(response);
      }
      );
  //$('#PageContent').load('pages/Compare.html');
});

