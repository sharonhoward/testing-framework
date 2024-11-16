---
theme: dashboard
title: RAI elections
toc: false
---


```js
data
```

## Overview

- zoom, drag, etc
- size of node reflects level of connectedness
- width of edges reflects number of links between the pair
- colour for auto-detected clusters
- hover over a node to temporarily highlight its network
- click on node to fix highlighting
- click outside nodes to reset

hover and click can be a bit temperamental, especially with small nodes/dense bits of the network, but they do work correctly in this version!

an interesting thing to look for (here and in filtered version below) is individuals who are connected to several different colour nodes: it may suggest they're good "bridges" between groups in the network.

```js
chart1()
```




## examine individual networks

Select names from the dropdown to see their personal networks.


```js 
//filter method  //https://observablehq.com/@asgersp/d3-force-directed-graph-with-input
//
const filterId = view(
		Inputs.select(
				//["All"].concat(data.nodes.map(d => d.id)),
				data.nodes.map((d) => d.id ),
				{
				label: "node", 
				//sort: true, 
				unique: true, 
				}
				)
		)
```


```js
chart2()
```





```js

const height = 800

function chart1() {


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
		
		// avoid (or reduce) overlap. may need tweaking
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
      .attr("stroke-width", d => d.value) ;
          
      
  

  const node = baseGroup.append("g")
      .selectAll("circle")
      .data(nodes)
      .join("circle")
      .classed('node', true)
      .attr("r", d => getRadius(d.degree)) // can tweak this
      .attr("fill", d => color(d.grp_leading_eigen))  
      .style("fill-opacity", 0.6)  
      .call(drag(simulation)); // this is what was missing for drag...
       


    
  // text labels 
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
        console.log(o.value)
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




```js

function chart2() {

  // The force simulation mutates links and nodes, so create a copy
  // so that re-evaluating this cell produces the same result.
  
  let links = []
  let nodes = []
  
//  if(filterId === "All"){
//     links = data.links.map(d => Object.create(d));
//     nodes = data.nodes.map(d => Object.create(d));
     
//  } else {
  
    links = data.links.filter(d => d.source == filterId || d.target == filterId).map(d => Object.create(d));
    const otherPersons = links.map(d => d.source !== filterId ? d.source : d.target)
    nodes = data.nodes.filter(d => d.id == filterId || otherPersons.indexOf(d.id) >= 0).map(d => Object.create(d));
//  }
  
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
      .attr("stroke-width", d => d.weight); // width of lines


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
// helper function for drag interaction. for dragging nodes.
// i think it's the same as drag().
/*function drag2(simulation) {

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
*/
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










```js
// data
const data = FileAttachment("../data/l_networks_rai_elections/bn-rai-elections.json").json();

```


