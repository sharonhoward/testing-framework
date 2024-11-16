---
theme: dashboard
title: marvel network
---

# Marvel Network

chart is working but with undefined message. filters working.

d3 v4 so might not automatically translate 

```js
dropdown()
```

```js
slider()
```

```js
//function chart() {
  
const svg = d3.create("svg")
    .attr("viewBox", [0, 0, width, height]);

svg.append('rect')
  .attr('width', '100%')
  .attr('height', '100%')
  .attr('fill', 'white')
  .on('click', function() {
    // Restore nodes and links to normal opacity.
    d3.selectAll('.link').style('stroke-opacity', '0.6');
    d3.selectAll('.node').style('opacity', '1');
});
  
var container = svg.append('g');
  
// Call zoom for svg container.
svg.call(zoom(container));

var link = container.append("g")
    .attr("class", "links")
  .selectAll("line");
  
var node = container.append("g")
    .attr("class", "nodes")
  .selectAll("circle");

// this is a bit different
// Make object of all neighboring nodes.
var linkedByIndex = {};
json.links.forEach(function(d) {
  linkedByIndex[d.source.index + ',' + d.target.index] = 1;
  linkedByIndex[d.target.index + ',' + d.source.index] = 1;
});

// A function to test if two nodes are neighboring.
function neighboring(a, b) {
  return linkedByIndex[a.source.index + ',' + b.source.index];
}

const updated = Object.assign(svg.node(), {

  update(nodes,links) {

      link = link.data(links, function(d) { return d.source.index + ", " + d.target.index;});
    
      link.exit().remove();
    
      var linkEnter = link.enter().append("line")
        .attr('class', 'link')
        .attr('stroke', 'gray');
    
      link = linkEnter.merge(link);

      node = node.data(nodes);
    
      node.exit().remove();
    
      var nodeEnter = node.enter().append("circle")
        // Use degree centrality from NetworkX in json.
        .attr('r', function(d, i) { return degreeSize(d.degree); })
        // Color by group, a result of modularity calculation in NetworkX.
        .attr("fill", function(d) { return color(d.group); })
        .attr('class', 'node')
        // On click, toggle ego networks for the selected node.
        .on('click', function(d, i) {
            // Ternary operator restyles links and nodes if they are adjacent.
            d3.selectAll('.link').style('stroke-opacity', function (l) {
              return l.target == d || l.source == d ? 1 : 0.1;
            });
            d3.selectAll('.node').style('opacity', function (n) {
              return neighboring(d, n) ? 1 : 0.1;
            });
            d3.select(this).style('opacity', 1);
        })
        .call(drag(simulation));
      
      node = nodeEnter.merge(node);
    
      node.append("title")
          .text(function(d) { return d.name; });

      simulation
          .nodes(nodes)
          .on("tick", ticked);

      simulation.force("link")
          .links(links);
    
      simulation.alpha(1).restart();

      function ticked() {
        link
            .attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });

        node
            .attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; });
      }
    }
  });
  
  const chart = display(updated);
//}
```

```js
  	// A slider (using only d3 and HTML5) that removes nodes below the input threshold.
function slider() {

  let min = d3.min(json.links, function(d) {return d.weight; });
  let max = d3.max(json.links, function(d) {return d.weight; })
  let slider = html`
    <label for="threshold">Edge Weight Threshold: ${min}</label>
    <input type="range" min="${min}" max="${max}" style="width:75%;"></input>`;
  let label = slider.querySelector('label');
  let range = slider.querySelector('input');
  range.value = min
  range.oninput = () => {
    let threshold = range.valueAsNumber
    label.innerHTML = `Edge Weight Threshold: ${threshold}`
    let newLinks = json.links.filter(l => l.weight > threshold);
    chart.update(json.nodes,newLinks);
  };
  return slider;
}
```

```js
	// A dropdown menu with three different centrality measures, calculated in NetworkX.

function dropdown() {
  let dropdown = html`
    <label for="centrality">Size Nodes By:</label>
    <select>
      <option value="degree">Degree Centrality</option>
      <option value="betweenness">Betweenness Centrality</option>
      <option value="eigenvector">Eigenvector Centrality</option>
    </select>`;
  let select = dropdown.querySelector('select');
  let label = dropdown.querySelector('label');
  dropdown.onchange = () => {
    var centrality = select.value;
    var centralitySize = d3.scaleLinear()
      .domain([d3.min(json.nodes, function(d) { return d[centrality]; }), d3.max(json.nodes, function(d) { return d[centrality]; })])
      .range([8,25]);
    d3.selectAll(".node").attr("r", d => centralitySize(d[centrality]));
  }
  return dropdown;
}
```


```js
// Create form for search (see function below).
function search() {
  let search = html`
      <label for='searchBox'>Search by name:</label>
      <input name='searchBox' type='text' placeholder='Type to search...' />`;
  let label = search.querySelector('label');
  let input = search.querySelector('input');
  search.onkeyup = () => {
    var term = input.value;
    var selected = d3.selectAll('.node').filter(function (d, i) {
      return d.name.toLowerCase().search(term.toLowerCase()) == -1;
    });
    selected.style('opacity', '0');
    d3.selectAll('.link').attr('stroke-opacity', '0');
    d3.selectAll('.node').transition()
      .duration(5000)
      .style('opacity', '1');
    d3.selectAll('.link').transition().duration(5000).style('stroke-opacity', '0.6');
  }
  return search
}
```

A demonstration of network code in JavaScript, from JSON to interactive diagram.

The code below is a step-by-step walkthrough for creating a force-directed network graph using D3. There are a lot of good tutorials out there already, but they don't always include the tools that most folks would like to have in an interactive network out-of-the-box, e.g clicking nodes to see neighborhoods, filtering edges by weight, searching nodes by name, resizing nodes by centrality, etc.

This code includes a lot of those bells and whistles, using a fun dataset from Marvel Comics.

**n.b. This demonstration is written in D3v4, and there are number of differences between version 4 and later versions of D3. While the same general principles still apply, this exact code is unlikely to work in later versions without modification.**

*Click the panels at the left to expose the JS code for any of the tools that you see.*
  
## Filtering, Resizing, Searching

The graph above is both zoomable and clickable. Clicking on a node will show that node and its neighbors. Mousing over a node will show the character's name as title text. 

But we can also filter the network by edge weight. The slider above eliminates edges if they have weights below the threshold---in this case that means if a character appears fewer than X times with any other character, then that edge will disappear from the graph. As the slider goes up, you'll see a network that connects just the most frequently co-occurring characters.

You can also resize nodes according to three different centrality values. The default is degree, but you can also use betweenness and eigenvector centrality.

Finally, so you can find specific characters more easily, there's a search box where you can simply type a character's name. Trying searching for "Scarlet Witch." (Keep in mind: some characters appear more than once in the network, because the same character can exist in different continuities.

## Creating the Graph

In order to get the graph displayed above, there are some basic variables and functions we need to add. The first is just an integer that defines the height of the SVG:

```js
const height=600;
```

Next we create a simulation, which defines the forces in our "force-directed" graph. This tells us how far apart nodes should be and how the graph should be centered, and it prevents nodes from overlapping.

```js
// almost the same
const simulation = d3
		.forceSimulation()
		// possibly d.id rather than d.index ?
    .force("link", d3.forceLink().id(function(d) { return d.index; }))
    .force("charge", d3.forceManyBody().strength([-250]).distanceMax([500]))
    .force("center", d3.forceCenter(width / 2, height / 2))
    .force("collide", d3.forceCollide().radius( function (d) { return degreeSize(d.degree); }));
```

D3 also lets us define scales to govern the color and size of our nodes. We'll create an ordinal scale for color and a linear scale for size. The size scale is based on degree, but that scale gets replaced with new ones in the code for the centrality dropdown, above.

```js
const color = d3.scaleOrdinal(d3.schemeCategory20);
```


```js
// this should be ok in current d3
// Linear scale for degree centrality.
const degreeSize = d3
	.scaleLinear()
  .domain([d3.min(json.nodes, function(d) {
  	return d.degree; 
  }),
  d3.max(json.nodes, function(d) {
  	return d.degree; 
  })
])
  .range([8,25]);
```

To make our graph even more interactive, we want to be able to zoom the SVG and drag around individual nodes. We can define drag and zoom functions to do that. These functions are both called in the main chart code, above.

```js
// should be fine in current d3
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

```js
// slight changes, replaced.
function zoom (container) {
  function zoomed(event, d) {
      container.attr("transform", "translate(" + event.transform.x + ", " + event.transform.y + ") scale(" + event.transform.k + ")");
  }
  
  return d3.zoom().on('zoom', zoomed)
}
/*
function zoom(container) {
  // Zooming function translates the size of the svg container.
  function zoomed() {
      container.attr("transform", "translate(" + d3.event.transform.x + ", " + d3.event.transform.y + ") scale(" + d3.event.transform.k + ")");
  }
  
  return d3.zoom().scaleExtent([0.5,3]).on('zoom', zoomed)
}*/

```

Finally, we load the data in from a JSON file and update the chart!

```js echo
const json = FileAttachment("../data/marvel.json").json();
```



```js 
chart.update(json.nodes,json.links)
```

what breaks if you turn off v4? idk.

```js 
import * as d3 from "npm:d3@4";
//const d3 = require("d3@4")
```
