---
theme: dashboard
title: Motherhood
toc: false
---

# A timeline of childbirth

*This is a work-in-progress data essay*

Alongside collecting information about women's work in archaeology, history, and heritage - including work related activities such as [Education](https://beyond-notability.github.io/bn_framework/education.html) - the [Beyond Notability](https://beyondnotability.org/) project team sought to collect data on biographical 'life events' such as marriage, divorce, and parenthood. When it came time to consider how we might represent these 'life events' as data, our focus turned to ways that enabled us to understand what events like becoming a parent did to women's ability to pursue their work in the fields of archaeology, history, and heritage. And to methods of visualisation that disaggregated women from the whole, that made people and their individual lives easier to see.

The graph on this page shows all the women in [our wikibase](https://beyond-notability.wikibase.cloud/) for whom we have ['had child in'](https://beyond-notability.wikibase.cloud/wiki/Special:WhatLinksHere/Property:P131) data with a known date on which that event occurred. Each woman is represented by a single row. The rows are sorted by date of birth, with the earliest - [Margaret Emily Blaauw](https://beyond-notability.wikibase.cloud/wiki/Item:Q3658), born 1798 - at the top and the latest - [Jacquetta Hawkes](https://beyond-notability.wikibase.cloud/wiki/Item:Q106), born 1910 - at the bottom. The right hand end of the row represents the last piece of data on the graph (rather than a data of death). Each row then shows four types of information:

- The year or years in which each woman had children, with each of these instances represented as a vertical line.
- For women who had more than on child, the periods between having their first and last child are represented by a thicker horizontal line.
- As a diamond, the years (usually not start and end dates) in which we have documentary evidence that each woman ['served on'](https://beyond-notability.wikibase.cloud/wiki/Property:P102) a committee or group, for example that [Sophie Lomas served on the Historical Committee of the Festival of Empire in 1911](https://beyond-notability.wikibase.cloud/wiki/Item:Q960), though that service may have started before that date or ended after that date.
- As a circle, the years (again, usually not start and end dates) in which we are aware that each woman ['held a position'](https://beyond-notability.wikibase.cloud/wiki/Property:P17) in or for an organisation, such as a recorded reference to [Lina Chaworth Musters having held the position of County Collector for The Folklore Society in 1894](https://beyond-notability.wikibase.cloud/wiki/Item:Q998), though - again - that position may have started before that date or ended after that date. Note that this category of data does not include employment at an institution that typically employed people on a formal, longstanding basis (this captured by our ['employed as'](https://beyond-notability.wikibase.cloud/wiki/Property:P105) statements).



```js
//toggle
const checkMothers = view(makeCheckbox) ;
```
<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => hadChildrenAgesChart(hadChildrenAges, lastAges, flatMothers, {width}, plotTitle, plotHeight))}
  </div>
</div>




What does organising and plotting the data in this way suggest?

- First, it foregrounds parenthood as a significant feature in the lives of many women included in our wikibase, and states unambiguously that many women who had children also had active and productive lives in the fields of archaeology, history, and heritage.
- Second, it suggests that few women sat on committees or held positions before the age of 30, and those that did cluster towards the end of the period of our study.
- Third, that after the age of 40 women with children started sitting on committees and holding positions with greater frequency.
- Fourth, that across our period, some women, though few in number, sat on committees or held positions in and around periods when they were having children.
- Fifth, given that a woman wouldn't be included in our wikibase unless they contributed to archaeology, history, and/or heritage, that many women who had children did things other than serving on committees or holding positions, and that these cluster towards the start of the period (that is, if you look at the first eighteen women on the plot, only one - [Mary Anne Everett Green](https://beyond-notability.wikibase.cloud/wiki/Item:Q2092) - has any data recorded in the ['served on'](https://beyond-notability.wikibase.cloud/wiki/Property:P102) or ['held a position'](https://beyond-notability.wikibase.cloud/wiki/Property:P17) fields). [Emily Winifred Allen](https://beyond-notability.wikibase.cloud/wiki/Item:Q488) was an active contributor to the life of the Cambrian Archaeological Association, speaking at meetings and exhibiting artefacts. [Fenella Armytage](https://beyond-notability.wikibase.cloud/wiki/Item:Q316) corresponded with the Royal Archaeological Institute. [Charlotte Latham](https://beyond-notability.wikibase.cloud/wiki/Item:Q945) collected folklore, published in the Folklore Society's journal, and supplied information to scholars working in the field.
- And sixth, it opens up questions that go beyond the data, back into the archive, back into particular cases and circumstances. Given that many of the first eighteen women on the plot were of means asks us to consider how was socio-economic status a factor in women working? (and did these women's self-fashion construct activities as something distinct from 'work'?) Did different work to fit around children? How did cultures created by the marriage bar - even if it didn't apply to many contexts these women worked in - shape what work women did and didn't do?

That is, visualising this particular combination of data and interpreting what we see opens out the scope of enquiry rather than providing a settled representation of how in this period motherhood related to work in the fields of archaeology, history, and heritage. And just as importantly, the interpretation draws us towards a series of caveats - health warnings - required so as to not misread the visualistion and the underlying data it contains.

- First, and most obviously, the data selected is the data that is interpreted. Add in some more data, such as instances of when women '[spoke at](https://beyond-notability.wikibase.cloud/wiki/Property:P23)' a meeting, conference, or congress and - as you can see above - the patterns change, with few women recorded as speaking until later in life, usually after having served on a committee or held a role. In turn, our interpretations change.
- Second, that we have recorded 'had child in' data for fewer than 10% of the women in the wikibase: [72](https://beyond-notability.wikibase.cloud/w/index.php?title=Special:WhatLinksHere/Property:P131&limit=500) women out of more than 900. That cannot be all the possible data, and is likely a sample skewed towards those women who were more notable and whose activities are recorded across multiple sources (for example, there are [56 women about whom we have recorded fewer than 5 pieces of information](https://tinyurl.com/2aryjrp7), none of whom have ['had child in'](https://beyond-notability.wikibase.cloud/wiki/Property:P131) associated with them). Even for women in our wikibase with notable husbands, we often find that little accessible information exists about their marital life, and - in particular - Wikipedia entries for these notable husbands frequently do not mention the women to whom they were married: for example, the Wikipedia entry for [Gerard Clauson](https://en.wikipedia.org/wiki/Gerard_Clauson) does not mention his marriage to [Honor Clauson](https://beyond-notability.wikibase.cloud/wiki/Item:Q3414). And similar patterns are true of women in our database with notable fathers: for example, [Frederick Grafton](https://en.wikipedia.org/wiki/Frederick_William_Grafton)'s daughter [Emily Grafton](https://beyond-notability.wikibase.cloud/wiki/Item:Q454) is not mentioned in his Wikipedia entry. And for people born after 1911, dates of birth are tricky to find as the 1911 Census is the last census we have easy access to. For data on childbirth after that period we have depended on sources like the Oxford Dictionary of National Biography, which again skews to 'notable' people. The data we have on childbirth is, then, partial at best.
- Third, this cannot be all the data out there about service on committees, positions held with bodies, etc - given the archives we have consulted, regional committees and less well regarded roles less likely to be captured in our data.
- Fourth, a data point for a date on which a woman 'had' a child cannot capture the fact that parenthood was not faced equally. Some people had help. Some children got unwell. Some parents got unwell. Some births were harder than others. Some children were adopted. Some people took on significant caring responsibilities that amounted to the labour of parenthood without ever 'having' children. And the dynamics of parenthood changed across our period and between regions. This was the period in British History in which [the concept of the working mother both emerged and was transformed](https://www.bloomsbury.com/uk/double-lives-9781408870761/). All data points cannot be treated equally.
- Fifth, more conceptually, if Beyond Notability had sought to recover the lives of men's work in archaeology, history, and heritage, would we have even thought to plot the relationship between their work and the years in which they 'had' children? Would we have thought of parenthood as a life event for them? Would we have thought to create visualisations that anchored their lives around their fertility and/or caring responsibilities? Probably not.

This might seem a bit of a downer to end on. But - we think - there is considerable merit to our approach to data capture. In particular by combining 'work' and 'life events' we open up linked data biography to asking better questions about the lifecourse as it relates to people of all genders. For example, in a forthcoming paper we argue that whilst the prevailing model for representing the life course as linked data - that is, the [Wikidata](https://www.wikidata.org/) data model - is adequate for representing the temporal relationship between most events across the lifecourse, it does a poor job with parenthood. That is, unless a person had a child who was themselves sufficiently notable to warrant a Wikidata entry, and in turn a date of birth, all other acts of childbirth on Wikidata are represented by [‘number of children’](https://www.wikidata.org/wiki/Property:P1971), a property that captures the number of children a person had – or has had so far – in their lifetime. This perspective disables the ability to see across and through life events. This in part can be explained by what is achievable through community and voluntary production of data using a platform such as Wikidata: a statement listing the number of children someone had will take considerably less time – and research – to implement than multiple statements recording the dates on which multiple children were born. But Wikidata is a central node within contemporary knowledge infrastructure. And by taking an atemporal viewpoint in some cases, whilst capturing granular temporal information in others, the model opens limited space for the rich, subtle, and granular conceptual changes required when researching and representing complex historical phenomena. This complexity is what our wikibase has sought to retain. As a result motherhood - where we are aware of it - relates to and is entangled other events in the lifecourse, with work in archaeology, history, and heritage; whatever that 'work' meant.

## ignore this

Here is an inline note.^[Inlines notes are easier to write, since
you don't have to pick an identifier and move down to type the
note.]

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.[^1] Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.[^2] 

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 


[^1]: [Observable Framework Markdown](https://observablehq.com/framework/markdown)
[^2]: [Footnote extension for OF](https://observablehq.observablehq.cloud/framework-example-markdown-it-footnote/)

```js
// editables

const plotTitle = "The ages at which BN women had children, sorted by mothers' dates of birth";

const plotHeight = 1500;
```

```js
// Import components
import {hadChildrenAgesChart} from "./components/mothers.js";
```



```js
//load data [dataloader uses zip method to create multiple objects]

const hadChildrenAges = FileAttachment("data/l_women_children/had-children-ages.csv").csv({typed: true});

//const workServedYearsWithChildren = FileAttachment("data/l_women_children/work-served-years-with-children.csv").csv({typed:true});

const workServedSpokeYearsWithChildren = FileAttachment("data/l_women_children/work-served-years-with-children.csv").csv({typed:true})

const lastAges = FileAttachment("data/l_women_children/last-ages-all.csv").csv({typed:true});

```



```js
const groupMothers = d3.group(workServedSpokeYearsWithChildren, (d) => d.activity );
```

```js
// make checkbox
const makeCheckbox =
 		Inputs.checkbox(
 		groupMothers,
    //d3.group(workServedSpokeYearsWithChildren, (d) => d.activity ),
    {
    label: "Activity type",
    key: ["work", "served", "spoke"] 
    }
  ) ;

```
```js
const flatMothers = checkMothers.flat();
```

