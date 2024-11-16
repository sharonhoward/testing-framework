# Drag Queens: Netwerk Diagram

I modified code from [**Guillermo Garcia's notebook**](https://observablehq.com/@garciaguillermoa/force-directed-graph) and [**Raven Gao's notebook**](https://observablehq.com/@ravengao/force-directed-graph-with-cola-grouping) to experiment with network diagrams. Network diagram shows drag queens who were featured on different franchises and seasons of the TV reality competition series, **RuPaul's Drag Race**. 

Major shout out to [**John Guerra**](https://observablehq.com/@john-guerra) for adding in edits to make this 100x cooler. John added in inputs to make the network diagram dynamic (Collide, Radial Force Strength, and Height) and easier to navigate. Thank you John!

```js
const collide = view(Inputs.toggle({ label: "Collide", value: true }))
```

```js
const useRadial = view(Inputs.toggle({ label: "Use Radial Force", value: false }))
```

```js
const radialForce = view(Inputs.range([0.01, 0.9], {
  step: 0.01,
  value: this?.value || 0.07,
  label: "Radial Force Strength",
  disabled: !useRadial
}))
```

```js
const height = view(Inputs.range([10, 1200], {label: "Height", value: 700, step:1}))
```

```js
chart()
```

```js
data
```

```js
function chart() {

  const strokeColor = "black";
  const highlightStroke = "pink";
  const imgLength = 24;
  const imgWidth = 24;
  const radius = 13;
  
  const width = 800;
  
  // const links = data.links.map(d => Object.create(d));
  // const nodes = data.nodes.map(d => Object.create(d));
  
  const links = data.links; // Reuse the same nodes to have the animation work when changing the inputs
  const nodes = data.nodes;


  const simulation = d3.forceSimulation(nodes)
      .alpha(1)
      .force("link", d3.forceLink(links).id(d => d.id).distance(30).strength(0.25))
      .force("charge", d3.forceManyBody())
      .force("collide", collide ? d3.forceCollide(11).iterations(4): null)
      .force(
        "position",
        useRadial ? 
          d3
            .forceRadial(
              (d) => (d.id.includes("Drag Race") ? width*0.01 : width * 0.5),
              width / 2,
              height / 2
            )
            .strength(radialForce)
        : null 
         
        )
      .force("x", d3.forceX(width/2))
      .force("y", d3.forceY(height/2).strength(0.1*width/height))
    // .force("center", d3.forceCenter(width / 2, height / 2));

  const svg = d3.create("svg")
      .style("overflow", "visible")
      .attr("viewBox", [0, 0, width, height]);


  const tooltip = d3.select("body").append("div")
  .attr("class", "toolTip")
    .style("position", "absolute")
    .style("visibility", "hidden")
    .text("Placeholder");

  //link connections taken straight from Raven Gao: https://observablehq.com/@ravengao/force-directed-graph-with-cola-grouping -------
  
  // create link reference
  let linkedByIndex = {};
  data.links.forEach(d => {
    linkedByIndex[`${d.source.id},${d.target.id}`] = true;
  });
  
  // nodes map
  let nodesById = {};
  data.nodes.forEach(d => {
    nodesById[d.id] = {...d};
  })

  const isConnectedAsSource = (a, b) => linkedByIndex[`${a},${b}`];
  const isConnectedAsTarget = (a, b) => linkedByIndex[`${b},${a}`];
  const isConnected = (a, b) => isConnectedAsTarget(a, b) || isConnectedAsSource(a, b) || a === b;

  //mouse over and mouse out functions adapted from Raven Gao: https://observablehq.com/@ravengao/force-directed-graph-with-cola-grouping -------

  const nodeMouseOver = (d, links) => {
    tooltip.style("visibility", "visible")
      .html(createTooltipText(links, d.id));

     node
      .transition(500)
        .style('opacity', o => {
          console.log("o", o, d);
          const isConnectedValue = isConnected(o.id, d.id);
          if (isConnectedValue) {
            return 1.0;
          }
          return 0.1;
        });

    link
      .transition(500)
        .style('stroke-opacity', o => {
          console.log(o.source.id === d.id)
          return (o.source.id === d.id || o.target.id === d.id ? 1 : 0.1)
        })
        .transition(500)
        .attr('marker-end', o => (o.source.id === d.id || o.target.id === d.id ? 'url(#arrowhead)' : 'url()'));
  }


  const nodeMouseOut = (e, d) => {

    tooltip.style("visibility", "hidden");

    node
      .transition(500)
      .style('opacity', 1);

    link
      .transition(500)
      .style("stroke-opacity", o => {
        console.log(o.value)
      });

  };

  const link = svg.append("g")
    .attr("stroke", "#D0D0D0")
    .attr("stroke-opacity", 0.6)
    .selectAll("line")
    .data(links)
    .join("line")
    .attr("stroke-width", d => Math.sqrt(d.value));

  const node = svg.append("g")
    .selectAll(".node")
    .data(nodes)
    .join("g")
      .attr('class', 'node')
      .call(drag(simulation));

  //include circle backdrop to create border around images
  node.append('circle')
      .attr('fill','black')
  //color & size of circle depends on what node represents (franchise? season? queen?)
      .attr("r", d => /S\d+/.test(d.id) ? 10 : d.id.includes('Drag Race') ? 12 : 10)
      .attr("fill", d => /S\d+/.test(d.id) ? "#B248F8" : d.id.includes('Drag Race') ? "#5448C8" : "black")
      .attr("stroke", d => /S\d+/.test(d.id) ? "white" : d.id.includes('Drag Race') ? "white" : "black");

// add text to nodes representing seasons
  node.append('text')
    .text(d => /S\d+/.test(d.id) ? d.id.match(/S\d+/)[0] : '')
    .attr('text-anchor', 'middle')
    .attr('font-size',10)
    .attr('font-family', 'Chivo Mono')
    .attr('dominant-baseline', 'central')
    .attr('fill', 'white');

//add images for queens
 node.append("image")
      .attr("xlink:href", d => {
        //set up custom functuon to look up the image url for each queen based on id (name)
    const matchingRefImg = ref_queen_img.find(i => i.name === d.id);
    return matchingRefImg ? matchingRefImg.link_image : '';
  })
      .attr("x", "-10px")
      .attr("clip-path",'inset(0 0 0 0 round 50%)')
      .attr("y", "-10px")
      .attr("width", "20px")
      .attr("height", "20px")
      .on("mouseover", (e, d) => nodeMouseOver(d, data.links))
    // hovering out returns image to regular size
      .on("mouseout", nodeMouseOut)
    //from Raven
      .on('mousemove', (event) => tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px"));
     
      
 /*    node.append("image")

      //.attr("x", "-10px")
      //.attr("clip-path",'inset(0 0 0 0 round 50%)')
      //.attr("y", "-10px")
      .attr("width", "20px") // needed
      .attr("height", "20px")
      .on("mouseover", (e, d) => nodeMouseOver(d, data.links))
    // hovering out returns image to regular size
      .on("mouseout", nodeMouseOut)
    //from Raven
      .on('mousemove', (event) => tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px"));
  */

  const tick = () => {
    link
        .attr("x1", d => d.source.x)
        .attr("y1", d => d.source.y)
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y);

    node
        .attr("transform", d => `translate(${d.x}, ${d.y})`);
  };

  simulation.on("tick", tick);

  invalidation.then(() => simulation.stop());


  tick();
  return svg.node();
}
```


Additional function below also from Guillermo.


```js
function drag(simulation) {
  
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

```js
const test_links = data.links.map(d => Object.create(d));
```
```js
//test_links.filter(link => link.source === "RuPaul's Drag Race S1").length;
```
```js 
//createTooltipText(test_links, "Miz Cracker")
```

```js
const nodes = data.nodes.map(d => Object.create(d));
```


```js
function createTooltipText (links, id) {
  const regex = /S\d+/;
  const sourceLinks = links.filter(link => link.source.id === id);
  const targetLinks = links.filter(link => link.target.id === id); 
  if (id.match(regex)) {
    const count = sourceLinks.length;
    return `<strong>${id}</strong> has a total of <strong>${count} queen${count === 1 ? '' : 's'}</strong>`;
  }
  else if (id.includes('Drag Race')) {
    const count = sourceLinks.length;
    return `<strong>${id}</strong> has a total of <strong>${count} season${count === 1 ? '' : 's'}</strong>`;
  }
  else {
    const count = targetLinks.length;
    return `<strong>${id}</strong> appeared on <strong>${count} season${count === 1 ? '' : 's'}</strong>`;
  }
}

```



# Import Data

I created a json file for this network diagram using data I scraped from [**RuPaul's Drag Race Wiki**](https://rupaulsdragrace.fandom.com/wiki/RuPaul%27s_Drag_Race_Wiki). The code and csv files are available on my [Github](https://github.com/tashapiro/drag-race). We'll use this **data** array to set up the nodes and links of the network diagram. 

```js
const data = FileAttachment("../data/network_20230824.json").json()
```

```js echo
const data_old= FileAttachment("../data/rpdr@1.json").json()
```

Also importing a reference csv file with all the image urls for each queen. In the network diagram function, we'll create a new look up function to search and return the **link_image** for each queen by **name**.

```js
const ref_queen_img = FileAttachment("../data/ref_queen_img.csv").csv()
```



# CSS

```js echo
//d3 = require("d3@7")
```

```html
<style>




    /*tooltip css adapted from Raven's notebook */

  .toolTip {
    font-family:Roboto;
    background: black;
    display:block;
    max-width:150px;
    width:auto;
    color:white;
    border-radius: .25rem;
    font-size:12px;
    padding: .2rem .4rem;
  }


  

</style>
```
