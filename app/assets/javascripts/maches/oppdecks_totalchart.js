AmCharts.makeChart("deck_pie_totalchart",
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
	"dataProvider": gon.oppdecks_totalchart
});
