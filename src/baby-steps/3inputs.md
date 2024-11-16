---
theme: dashboard
title: Inputs
toc: true
---

# Working out Inputs 


```js
const lecturersDates = FileAttachment("../data/l_women_lecturing/lecturers-dates.csv").csv({typed: true}); 
```

## lecturers table 

(trimmed, don't copy straight back into anything important)

```js

Inputs.table(lecturersDates, {
	layout: "auto",
	//value:"position_label",
	sort:"year1",
	format: {
		bn_id: id => htl.html`<a href=https://beyond-notability.wikibase.cloud/entity/${id} target=_blank>${id}</a>`,
		"year1": d3.format(".0f")
	},
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
})

```


columns

```js echo
lecturersDates.columns
```

data

```js echo
lecturersDates
```


d3.group position label

```js echo
const lecturersPositions = d3.group(lecturersDates, d => d.position_label)
```


```js echo
lecturersPositions
```

a simple scatter plot for testing

Plot.plot({
	x: {grid:true, label: "yob"},
	y: {label:"year"},
	marks: [
		Plot.dot(lecturersDates, {
			x: "bn_dob_yr",
			y: "year1",
			fill: "position_label"
		})
	]
})










## date range

the standard slider is just a single thing, so not all that useful for dates. 

because who on earth would ever want a slider with two buttons!

presumably if you make the value the top of the range it'll start by showing all data?

```js echo
const pickDates = view(
		Inputs.range(
			[1881,1950], 
			{
			step:1, 
			label:"year", 
			value:1950
			}
		)
	);

```

filter some data


```js echo
lecturersDates
	.filter((d) => d.year1 <= 1890)
```

[find min and max in data](https://observablehq.com/d/93a01eebe25bfa8f)

min: ${d3.min(lecturersDates.map(d => d.year1))}

max: ${d3.max(lecturersDates.map(d => d.year1))}

[filter for plots](https://observablehq.com/plot/transforms/filter)

//d3.range makes a range out of a min and max.
//d3.range(earliest, latest)




### TODO a proper date slider ????

there's a nice thing here but now i have no idea how to import it (let alone how to use it with data).

https://observablehq.com/@mootari/range-slider

```js
// hang on this is just a single thing. how do you make a proper date slider?
//const y = view(Inputs.range([0, 255], {step: 1}));


//see projects md for stuff about importing

```




### standard slider WORKING


a table and a plot using the same slider


```js
// shared earliest/latest and slider for table and plot
const earliest = d3.min(lecturersDates.map(d => d.year1))
const latest = d3.max(lecturersDates.map(d => d.year1))

const pickYears = view(
		Inputs.range(
			[earliest, latest], 
			{
			step:1, 
			label:"year", 
			value:latest
			}
		)
	);

```


```js 
// make new filter data array for the table
const simple_slider =
lecturersDates
  .filter((d) => d.year1 <= pickYears)
  .map((d) => ({...d}) )
//you have to use the right variable in the filter you twit.


// function for plot. uses full data initially and pickYears goes in a filter.
function lecturersDatesChart(data, {width}) {
 return Plot.plot({
	title: "By date",
	x: {label: "year", ticks: d3.range(1880,1950,5), tickFormat: d3.format('d')},
	y: {label: "number of positions", grid:true},
	
	width,
	height:600,
	 //facet: {data, x: "position_label", label:null},
	marks: [
		//Plot.ruleY[0],
		//Plot.gridX(interval:10),
		Plot.rectY(
			data.filter((d) => d.year1 <= pickYears), // filter/pickYears here
			Plot.groupX({y: "count"}, {x:"year1"})
		)
	]
 });
}
```


```js
// now the table uses the filtered data
// possible to make this a function like the plot?
Inputs.table(simple_slider, {
	layout: "auto",
	//value:"position_label",
	sort:"year1",
	format: {
		bn_id: id => htl.html`<a href=https://beyond-notability.wikibase.cloud/entity/${id} target=_blank>${id}</a>`,
		"year1": d3.format(".0f")
	},
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
})

```



 
<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => lecturersDatesChart(lecturersDates, {width}))}
  </div>
</div>










## WORKING radio


the same sort of process as for select

minor thing (should be...) i'm sure i saw a way to split this up a bit more so you have a const for the inputs.radio part and then put it in view() afterwards

bizarre it seems to work perfectly so idk why i had an error first time i tried it, except of course THINGS. well anyway.

would still like to work out how to write the const View inline; that didn't work at all. but it's fine, jb isn't an idiot.

### pickCategory in two stages

```js 

const lecturerPickCategory = 		
	Inputs.radio(
				lecturersDates.map(d => d.position_label),
				{
				label: "Position type", 
				value: "Lecturer (freelance)", // [no square brackets]
				sort: true, 
				unique: true
				}
		)		
```


```js 
//a) map position_label and unique:true
const lecturerPickCategoryView = view(
		lecturerPickCategory
)
```



```js 
//b) use it to make the new filter data array
const data_radio =
lecturersDates
  .filter((d) => d.position_label === lecturerPickCategoryView)
  .map((d) => ({...d}) )

```



```js 
//c) and then use data_filter in the table
Inputs.table(data_radio, {
	layout: "auto",
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
})

```




### no All


```js 
//a) map position_label and unique:true
const lecturerPickCategoryOne = view(
		Inputs.radio(
				lecturersDates.map(d => d.position_label),
				{
				label: "Position type", 
				value: "Lecturer (freelance)", // [no square brackets]
				sort: true, 
				unique: true
				}
		)
)
```



```js 
//b) use it to make the new filter data array
const data_radio_one =
lecturersDates
  .filter((d) => d.position_label === lecturerPickCategoryOne)
  .map((d) => ({...d}) )

```



```js 
//c) and then use data_filter in the table
Inputs.table(data_radio_one, {
	layout: "auto",
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
})

```


### start with All selected



```js
//a)
const lecturerPickAllCategory = view(
		Inputs.radio(
				["All"].concat(lecturersDates.map(d => d.position_label)),
				//lecturersDates.map(d => d.position_label),
				{
				label: "Position type", 
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
lecturersDates
  .filter((d) =>  lecturerPickAllCategory === "All" ||  d.position_label === lecturerPickAllCategory)
  .map((d) => ({...d}) )

```



```js
//c) 
Inputs.table(data_all_radio, {
	layout: "auto",
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
})

```






## WORKING!!! select

how to start with everything selected. 

so it's three steps

a) make select dropdown box: concat "all" map position_label and unique:true

does this work  multiple:true - no. come back to that later if you need it.

```js echo
const lecturerAllCategory = view(
		Inputs.select(
				["All"].concat(lecturersDates.map(d => d.position_label)),
				{
				label: "Position type", 
				sort: true, 
				unique: true, 
				}
				)
		)
```

b) use that to make the new filtering data array



```js echo
const data_select =
lecturersDates
  .filter((d) => lecturerAllCategory === "All" || d.position_label === lecturerAllCategory)
  .map((d) => ({...d}) )

```

c) and then use data_select in the table

```js echo
Inputs.table(data_select, {
	layout: "auto",
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
})

```

and this is what data_filter looks like

```js 
data_select
```




## WORKING original select

with d3.group. probably should be able to rewrite this with map.

have to have a group selected. will probably have some uses somewhere...


```js
const selectPosition = view(   
		Inputs.select(
    d3.group(lecturersDates, (d) => d.position_label ),
    {label: "Position type"}
  ) 
);
```

selectPosition


```js
selectPosition
```


table

```js
Inputs.table(selectPosition, {
	layout: "auto",
	//value:"position_label",
	sort:"year1",
	format: {
		bn_id: id => htl.html`<a href=https://beyond-notability.wikibase.cloud/entity/${id} target=_blank>${id}</a>`,
		"year1": d3.format(".0f")
	},
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
})

```




## WORKING. checkbox for table

using d3.group

i think the docs may be wrong - when they mention keyof and valueof it should be key and value? this seems to work - gives the right values to check. 


```js
//(if you put the const in the same code chunk as table get data is not iterable error)
// when using flat() changes to a "is not a function" error
```


with "key" it starts talking to the inner data. 

before you flatten you have two separate arrays for freelance and Extension

finally to make the table work you have to flatten the two arrays into one.


can you rewrite using map? it may be a bit different from select and radio

can't get it to work; just stick with what you have.

working version using d3.group



```js echo
const checkGroupPosition = view(   
		Inputs.checkbox(
    d3.group(lecturersDates, (d) => d.position_label ),
    {
    label: "Position type",
    key: ["Lecturer (freelance)", "Lecturer (Extension)"] // does need this
    }
  ) 
);
```


table

```js echo

Inputs.table(checkGroupPosition.flat(), {
	layout: "auto",
	sort:"year1",
	format: {
		bn_id: id => htl.html`<a href=https://beyond-notability.wikibase.cloud/entity/${id} target=_blank>${id}</a>`,
		"year1": d3.format(".0f")
	},
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
})


```


## WORKING checkbox for scatterplot


using d3.group and then flat

```js
const checkGroupPosition2 = view(   
		Inputs.checkbox(
    d3.group(lecturersDates, (d) => d.position_label ),
    {
    label: "Position type",
    key: ["Lecturer (freelance)", "Lecturer (Extension)"] // does need this
    }
  ) 
) ;
```



wtf it just works now.

```js
Plot.plot({
	x: {grid:true, label: "yob"},
	y: {label:"year"},
	marks: [
		Plot.dot(
		checkGroupPosition2.flat(),
//		lecturersDates,
		 {
			x: "bn_dob_yr",
			y: "year1",
			fill: "position_label"
		})
	]
})

```

  





## WORKING. search

why is this so much easier? i suppose because you aren't trying to select a particular variable... 

```js
//const search = view( Inputs.search(lecturersDates, {placeholder: "Search..."}) );
```


```js
// Inputs.table(search, {
```





## random things learned so far

unlike the checkbox .flat() doesn't do anything to change the data, because you only get the one array, of the selcted category, to start with.

so adding a [null, array] sort of concatting is too late even if it worked.
you've got to do it before it's selected the category shurely
and you've got to get it to select both categories


so d3.group and map do very different things. d3.group gives you all the data (grouped) *as well as* the category names. map only gives the category names.

so now you have the category names from the data instead of writing out, and you can concat the all/null label.



d3.group DOES NOT WORK FOR RADIO

now the real thing and value: doesn't fucking work.


```js echo
const radioPosition = view(   
		Inputs.radio(
    d3.group(lecturersDates, (d) => d.position_label ),
    {
    label: "Position type",
    value: ["Lecturer (freelance)"], // doesn't fucking select it
    key: ["Lecturer (freelance)", "Lecturer (Extension)"] // ? does need this
    }
  ) 
)
```

null before selecting. then a single array. 
and you get "TypeError: data is null" for the fucking table before selecting ffs. wtf is wrong with this stuff.

```js echo
radioPosition
```

```js echo
Inputs.radio(
    d3.group(lecturersDates, (d) => d.position_label ),
    {
    label: "Position type",
    value: d=>d.position_label=="Lecturer (freelance)", 
    //key: ["Lecturer (freelance)", "Lecturer (Extension)"] // ? does need this
    }
  ) 
```

table

```js
Inputs.table(radioPosition,  {
	layout: "auto",
	//value:"position_label",
	sort:"year1",
	format: {
		bn_id: id => htl.html`<a href=https://beyond-notability.wikibase.cloud/entity/${id} target=_blank>${id}</a>`,
		"year1": d3.format(".0f")
	},
  columns: [
    "bn_id",
    "person_label",
    "position_label",
    "organisation",
    "year1"
  ], 
  header: {
    bn_id: "Id",
    person_label: "name",
    position_label: "position type",
    organisation: "organised by",
    year1: "year"
  }
});
```





## non-working but keep for reference: checkbox with map


attempt to use it with map instead? the three steps. doesn't work.

a) added value (as per radio) to make it check the boxes. but why would you use All here when you can select both anyway?


const checkLecturerAllCategory = view(
		Inputs.checkbox(
		lecturersDates.map(d => d.position_label),
			{
				label: "Position type", 
				sort: true, 
				unique: true, 
				value: ["Lecturer (freelance)", "Lecturer (Extension)"] ,
				key: ["Lecturer (freelance)", "Lecturer (Extension)"] 
				//value: ["All", "Lecturer (freelance)", "Lecturer (Extension)"] 
			}
		)
		);


hmm. this needs to be the array of data, not just the two labels. why doesn't map() work?


b) use that to make the new filtering data array


const data_check =
lecturersDates
  .filter((d) => d.position_label===checkLecturerAllCategory ) // 
  .map((d) => ({...d}) )




c) and then use data_check in the table/plot

????




## TODO select with multiple:true

sort of got it working using multiple:true in select
and then needs flat() in inputs.table. but it starts by showing nothing which isn't really what you want either. even with required:false






```js

// there might be more code in the lecturers inputs md in _stuff though i don't think any of it gets you anywhere new


// this might help with at least part of the problem... https://talk.observablehq.com/t/conditional-filtering-with-inputs-select/8280
// goes with https://observablehq.com/d/60dc128e129abd86 which i might have forked already
// maybe this? https://talk.observablehq.com/t/d3-group-join-on-nytimes-covid-19-data/3366
// or https://talk.observablehq.com/t/nested-input-dynamic-selection/7783

// https://talk.observablehq.com/t/two-questions-about-input-select/6639
```


## combined???


now you can do checkbox and search separately... can you combine them. 
worry about select later (it's probably better suited to categories with more values anyway)

a step too far this week i think!


https://talk.observablehq.com/t/multiple-filter-conditions-on-csv-with-input-select/8889/10

> In Framework you can call view multiple times to declare separate reactive values within the same code block. And the advantage is that these can update independently (rather than with Inputs.form where the entire form updates, potentially causing more downstream evaluation than necessary).

So why not do this:

const species = view(Inputs.checkbox(penguins.map((d) => d.species), {label: "Species", unique: true}));

const island = view(Inputs.checkbox(penguins.map((d) => d.island), {label: "Island", unique: true}));

const sex = view(Inputs.checkbox(penguins.map((d) => d.sex), {label: "Sex", unique: true}));

This also uses the unique option of Inputs.checkbox so you don’t have to do that yourself. (And I prefer to inline the array.map instead of writing the prop helper.)

but then what Mike? ffs.
----

```js
// TODO
// multiple inputs with Form. but got stuck on select. try range then see? i think there might be a separate problem with form, but can't tell atm

//const form = view(Inputs.form({
//  option1: Inputs.checkbox(["A", "B"], {label: "Select some"}),
//  option2: Inputs.range([0, 100], {label: "Amount", step: 1})
//})
//)
```

```js
const lecturerPositionCategory = view(
		Inputs.select(
				["All"].concat(lecturersDates.map(d => d.position_label)),
				{
				label: "Position type", 
				sort: true, 
				unique: true, 
				}
				)
		);

const search = view( 
		Inputs.search(
		lecturersDates, 
		{placeholder: "Search...",
		columns: ["person_label", "organised_label"]}
		) 
	);		
```

----






