---
theme: dashboard
title: RAI testing filters
toc: false
---

a fairly simple network graph for testing, no click to highlight and suchlike, so you'll need to make sure filters work with that. 

can i use degree/n_events as the filter? not sure that's a good idea. might work better when looking at a single person's network, but even then probably better to use links.



 
```js 
//working dropdown (so you can see how to combine filters)
//filter method  //https://observablehq.com/@asgersp/d3-force-directed-graph-with-input
//
const filterId = view(
		Inputs.select(
				["All"].concat(weightData.nodes.map(d => d.id)),
				//data.nodes.map((d) => d.id ),
				{
				label: "node", 
				//sort: true, 
				unique: true, 
				}
				)
		)
```

ohkayyy. can i work out how to do a checkbox filter with the fake groups? then i'll need to work out data to do that properly, but it'll be useful to have a method working.








```js
//using d3.group and then flat
const checkGroup = view(
	Inputs.checkbox(
			d3.group(data.nodes, (d) => d.group ), {
			label: "group:",
			key: ["group1", "group2", "group3", "group4"],
			//value: group,
			sort: true
			}
))

```


```js

Inputs.table(checkGroup.flat(), {
	layout: "auto",
	format: {
		person: person => htl.html`<a href=https://beyond-notability.wikibase.cloud/entity/${person} target=_blank>${person}</a>`
	},
  columns: [    
    "person",
    "id",
    "degree",
    "degree_rank",
    "group"
  ], 
  header: {
    person: "Id",
    id: "name",
    degree: "connections",
    degree_rank: "ranking",
    group: "size"
  }
})


```


```js
//checkGroup.flat()
//	Plot.dot(checkGroupPosition2.flat(),
//d3.group(data.nodes, (d) => d.group )
```





```js echo
weightData
```




```js 
//easy to get min and max to put in the slider.
const minWeight = d3.min(data.links.map(d => d.weight));
const maxWeight = d3.max(data.links.map(d => d.weight))

const weightConnections = view(Inputs.range(
	[minWeight, maxWeight], {
  	label: "Minimum weight",
  	step: 1,
  	value: 1
})
)
```



```js
// think i've got it!
const weightLinks = data.links.filter(l => l.weight >= weightConnections);

const weightNodes = data.nodes.filter((n) =>
    weightLinks.some((l) => l.source === n.id || l.target === n.id)
  );

const weightData = {nodes: weightNodes, links:weightLinks}
```



## Chart


```js
chart2()
```


```js
function chart2() {

  // The force simulation mutates links and nodes, so create a copy
  // so that re-evaluating this cell produces the same result.
  
  let links = []
  let nodes = []
  
  // it feels a bit circular to use filterId and weightData both here and in the filterId input, but seems to work without any trouble.
  
  
  if(filterId === "All"){
     links = weightData.links.map(d => Object.create(d));
     nodes = weightData.nodes.map(d => Object.create(d));
     
  } else {
  
    links = weightData.links.filter(d => d.source == filterId || d.target == filterId).map(d => Object.create(d));
    const otherPersons = links.map(d => d.source !== filterId ? d.source : d.target)
    nodes = weightData.nodes.filter(d => d.id == filterId || otherPersons.indexOf(d.id) >= 0).map(d => Object.create(d));
  }
  


  // Create a simulation with several forces. 
  const simulation = d3.forceSimulation(nodes)
      //.force("charge", d3.forceManyBody()) // why forceManyBody twice?
      .force("link", d3.forceLink(links).id(d => d.id))
      .force("charge", d3.forceManyBody().strength(-620))
      .force("center", d3.forceCenter(0, 0))
      .force("x", d3.forceX())
      .force("y", d3.forceY())
      .force("collide", d3.forceCollide(40))
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
      .attr("stroke-width", d => d.weight); // width of lines ? is this right?


	// circles
  const node = svg.append("g")
      .attr("stroke", "#fff")
      .attr("stroke-width", 1)
      .selectAll("circle")
      .data(nodes)
      .join("circle")
      .attr("r", d => getRadius(d.degree)) // tweak
      .attr("fill", d => color(d.grp_leading_eigen))  
      .style("fill-opacity", 0.6)
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
    .text(function(d) { return d.id })

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
// display and appearance related stuff

const height = 800

// make very big nodes a bit smaller and very small nodes a bit bigger.
// can do final tweaks inside chart code.
// my maths is a bit shaky here, probably need to check this
function getRadius(useCasesCount){
		var	m=useCasesCount/2
		var d=3/useCasesCount
  if(useCasesCount>=9){   
  	var radius = m+d  
    return radius
  }
  return 8
}

// need better colour function really
const color = d3.scaleOrdinal(d3.schemeCategory10);
```







```js
function drag(simulation) {
  function dragstarted(event) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
    event.subject.fx = event.subject.x;
    event.subject.fy = event.subject.y;
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

// data

const data = FileAttachment("../data/l_networks_rai_elections/bn-rai-elections.json").json();

```




## "number of Connections" filter 

(results)


```js 
// range can be fixed or use data, if you can work out how
const maxLinks = 50;

const numberOfConnections = view(Inputs.range(
	[1, maxLinks], {
  	label: "Minimum connections",
  	step: 1,
  	value: 1
})
)
```

```js echo
results
```


```js echo
resnodes
```



length is just telling you how many of *something* there are 

```js echo
results.links.length
```

eg above is the number of rows in the (filtered) links data, nothing to do with the number of links individuals or pairs have.

degree is a person's total number of connections once you sum the weights in bn_election_edges.

`connections` is in resnodes and resultsnodes you dummy. 
it's the number of appearances in bn_election_edges. 

so i think: step 1 resnodes gets nodes that have min n connections; step 2 resultslinks gets the links; step 3 resultsnodes discards any resnodes if *none* of their linked nodes have at least 5 connections (or, both sides in a pair must have min 5 connections to be included). 
that seems kind of... wrong and confusing? it's dropping people who *do* meet the min 5 threshold.

so maybe this isn't quite the measure you want. and actually a weights filter ought to be simpler? but at least now you know what it's doing.




```js
// doesn't seem to be necessary after all. 
const foundData = {
    nodes: data.nodes,
    links: data.links.filter(
      (l) =>
        data.nodes.some((n) => n.id === l.source) &&
        data.nodes.some((n) => n.id === l.target)
    )
}
```





```js

// filtering by min number of connections a node has.
// code based on KDL agents.
// i think: resnodes gets nodes that have min 5 connections; resultslinks gets their links; resultsnodes discards resnodes if none of their linked nodes have at least 5 connections (or, both sides in a pair must have min 5 connections to be shown). 

  let resnodes = data.nodes
    .map((n) => {
      return {
        ...n,
        connections: data.links.filter(
          (l) => l.source === n.id || l.target === n.id
        ).length
      };
    })
    .filter((n) => n.connections >= numberOfConnections); 

  const resultslinks = data.links.filter(
    (l) =>
      resnodes.some((n) => n.id === l.source) &&
      resnodes.some((n) => n.id === l.target)
  );

  const resultsnodes = resnodes
    .map((n) => {
      return {
        ...n,
        connections: resultslinks.filter((l) => l.source === n.id || l.target === n.id)
          .length
      };
    })
    .filter((d) => d.connections > 0);

  const results = { nodes: resultsnodes, links: resultslinks };
```





```js 
// easy....
//const maxDegree = d3.max(foundData.nodes.map(d => d.degree))
```



```js
// isolated nodes with &&. but with || node not found error 
// because it's a bad idea to use a node measure to filter links!
// but it does work.

let filtNodes = foundData.nodes.filter((d) => d.degree>=numberOfConnections);

const filteredLinks = foundData.links.filter(
	(l) =>
		filtNodes.some((n) => n.id===l.source) && // || or && ...
		filtNodes.some((n) => n.id== l.target)
	);
	
const filteredNodes = filtNodes.filter((d) => d.degree >0);

const filteredData = {nodes:filteredNodes, links:filteredLinks}
```




