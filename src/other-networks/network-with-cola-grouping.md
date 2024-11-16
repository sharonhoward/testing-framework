# Network Graph highlight grouping

This network of pattern (of sub-structures) network in a Medical compound dataset is positioned by simulated forces using [d3-force](https://github.com/d3/d3-force) (or [WebCoLa](/@mbostock/hello-cola).)`

hover highlights connections (plus tooltips); click to make it stick; click again outside nodes to reset.
there is also a right-click for context, i think it's working?

it doesn't have any filters.

```js
chart()
```

```js
function chart() {
  const links = data.links.map(d => Object.create(d));
  const nodes = data.nodes.map(d => Object.create(d));
  const [width, height] = [1000, 1000];
  
  // replaced const svg = d3.select(DOM.svg(width, height));
  const svg = d3.create("svg")
    .attr("viewBox", [0, 0, width, height]);

  const aiScoreMinDiff = 0.05;
  
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
  const nodeRadius = d => 15 * d.support;

  const baseGroup = svg.append("g");
  function zoomed() {
    //replaced baseGroup.attr("transform", d3.event.transform); 
    baseGroup.attr("transform", d3.zoomTransform(this));
  }

  const zoom = d3.zoom()
    .scaleExtent([0.2, 8])
    //.translateExtent([[-100, -100], [width + 1000, height + 1000]])
    .on("zoom", zoomed);
  
  svg.call(zoom);
  let ifClicked = false;





  const simulation = d3.forceSimulation()
    .force("link", d3.forceLink().id( function(d) { return d.id; } ).strength(0.3)) 
		.force("charge", d3.forceManyBody())
  	.force("y", d3.forceY(height/2).strength(0.1))
		.force("center", d3.forceCenter(width / 2, height / 2))
    .force("x", d3.forceX(d => {
      if (d.level === 1) {
        return width/7 - 50; // width/5 - 50 - 400;
      }
      return width/7 * d.level; // width/5 * d.group - 400;
    }).strength(0.95))
    .force("collide", d3.forceCollide().radius(d => nodeRadius(d) + 1).iterations(2));
  

 // may not need this baseGroup stuff...?

  const link = baseGroup.append("g")
      .selectAll("line")
      .data(links)
      .join("line")
      .classed('link', true)
      .style('stroke', d => {
        console.log(d.target)
        const aiScoreDiff = nodesById[d.target].aiScore - nodesById[d.source].aiScore;
        
        if (Math.abs(aiScoreDiff) < aiScoreMinDiff) {
          return '#999';
        } else {
          if (aiScoreDiff > 0) {
            return "#84c942"; // inactive -> active
          } else {
            return "#e85335"; // active -> inactive
          }
        }
      })
      .style("stroke-opacity", 0.5);

  const node = baseGroup.append("g")
      .selectAll("circle")
      .data(nodes)
      .join("circle")
      .classed('node', true)
      .attr("r", d => nodeRadius(d))
      .attr("fill", nodeColor);  
  
  
    // edit context menu. can you get rid of this?
    //const rightClickItems = ['Expand sub-network of the pattern', 'Mark the pattern', 'Mark compound population'];
    
    const menuItems = baseGroup.selectAll(".menuitems")
      //.data(rightClickItems)
      //.join('g')
      .classed('menuitems', true)
      .attr('visibility', "hidden")
      .attr('transform', `translate(${0}, ${0})`)
      //.on('click', rightClickActions);

    menuItems.append('rect')
      .attr('x', 0)
      .attr('y', (d,i) => i * 20)
      .attr('width', 180)
      .attr('height', 20);
      
    menuItems.append('text')
      .text(d => d)
      .attr('x', 3)
      .attr('y', (d,i) => 13 + i * 20)
      .style('fill', 'black')
      .style('font-size', '11px');
  
  
  
  
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

  simulation
      .nodes(nodes)
      .on("tick", ticked);

  simulation.force("link")
      .links(links);
  
  const mouseOverFunction = (event, d) => {
    tooltip.style("visibility", "visible")
    .html(() => {
        const content = `<strong>Pattern:</strong> <span>{${d.id.replace(/-/g, ',')}}</span>`+'<br>'
                        +`<strong>aiScore:</strong> <span>${d3.format('.2f')(d.aiScore)}</span>`;

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

  };
  
  const mouseClickFunction = (event, d) => {
    // we don't want the click event bubble up to svg
    event.stopPropagation();
    
    menuItems.attr('visibility', "hidden");

    ifClicked = true;
    
    node
      .transition(500)
      .style('opacity', 1)

    link
      .transition(500);
 
    node
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
  
  
  const rightClickActions = (d, menuItem, i) => {
    // d is the clicked node, i is the menuItem index
    console.log(d.id, menuItem, i)
    
    // Expand sub-network of the patter
    if (i === 0) {
      // sending d.id (pattern) to backend to get sub-network
    };
    
    menuItems.attr('visibility', "hidden");
  };
  
  
  const rightClickFunction = (event, d) => {
    event.preventDefault();
    
    // add clicked effect: highlight right-clicked item
    ifClicked = true;
    
    node
      .transition(500)
      .style('opacity', 1)

    link
      .transition(500);
 
    node
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

    tooltip.style("visibility", "hidden");

    const position = {x: d.x, y: d.y};

    menuItems.attr('visibility', "visible")
      .attr('transform', `translate(${position.x}, ${position.y})`)
      .on('click', (menuItem, i) => rightClickActions(d, menuItem, i));
  };
  

  
  
  node.on('mouseover', mouseOverFunction)
      .on('mouseout', mouseOutFunction)
      .on('click', mouseClickFunction)
      .on('contextmenu', rightClickFunction)
      .on('mousemove', (event) => tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px"));
  
  svg.on('click', () => {
    ifClicked = false;
    node
      .transition(500)
      .style('opacity', 1);

    link
      .transition(500)
      .style("stroke-opacity", 0.5)
    
    menuItems.attr('visibility', "hidden");
  });

  //invalidation.then(() => layout.stop());

  return svg.node();
}
```
end of chart code

```js
const tooltip = d3.select("body").append("div")
  .attr("class", "svg-tooltip")
    .style("position", "absolute")
    .style("visibility", "hidden")
    .text("I'm a circle!");
```

```js
// filter by: support > 0.4
const data = d3.json("https://gist.githubusercontent.com/ravengao/a548cc4a7dd38f1afe0fe4b31ba8901b/raw/fd86a4e94e31ca2497ee78e1006dbed798f62e67/sample_data_supp%253E0.4_new.json")
// data = d3.json("https://gist.githubusercontent.com/ravengao/5b65551b7a0199e01380ddc1b13248a0/raw/d31bd24ef9286cb5a6eb4520f99f6a3c6b68c330/sample_v2.json")

// filter by: support > 0.3
//data = d3.json("https://gist.githubusercontent.com/ravengao/3a6deb4f4add94eb485b570d04128c81/raw/02b60190a410f2143ccdc13c24b614073bb592a7/sample_v2%253E0.3.json")
```

```js
data
```

```js
const height = 600
```

```js
// calculate node color with aiScore, in a range of (0.3, 0.6)
//nodeColor = {
 const nodescale = d3.scaleLinear().domain([0.3, 0.6]).range([0, 1]);
 const nodeColor = d => d3.interpolateRdYlGn(nodescale(d.aiScore || 0));
//}

```


```js
function drag(simulation)  {
  
  function dragstarted(event, d) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  }
  
  function dragged(event, d) {
    d.fx = event.x;
    d.fy = event.y;
  }
  
  function dragended(event, d) {
    if (!event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }
  
  return d3.drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended);
}
```

needed various changes from d3 v5, mainly to do with d3.event/event.
it's important to refresh the page manually when making changes, not just rely on the dev refresh...


fixed... i think:
- zoom/drag 
- click to highlight connections. 
- hover to highlight connections.
- tooltips.

resources
- https://observablehq.com/@d3/d3v6-migration-guide
- drag queens chart which has used/adapted a lot of the code

```js
//d3 = require("d3@5")
//import * as d3 from "npm:d3@5";
```



```js
//i don't think this is essential. the only call to cola is commented out.
//cola = require("webcola@3/WebCola/cola.min.js")
```

```js 
html
`<style>         
    .node {
        stroke: #fff;
        stroke-width: 0px;
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
      font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple   Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
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

    .svg-contextmenu {
      font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple   Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
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
    }

    .menuitems rect {
      fill: white;
    }

    .menuitems:hover rect { 
      fill: gray;
    }

    .menuitems:hover text { 
      cursor: default;
    }

    svg {
        background-color: #333;
    }
</style>`
```
