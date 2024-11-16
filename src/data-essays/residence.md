---
theme: dashboard
title: residence
---




## resided at date types



```js
function residedTypesChart(data, {width}) {
	return Plot.plot({
title: "Resided at dates",
  x: {grid: true, label:"count"},
  y: {label: null},
  //color: {legend: true},
  width,
  height:400,
  marginLeft: 80,
  marks: [
    Plot.ruleX([0]),
    Plot.rectX(
    	data, 
    	Plot.groupY({x: "count"}, {y:"date_prop_label", sort: {y: "x", reverse: true} }) )
  ]
});
}
```


<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => residedTypesChart(resided, {width}))}
  </div>
</div>


```js
//resided
```



## early and late

dates for women with early (up to age 30) and late (60+) residences only

- excluded any with undated resided at; anyone born before 1831 and after 1910;
- also, for early: excluded any with a start date and no corresponding end date, and any with an earliest date 
- and for late: excluded any with an end date and no matching start date, and any with a latest date


```js
Plot.plot({
  y: {grid: true},
  color: {legend: true},
  marks: [
    Plot.dot(datesResidedEarlyLate, 
    	Plot.dodgeX("middle", 
    		{fx: "group", 
    		 y: "age", 
    		 fill: "residence",
    		 tip: {
    		 	format: {
    		 		fill: false,
    		 		fx: false, 
    		 		y: true,
    		 		property: true,
    		 		year: (d) => `${d}`
    		 	}
    		 },
    		 channels: {
    		 		//name:"personLabel", // maybe?
	    		 	property:"propertyLabel",
	    		 	year: "year"
    		 }
    	 },
    	)	
    )
  ]
})
```

```js
//datesResidedEarlyLate
```

for comparison: other women


```js
Plot.plot({
	height:900,
  y: {grid: true},
  color: {legend: true},
  marks: [
    Plot.dot(datesResidedOther, 
    	Plot.dodgeX("middle", {
    		y: "age", 
    		fill: "residence",
    		r:2.5
    	})
    )
  ]
})
```







```js
//const dates = FileAttachment("./data/l_dates_simplified_all/dates-all-simplified.csv").csv({typed: true});

const resided = FileAttachment("./data/l_resided_at/resided.csv").csv({typed: true})

const residedDated = FileAttachment("./data/l_resided_at/resided-dated.csv").csv({typed: true})

const residedAges = FileAttachment("./data/l_resided_at/resided-birth-age.csv").csv({typed: true})

const datesResidedEarlyLate = FileAttachment("./data/l_resided_at/dates-resided-early-late.csv").csv({typed: true})

const datesResidedOther = FileAttachment("./data/l_resided_at/dates-resided-other.csv").csv({typed: true})

```
