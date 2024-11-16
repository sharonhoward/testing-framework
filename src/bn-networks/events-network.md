---
theme: dashboard
title: networks WIP inputs
---

## work on filters/inputs

things i'd like

checkbox?

- change colours of nodes according to selected grp
- change size of nodes according to centrality measure (marvel network has this, though as a dropdown)

but... grpX and centrality measures are all distinct columns, not categories...

slider
- filter by a measure (number of links?)



[then work out how to have more than one...?]

```js
data
```


```js 
//a) make select dropdown box: concat "all" map position_label and unique:true
const filterGroup = view(
		Inputs.select(
				["All"].concat(data.nodes.map(d => d.group)),
				{
				label: "group", 
				sort: true, 
				unique: true, 
				}
				)
		)
```


```js
//b) use that to make the new filtering data array
const group_select =
	data.nodes
  	.filter((d) => filterGroup === "All" || d.group === filterGroup)
  .map((d) => ({...d}) )

```


```js
//c) and then use group_select in the table
Inputs.table(group_select, {
	layout: "auto",
	format: {
		person: person => htl.html`<a href=https://beyond-notability.wikibase.cloud/entity/${person} target=_blank>${person}</a>`
	},
  columns: [    
    "person",
    "id",
    "n_event",
    "grp3",
    "group"
  ], 
  header: {
    person: "Id",
    id: "name",
    n_event: "connections",
    grp3: "group",
    group: "size"
  }
})

```




```js
chart2()
```

```js

function chart2() {

 
  // The force simulation mutates links and nodes, so create a copy
  // so that re-evaluating this cell produces the same result.
  const links = data.links.map(d => ({...d}));
  const nodes = data.nodes.map(d => ({...d}));

//  const links = data.links.map(d => Object.create(d));
//  const nodes = data.nodes.map(d => Object.create(d));

  // Create a simulation with several forces.
  const simulation = d3.forceSimulation(nodes)
      .force("charge", d3.forceManyBody()) // why forceManyBody twice?
      .force("link", d3.forceLink(links).id(d => d.id))
      
      .force("charge", d3.forceManyBody().strength(-320))
      .force("center", d3.forceCenter(0, 0))
      .force("x", d3.forceX())
      .force("y", d3.forceY());

      

  // Create the SVG container.
  const svg = d3.create("svg")
      .attr("viewBox", [-width / 2, -height / 2, width, height]);


  // Add a line for each link, and a circle for each node.
  const link = svg.append("g")
      .attr("stroke", "#999")
      .attr("stroke-opacity", 0.4)
      .selectAll("line")
      .data(links)
      .join("line")
      //.attr("stroke-width", d => Math.sqrt(d.value));
      .attr("stroke-width", d => d.value); // width of lines


	// circles
  const node = svg.append("g")
      .attr("stroke", "#fff")
      .attr("stroke-width", 1)
      .selectAll("circle")
      .data(nodes)
      .join("circle")
      .attr("r", d => getRadius(d.n_event))
      
      .attr("fill", d => color(d.grp3))  
      .style("fill-opacity", 0.8)
      .attr("stroke", "black")
      .style("stroke-width", 1)
      
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
//    .text(function(d) { return d.id })
    .text(function(d) { return d.name_label })

    .call(drag(simulation));

  
  
  node.append("title")
      .text(d => d.id);



  simulation.on("tick", () => {
    link
        .attr("x1", d => d.source.x)
        .attr("y1", d => d.source.y)
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y);

    node
        .attr("cx", d => d.x)
        .attr("cy", d => d.y);
    
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
//using d3.group and then flat
/*const checkGroup = view(
	Inputs.checkbox(
			d3.group(data.nodes, (d) => d.group ), {
			label: "group:",
			key: ["group1", "group2", "group3"],
			//value: group
			}
))
*/
```


```js
/*
Inputs.table(checkGroup.flat(), {
	layout: "auto",
	format: {
		person: person => htl.html`<a href=https://beyond-notability.wikibase.cloud/entity/${person} target=_blank>${person}</a>`
	},
  columns: [    
    "person",
    "id",
    "n_event",
    "grp3",
    "group"
  ], 
  header: {
    person: "Id",
    id: "name",
    n_event: "connections",
    grp3: "group",
    group: "size"
  }
})
*/

```


```js
//checkGroup.flat()
//	Plot.dot(checkGroupPosition2.flat(),
//d3.group(data.nodes, (d) => d.group )
```


```js
/*Plot.plot({
	x: {grid:true},
	y: {label:"year"},
	marks: [
		Plot.dot(
		checkGroup.flat(),
		 {
			x: "grp3",
			y: "n_event",
			fill: "group"
		})
	]
})
*/
```



## select dropdown - working

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
chart()
```


## functions

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
      .force("charge", d3.forceManyBody()) // why forceManyBody twice?
      .force("link", d3.forceLink(links).id(d => d.id))
      .force("charge", d3.forceManyBody().strength(-320))
      .force("center", d3.forceCenter(0, 0))
      .force("x", d3.forceX())
      .force("y", d3.forceY());
     

  // Create the SVG container. 
  const svg = d3.create("svg")
      .attr("viewBox", [-width / 2, -height / 2, width, height]);


  // Add a line for each link, and a circle for each node.
  const link = svg.append("g")
      .attr("stroke", "#999")
      .attr("stroke-opacity", 0.4)
      .selectAll("line")
      .data(links)
      // .join vs .enter().append. here and in node. ? seems to work with either. example used enter()...
      // https://www.createwithdata.com/d3-has-just-got-easier/
      .join("line")
      //.enter().append("line")
      
      //.attr("stroke-width", d => Math.sqrt(d.value));
      .attr("stroke-width", d => d.value); // width of lines


	// circles
  const node = svg.append("g")
      .attr("stroke", "#fff")
      .attr("stroke-width", 1)
      .selectAll("circle")
      .data(nodes)
      .join("circle")
         // .enter().append("circle")
      .attr("r", d => getRadius(d.n_event))
      .attr("fill", d => color(d.grp3))  
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
    .text(function(d) { return d.name_label })
//    .text(function(d) { return d.id })

    .call(drag(simulation));

  
  
  node.append("title")
      .text(d => d.id);
      
  

  simulation.on("tick", () => {
    link
        .attr("x1", d => d.source.x)
        .attr("y1", d => d.source.y)
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y);

    node
        .attr("cx", d => d.x)
        .attr("cy", d => d.y);
    
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
// data
// events data. group col is grp2, grp3, grp4 otherwise should match

const data = FileAttachment("../data/l_networks/bn-events.json").json();

//const data = FileAttachment("../data/miserables.json").json();
//const data = FileAttachment("../data/4graph.json").json()
```



## possible resources


it's probably all in here but ugh

https://www.d3indepth.com/

helpful? quite old

https://flowingdata.com/2012/08/02/how-to-make-an-interactive-network-visualization/

maybe

https://ona-book.org/advanced-viz.html#adding-a-search-box-to-search-and-highlight-a-specific-mp-name

https://nlinc1905.github.io/javascript,/html,/d3,/data/visualization,/network/science/2017/04/09/how-to-build-interactive-network-graph-d3.html


how do you join the filtered group to links again?

https://stackoverflow.com/questions/37649329/how-to-approach-filtering-nodes-and-edges-rendered-via-d3-js-according-to-user-p

The approach

    First you need to narrow down the source data by using filtering or whatever makes sense in your situation. You end up with filtered data.
    
    Then you need to selectAll the nodes that have been drawn already and join the selection with filtered data from step 1.
    
    Finally use the d3 enter, update and exit selections to add, update and remove nodes and links.

Example

Mike Bostock published an example of [Modifying a Force Layout].(https://bl.ocks.org/mbostock/1095795)

[of course the example is more complicated.]

 



```js
// https://observablehq.com/framework/lib/d3
// https://richardbrath.wordpress.com/2018/11/24/using-font-attributes-with-d3-js/

```








radical translations checkbox for languages

```js echo
/*
const translatedTo = view(Inputs.checkbox(languages, {
  label: html`<b>Languages translated to</b>`
})
)

const languages = raw.nodes
  .filter((n) => n.group === "language" && n.title !== "German")
  .map((n) => n.title)
  .sort()

each language has a ?row in raw.nodes (which is mixed types of object)
 
 0:    
  Object {
  id: "english"
  title: "English"
  group: "language"
  url: "/database/agents/?language__term=English"
  meta: 
  Array(0) []
}
 
*/
```

ok how does that get people?

the language seems to be in the results.links.meta which is a flat list of people, places, languages.

bloody hell. all i want is to use a variable in the nodes.
