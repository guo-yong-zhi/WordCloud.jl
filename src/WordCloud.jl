module WordCloud
export wordcloud, processtext, html2text, countwords, lemmatize, lemmatize!, casemerge!
export parsecolor, rendertext, shape, ellipse, box, squircle, loadmask, outline, padding, paint, paintsvg, svgstring
export imageof, showmask, showmask!
export record, placement!, rescale!, recolor!, take, keep, ignore, pin, runexample, showexample, 
    generate!, generate_animation!, fit!
export getparameter, setparameter!, hasparameter, getstate, setstate!,
    getcolors, getangles, getwords, getweights, setcolors!, setangles!, setwords!, setweights!,
    getpositions, setpositions!, getimages, getsvgimages, setimages!, setsvgimages!, getmask, getsvgmask, 
    getfontsizes, setfontsizes!, getfonts, setfonts!, initimage!, initimages!
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
include("utils.jl")
end
