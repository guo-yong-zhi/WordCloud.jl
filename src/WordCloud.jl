module WordCloud
export wordcloud, processtext, html2text, countwords, filtcount
export parsecolor, rendertext, shape, ellipse, box, loadmask, outline, padding, paint, paintsvg, svgstring
export train!, Momentum, generate!, generate_animation!
export getshift, getcenter, setshift!, setcenter!
export record, placement!, rescale!, take, keep, ignore, pin, runexample, showexample, imageof, bitor
export getcolors, getangles, getwords, getweights, setcolors!, setangles!, setwords!, setweights!,
    getpositions, setpositions!, getimages, getsvgimages, setimages!, setsvgimages!, getmask, getsvgmask, 
    getfontsizes, setfontsizes!, getfonts, setfonts!, getstate, setstate!, initimage!, initimages!

include("rendering.jl")
include("qtree.jl")
include("train.jl")
include("textprocessing.jl")
using .Render
using .QTree
using .Trainer
using .TextProcessing

include("wc-class.jl")
include("wc-method.jl")
include("wc-helper.jl")
include("strategy.jl") 
include("utils.jl")
end
