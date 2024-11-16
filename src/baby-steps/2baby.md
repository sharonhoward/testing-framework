---
theme: dashboard
title: baby steps ffs
toc: false
---

# one step at a time...


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
//columns
lecturersDates.columns
```

all the data

```js echo
//all the data
lecturersDates
```



## how to manipulate the data?

    lecturersDates.map((d) => d.bn_id) 

```js
lecturersDates.map((d) => d.bn_id)
```

    d3.group(lecturersDates, (d) => d.bn_id )
    
```js
d3.group(lecturersDates, (d) => d.bn_id )
```

does the (d) make a difference? i can't see any, so what does it do? (A. below)

    d3.group(lecturersDates, d => d.bn_id)

```js
d3.group(lecturersDates, d => d.bn_id)
```

so you can see the difference between d3.group and array.map. but then what?

seems possible that you would use d3.group/.map in different places inside a plot/input view?  so d3.group goes in the data bit whereas map might go further inside... ?


select columns in map


```js echo
lecturersDates.map(d => ({
			id: d.bn_id, 
			//person: d.personLabel,
			name: d["person_label"],
			position: d.position_label
			}) 
) //; doesn't work if you have a semicolon...
```


and to get everything without specifying "..."

```js echo
lecturersDates.map(d => ({...d }) )
```


## Learn just enough JS lesson

https://observablehq.com/d/7c6978556abfd9c5  (forked)

https://observablehq.com/@observablehq/learn-javascript-introduction (original)


### objects

    myArrayOfObjects[0]

```js

lecturersDates[0]
```

> Array.filter() allows you to filter an array based on some condition.

    [1, 2, 3, 4, 5].filter(d => d < 3)
    
```js
[1, 2, 3, 4, 5].filter(d => d < 3)
```

> myData.filter(d => d.city == 'Denver')

    lecturersDates.filter(d => d.position_label =="Lecturer (freelance)")


```js 
lecturersDates.filter(d => d.position_label =="Lecturer (freelance)")
```

> Array.map() is another very useful method for Array that allows you create a new array, populated with whatever results you specify.


    myNewArray = myData.map(d => d.name)
       

```js echo
const myData = [
  {name: 'Paul', city: 'Denver'},
  {name: 'Robert', city: 'Denver'},
  {name: 'Ian', city: 'Boston'},
  {name: 'Cobus', city: 'Boston'},
  {name: 'Ayodele', city: 'New York'},
  {name: 'Mike', city: 'New York'},
]
const myNewArray = myData.map(d => d.name)
```



```js
myNewArray
```

> If you want to copy all the values in your array, and add some new ones, you can use the {...} notation.  

    myData.map(d => ({...d, date: new Date() }) )
    
    
```js echo
const myNewerArray = myData.map(d => ({...d, date: new Date() }) )
```

```js
myNewerArray
```

### functions


two ways to write functions

"modern"... this apparently needs const in OF.
[without throws a syntax error Assignment to external variable.]

```js echo
const myModernFunctionWithParameters = (firstName, lastName) => {
  return `My first name is ${firstName}, and my last name is ${lastName}.`
}
```

now it seems to work

```js echo
myModernFunctionWithParameters("S", "H")
```


if you only have one param do you need (brackets) ? doesn't error, does it work.


```js echo
const myFirstnameFunctionWithParameters = firstName => {
  return `My first name is ${firstName}.`
}
```

yes. so i think the answer to d vs (d) is that if there's only one parameter you may not need (brackets) in this form but it won't hurt to use them; but if you have more than one parameter you definitely need them. if you use the older function(d) {} form you'll also always need them.


```js echo
myFirstnameFunctionWithParameters("Sharon")
```

older form... no error, does it work?


```js echo
function myFunctionWithParameters(firstName, lastName) {
  return `My first name is ${firstName}, and my last name is ${lastName}.`
}
```

yes. (the parameter strings need to be quoted)


```js echo
myFunctionWithParameters("S", "H")
```

nb d vs (d) in the examples

[1, 2, 3, 4, 5].filter(d => d < 3)

older method

[1, 2, 3, 4, 5].filter(function(d) { return d < 3 })


## try something...

drill down


```js echo

const categories = ["country", "age_group"] 

const data = [
  {category: "country", sub_category: "USA"},
  {category: "country", sub_category: "Canada"},
  {category: "country", sub_category: "Mexico"},
  {category: "age_group", sub_category: "1–10"},
  {category: "age_group", sub_category: "11–30"},
  {category: "age_group", sub_category: "31–60"},
]

```


```js echo
const category = view(Inputs.select(categories, {label: "Categories"} ));

//   viewof category = Inputs.select(categories, { label: "Categories" }) // Observable notebook version. 
```
   
   
```js echo
const sub_category = view(Inputs.select(
  data
    .filter((d) => d.category === category)  
    .map((d) => d.sub_category),
  { label: "Sub-category" }
)
)
```

default to no filter


```js echo
const category2 = view(Inputs.select([null, ...categories], { label: "Categories" }))
```

the filter... can i put this in a table? make it a const and put it in a table?

look at this model again
    lecturersDates.map(d => ({id: d.bn_id, position: d.position_label	}) ) 


```js echo
const data_filtered =
data
  .filter((d) => category2 === null || d.category === category2)
  .map((d) => ({subcat: d.sub_category, cat:d.category}) )

```

```js echo
data_filtered
```

yes! can i have category as well? yes!!
ok it doesn't make any sense but still you did it :-D

```js
Inputs.table(data_filtered, {
	layout: "auto",
  columns: [
    "subcat",
    "cat"
  ]
})

```




## where i'm at with inputs

- I can get data using d3.group but I can't concat an "All"

OR

- I can concat "All" to .map but it doesn't fucking get the data


colors example

value: for selection works fine.

```js echo
const color = view(Inputs.radio(["red", "green", "blue"], {label: "color", value: "red"}));
```

${color}

the array looks the same as the lecturers one below...  but that can be misleading perhaps...

```js echo
["red", "green", "blue"]
```

now the real thing and value: doesn't fucking work with d3.group or map

d3.group

```js echo

const radioPosition = view(Inputs.radio(
    d3.group(lecturersDates, (d) => d.position_label ),
    //lecturersDates.map(d => d.position_label),
    {
      label: "Position type",
      unique: true,
      //value: ["Lecturer (freelance)"], // doesn't fucking select it WHY
      //key: ["Lecturer (freelance)", "Lecturer (Extension)"] // ? doesnt need this?
    }
  ) 
);
```




```js echo
radioPosition
```

- null before selecting. 
- then a single array. 
- plus "TypeError: data is null" for the fucking table before selecting ffs.

map. still not selected. 

```js echo
const radioPositionMap = view(Inputs.radio(
    lecturersDates.map(d => d.position_label) ,
    {
      label: "Position type",
      unique: true,
      value: ["Lecturer (freelance)"], // doesn't fucking select it WHY
      //key: ["Lecturer (freelance)", "Lecturer (Extension)"] // ? does need this
    }
  ) 
);
```


```js echo
radioPositionMap
```

- null before selecting
- then the label only


using map

```js echo
lecturersDates.map(d => d.position_label)
```

this gets all the data. but idk if it understands aything different about it from the original

```js echo
lecturersDates.map(d => ({...d }) )
```


```js echo
const lecturersDatesMap = lecturersDates.map(d => ({...d }) );

```


```js echo
lecturersDates == lecturersDatesMap
```

looks like there's *something* different...


## the working checkbox

what's different about it? why can you get it working but not other things?

looked at source code, dunno.

using d3.group

docs mention keyof and valueof but should be key and value? 


```js echo
const checkPosition = view(   
		Inputs.checkbox(
    //lecturersDates.map((d) => d.position_label),
    d3.group(lecturersDates, (d) => d.position_label ),
    {
     //unique:true,
    label: "Position type",
    key: ["Lecturer (freelance)", "Lecturer (Extension)"] // does need this
    }
  ) 
);
```

with "key" it starts talking to the inner data. but that doesn't seem to work with .map

before you flatten you have two separate arrays for freelance and Extension

```js 
checkPosition
```

finally to make the table work you have to flatten the two arrays into one.

```js 
//checkPosition.flat()
```

table

```js echo

Inputs.table(checkPosition.flat(), {
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






## make categories

do you make an array with just the two categories first? 

does it need to be a const in this context? i think so.


```js echo
const mycategories = ["Lecturer (freelance)", "Lecturer (Extension)"] 
```

```js
mycategories
```


looks like there are two ways to concat the null - results seem to be the same


```js
const mycategory2 = Inputs.select([null, ...mycategories], {label: "Categories"})

const mycategory3 = Inputs.select([null].concat(mycategories), {label: "Categories"})
```

mycategory2  using [null, ... mycategories]


```js

mycategory2
```

```js

[null, ...mycategories]
```

category3  using [null].concat(categories)  

```js

mycategory3
```

```js

[null].concat(mycategories)
```




## Questions

added these here because i think both Qs are relevant to your problems...

Q: with checkbox and select (and possibly others), if the const for the input/view is in the same chunk as the table you get a data is not iterable error. would be nice to understand why.

I think it's to do with promises. https://observablehq.com/framework/reactivity

> Implicit await only applies across code blocks, not *within* a code block. 
> Within a code block, a promise is just a promise.


checkbox

Q got it working, but why doesn't .map work when it seems as though it should? leave it since you have a working solution...
atm just get the two labels and it isn't talking to the inner data.
key: doesn't do anything. value: pre-selects the two...


```js
const checkPositionMap = view(   
		Inputs.checkbox(
    lecturersDates.map((d) => d.position_label), // ????
    {
    unique:true,
    label: "Position type",
    value: ["Lecturer (freelance)", "Lecturer (Extension)"] // 
    }
  ) 
);
```








