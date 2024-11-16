---
theme: dashboard
title: BM Reading Room and Education
toc: false
---

# In the BM Reading Room




<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => bmYearsChart(bm, education, {width}))}
  </div>
</div>





```js
// load data

const education = FileAttachment("../data/l_bm/educated.csv").csv({typed: true});
const bm = FileAttachment("../data/l_bm/bm.csv").csv({typed: true});


```


```js
// can't get image to load; not sure what i'm doing wrong. pretty sure you can use a local image file.
// Second, the url for your image should be loaded into a variable in a separate JS block (so you get the benefits of code blocks implicitly awaiting on each others’ values), which you can then reference in your mark, like this:
//const imageURL = FileAttachment("data/example.jpeg").url()

const book_img = FileAttachment("../data/Black_book_icon.svg.png").url();

// Waldir, CC BY-SA 3.0 <https://creativecommons.org/licenses/by-sa/3.0>, via Wikimedia Commons
// https://commons.wikimedia.org/wiki/File:Black_book_icon.svg

```

```js
//book_img
```


function makeSquare(options = {}) {
  const { size = 10, stroke = "crimson", strokeWidth = 2 } = options;
  const d = size * 0.95;
  const r = d / 2;
  const points = [-r, r, r, r, r, -r, -r, -r];
  return d3
    .create("svg:polygon")
    .attr("points", points)
    .attr("fill", "none")
    .attr("stroke", stroke)
    .attr("stroke-width", strokeWidth)
    .node();
}



      	//symbol: symbolStar, in plot.dot worked but not range in plot ???
      	
```js
// https://talk.observablehq.com/t/custom-symbols-in-plot/9466/4
// specify them as part of the symbol scale’s range option:

const symbolStar = {
        draw(context, size) {
          const l = Math.sqrt(size);
          const x = l * Math.cos(Math.PI / 6);
          const y = l * Math.sin(Math.PI / 6);
          context.moveTo(0, -l);
          context.lineTo(0, l);
          context.moveTo(-x, -y);
          context.lineTo(x, y);
          context.moveTo(x, -y);
          context.lineTo(-x, y);
          context.closePath();
        }
      };
      


// but this doesn't work??
/*
Plot.plot({
  symbol: {
      range: [symbolStar, symbolCross, symbolWye, …]
  },
  marks: [ … ]
})
*/
```





```js
// TODO componentise this properly
// why does fy:group not work as expected?


const colorTime = Plot.scale({
		color: {
			range: ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "lightgray"], 
			domain: ["point in time", "start time", "end time", "latest date", "filled"]
		}
	});

	
const plotHeight = 2000;
const plotMarginTop = 10;
const plotMarginLeft = 180;


// BY DATE   	
function bmYearsChart(bm, education, {width}) {

  return Plot.plot({
  
    title: "BM Reading Room and Education",
    
    width,
    height: plotHeight,
    marginTop: plotMarginTop,
    marginLeft: plotMarginLeft,

    	
    x: {
    	grid: true, 
    	tickFormat: d3.format('d'),
    	
    	}, 
    	
    y: {label: null}, // this affects tooltip label too  
       
    symbol: {legend:true, 
    				range: ["triangle", "diamond2", "diamond2", "star", "square"], 
						domain: ["point in time", "start time", "end time", "latest date", "filled"]
		} ,
    color: colorTime,
    
    marks: [
     
      Plot.axisX({anchor: "top", 
      						label: "year of event", 
      						tickFormat: d3.format('d')}
      						),
      Plot.axisX({anchor: "bottom", 
      						label: "year of event", 
      						tickFormat: d3.format('d')}
      						),
      
      
    	// GUIDE LINES. a bit tricky if it can start with either bm or education. hmm.
      
    	
      Plot.ruleY(bm, { 
      	x1:1870, // TODO variable earliest_year for when the data expands.(for the whole dataset) needs to be 0 (or 5). and has to be earliest of *either* education *or* BM. so earliest_bm doesn't work for this. 
      	x2:1920, 
      	y: "person_label", 
      	stroke: "lightgray" , 
      	strokeWidth: 1,
      channels: {"first": 'earliest_bm', "year":"year"}, 
      sort: {y: 'first'} // only need to do this once
      }),
      
      
    
    //  VERTICAL RULES
    
    	// this should be *after* left-most Y rule 
      Plot.ruleX([1870]), // makes X start at 1870. 
      //TODO variable earliest_year as above
      
      // DOTS
      
 			// educated at fill years for start/end pairs. draw BEFORE single points.
 			// Q is there any way to do this so the fill looks like joined up lines rather than dots?
 			
      Plot.dot(
      	education, {
      	x: "year", 
      	y: "person_label" , 
      	filter: (d) => d.year_type=="filled",
      	dy:6,
      	symbol: "year_type",
      	fill:"year_type",
      	r:4,
      	tip:false, // don't want tooltips for these!
       }
      ),
    	
    	
			// educated at single points (point in time, start/end, latest)
      Plot.dot(
      	education, {
      	x: "year", 
      	y: "person_label" , 
      	fill: "year_type",
      	symbol: "year_type",
      	filter: (d) =>  d.year_type !="filled"  &	d.src=="educated", 
      	dy:6, // vertical offset. negative=above line.
      	// tips moved to Plot.tip
    	}), // /dot
 
    	
    	// BM dot  . want to use Plot.image with book icon but it won't work!
    	//Plot.dot(
    	Plot.image(
      	bm, {
      	x: "year", 
      	y: "person_label" , 
      	src: book_img, 
      	//symbol:"wye",
      	dy: -6, // moves the dot
      	channels: {
      		"BM year":"year", 
      		"age": "age",
      		} , 
      // tooltip
  			tip: {
    			format: {
    				"BM year": (d) => `${d}`, // added channel for label. why oh why can't I just give x a different label?
    				x: false,
      			y: false, // now need to exclude this explicitly
    				
    			},
  				anchor: "bottom-left", 
  				dx: 6,
  				dy: -6
  		  }
    	}), // /dot

      
      // TOOLTIPS
            
      // tip education negative offset
    	Plot.tip(education, Plot.pointer({
    			x: "year", 
    			y: "person_label", // can you really not give this a label?
      	  filter: (d) =>  d.year_type !="filled",  // no tips on filled years!
    			anchor:"top-right",
    			dx:-6,
    			dy:6,
    			channels: {
      		//woman: "person_label",
    			//"event type":"src",
    			"education year": "year",
      		//"year of birth":"bn_dob_yr", 
      		"age":"age",
      		where:"by_label",
      		qualification:"degree_label", 
      		} , 
      		format: {
      			x:false, 
      			y:false,
      			//woman: true,
      			// make these go first, do formatting
      			//"event type":true,
      			"education year": (d) => `${d}`, 
      			//"year of birth": (d) => `${d}`,
      			}
    			}
    		)	
    	), // /tip
    ]  // /marks
  });
};



```





