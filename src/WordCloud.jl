module WordCloud
export wordcloud, processtext, html2text, countwords, filtcount, filtcount, shape, ellipse, box, loadmask, outline, padding, paint, paintsvg,
    train!, Momentum, generate!, generate_animation!
export getshift, getcenter, setshift!, setcenter!
export record, parsecolor, placement!, rescale!, imageof, bitor, take, ignore, pin, runexample, showexample
export getstate, setstate!, getcolors, getangles, getwords, getweights, setcolors!, setangles!, setweights!, setwords!,
    getpositions, setpositions!, getimages, getmask, getfontsizes, setfontsizes!, getfonts, setfonts!, initword!, initwords!

include("qtree.jl")
include("rendering.jl")
include("textprocessing.jl")
using .Render
using .QTree
using .TextProcessing
include("train.jl")
include("interface.jl")
include("strategy.jl") 
include("utils.jl")

end
