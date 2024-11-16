---
theme: dashboard
title: Motherhood (v2)
toc: false
---

# Timelines of childbirth

componentised version. if you're having problems, you may need to test stuff out in v1 first!

nb that componenting involved adding the extra data bits to the function parameters (in both the components js and when you get the chart in the md), it can't use them directly once moved out of the md. but it was fine to use the same names so not too confusing right...

added spoke at, but can't make toggle work!!!!! 

<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => hadChildrenAgesChart(hadChildrenAges, lastAges, workServedSpokeYearsWithChildren,  {width}, plotTitle, plotHeight))}
  </div>
</div>


end of chart, imports and stuff start here...

```js
// editables

const plotHeight = 1500;

const plotTitle = "The ages at which BN women had children, sorted by mothers' dates of birth";
```


```js
// Import components
import {hadChildrenAgesChart} from "./components/mothers.js";
```

```js

//load data [dataloader uses zip method to create multiple objects]

const hadChildrenAges = FileAttachment("../data/l_women_children/had-children-ages.csv").csv({typed: true});

//const workYearsWithChildren = FileAttachment("../data/l_women_children/work-years-with-children.csv").csv({typed:true});

//const servedYearsWithChildren = FileAttachment("../data/l_women_children/served-years-with-children.csv").csv({typed:true});

//const workServedYearsWithChildren = FileAttachment("../data/l_women_children/work-served-years-with-children.csv").csv({typed:true});

//const spokeYearsWithChildren = FileAttachment("../data/l_women_children/spoke-years-with-children.csv").csv({ typed:true});

const workServedSpokeYearsWithChildren = FileAttachment("../data/l_women_children/work-served-years-with-children.csv").csv({typed:true})

const lastAges = FileAttachment("data/l_women_children/last-ages-all.csv").csv({ typed:true});
//FileAttachment("../data/l_women_children/consolidated-last-ages.csv").csv({ typed:true});

```


## ARRRRGHHHHHH FUYCKING THINGS

i think you're nearly there but have to rewrite the makeToggle so it doesn't need .flattening... you never did that for checkboxes.

got select working! but can only select one at a time. 
will multiple:true do it? breaks. idk why

what i could do is make a new category of positions+served / spoke, and then either/or works. that would be ok for now, but i need to make this work properly anyway.


so how to get checkbox working? 
why is it different from select and radio?
i suppose because it can select multiple options; that's why you have the multiple arrays that you then flatten together?




checkbox

```js
//using d3.group and then flat
const checkMothers = view(   
		Inputs.checkbox(
    d3.group(workServedSpokeYearsWithChildren, (d) => d.activity ),
    {
    label: "Activity type",
    key: ["work", "served", "spoke"] // does need this
    }
  ) 
) ;
```




```js
//workServedSpokeYearsWithChildren
```








```js
function testChart(data, lastAges, workServedSpokeYearsWithChildren, {width}, plotTitle, plotHeight) {

  return Plot.plot({
  
    title: plotTitle,
    
    width,
    height: plotHeight, // 1600,
    marginTop: 25, // increases gap between plotTitle and plot but...
    marginLeft: 180,
    //marginBottom: 20, //causes overlap 
    
    x: {
    	grid: true, 
    	label: "age at birth of child", // why does this not show at top as well?
    	axis: "both" // "both" top and bottom. [null for nothing.]
    	},
    	
    y: {label: null}, // this affects tooltip label too
    
    symbol: {range: ["circle", "diamond2", "times"], 
				 domain: ["work", "served", "spoke"]
		},
		    
    marks: [
      
      
      // thin horizontal guideline, age 15 to last event. 
      Plot.ruleY(lastAges, {
      	x1:15, x2: "last_age", // ?need to incorporate work ages into last_age...
      	y: "personLabel", 
      	stroke: "lightgray" , 
      	strokeWidth: 1,
      channels: {
      	yob: 'bn_dob_yr', 
      	year:"year"
      	}, 
      	sort: {y: 'yob'} // sort only needed once?
      }),
     	
      
      // thicker horizontal line first child to last child. 
        Plot.ruleY(data, {
      	x1:"start_age", x2: "last_age", // x1 to start this at 15 as well. need to incorporate work ages into last_age...
      	y: "personLabel", 
      	stroke: "lightgray" , 
      	strokeWidth: 4,
      channels: {
      	yob: 'bn_dob_yr', 
      	year:"year"
      	}, 
      	//sort: {y: 'yob'} // sort only needed once?
      }),
      
      // vertical ruled line
      // needs to come *after* leftmost ruleY
      Plot.ruleX([15]), // makes X start at 15. 
         

      // dots for combined activity. 
      
    	Plot.dot(
    	checkMothers.flat(),
    	//workServedSpokeYearsWithChildren , 
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
    				"spoke": "spoke",
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
      			  spoke:true,
      			  "year": (d) => `${d}`,
      			  age:true
    			},
    			anchor:"top", // tips below the line
    			}
    		}
    	)  ,

   
    	// barcode style for birth years [go in last so they're on top]
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
      			"child born": (d) => `${d}`, // TODO proper date formatting?
      			x: true,
      			child:true
    			},
    			anchor:"bottom" // tips above the line
  		  } 
    	}), // /tick

    	
    ] // /marks
  }); // /plot
} // /function

```




<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => testChart(hadChildrenAges, lastAges, workServedSpokeYearsWithChildren,  {width}, plotTitle, plotHeight))}
  </div>
</div>




YESSSSSSSS

```js
Plot.plot({
	x: {grid:true, label: "yob"},
	y: {label:"year"},
	marks: [
		Plot.dot(
		checkMothers.flat(),
		 {
			x: "bn_dob_yr",
			y: "start_year",
			fill: "activity"
		})
	]
})
```


select

```js
//a) make select dropdown box: concat "all" map position_label and unique:true
//does this work  multiple:true - no. 

const pickMothers = view(
		Inputs.select(
				["All"].concat(workServedSpokeYearsWithChildren.map(d => d.activity)),
				{
				label: "Activity type", 
				sort: true, 
				unique: true, 
				//multiple: true,
				}
				)
		)
```

```js
//b) use that to make the new filtering data array

const data_select =
workServedSpokeYearsWithChildren
  .filter((d) => pickMothers === "All" || d.activity === pickMothers)
  .map((d) => ({...d}) )

```