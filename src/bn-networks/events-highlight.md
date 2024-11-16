---
theme: dashboard
title: "events networks: highlight labels etc"
---

based on [Network Graph with d3.force grouping](https://observablehq.com/@ravengao/force-directed-graph-with-cola-grouping)

hover highlights connections (plus tooltips); click to make it stick; click again outside nodes to reset.

saved working version without inputs to v4-networks. so let's play around

inputs I want:

1. select name to highlight (not seen this in d3, but r visnetwork does it (not v well though))
2. radio button to choose between centrality measures/cluster algorithms
	- centrality measures to change size of node
	- clustering change colour of node
3. checkbox to filter groups of things in and out 


```js 
// have this working with d3.filter in v3 networks, but that's not what i want here
/*const filterId = view(
		Inputs.select(
				["All"].concat(data.nodes.map(d => d.id)),
				{
				label: "node", 
				//sort: true, 
				unique: true, 
				}
				)
		)*/
```

 

```js
// working with centralityMeasure function, but getting sizing right is tricky.
/*
	const pickCentrality = view(
		Inputs.radio(
			["degree", "betweenness"],
			{label: "Centrality measure", value: "degree"}
		)
	)
	*/
```


not sure about this after all that...

```js
const pickCluster = view(
		Inputs.radio(
			["edge betweenness", "infomap", "leading eigenvector"],
			{label: "Clustering method", value: "edge betweenness"}
		)
	)
```




```js 
//a) map position_label and unique:true 
/*const nodePick = view(
		Inputs.radio(
				data.nodes.map(d => d.group),
				{
				label: "group", 
				value: "group1", // [no square brackets]
				sort: true, 
				unique: true
				}
		)
)
*/
```


```js 
//b) use it to make the new filter data array
/*const data_radio_one =
data.nodes
  .filter((d) => d.group === nodePick)
  .map((d) => ({...d}) )
*/
```

```js 
//c) and then use data_filter in the table
/*
Inputs.table(data_radio_one, {
	layout: "auto",
  columns: [
    "id",
    "person",
    "group",
    "degree",
    "betweenness"
  ], 
  header: {
    id: "name",
    person: "id",
    group: "group",
    degree: "degree",
    betweenness: "btwn"
  }
})
*/
```



```js
data
```


```js
chart()
```


```js
const height = 800


// working! but resizing is tricky.  
/*function centralityMeasure(m) {
  if (pickCentrality === "degree") {
				return d => getRadius(d.degree)
      } else if (pickCentrality === "betweenness") {
      	return d => getRadius(d.betweenness)
      } else {
  			return d => getRadius(d.degree)
      }
  	}	
*/

/**/
function clustering(m) {
  if (pickCluster === "edge betweenness") {
				return d => color(d.grp_edge_btwn)
      } else if (pickCluster === "infomap") {
      	return d => color(d.grp_infomap)
      } else {
  			return d => color(d.grp_leading_eigen)
      }
  	}	


function chart() {
  const links = data.links.map(d => Object.create(d));
  const nodes = data.nodes.map(d => Object.create(d));
  
    // Create the SVG container.
    
 /* const svg = d3.create("svg")
    //.attr("viewBox", [0, 0, width, height]); // or
     .attr("viewBox", [-width / 2, -height / 2, width, height]); // with simulation forceCenter(0,0) */
  
  const svg = d3.create("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", [-width / 2, -height / 2, width, height])
      .attr("style", "max-width: 100%; height: auto;");
  
  
  // create link reference
  let linkedByIndex = {};
  data.links.forEach(d => {
    linkedByIndex[`${d.source},${d.target}`] = true;
  });
  
  // nodes map
  let nodesById = {};
  data.nodes.forEach(d => {
    nodesById[d.id] = {...d};
  })

  const isConnectedAsSource = (a, b) => linkedByIndex[`${a},${b}`];
  const isConnectedAsTarget = (a, b) => linkedByIndex[`${b},${a}`];
  const isConnected = (a, b) => isConnectedAsTarget(a, b) || isConnectedAsSource(a, b) || a === b;
  const isEqual = (a, b) => a === b;
  // todo?
  //const nodeRadius = d => 15 * d.support;



// not quite sure what the significance of baseGroup is...
  const baseGroup = svg.append("g");
  
  function zoomed() {
    baseGroup.attr("transform", d3.zoomTransform(this));
  }

  const zoom = d3.zoom()
    .scaleExtent([0.2, 8])
    .on("zoom", zoomed);
  
  svg.call(zoom);
  
  let ifClicked = false;

// overlap/collide etd: check https://observablehq.com/@d3/collision-detection/2?collection=@d3/d3-force 
// https://observablehq.com/@d3/forcecenter-strength?collection=@d3/d3-force
// https://observablehq.com/@d3/clustered-bubbles?collection=@d3/d3-force

// .force("link", d3.forceLink(links).id(d => d.id).distance(30).strength(0.25))

  const simulation = d3.forceSimulation()
    .force("link", d3.forceLink().id( function(d) { return d.id; } ).strength(0.3)) 
		.force("charge", d3.forceManyBody().strength(-300) ) //
		//.force("center", d3.forceCenter(0,0))
		
		// avoid (or reduce) overlap. seems i really have to turn up the addition to getRadius(d), much higher than examples.
		.force("collide", d3.forceCollide().radius(d => getRadius(d) + 20).iterations(2))  

		 // .force("x", d3.forceX().strength(0.001)) // hmm.
     // .force("y", d3.forceY().strength(0.001)) ;
     
      .force("x", d3.forceX())
      .force("y", d3.forceY());
		

  const link = baseGroup.append("g")
      .selectAll("line")
      .data(links)
      .join("line")
      //.classed('link', true) // aha now width works.
      .attr("stroke", "#bdbdbd") 
      .attr("stroke-opacity", 0.4) // is this working? works with attr instead of style
      .attr("stroke-width", d => d.weight) ;
          
      
  

  const node = baseGroup.append("g")
      .selectAll("circle")
      .data(nodes)
      .join("circle")
      .classed('node', true)
      // pick between measures 
//		//.attr("r", centralityMeasure(d => d)) // works! but need better sizing for different measures. also, colours change 
      .attr("r", d => getRadius(d.degree)) 
      //.attr("fill", d => color(d.grp_leading_eigen))  
      // pick clusters
      .attr("fill", clustering(d => d)) // changing color again.
      .style("fill-opacity", 0.6)  
      .call(drag(simulation)); // this is what was missing for drag...
       


    
  // text labels - i think working correctly. a bit temperamental when nodes overlap and/or small?
  // stuff has to be added in several places after this to match node and link.
 
 	const text = baseGroup.append("g")
    //.attr("class", "labels")
    .selectAll("text")
    .data(nodes)
    .join("text")
    .attr("dx", d => d.x)
    .attr("dy", d => d.y)
    
    .attr("opacity", 0.8)
    .attr("font-family", "Arial")
    .style("font-size","13px")
    .text(function(d) { return d.id })
    .call(drag(simulation));
     
  
  function ticked() {
    link
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

    node
        .attr("cx", function(d) { return d.x; })
        .attr("cy", function(d) { return d.y; });    
    
    text 
        .attr("dx", d => d.x)
        .attr("dy", d => d.y);
        
  }


  simulation
      .nodes(nodes)
      .on("tick", ticked);

  simulation.force("link")
      .links(links);
  
  
  const mouseOverFunction = (event, d) => {
    tooltip.style("visibility", "visible")
    .html(() => {
        const content = `<span>${d.id}</span>`;
        return content;
      });

    if (ifClicked) return;

    node
      .transition(500)
        .style('opacity', o => {
          const isConnectedValue = isConnected(o.id, d.id);
          if (isConnectedValue) {
            return 1.0;
          }
          return 0.1;
        });

    link
      .transition(500)
        .style('stroke-opacity', o => {
        console.log(o.source === d)
      return (o.source === d || o.target === d ? 1 : 0.1)})
        .transition(500)
        .attr('marker-end', o => (o.source === d || o.target === d ? 'url(#arrowhead)' : 'url()'));
        
    text
      .transition(500)
        .style('opacity', o => {
          const isConnectedValue = isConnected(o.id, d.id);
          if (isConnectedValue) {
            return 1.0;
          }
          return 0.1;
        });
        
  };

  const mouseOutFunction = (event, d) => {
  
    tooltip.style("visibility", "hidden");

    if (ifClicked) return;

    node
      .transition(500)
      .style('opacity', 1);

    link
      .transition(500)
      .style("stroke-opacity", o => {
        console.log(o.weight)
      });

	 	text
      .transition(500)
      .style('opacity', 1);




  };
  
  
  const mouseClickFunction = (event, d) => {
  
    // we don't want the click event bubble up to svg
    event.stopPropagation();
    
    ifClicked = true;
    
    node
      .transition(500)
      .style('opacity', 1)

    link
      .transition(500);
      
    text
      .transition(500)
      .style('opacity', 1)
 
 
    node
      .transition(500)
        .style('opacity', o => {
          const isConnectedValue = isConnected(o.id, d.id);
          if (isConnectedValue) {
            return 1.0;
          }
          return 0.1
        })

    text
      .transition(500)
        .style('opacity', o => {
          const isConnectedValue = isConnected(o.id, d.id);
          if (isConnectedValue) {
            return 1.0;
          }
          return 0.1
        })


    link
      .transition(500)
        .style('stroke-opacity', o => (o.source === d || o.target === d ? 1 : 0.1))
        .transition(500)
        .attr('marker-end', o => (o.source === d || o.target === d ? 'url(#arrowhead)' : 'url()'));
        
  };
  
  
  node.on('mouseover', mouseOverFunction)
      .on('mouseout', mouseOutFunction)
      .on('click', mouseClickFunction)
      .on('mousemove', (event) => tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px"));
  
  svg.on('click', () => {
    ifClicked = false;
    node
      .transition(500)
      .style('opacity', 1);

    link
      .transition(500)
      .style("stroke-opacity", 0.5)

    text
      .transition(500)
      .style('opacity', 1);
    
    
  });

  invalidation.then(() => simulation.stop());

  return svg.node();
}

```

end of chart code




```js
data
```



```js
// data
// events data. 
const data = FileAttachment("../data/l_networks/bn-events.json").json();

```


getRadius function 

this needs some work... not sure hwat happens with measures that are <1. lol they're kind of ok, it's the big numbers that are the problem.


```js echo

// works less well with degree than with n_event...
function getRadius(useCasesCount){
		var	m=useCasesCount/1.5
		var d=3/useCasesCount
  if(useCasesCount>=9){   
  	var radius = m+d  
    return radius
  }
  return 8
}


const color = d3.scaleOrdinal(d3.schemeCategory10);
```



```js
const tooltip = d3.select("body").append("div")
  .attr("class", "svg-tooltip")
    .style("position", "absolute")
    .style("visibility", "hidden")
    .text("I'm a circle!");
```




```js
function drag(simulation) {
  function dragstarted(event) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
//    d.fx = d.x;  doesn't work
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

groups

  grp_edge_b: "9"
  grp_infomap: "5"
  grp_leading_e: "1"
  grp_louvain

"edge betweenness"
"infomap"
"leading eigenvector"


group_edge_betweenness(): Group densely connected nodes using igraph::cluster_edge_betweenness()
  Community structure detection based on the betweenness of the edges in the network. This method is also known as the Girvan-Newman algorithm.
  The idea behind this method is that the betweenness of the edges connecting two communities is typically high, as many of the shortest paths between vertices in separate communities pass through them. The algorithm successively removes edges with the highest betweenness, recalculating betweenness values after each removal. This way eventually the network splits into two components, then one of these components splits again, and so on, until all edges are removed. The resulting hierarhical partitioning of the vertices can be encoded as a dendrogram.

group_infomap(): Group nodes by minimizing description length using igraph::cluster_infomap()
  Find community structure that minimizes the expected description length of a random walker trajectory. 

group_leading_eigen(): Group nodes based on the leading eigenvector of the modularity matrix using igraph::cluster_leading_eigen()
  This function tries to find densely connected subgraphs in a graph by calculating the leading non-negative eigenvector of the modularity matrix of the graph.

The leading eigenvector method works by calculating the eigenvector of the modularity matrix for the largest positive eigenvalue and then separating vertices into two community based on the sign of the corresponding element in the eigenvector. If all elements in the eigenvector are of the same sign that means that the network has no underlying comuunity structure. 

group_louvain(): Group nodes by multilevel optimisation of modularity using igraph::cluster_louvain()
  This function implements the multi-level modularity optimization algorithm for finding community structure, see references below. It is based on the modularity measure and a hierarchical approach.
  
It is based on the modularity measure and a hierarchical approach. Initially, each vertex is assigned to a community on its own. In every step, vertices are re-assigned to communities in a local, greedy way: each vertex is moved to the community with which it achieves the highest contribution to modularity. When no vertices can be reassigned, each community is considered a vertex on its own, and the process starts again with the merged communities. The process stops when there is only a single vertex left or when the modularity cannot be increased any more in a step. Since igraph 1.3, vertices are processed in a random order.



Changes etc
-------
various changes from d3 v5, mainly to do with d3.event/event.
it's important to refresh the page manually when making changes, not just rely on the dev refresh...

converting to use your data...

- zoom and drag working
- nodes drag fixed
- click to highlight connections working
- hover to highlight connections working
- tooltips working; got rid of right click tips
- added visible labels


resources
- https://observablehq.com/@d3/d3v6-migration-guide
- drag queens chart which has used/adapted a lot of the code


for reference

radio button for categories, 
to start with All selected... you won't want that to choose between different things.


```js
//a)
const nodesPickAllCategory = view(
		Inputs.radio(
				["All"].concat(data.nodes.map(d => d.group)),
				{
				label: "group type", 
				value: "All", // [no square brackets]
				sort: true, 
				unique: true
				}
		)
)
```


```js
//b) 
const data_all_radio =
data.nodes
  .filter((d) =>  nodesPickAllCategory === "All" ||  d.group === nodesPickAllCategory)
  .map((d) => ({...d}) )

```



```js 
//c) and then use data_filter in the table
Inputs.table(data_all_radio, {
	layout: "auto",
  columns: [
    "id",
    "person",
    "group",
    "degree",
    "betweenness"
  ], 
  header: {
    id: "name",
    person: "id",
    group: "group",
    degree: "degree",
    betweenness: "btwn"
  }
})

```





```js 
html
`<style>         
    .node {
        stroke: #f0f0f0;
        stroke-width: 1px;
    }

    .link {
        stroke: #999;
        stroke-opacity: .4;
        stroke-width: 0.5;
    }

    .group {
        stroke: #fff;
        stroke-width: 1.5px;
        fill: #fff;
        opacity: 0.05;
    }
    .svg-tooltip {
     // font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple   Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
      background: rgba(69,77,93,.9);
      border-radius: .1rem;
      color: #fff;
      display: block;
      font-size: 12px;
      max-width: 320px;
      padding: .2rem .4rem;
      position: absolute;
      text-overflow: ellipsis;
      white-space: pre;
      z-index: 300;
      visibility: hidden;
    }

    svg {
       // background-color: #333;
    }
</style>`
```
