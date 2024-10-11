"""
The WordCloud.jl package is a flexible, faithful and efficient word cloud generator in Julia.

```julia
using WordCloud
wc = wordcloud("It's easy to generate a beautiful word cloud.") |> generate!
paint(wc, "wordcloud.svg")
```

Please visit the repository at: <https://github.com/guo-yong-zhi/WordCloud.jl>
"""
module WordCloud
export wordcloud, processtext, html2text, countwords, casemerge!, rescaleweights
export parsecolor, rendertext, shape, ellipse, box, squircle, star, ngon, bezistar, bezingon,
    loadmask, outline, padding, paint, paintsvg, paintcloud, paintsvgcloud, svgstring
export imageof, showmask, showmask!
export record, @record, layout!, rescale!, recolor!, keep, ignore, pin, runexample, showexample, generate!, fit!
export getparameter, setparameter!, hasparameter, getstate, setstate!,
    getscheme, getcolors, getangles, getwords, getweights, setcolors!, setangles!, setwords!, setweights!,
    getpositions, setpositions!, getimages, getsvgimages, setimages!, setsvgimages!, getmask, getsvgmask, 
    getfontsizes, setfontsizes!, getfonts, setfonts!, getmaskcolor, getbackgroundcolor, setbackgroundcolor!, 
    initialize!, configsvgimages!
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
