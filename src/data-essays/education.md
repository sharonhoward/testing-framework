---
theme: dashboard
title: Education (toggle)
toc: false
---

# Timelines of higher education



Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.



```js
// toggle baby! 8-)
const makeToggleView = view(makeToggle);
```
<div class="grid grid-cols-1">
  <div class="card">
    ${makeChart(makeToggleView) }
  </div>
</div>


Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

```js
// editables

const plotHeight = 5000;

const titleAge = "Higher education timelines: lifecycle (ordered by date of birth)";
const titleYear = "Higher education timelines: chronological (ordered by date of birth)";


// TODO maybe can i make title toggle too?  	   	
// something like this?
//const whichTitle = (select) => {
//  return select === "dates" ?  
//  "chronology" : "age" 
//};
```


```js
// Import components

import {educatedAgesChart, educatedYearsChart} from "./components/education.js";
```




```js
// load data

const education = FileAttachment("../data/l_dates_education2/educated_degrees2.json").json({typed: true});
```








```js
// make the radio button for the toggle

const makeToggle =
		Inputs.radio(
			["dates", "ages"],  
			{
				label: "View by: ", 
				value:"dates", // preference
				}
			);
```



```js
// the toggle function

//TODO i'd like less repetition in here but i can live with it.

const makeChart = (selection) => {
  return selection === "dates" ?  
  resize((width) => educatedYearsChart(education, {width}, titleYear, plotHeight)) : 
  resize((width) => educatedAgesChart(education, {width}, titleAge, plotHeight)) 
}

```
