var colours;

var initChartLib = function(){

    var objColors = $('body').data('sprFlat').getColors();

     colours = {
        white: objColors.white,
        dark: objColors.dark,
        red : objColors.red,
        blue: objColors.blue,
        green : objColors.green,
        yellow: objColors.yellow,
        brown: objColors.brown,
        orange : objColors.orange,
        purple : objColors.purple,
        pink : objColors.pink,
        lime : objColors.lime,
        magenta: objColors.magenta,
        teal: objColors.teal,
        textcolor: '#5a5e63',
        gray: objColors.gray
    }

    //initPieChartPage(20,100,1500, colours);
}



//Setup easy pie charts in page
var initPieChartPage = function(lineWidth, size, animateTime, colours) {

	$(".easy-pie-chart").easyPieChart({
        barColor: colours.dark,
        borderColor: colours.dark,
        trackColor: colours.gray,
        scaleColor: false,
        lineCap: 'butt',
        lineWidth: lineWidth,
        size: size,
        animate: animateTime
    });
    $(".easy-pie-chart-red").easyPieChart({
        barColor: colours.red,
        borderColor: colours.red,
        trackColor: '#fbccbf',
        scaleColor: false,
        lineCap: 'butt',
        lineWidth: lineWidth,
        size: size,
        animate: animateTime
    });
    $(".easy-pie-chart-green").easyPieChart({
        barColor: colours.green,
        borderColor: colours.green,
        trackColor: '#b1f8b1',
        scaleColor: false,
        lineCap: 'butt',
        lineWidth: lineWidth,
        size: size,
        animate: animateTime
    });
    $(".easy-pie-chart-blue").easyPieChart({
        barColor: colours.blue,
        borderColor: colours.blue,
        trackColor: '#d2e4fb',
        scaleColor: false,
        lineCap: 'butt',
        lineWidth: lineWidth,
        size: size,
        animate: animateTime
    });
    $(".easy-pie-chart-teal").easyPieChart({
        barColor: colours.teal,
        borderColor: colours.teal,
        trackColor: '#c3e5e5',
        scaleColor: false,
        lineCap: 'butt',
        lineWidth: lineWidth,
        size: size,
        animate: animateTime
    });
    $(".easy-pie-chart-purple").easyPieChart({
        barColor: colours.purple,
        borderColor: colours.purple,
        trackColor: '#dec1f5',
        scaleColor: false,
        lineCap: 'butt',
        lineWidth: lineWidth,
        size: size,
        animate: animateTime
    });

}