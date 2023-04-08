"""
The WordCloud package is a flexible, fast and exact word cloud generator in julia.

```julia
using WordCloud
wc = wordcloud("It's easy to generate word clouds") |> generate!
paint(wc, "wordcloud.svg")
```

Have a look at the repository: https://github.com/guo-yong-zhi/WordCloud.jl
"""
module WordCloud
export wordcloud, processtext, html2text, countwords, lemmatize, lemmatize!, casemerge!, rescaleweights
export parsecolor, rendertext, shape, ellipse, box, squircle, star, ngon, bezistar, bezingon,
    loadmask, outline, padding, paint, paintsvg, svgstring
export imageof, showmask, showmask!
export record, @record, placewords!, rescale!, recolor!, take, keep, ignore, pin, runexample, showexample, generate!, fit!
export getparameter, setparameter!, hasparameter, getstate, setstate!,
    getcolors, getangles, getwords, getweights, setcolors!, setangles!, setwords!, setweights!,
    getpositions, setpositions!, getimages, getsvgimages, setimages!, setsvgimages!, getmask, getsvgmask, 
    getfontsizes, setfontsizes!, getfonts, setfonts!, getmaskcolor, getbackgroundcolor, setbackgroundcolor!, 
    initword!, initwords!
export getshift, getcenter, setshift!, setcenter!

using Stuffing

include("rendering.jl")
include("textprocessing.jl")
using .Render
using .TextProcessing

include("wc-class.jl")
include("wc-method.jl")
include("wc-helper.jl")
include("strategy.jl") 
include("artist.jl") 
include("utils.jl")
end
