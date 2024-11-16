---
sql:
  murphy_cast: ../data/murphy_cast.csv
	flanagan_cast: ../data/flanagan_cast.csv
	whedon_cast: ../data/whedon_cast.csv
---
this front matter stuff doesn't work... idk why. 


# TV Shows - Cast Connections
D3 Network Diagram exploring overlapping actors within specific universes. Universe is determined by TV Show Creator. Data from [The Movide Database tmdb](https://developer.themoviedb.org/reference/search-movie). A user explore a different universe using the TV Creator dropdown.

Code shout out to Mike Bostock - this would not happen without his notebook explaining how to center [text within circles](https://observablehq.com/@mbostock/fit-text-to-circle)...I repurposed Mike's code and created a function to apply text in this graphic. Thanks Mike, not all heroes wear capes :) 

```js
const tvDirector = view(Inputs.select(["Mike Flanagan", "Ryan Murphy", "Joss Whedon"], {label: "TV Creator"}))
```

```js
const height = view(Inputs.range([10, 1200], {label: "Height", value: 500, step:1}))
```

```js
const collide = view(Inputs.toggle({ label: "Collide", value: true }))
```

```js
const useRadial = view(Inputs.toggle({ label: "Use Radial Force", value: true }))
```

```js
const radialForce = view(Inputs.range([0.01, 0.9], {
  step: 0.01,
  value: this?.value || 0.25,
  label: "Radial Force Strength",
  disabled: !useRadial
}))
```

```js
const showColor = view(Inputs.color({label: "Show Color", value: "#532aea"}))
```

```js
const actorRadius = view(Inputs.radio(["Default", "Episode Count"], {label: "Actor Radius", value: "Episode Count"}))
```

```js
const actorNodeStyle = view(Inputs.radio(["Name", "Image"], {label: "Actor Node Style", value: "Image"}))
```

```js
network()
```

```js
function network() {

  const max_episodes = d3.max(actors.map(d=>d.total_episodes));

  const strokeColor = "black";
  const highlightStroke = "pink";
  const imgLength = 24;
  const imgWidth = 24;
  const radiusMultiplier = 30 / max_episodes;
  const lineWidth = 1;
  const showNodeFill = showColor;
  const showNodeStroke = "black";
  const lineHeight = 16;
  const fontColor = "white";
  const fontFamily= "Oswald";
  const minRadius = max_episodes * .3;
  const showRadius = 30;
  const textRadiusMultiplier = 0.7;
  
  const width = 600;
  
  const links = data.links; // Reuse the same nodes to have the animation work when changing the inputs
  const nodes = data.nodes;

function getRadius(node) {
  const getEpisodes = actors.find((i) => i.name === node.id);
  const totalEpisodes = getEpisodes ? getEpisodes.total_episodes : 0;
  let effectiveEpisodes;

  if (actorRadius === "Episode Count" & totalEpisodes > minRadius) {
    effectiveEpisodes = totalEpisodes * radiusMultiplier;
  }
  else if(actorRadius == "Episode Count" & totalEpisodes <= minRadius){
    effectiveEpisodes = minRadius * radiusMultiplier
  }
  else if (actorRadius === "Default") {
    effectiveEpisodes = showRadius/2;
  } else {
    // Handle other cases here if needed
    effectiveEpisodes = 0; // Default value when actorRadius is not recognized
  }

  return effectiveEpisodes;
}




  const simulation = d3.forceSimulation(nodes)
      .alpha(1)
      .force("link", d3.forceLink(links).id(d => d.id).distance(30).strength(0.25))
      .force("charge", d3.forceManyBody())
      .force("collision", d3.forceCollide().radius(d=> d.group === 'Show' ? showRadius *1.15 : getRadius(d)*1.1))
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
     .force("center", d3.forceCenter(width / 2, height / 2));

  const svg = d3.create("svg")
      .style("overflow", "hidden")
      .attr("viewBox", [0, 0, width, height]);



    const nodeMouseOver = (d, links) => {
    tooltip.style("visibility", "visible")
      .html(createTooltipText(links, d.id, actors, d.group));

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


  const tooltip = d3.select("body").append("div")
  .attr("class", "toolTip")
    .style("position", "absolute")
    .style("visibility", "hidden")
    .text("Placeholder");
  
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


  const link = svg.append("g")
    .attr("stroke", "#D0D0D0")
    .attr("stroke-opacity", 0.6)
    .selectAll("line")
    .data(links)
    .join("line")
    .attr("stroke-width", d => lineWidth);

  const node = svg.append("g")
  .selectAll(".node")
  .data(nodes)
  .enter()
  .append("g")
  .attr('class', 'node')
  .call(drag(simulation));

// Iterate through each node
node.each(function (d) {
  
  const currentNode = d3.select(this);
  const radius = d.group === 'Show' ? showRadius : getRadius(d);
  const textRadius = d.group === 'Show' ? showRadius *textRadiusMultiplier : getRadius(d) * textRadiusMultiplier;
  const labelText = d.id; // Use the 'id' property from the data

  // Create a circle for each node
  currentNode.append('circle')
    .attr("r", radius)
    .attr("fill", d.group === 'Show' ? showNodeFill : 'black')
    .attr("stroke", "black");

  // Create text label for each node based on 'id'
  currentNode.append("text")
    .style("text-anchor", "middle")
    .attr("transform", `translate(0, 0) scale(${textRadius / getTextRadius(getLines(labelText, lineHeight), lineHeight)})`)
    .selectAll("tspan")
    .data(getLines(labelText, lineHeight))
    .enter()
    .append("tspan")
    .attr("x", 0)
    .attr("y", (d, i) => (i - getLines(labelText, lineHeight).length / 2 + 0.8) * lineHeight)
    .style("font-family", "Oswald")
    .style("fill", fontColor)
    .text(d => d.text);

if (actorNodeStyle === "Image") {
currentNode.append("image")
  .attr("class","headshot")
  .attr("x", (d) => -getRadius(d))
  .attr("y", (d) => -getRadius(d))
  .attr("width", (d) => getRadius(d)*2)
  .attr("href", (d) => {
    const matchingRefImg = actors.find((i) => i.name === d.id);
    return matchingRefImg ? matchingRefImg.image_url : "";
  }) // attr href
  .style("clip-path", (d) => {
   const getEpisodes = actors.find((i) => i.name === d.id);
    return getEpisodes ? "circle(" + getRadius(d) + "px at " + getRadius(d) + "px " + getRadius(d) + "px)" : radius;//
  }) // clip-path
} // end of if actornodestyle?

  currentNode.append('circle')
    .attr('fill', 'transparent')
    .attr("r", radius)
    .attr("stroke", "black")
    .on("mouseover", (e, d) => nodeMouseOver(d, data.links))
    .on("mouseout", nodeMouseOut)
    .on('mousemove', (event) => tooltip.style("top", (event.pageY - 10) + "px").style("left", (event.pageX + 10) + "px"));

  
});

  

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
end of network

## Functions

### Text in Circle Functions adapted from Mike Bostock

```js
function getLines(text, lineHeight) {
  const text_array = [text]
  const words = text_array[0].split(/\s+/g);

  function measureWidth() {
    const canvas = document.createElement("canvas");
    const context = canvas.getContext("2d");
    return text => context.measureText(text).width;
  }

  const targetWidth = Math.sqrt(measureWidth()(text) * lineHeight);

  const lines = (function() {
    let line;
    let lineWidth0 = Infinity;
    const lines = [];
    for (let i = 0, n = words.length; i < n; ++i) {
      let lineText1 = (line ? line.text + " " : "") + words[i];
      let lineWidth1 = measureWidth()(lineText1);
      if ((lineWidth0 + lineWidth1) / 2 < targetWidth) {
        line.width = lineWidth0 = lineWidth1;
        line.text = lineText1;
      } else {
        lineWidth0 = measureWidth()(words[i]);
        line = { width: lineWidth0, text: words[i] };
        lines.push(line);
      }
    }
    return lines;
  })();

  return lines;
}
```



```js
function getTextRadius(lines, lineHeight) {
  let radius = 0; 
  for (let i = 0, n = lines.length; i < n; ++i) {
    const dy = (Math.abs(i - n / 2 + 0.5) + 0.5) * lineHeight;
    const dx = lines[i].width / 2;
    radius = Math.max(radius, Math.sqrt(dx ** 2 + dy ** 2));
  }

  return radius;
}
```

### Tooltip Function



```js
function createTooltipText(links, id, reference, group) {
  const regex = /S\d+/;
  const sourceLinks = links.filter(link => link.source.id === id);
  const targetLinks = links.filter(link => link.target.id === id); 
  const ref = reference.filter(d => d.name === id); 
  if (group === 'Show') {
    const count = sourceLinks.length;
    return `<strong>${id}</strong> has a total of <strong>${count} actor${count === 1 ? '' : 's'}</strong>`;
  }
  else {
    const count = targetLinks.length;
    return `<strong>${id}</strong> appeared on <strong>${count} show${count === 1 ? '' : 's'}</strong> and a total of <strong>${ref[0].total_episodes} episodes</strong>`;
  }
}

```

### Drag D3 Function


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

## Import Data

### Network JSON Data

Data taken from tmdb's API. I wrangled data in R and exported to explore in this notebook. Data sets for different creators, including Ryan Murphy, Mike Flanagan, and Joss Whedon.


```js
const murphy = FileAttachment("../data/murphy@1.json").json()
const flanagan = FileAttachment("../data/flanagan.json").json()
const whedon = FileAttachment("../data/whedon.json").json()
```

```js
const max_episodes = d3.max(actors.map(d=>d.total_episodes))
```

### CSV attachment with Cast Info and Image URLs

This will be handy to plot actor images.

```table echo

```

```table echo

```

```table echo

```

### Dynamic Data
Swap out data set depending on TV director/creator selected.


```js echo
/*const whedon_cast = FileAttachment("../data/whedon_cast.csv").csv({typed:true});
const flanagan_cast = FileAttachment("../data/cast.csv").csv({typed:true});
const murphy_cast = FileAttachment("../data/murphy_cast.csv").csv({typed:true});
*/
```

```js echo
/*const dbClient = DuckDBClient.of([
  FileAttachment("../data/whedon_cast.csv").csv({typed:true}),
  FileAttachment("../data/cast.csv").csv({typed:true}),
  FileAttachment("../data/murphy_cast.csv").csv({typed:true})
])*/

```

To get a DuckDB client, pass zero or more named tables to DuckDBClient.of. Each table can be expressed as a FileAttachment, Arquero table, Arrow table, an array of objects, or a promise to the same. For file attachments, the following formats are supported: CSV, TSV, JSON, Apache Arrow, and Apache Parquet. For example, below we load a sample of 250,000 stars from the Gaia Star Catalog as a Parquet file:

const db = DuckDBClient.of({gaia: FileAttachment("gaia-sample.parquet")});

Now we can run a query using db.sql to bin the stars by right ascension (ra) and declination (dec):

const bins = db.sql`SELECT
  floor(ra / 2) * 2 + 1 AS ra,
  floor(dec / 2) * 2 + 1 AS dec,
  count() AS count
FROM
  gaia
GROUP BY
  1,
  2`
  

```js echo
const db = DuckDBClient.of({
  show_cast: tvDirector === 'Mike Flanagan' ? flanagan_cast : tvDirector === 'Ryan Murphy' ? murphy_cast : whedon_cast
})
```



```js echo
const actors = db.query`select  name, image_url, sum(episode_count) as total_episodes  
from show_cast
group by 1,2`
```


```js echo
const data = tvDirector === 'Mike Flanagan' ? flanagan : tvDirector === 'Ryan Murphy' ? murphy : whedon;
```



## CSS

```html
<style>

  @import url('https://fonts.googleapis.com/css?family=Barlow&display=swap');
  @import url('https://fonts.googleapis.com/css?family=Oswald&display=swap');


  p {
    max-width:100%;
  }
  body, label {
    font-family:"Barlow";
  }

  label {
    font-weight:bold;
  }
  
  .toolTip {
    max-width:250px!important;
    background-color:black;
    color:white;
    padding:5px 10px;
    border-radius:5px;
    font-family:Roboto Condensed;
  }


  .headshot {
    clip-path:circle("40%")!important;
  }

  .showLabel {
    max-width:200px!important;
  }
</style>
```
