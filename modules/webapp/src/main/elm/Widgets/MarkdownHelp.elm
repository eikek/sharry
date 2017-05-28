module Widgets.MarkdownHelp exposing (..)

import Html exposing (Html)
import Markdown

-- based on https://gist.github.com/jonschlinkert/5854601

helpText: String
helpText = """# Typography

## Headings

Headings from 1 to 6 are constructed with a `#` for each level:

```markdown
# heading 1
## heading 2
### heading 3
#### heading 4
##### heading 5
###### heading 6
```

renders to

# heading 1
## heading 2
### heading 3
#### heading 4
##### heading 5
###### heading 6


## Horizontal Rules

A "thematic break" between paragraph-level elements can be created
with any of the following:

* `___`: three consecutive underscores
* `---`: three consecutive dashes
* `***`: three consecutive asterisks

renders to:

___

---

***


## Emphasis

### Bold

For emphasizing a snippet of text with a heavier font-weight.

The following snippet of text is **rendered as bold text**.

``` markdown
**rendered as bold text**
```
renders to:

**rendered as bold text**


### Italics
For emphasizing a snippet of text with italics.

The following snippet of text is _rendered as italicized text_.

``` markdown
_rendered as italicized text_
```

renders to:

_rendered as italicized text_

### strikethrough
In GFM you can do strickthroughs.

``` markdown
~~Strike through this text.~~
```
Which renders to:

~~Strike through this text.~~


## Blockquotes

For quoting blocks of content from another source within your
document. Add `>` before any text you want to quote.

```markdown
> Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer posuere erat a ante.
```

Renders to:

> Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer posuere erat a ante.


Blockquotes can also be nested:

``` markdown
> Donec massa lacus, ultricies a ullamcorper in, fermentum sed augue.
Nunc augue augue, aliquam non hendrerit ac, commodo vel nisi.
>> Sed adipiscing elit vitae augue consectetur a gravida nunc vehicula. Donec auctor
odio non est accumsan facilisis. Aliquam id turpis in dolor tincidunt mollis ac eu diam.
>>> Donec massa lacus, ultricies a ullamcorper in, fermentum sed augue.
Nunc augue augue, aliquam non hendrerit ac, commodo vel nisi.
```

Renders to:

> Donec massa lacus, ultricies a ullamcorper in, fermentum sed augue.
Nunc augue augue, aliquam non hendrerit ac, commodo vel nisi.
>> Sed adipiscing elit vitae augue consectetur a gravida nunc vehicula. Donec auctor
odio non est accumsan facilisis. Aliquam id turpis in dolor tincidunt mollis ac eu diam.
>>> Donec massa lacus, ultricies a ullamcorper in, fermentum sed augue.
Nunc augue augue, aliquam non hendrerit ac, commodo vel nisi.


## Lists

### Unordered

A list of items in which the order of the items does not explicitly
matter.

You may use any of the following symbols to denote bullets for each
list item:

```markdown
* valid bullet
- valid bullet
+ valid bullet
```

For example

``` markdown
+ Lorem ipsum dolor sit amet
+ Consectetur adipiscing elit
+ Integer molestie lorem at massa
+ Facilisis in pretium nisl aliquet
+ Nulla volutpat aliquam velit
  - Phasellus iaculis neque
  - Purus sodales ultricies
  - Vestibulum laoreet porttitor sem
  - Ac tristique libero volutpat at
+ Faucibus porta lacus fringilla vel
+ Aenean sit amet erat nunc
+ Eget porttitor lorem
```
Renders to:

+ Lorem ipsum dolor sit amet
+ Consectetur adipiscing elit
+ Integer molestie lorem at massa
+ Facilisis in pretium nisl aliquet
+ Nulla volutpat aliquam velit
  - Phasellus iaculis neque
  - Purus sodales ultricies
  - Vestibulum laoreet porttitor sem
  - Ac tristique libero volutpat at
+ Faucibus porta lacus fringilla vel
+ Aenean sit amet erat nunc
+ Eget porttitor lorem


### Ordered

A list of items in which the order of items does explicitly matter.

``` markdown
1. Lorem ipsum dolor sit amet
2. Consectetur adipiscing elit
3. Integer molestie lorem at massa
4. Facilisis in pretium nisl aliquet
5. Nulla volutpat aliquam velit
6. Faucibus porta lacus fringilla vel
7. Aenean sit amet erat nunc
8. Eget porttitor lorem
```
Renders to:

1. Lorem ipsum dolor sit amet
2. Consectetur adipiscing elit
3. Integer molestie lorem at massa
4. Facilisis in pretium nisl aliquet
5. Nulla volutpat aliquam velit
6. Faucibus porta lacus fringilla vel
7. Aenean sit amet erat nunc
8. Eget porttitor lorem


**TIP**: If you just use `1.` for each number, it will automatically
  number each item. For example:

``` markdown
1. Lorem ipsum dolor sit amet
1. Consectetur adipiscing elit
1. Integer molestie lorem at massa
1. Facilisis in pretium nisl aliquet
1. Nulla volutpat aliquam velit
1. Faucibus porta lacus fringilla vel
1. Aenean sit amet erat nunc
1. Eget porttitor lorem
```

Renders to:

1. Lorem ipsum dolor sit amet
2. Consectetur adipiscing elit
3. Integer molestie lorem at massa
4. Facilisis in pretium nisl aliquet
5. Nulla volutpat aliquam velit
6. Faucibus porta lacus fringilla vel
7. Aenean sit amet erat nunc
8. Eget porttitor lorem


## Code

### Inline code

Wrap inline snippets of code with `` ` ``.

``` html
For example, `<section></section>` should be wrapped as "inline".
```

renders to

For example, `<section></section>` should be wrapped as "inline".


### Indented code

Or indent several lines of code by at least four spaces, as in:

``` js
    // Some comments
    line 1 of code
    line 2 of code
    line 3 of code
```

    // Some comments
    line 1 of code
    line 2 of code
    line 3 of code


### Block code "fences"

Use "fences"  ```` ``` ```` to block in multiple lines of code.

<pre>
```
Sample text here...
```
</pre>


```
Sample text here...
```


## Links

### Basic link

``` markdown
[Sharry](https://github.com/eikek/sharry)
```

Renders to (hover over the link, there is no tooltip):

[Sharry](https://github.com/eikek/sharry)


### Add a title

``` markdown
[Sharry](https://github.com/eikek/sharry/ "Visit Sharry!")
```

Renders to (hover over the link, there should be a tooltip):

[Sharry](https://github.com/eikek/sharry/ "Visit Sharry!")


## Images

Images have a similar syntax to links but include a preceding
exclamation point.

``` markdown
![Minion](http://octodex.github.com/images/minion.png)
```
![Minion](http://octodex.github.com/images/minion.png)

or

``` markdown
![Alt text](http://octodex.github.com/images/stormtroopocat.jpg "The Stormtroopocat")
```
![Alt text](http://octodex.github.com/images/stormtroopocat.jpg "The Stormtroopocat")

Like links, Images also have a footnote style syntax

``` markdown
![Alt text][id]
```
![Alt text][id]

With a reference later in the document defining the URL location:

[id]: http://octodex.github.com/images/dojocat.jpg  "The Dojocat"


    [id]: http://octodex.github.com/images/dojocat.jpg  "The Dojocat"
"""

helpTextHtml: Html msg
helpTextHtml =
    Markdown.toHtml [] helpText
