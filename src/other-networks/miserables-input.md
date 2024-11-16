# miserables filter Input.select 

This network of character co-occurence in _Les Misérables_ is positioned by simulated forces using [d3-force](https://github.com/d3/d3-force). See also a [disconnected graph](/@mbostock/disjoint-force-directed-graph), and compare to [WebCoLa](/@mbostock/hello-cola).




```js 
const filterId = view(
		Inputs.select(
				["All"].concat(data.nodes.map(d => d.id)),
				//d3.group(data.nodes, (d) => d.id ),
				{
				label: "node", 
				sort: true, 
				unique: true, 
				}
				)
		)
```



```js 
const data_select =
data.nodes
  .filter((d) => filterId === "All" || d.id === filterId)
  .map((d) => ({...d}) )
```


```js
data_select
```


```js
chart()
```

```js echo
function chart() {
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
  
  const simulation = d3.forceSimulation(nodes)
        .force("charge", d3.forceManyBody()) // why forceManyBody twice?
      .force("link", d3.forceLink(links).id(d => d.id))
      .force("charge", d3.forceManyBody().strength(-320))
      .force("center", d3.forceCenter(0, 0))
      .force("x", d3.forceX())
      .force("y", d3.forceY());
      
 //     .force("link", d3.forceLink(links).id(d => d.id))
 //     .force("charge", d3.forceManyBody())
 //     .force("center", d3.forceCenter(width / 2, height / 2));

  //const svg = d3.select(DOM.svg(width, height))
  
  // Create the SVG container. 
  const svg = d3.create("svg")
      .attr("viewBox", [-width / 2, -height / 2, width, height]);
 //   .style('max-width', '100%')
 //   .style('max-height', '100%');

  const link = svg.append("g")
      .attr("stroke", "#999")
      .attr("stroke-opacity", 0.6)
    .selectAll("line")
    .data(links)
    .enter().append("line")
      .attr("stroke-width", d => Math.sqrt(d.value));

  const node = svg.append("g")
      .attr("stroke", "#fff")
      .attr("stroke-width", 1.5)
    .selectAll("circle")
    .data(nodes)
    .enter().append("circle")
      .attr("r", d => d.value)
      .attr("fill", color)
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
  });

  invalidation.then(() => simulation.stop());

  return svg.node();
}
```

```js echo
filterId
```

```js echo
const data = d3.json("https://gist.githubusercontent.com/AsgerSP/557c583727b52624f724536bed5eeb5d/raw/278b359d2f4877b99a4d6d70297b08ab4ef348d1/lesmis1.json")
```

```js echo
const height = 500
```

```js echo
//const width = 800
```

```js echo
//color = {
  const colorscale = d3.scaleOrdinal(d3.schemeCategory10);
  const color = d => colorscale(d.group);
  //return d => scale(d.group);
//}
```

```js echo
function drag(simulation) {
  
  function dragstarted(d) {
    if (!d3.event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  }
  
  function dragged(d) {
    d.fx = d3.event.x;
    d.fy = d3.event.y;
  }
  
  function dragended(d) {
    if (!d3.event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }
  
  return d3.drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended);
}
```


```js echo
//d3 = require("d3@5")
import * as d3 from "npm:d3@6";
```
