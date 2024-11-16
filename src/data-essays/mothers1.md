---
theme: dashboard
title: Motherhood (v1)
toc: false
---

# Timelines of childbirth

version in bn_framework has been tidied up, converted to use components, and removed the by dates function at the bottom.

nb that componenting involved adding the extra data bits to the function parameters (in both the components js and when you get the chart in the md), it can't use them directly once moved out of the md. but it was fine to use the same names so not too confusing right...

```js

const hadChildrenAges = FileAttachment("data/l_women_children/had-children-ages.csv").csv({typed: true});

const workYearsWithChildren = FileAttachment("data/l_women_children/work-years-with-children.csv").csv({typed:true});

const servedYearsWithChildren = FileAttachment("data/l_women_children/served-years-with-children.csv").csv({typed:true});

//const workYears = FileAttachment("data/l_women_children/work-years.csv").csv({typed:true});

const lastAges = FileAttachment("data/l_women_children/consolidated-last-ages.csv").csv({typed:true});

const workServedYearsWithChildren = FileAttachment("data/l_women_children/work-served-years-with-children.csv").csv({typed:true});



```

<!-- 
need to add more variables as points...

 -->

```js
function hadChildrenAgesChart(data, {width}) {
  return Plot.plot({
    title: "The ages at which BN women had children, sorted by mothers' dates of birth",
    width,
    height: 1600,
    marginTop: 0,
    marginLeft: 180,
    x: {
    	grid: true, 
    	label: "age at birth", // how to get this at top as well?
    	axis: "both" // "both" top and bottom. null for nothing.
    	},
    y: {label: null}, // this affects tooltip label too
    
    symbol: {range: ["circle", "diamond2"], 
				 domain: ["work", "served"]
		},
    
    marks: [
      
      // from age 15 to last age. 
      Plot.ruleY(lastAges, {
      	x1:15, x2: "last_age", // x1 to start this at 15 as well. need to incorporate work ages into last_age...
      	y: "personLabel", 
      	stroke: "lightgray" , 
      	strokeWidth: 1,
      channels: {
      	yob: 'bn_dob_yr', 
      	year:"year"
      	}, 
      	sort: {y: 'yob'} // sort only needed once?
      }),
     	
      
      // highlight first child to last child. 
        Plot.ruleY(data, {
      	x1:"start_age", x2: "last_age", // x1 to start this at 15 as well. need to incorporate work ages into last_age...
      	y: "personLabel", 
      	stroke: "lightgray" , 
      	strokeWidth: 3,
      channels: {
      	yob: 'bn_dob_yr', 
      	year:"year"
      	}, 
      	//sort: {y: 'yob'} // sort only needed once?
      }),
      
      // this should come *after* (on top of) leftmost ruleY
      Plot.ruleX([15]), // makes X start at 15. 
         
      // dots for combined activity. not working.? works here but not in componentised version. might as well get on with it here and work that out afterwards
    	Plot.dot(workServedYearsWithChildren , 
    		{
    			x:"activity_age",
    			y:"personLabel",
    			strokeOpacity:0.7,
    			r:4,
    			symbol:"activity",
    			//title: "positions", // TODO better tips
    			channels: {
    				"position": "positions",
    				"service": "service",
    				"year": "start_year",
    				"age": "activity_age",
    			},
    			tip: {
    			format: {
      			  y: false, // now need to exclude this explicitly
      			  x: false,
      			  symbol:false,
      			  position:true,
      			  service:true,
      			  "year": (d) => `${d}`,
      			  age:true
    			},
    			anchor:"top", // tips below the line
    			}
    		}
    	)  ,


    	   
      Plot.tickX(data, 
      	{
      		x: "age", 
      		y: "personLabel" , 
      		strokeWidth: 2,
      		tip:true,
      		channels: {
      			"child born":"year", 
      			child:"childLabel", 
      			"year of birth":"bn_dob_yr", 
      			//woman: "personLabel"
      		} , 
      	//sort: {y: 'yob'} , // sorting again doesn't seem to be needed
      	// tooltips
  			tip: {
    			format: {
    				//woman: true, // added channel for label.
      			y: false, // now need to exclude this explicitly
    				"year of birth": (d) => `${d}`,
      			"child born": (d) => `${d}`, // is there a more correct way to make this format as a year, without a comma?
      			x: true,
      			child:true
    			},
    			anchor:"bottom"
  		  } 
    	}), // /tick

    	
    ] // /marks
  }); // /plot
} // /function

// channels to reference more data variables; can be called anything
// i think you only need to do the sort once
// seems clunky to make y label empty then define same variable as a channel for tooltip then exclude y again! maybe there's a better way to keep y label for tooltip but omit from y axis...
```


<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => hadChildrenAgesChart(hadChildrenAges, {width}))}
  </div>
</div>



```js
// a version showing dates rather than ages so we can see when we have data for... 

function hadChildrenYearsChart(data, {width}) {
  return Plot.plot({
    title: "When BN women had children, sorted by date of first child",
    width,
    height: 900,
    marginTop: 0,
    marginLeft: 180,
    x: {grid: true, label: "year child born", tickFormat: d3.format(".0f")}, // get rid of commas in years
    // Plot.plot({  x: {    tickFormat: d3.format(".0f"), 
    y: {label: null}, // this affects tooltip label too
    marks: [
      Plot.ruleX([1830]), // makes X start at specified number.
      Plot.ruleY(data, {x1:1830, x2: "latest_year", y: "personLabel", stroke: "lightgray" , // x1 to start this at 10 as well
      channels: {yob: 'bn_dob_yr', year:"year", "first year":"earliest_year"}, sort: {y: "first year"}
      }),
      Plot.tickX(
      	data, {x: "year", y: "personLabel" , tip:true,
      	channels: {
      	// label:colname
      		"age at birth of child": "age",
      		"year child born":"year", 
      		child:"childLabel", 
      		"year of birth":"bn_dob_yr", 
      		woman: "personLabel"
      		} , 
      // tooltip
  			tip: {
    			format: {
    				woman: true, // added channel for label.
      			y: false, // now need to exclude this explicitly.
    				"year of birth": (d) => `${d}`, // same effect as d3.format in next line
      			"year child born": d3.format(".0f"), 
      			x: true,
      			child:true
    			}
  		  }
    	})
    ]
  });
}

```


<!-- 
<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => hadChildrenYearsChart(hadChildrenAges, {width}))}
  </div>
</div>
 -->