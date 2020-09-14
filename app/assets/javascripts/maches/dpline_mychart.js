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
            "title": "DP"
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