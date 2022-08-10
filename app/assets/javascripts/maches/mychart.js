AmCharts.makeChart("dpline_mychart",
{
    "type": "serial",
    "categoryField": "category",
    "zoomOutButtonPadding": 9,
    "zoomOutButtonTabIndex": -3,
    "startDuration": 1,
    "startEffect": "easeInSine",
    "theme": "default",
    "categoryAxis": {
        "gridPosition": "start",
        "autoGridCount": false
    },
    "trendLines": [],
    "graphs": [
        {
            "balloonText": "対戦数 :[[category]]<br>DP:[[value]]",
            "bullet": "round",
            "bulletAlpha": 0,
            "id": "AmGraph-1",
            "markerType": "circle",
            "periodSpan": 0,
            "tabIndex": 0,
            "title": "graph 1",
            "valueField": "column-1"
        }
    ],
    "guides": [],
    "valueAxes": [
        {
            "id": "ValueAxis-1",
            "usePrefixes": "true"
        }
    ],
    "allLabels": [],
    "balloon": {},
    "legend": {
        "enabled": false,
        "bottom": 0,
        "useGraphSettings": true
    },
    "dataProvider": gon.dpline_mychart
});


AmCharts.makeChart("deck_pie_mychart",
{
	"type": "pie",
	"balloonText": "[[title]]<br><span style='font-size:14px'><b>[[percents]]%</b></span>",
	"labelText": "[[title]]",
	"labelRadius": 18,
	"minRadius": 100,
	"radius": 0,
	"pullOutEffect": "elastic",
	"startEffect": "easeInSine",
	"titleField": "category",
	"valueField": "column-1",
	"allLabels": [],
	"balloon": {},
	"legend": {
		"enabled": false,
		"align": "center",
    "labelWidth": 0,
    "markerType": "circle",
    "valueText": ""
	},
	"dataProvider": gon.oppdecks_mychart
});