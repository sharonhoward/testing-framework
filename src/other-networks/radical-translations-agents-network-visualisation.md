# Agents Network Visualisation
## Radical Translations

one last try at this because it's got everything you need and it's recent code written by people who know what they're doing. lol.

tooltips not working - pretty sure thats the mutable thing 

can't reset after clicking to highlight? second click doesn't work.

but it is really hard...

get rid of most of the text except where useful

raw data

```js echo
raw
```

the normalised data

```js echo
data
```

```js echo
filteredData
```

biographical and bibliographical information collected in the [database](https://radicaltranslations.org/database/) about translators, authors of source texts, publishers, periodicals, and organisations that they were associated with. 


The edges represent 8 different types of relationships:
* Based in (place)
* Edited (REMOVE?)
* Knows: linking two persons with any degrees of acquaintance (ranging from epistolary correspondence to kinship); this property does not specify the characteristic of the relation but groups of people that were very “close” in real life can typically be identified through the presence of many interconnecting “knows” links 
* Member of: links persons to organisations
* Published: links publishers to authors of source texts or translators
* Published in (place): links authors of source texts and translators to places
* Translated: links translators to authors of source texts

Results can also be filtered and parsed by target language (languages translated to) and by minimum number of connections (2 is the default value). “Knows” connections are always reciprocal so Agent A’s connection to Agent B is counted as 2 connections. 

---

[Part 2 - Resources Network Visualisation](https://observablehq.com/@jmiguelv/radical-translations-resources-network-visualisation?collection=@jmiguelv/radical-translations)

## ${config.title} network

The visualisation shows a network of -- *${nodeGroups.join(", ")}* -- nodes, and how they are connected to one another via the relationships *${linkLabels.join(", ")}*. The size of the nodes corresponds to the number of connections the node has.

To interact with the visualisation:
* Search nodes to show the nodes and connections that are related to the search term.
* Select relationships to show using the checkboxes.
* Hover over the nodes to show more information about the node.
* Click on a node to highlight/hide the selected node network.
* Double-click on a node to view more details about it in the [Radical Translations website](https://radicaltranslations.org).


filters are working!!
probably need a closer look at the data to see how they work..


### Filter the visualisation

```js
const height = window.outerHeight - 175
```

```js
const 
	foundNodes = view(Inputs.search(data.nodes, {
  datalist: nodesData,
  label: html`<b>Search nodes</b>`,
  placeholder: "Name, type, etc.",
  width: width / 2
}))
```


```js 
//what's this for? it doesn't seem to be used anywhere else.
//ah, it shows both relationships and translatedTo in the original notebook
//const filters = html`${[view(relationships), view(translatedTo)]}`
```

```js
//display options - the set of sliders. put these in separately intead
//once you did that the relationships.includes errors went away
/*const display = html`<h4>Display options</h4>${[
  view(numberOfConnections), 
  view(linkDistance),
  view(strokeWidth),
  //view(zoomLevel), // this one was causing relationships.includes error
  view(showData)
]}`*/
```

 

```js
//relationships is about links data rather than nodes
const relationships = view(Inputs.checkbox(linkLabels, {
  label: html`<b>Relationships</b>`,
  format: (x) =>
    html`<span style="border-bottom: solid ${strokeWidth}px ${linkColor(
      x
    )}; margin-bottom: -2px;">${x}`,
  value: config.relationships
}))
```


```js 
// this is nodes though
const translatedTo = view(Inputs.checkbox(languages, {
  label: html`<b>Languages translated to</b>`
})
)
```


```js
//in notebook conversion, is this relevant? (wtf does it mean?)
// Generators.input is now an async generator
//try deleting .input and see if it works? seems to stop the error
//TypeError: foundNodes.input is undefined

const numberOfConnections = view(Inputs.range([0, 25], {
  label: html`<b>Minimum number of connections</b>`,
  step: 1,
  value:
    //viewof 
    //foundNodes.input.value ||
    foundNodes.value ||
    relationships.length > 0 ||
    translatedTo.length > 0
      ? config.connections
      : 10
})
)
```

```js
const linkDistance = view(Inputs.range([10, 100], {
  label: html`<b>Link distance</b>`,
  step: 5,
  value: 30
})
)
```


```js
const strokeWidth = view(Inputs.range([0.5, 2.5], {
  label: html`<b>Link width</b>`,
  step: 0.25,
  value: 1.5
})
)
```

```js 
const zoomLevel = view(Inputs.range([0.25, 2], {
  label: html`<b>Zoom</b>`,
  step: 0.25,
  value: results.nodes.length > 500 ? 0.75 : 1
})
)
```

```js
const showData = view(Inputs.toggle({ label: html`<b>Show data</b>` }) )
```


### Visualising ${config.title.toLowerCase()}${foundNodes.value ? `, with *${foundNodes.value}* in the content` : ""}${relationships.length > 0 ? `, with *${relationships.join(", ")}* relationships` : ", with any relationship"}${translatedTo.length > 0 ? `, that translated to *${translatedTo.join(", ")}*` : ""}
*${results.nodes.length === 0 ? "No results. Try reducing the minimum number of connections and/or changing the filters." : `${results.nodes.length} nodes with a minimum of ${numberOfConnections} connections and ${results.links.length} links`}*


```js 
// ????
  /*function link(item) {
    return html`<a href="${baseUrl}${item.url}" target="network:detail">${item.title}</a>`;
  }
  function sparkbar(max) {
    return (x) => html`<span class="sparkline"
      style="width: ${(100 * x) / max}%;">${x.toLocaleString("en")}`;
  }*/

  //const data = results.nodes;

/*const nodeSelection = 
   Inputs.table(results.nodes, {
    columns:
      data.length > 0 ? Object.keys(data[0]).filter((c) => c !== "url") : [],
    //format: {
     // title: (v, i, d) => d[i],
      //connections: sparkbar(d3.max(data, (d) => d.connections / 3))
    //},
    multiple: false,
    rows: 5.5,
    sort: "title"
  })

*/
```



chart code starts here


```js 

//chart = {
  const clinks = results.links.map((d) => Object.create(d));

  const linksByIndex = {};
  clinks.forEach((l) => (linksByIndex[`${l.source},${l.target}`] = true));

  const areConnected = (a, b) =>
    a === b ||
    linksByIndex[`${a.id},${b.id}`] ||
    linksByIndex[`${b.id},${a.id}`];

  const cnodes = results.nodes.map((d) => Object.create(d));

  const simulation = d3
    .forceSimulation(cnodes)
    .force("charge", d3.forceManyBody())
    .force(
      "collision",
      d3.forceCollide().radius((d) => d.radius)
    )
    .force(
      "link",
      d3
        .forceLink(clinks)
        .id((d) => d.id)
        .distance(linkDistance)
    )
    .force("x", d3.forceX())
    .force("y", d3.forceY());

  const left = -width / 2;
  const top = -height / 2;

  const svg = d3.create("svg").attr("viewBox", [left, top, width, height]);

  svg
    .append("svg:defs")
    .selectAll("marker")
    .data(["arrow"])
    .enter()
    .append("svg:marker")
    .attr("id", String)
    .attr("viewBox", "0 0 10 10")
    .attr("refX", 25)
    .attr("refY", 5)
    .attr("markerWidth", 3)
    .attr("markerHeight", 3)
    .attr("orient", "auto")
    .append("svg:path")
    .attr("d", "M 0 0 L 10 5 L 0 10 z");

  const root = svg.append("g").attr("id", "root");
  
  const transform = d3.zoomIdentity.translate(0, 0).scale(zoomLevel);
  
  root.attr("transform", transform);

  const linkOpacity = 0.75;
  
  const link = root
    .append("g")
    .attr("opacity", linkOpacity)
    .selectAll("line")
    .data(clinks)
    .join("line")
    .attr("stroke", (d) => linkColor(d.label))
    .attr("stroke-width", strokeWidth)
    .attr("marker-end", "url(#arrow)");

  const node = root
    .append("g")
    .attr("stroke-width", strokeWidth)
    .selectAll("circle")
    .data(cnodes)
    .join("circle")
    .attr("id", (d) => d.id)
    .attr("class", (d) => (d.url !== undefined ? "has-link" : "no-link"))
    .attr("r", (d) => Math.sqrt(d.connections + 25))
    .attr("stroke", (d) => nodeStroke(d.group))
    .attr("fill", (d) => nodeFill(d.group))
    .call(drag(simulation));


  const tooltip = d3
    .select("body")
    .append("div")
    .attr("class", "tooltip")
    .style("visibility", "hidden");


  const hideTooltip = () => tooltip.style("visibility", "hidden");
  
  const showTooltip = (node) =>
    tooltip
      .style("visibility", "visible")
      .html(
        `${node.id}: ${node.group}<br>${node.title}<br>${node.connections} connections`
      );

  let focusedNode = null;
  const transitionTimeout = 125;

  const handleNodeClick = (d) => {
    
    showTooltip(d);

// PROBLEM

    if (d === focusedNode) {
    
       
    // original notebook code
    // mutable selectedNode = focusedNode = null;
    
    // replace any assignments to mutable foo with calls to setFoo
    //const setSelectedNode = (value) => (selectedNode.value = value);
    
    setSelectedNode(d);
       
      hideTooltip();

      link
        .transition(transitionTimeout)
        .style("opacity", linkOpacity)
        .transition(transitionTimeout)
        .attr("marker-end", "url(#arrow)");
        
      node.transition(transitionTimeout).style("opacity", 1);
      
    } 
    else {
    
       setSelectedNode(d)
				//mutable selectedNode = focusedNode = d;

				
				
      link
        .transition(transitionTimeout)
        .style("opacity", (l) =>
          l.source.id === d.id || l.target.id === d.id ? 1.0 : 0.1
        )
        .transition(transitionTimeout)
        .attr("marker-end", (l) =>
          l.source.id === d.id || l.target.id === d.id ? "url(#arrow)" : "url()"
        );
        
      node
        .transition(transitionTimeout)
        .style("opacity", (n) => (areConnected(n, d) ? 1.0 : 0.25));
        
    } // end else?
    
  }; // end handleNodeClick i think
  
// END OF PROBLEM?

  node
    .on("mousemove pointermove", (e) =>
      tooltip
        .style("top", `${e.clientY - 10}px`)
        .style("left", `${e.clientX + 10}px`)
    )
    .on("mouseenter pointerenter", (e, d) => {
      showTooltip(d);
    })
    .on("mouseout pointerout", () => {
      hideTooltip();
    })
    
    // doubleclick opens a webpage, which is cute but let's turn it off for now.
    // but what does selectedNode do here?
    /*
      .on("dblclick", (e, d) => {
      if (d.url !== undefined) {
        window.open(`${baseUrl}${d.url}`, "agent:detail");
      }
      
       //selectedNode(focusedNode); 
         mutable selectedNode = focusedNode = null;
       
      handleNodeClick(d);
      
    }) */
    
    .on("click", (e, d) => {
      handleNodeClick(d);
    });

  simulation.on("tick", () => {
    link
      .attr("x1", (d) => d.source.x)
      .attr("y1", (d) => d.source.y)
      .attr("x2", (d) => d.target.x)
      .attr("y2", (d) => d.target.y);

    node.attr("cx", (d) => d.x).attr("cy", (d) => d.y);
  });

  invalidation.then(() => simulation.stop());

  //return svg.node();
  
  const chart = display(svg.node()); 
  
//}

```
chart code ends here



node key should have coloured circles. link key seems about right?


<div class="oi-f09d35">
  ${showData ? html`<h3>Data</h3><i>Select an item to higlight the selected item network</i>${ nodeSelection ?  nodeSelection : ""}` : ""}
  <p>
    <label><b>Node key</b></label>
    ${nodeGroups.map((n) => html`<span class="node-key" style="background: ${nodeColor(n)}"></span>
    <span>${n}</span>`)}
  </p>
  <p>
    <label><b>Link key</b></label>
    ${linkLabels.map((l) => html`<span class="link-key" style="border-bottom: ${strokeWidth}px solid ${linkColor(l)}">${l}</span> `)}
  </p>
  <p>
    <label><b>Selected node</b></label>
    <span>${getSelectedNodeInfo() ? html`<em>${getSelectedNodeInfo()}</em>` : html`<i>Click on a node to highlight/hide the selected node network</i>`}</span>
  </p>
</div>




## Problem

- when you refresh the page selectedNode is null.
- when you click on a node it changes to the data for the node
- you can click on other nodes (though it feels a bit laggy)
- but it doesn't unset (and go back to null) when you click a second time/click elsewhere in the chart
- tweaking setSelectedNode in the chart doesn't make any obvious difference to chart behaviour but can affect selectedNode here.
- it does do something in the chart! change setSelectedNode to selectedNode it breaks. 
- but in selectedNode info below, it has to be selectedNode... setSelectedNode doesn't work.




```js echo
// original code
//mutable selectedNode = null

const selectedNode = Mutable(null);
const setSelectedNode = (value) => (selectedNode.value = value);
```


```js 
function getSelectedNodeInfo() {
  let info = null;

  if (selectedNode !== null) {
    info = `${selectedNode.group}: ${selectedNode.title}`;

    if (selectedNode.url !== undefined) {
      info = `<a href="${baseUrl}${selectedNode.url}" target="agent:detail">${info}</a>`;
    }
  }

  return info;
}

// original code
/*
getSelectedNodeInfo = () => {
  let info = null;

  if (selectedNode !== null) {
    info = `${selectedNode.group}: ${selectedNode.title}`;

    if (selectedNode.url !== undefined) {
      info = `<a href="${baseUrl}${selectedNode.url}" target="agent:detail">${info}</a>`;
    }
  }

  return info;
}
*/

```

moved code about reactivity and mutables to a baby steps md to come back to maybe.


## Code

### Filter data

Data after searches, filters and display options are applied.

`results` is the data that's fed into `chart` 


```js echo
//const results = {

  let resnodes = filteredData.nodes
    .map((n) => {
      return {
        ...n,
        connections: filteredData.links.filter(
          (l) => l.source === n.id || l.target === n.id
        ).length
      };
    })
    .filter((n) => n.connections >= numberOfConnections);

  const resultslinks = filteredData.links.filter(
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
  
//}
```


```js echo
filteredData
```


Data after search and filters are applied.

```js echo
//const filteredData = {

  const flinks = foundData.links
    .filter(
      (l) => relationships.length === 0 || relationships.includes(l.label)
    )
    .filter(
      (l) =>
        translatedTo.length === 0 ||
        l.meta.some((m) => translatedTo.includes(m))
    );

  const fnodes = foundData.nodes.filter((n) =>
    flinks.some((l) => l.source === n.id || l.target === n.id)
  );

	const filteredData = {nodes: fnodes, links:flinks};
  //return { nodes: nodes, links: links };
  
//}
```

Data after text search is done.

```js echo

const foundData = {

  //return {
    nodes: foundNodes,
    links: data.links.filter(
      (l) =>
        foundNodes.some((n) => n.id === l.source) &&
        foundNodes.some((n) => n.id === l.target)
    )
  //};
}
```


mdNetwork not needed now?

```js
/*const mdNetwork = (relationship, title) =>
  htl.html`<a href="#chart" onclick=${updateInput(viewof relationships, [
    relationship
  ])}>${title}</a>`*/
```
updateInput only in mdNetwork
```js
/*function updateInput(input, value) {
  input.value = value;
  input.dispatchEvent(new Event("input"));
}*/
```
not needed?
```js
//const mdNetworkLink = (id, title) =>
//  htl.html`<a href="#chart" onclick=${() => toggleNode(id)}>${title}</a>`
```
```js
//const toggleNode = (id) => {
//  d3.select(`#${id}`).dispatch("click");
//}
```


### Link functions


```js
const linkColor = d3.scaleOrdinal().domain(linkLabels).range(d3.schemeCategory10)
```


```js
const linkLabels = data.links
  .reduce((a, c) => {
    if (!a.includes(c.label)) a.push(c.label);
    return a;
  }, [])
  .sort()
```

### Node functions


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

  return d3
    .drag()
    .on("start", dragstarted)
    .on("drag", dragged)
    .on("end", dragended);
}

```


[moved nodeselect related stuff out]


```js
//it seems that this construction for const should work...
const nodeStroke = (value) => (isOutline(value) ? nodeColor(value) : "#eee")
const nodeFill = (value) => (isOutline(value) ? "#fff" : nodeColor(value))
```

```js 
// isOutline = (value) => ["organisation", "language", "place"].includes(value)
const isOutline = (value) => false
```

```js 
//this needs nodeGroups
const nodeColor = d3.scaleOrdinal().domain(nodeGroups).range(d3.schemeSet2)
```

```js echo
const nodeGroups = data.nodes
  .reduce((a, c) => {
    if (!a.includes(c.group)) a.push(c.group);
    return a;
  }, [])
  .sort((a, b) => {
    a = a.startsWith("person") ? `0${a}` : a.startsWith("org") ? `1${a}` : a;
    b = b.startsWith("person") ? `0${b}` : b.startsWith("org") ? `1${b}` : b;

    return a.localeCompare(b);
  })
```



```js

const nodesData = [
  ...new Set(
    data.nodes
      .map((n) => n.group.replaceAll(/[()]/g, ""))
      .concat(
        data.nodes.map((n) => n.title.replaceAll(/(\[.*?\]\s)|(\(.*?\))/g, ""))
      )
      .concat(
        data.nodes.flatMap((n) =>
          n.meta !== undefined
            ? n.meta
                .filter((r) => r)
                .map((r) => r.replaceAll(/(\[.*?\]\s)|(\(.*?\))/g, ""))
            : ""
        )
      )
      .sort()
  )
]
```


```js
const languages = raw.nodes
  .filter((n) => n.group === "language" && n.title !== "German")
  .map((n) => n.title)
  .sort()
```


### Data table functions

these don't seem to be used anywhere else ??? have i deleted anything??
and problems with them... another mutable.

```js echo
/*const handleTableClear = {
  if (nodeSelection === null && tableSelectedNode !== null) {
    d3.select(`#${tableSelectedNode.id}`).dispatch("click");
     tableSelectedNode = Mutable(null);
  }
}*/
```

```js echo
/*const handleTableSelection = {
  if (nodeSelection !== null) {
     tableSelectedNode = Mutable(nodeSelection);
    d3.select(`#${nodeSelection.id}`).dispatch("click");
  }
}*/
```

```js
//const tableSelectedNode = Mutable(null);
```

### Normalise the data

* Transform person ${config.title.toLowerCase()} with no gender into unknown gender.
* Flatten the meta information.
* Remove nodes with no links.
* Copy the meta information into the links for easier filtering.



i've renamed nodes, links here to datanodes, datalinks to be unambiguous


```js echo
//data = {
  const datanodes = raw.nodes
    .map((n) => {
      if (n.group === "person (None)") n.group = "person (u)";

      n.meta =
        n.meta !== undefined ? Object.values(n.meta).flatMap((m) => m) : [];

      return n;
    })
    .filter((n) =>
      raw.edges.some((e) => e.source === n.id || e.target == n.id)
    );

  const datalinks = raw.edges
  .map((e) => {
    const nodes = raw.nodes.filter(
      (n) => n.id === e.source || n.id === e.target
    );
    e.meta = nodes.flatMap((n) => (n.meta !== undefined ? n.meta : []));

    return e;
  });

  
//}


  //const data = nodes.map(links); // ??????? how do i make data ?
  
  //that's it folks. amazing.
  const data = {nodes:datanodes, links:datalinks};
  

```

```js echo
//data
```




### Load the data


```js echo
const raw = FileAttachment("../data/network@26.json").json()
const config = ({ title: "Agents", relationships: ["knows"], connections: 2 })
const baseUrl = "https://radicaltranslations.org"
```

### Filters and display options

The views are defined here so they can be grouped in a single form above. Because they are used above, they produce empty outputs in this section.

[moved them up]





### Styles
CSS styles.

```js
const styles = html`
  <style>
  .sparkline {
    background: lightgray;
    box-sizing: border-box;
    color: steelblue;
    float: right;
    padding-right: 2px;
  }
  .node-key {
    border-radius: 50%;
    display: inline-block;
    height: 15px;
    width: 15px; 
    margin-left: 10px;
  }
  .link-key {
    margin-left: 10px;
  }
  .has-link {
    cursor: pointer;
  }
  .tooltip {
    background: rgba(6, 6, 6, .6);
    border-radius: .4rem;
    color: #fff;
    display: block;
    font-family: sans-serif;
    font-size: .8rem;
    max-width: 400px;
    padding: .4rem;
    position: absolute;
    text-overflow: ellipsis;
    z-index: 300;
  }
</style>`
```

### Imports

this is just a chunk of text

```js echo
//import { rtDescription } from "@jmiguelv/radical-translations"
```

this one seems a bit odd and probably notebook specific, but presumably it's just Plot.
actually it is a real thing https://observablehq.com/plot/getting-started

import {barY, groupX} from "@observablehq/plot";

but that causes error. pretty sure you don't need it.

```js echo
//import { d3 } from "@observablehq/plot"
```

## References
* [Disjoint force directed graph](https://observablehq.com/@d3/disjoint-force-directed-graph)
* [Basic tooltip](https://observablehq.com/@jianan-li/basic-tooltip)
* [Form inputs](https://observablehq.com/@observablehq/inputs)
* [Zoom transform](https://devdocs.io/d3~6/d3-zoom#zoomtransform)
* [Force layout](https://www.d3indepth.com/force-layout/)
* [Understanding the force layout](https://medium.com/@sxywu/understanding-the-force-ef1237017d5)
* [Multitouch events](https://observablehq.com/@d3/multitouch)
* https://observablehq.com/@ravengao/force-directed-graph-with-cola-grouping
* https://observablehq.com/@vk2425/game-of-thrones-relationship-graph
