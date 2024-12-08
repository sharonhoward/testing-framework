---
theme: dashboard
title: excavations networks select
toc: false
---


## select dropdown

source for filter method (not the input itself) https://observablehq.com/@asgersp/d3-force-directed-graph-with-input

```js 
const filterId = view(
		Inputs.select(
				["All"].concat(data.nodes.map(d => d.id)),
				//d3.group(data.nodes, (d) => d.id ),
				{
				label: "node", 
				//sort: true, 
				unique: true, 
				}
				)
		)
```

```js 
/*
const data_select =
data.nodes
  .filter((d) => filterId === "All" || d.id === filterId)
  .map((d) => ({...d}) )
  */
```

```js
data
```

slider working. now all you have to do is figure out how to get it into the chart.

might change this to number of appearances if i put that count back in.

```js
// slider from 1 to whatever the top value of degree is.

const top = d3.max(data.nodes.map(d => d.degree))

const slideLinks = view(
		Inputs.range(
			[1, top], 
			{
			step:1, 
			label:"links", 
			value:1
			}
		)
	);

```

this is just the number.
```js
slideLinks
```


```js
chart()
```


## functions

curvy links?

```js
function linkArc(d) {
  const r = Math.hypot(d.target.x - d.source.x, d.target.y - d.source.y);
  return `
    M${d.source.x},${d.source.y}
    A${r},${r} 0 0,1 ${d.target.x},${d.target.y}
  `;
}
```

```js

function chart() {

  // The force simulation mutates links and nodes, so create a copy
  // so that re-evaluating this cell produces the same result.
  
  let links = []
  let nodes = []
  
  if(filterId === "All"){
     links = data.links.map(d => Object.create(d));
     nodes = data.nodes.map(d => Object.create(d));
     
  } else {
  
    links = data.links.filter(d => d.source == filterId || d.target == filterId).map(d => Object.create(d));
    const otherPersons = links.map(d => d.source !== filterId ? d.source : d.target)
    nodes = data.nodes.filter(d => d.id == filterId || otherPersons.indexOf(d.id) >= 0).map(d => Object.create(d));
  }
  
//  const links = data.links.map(d => ({...d}));
//  const nodes = data.nodes.map(d => ({...d}));
//  const links = data.links.map(d => Object.create(d)); //timeseries had this but i don't *thnk* it's significant diff.
//  const nodes = data.nodes.map(d => Object.create(d));


  // Create a simulation with several forces. 
  const simulation = d3.forceSimulation(nodes)
      //.force("charge", d3.forceManyBody()) // why forceManyBody twice?
      .force("link", d3.forceLink(links).id(d => d.id))
      .force("charge", d3.forceManyBody().strength(-620))
      .force("center", d3.forceCenter(0, 0))
      .force("x", d3.forceX())
      .force("y", d3.forceY())
      .force("collide", d3.forceCollide(30))
      ;
     

  // Create the SVG container. 
  const svg = d3.create("svg")
      .attr("viewBox", [-width / 2, -height / 2, width, height]);


  // Add a line for each link, and a circle for each node.
  const link = svg.append("g")
      .attr("stroke", "#999")
      .attr("stroke-opacity", 0.4)
      .selectAll("line")
      .data(links)
      // https://www.createwithdata.com/d3-has-just-got-easier/
      .join("line")
      //.attr("stroke-width", d => Math.sqrt(d.value));
      .attr("stroke-width", d => d.weight); // width of lines


	// circles
  const node = svg.append("g")
      .attr("stroke", "#fff")
      .attr("stroke-width", 1)
      .selectAll("circle")
      .data(nodes)
      .join("circle")
      .attr("r", d => getRadius(d.degree/2)) // tweak 
      .attr("fill", d => color(d.gender))  
      .style("fill-opacity", 0.6)
      .attr("stroke", "black")
      .style("stroke-width", 1)
      
      // change opacity on hovering. 
     /* .on("mouseover",function(){
      const target = d3.select(this)
      target.style("fill-opacity", 0.9)
      })
    .on("mouseout",function(){
      const target = d3.select(this) 
      target.style("fill-opacity", 0.6)
      })*/
      
        //.on("mouseover", (event, d) => tooltip_in(event, d))
        //.on("mouseout", tooltip_out)
        
      .call(drag(simulation));
  
  
  // labels
  var text = svg.append("g")
    .attr("class", "labels")
    .selectAll("text")
    .data(nodes)
    .enter().append("text")
    .attr("dx", d => d.x)
    .attr("dy", d => d.y)
    
    .attr("opacity", 0.8)
    .attr("font-family", "Arial")
    .style("font-size","14px")
    .text(function(d) { return d.id })
//    .text(function(d) { return d.id })

    .call(drag(simulation));

  
  
  //node.append("title")
  //    .text(d => d.id);
      
  
/*
how to use linkArc?
https://observablehq.com/@d3/mobile-patent-suits
simulation.on("tick", () => {
    link.attr("d", linkArc);
    node.attr("transform", d => `translate(${d.x},${d.y})`);
  });
  */

  simulation.on("tick", () => {
    link
        .attr("x1", d => d.source.x)
        .attr("y1", d => d.source.y)
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y)
        ;

    node
        .attr("cx", d => d.x)
        .attr("cy", d => d.y)
        ;
    
    text
        .attr("dx", d => d.x)
        .attr("dy", d => d.y);
  });
  

  invalidation.then(() => simulation.stop());

  svg.call(d3.zoom()
      .extent([[0, 0], [width, height]])
      .scaleExtent([0.2, 10])
      .on("zoom", zoomed));

// https://stackoverflow.com/a/71011116/7281022
// zoomTransform(this) rather than transform 
  function zoomed() {
  	//svg.attr("transform", d3.zoomTransform(this));
    node.attr("transform", d3.zoomTransform(this));
    link.attr("transform", d3.zoomTransform(this));
    text.attr("transform", d3.zoomTransform(this));
  }  
  
  return svg.node();

}

```


```js
// helper function for drag interaction. for dragging nodes.

function drag(simulation) {

  function dragstarted(event) {
//  if (!d3.event.active) simulation.alphaTarget(0.3).restart(); doesn't work
    if (!event.active) simulation.alphaTarget(0.3).restart();
    event.subject.fx = event.subject.x;
    event.subject.fy = event.subject.y;
//    d.fx = d.x;  doesn't work
  }

  function dragged(event) {
    event.subject.fx = event.x;
    event.subject.fy = event.y;
  }

  function dragended(event) {
    if (!event.active) simulation.alphaTarget(0);
    event.subject.fx = null;
    event.subject.fy = null;
  }


  return d3.drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended);
}

```


```js

const height=800;

const color = d3.scaleOrdinal(d3.schemeCategory10);


function getRadius(useCasesCount){
		var	m=useCasesCount/1.5
		var d=3/useCasesCount
  if(useCasesCount>=9){   
  	var radius = m+d  
    return radius
  }
  return 6
}
```






## data


```js
const data = FileAttachment("../data/l_networks_excavations/bn-excavations.json").json();
```




