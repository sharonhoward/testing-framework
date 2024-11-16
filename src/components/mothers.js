import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";

//const groupMothers = d3.group(workServedSpokeYearsWithChildren, (d) => d.activity );

//workServedSpokeYearsWithChildren,  
export function hadChildrenAgesChart(hadChildrenAges, lastAges, groupMothers,
{width}, plotTitle, plotHeight) {

  return Plot.plot({
  
    title: plotTitle,
    
    width,
    height: plotHeight,
    marginTop: 25,
    marginLeft: 180,
    
    x: {
    	grid: true, 
    	//tickFormat: d3.format('d'),
    	label: "age at birth of child", // only shows at bottom, why?
    	axis: "both" // "both" top and bottom. [null for nothing.]
    	},
    	
    y: {label: null}, // this affects tooltip label too
    
    symbol: {range: ["circle", "diamond2", "times"], 
				 domain: ["work", "served", "spoke"]
		},
		    
    marks: [

			// this works in the education timeline but not here. no error message, just blank.
//    	Plot.axisX({anchor: "top", 
//      						label: "age at birth of child", 
//      						tickFormat: d3.format('d')}
//      						),
//      Plot.axisX({anchor: "bottom", 
//      						label: "age at birth of child", 
//      						tickFormat: d3.format('d')}
//      						),
      
      // horizontal guideline
      // age 15 to last event. 
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
     	
      
      // horizontal thicker line first child to last child. 
        Plot.ruleY(hadChildrenAges, {
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
      // needs to be *after* leftmost ruleY
      Plot.ruleX([15]), // makes X start at 15. 
         

      // dots for combined activity. 
      
    	Plot.dot(
    	//workServedSpokeYearsWithChildren , 
    	groupMothers,
    		{
    			x:"activity_age",
    			y:"personLabel",
    			strokeOpacity:0.7,
    			r:4,
    			symbol:"activity",
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
      Plot.tickX(hadChildrenAges, 
      	{
      		x: "age", 
      		y: "personLabel" , 
      		strokeWidth: 2,
      		//tip:true,
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

// channels to reference more data variables; can be called anything
// i think you only need to do the sort once
// seems clunky to make y label empty then define same variable as a channel for tooltip then exclude y again! maybe there's a better way to keep y label for tooltip but omit from y axis...
