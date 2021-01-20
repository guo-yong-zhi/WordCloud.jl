module WordCloud
export wordcloud, shape, ellipse, box, loadmask, processtext, outline, padding, paint, paintsvg,
    train!, Momentum, generate!, generate_animation!
export getshift, getcenter, setshift!, setcenter!
export record, parsecolor, placement!, rescale!, imageof, bitor, take, ignore, pin, runexample, showexample
export getstate, setstate!, getcolors, getangles, getwords, getweights, setcolors!, setangles!, setweights!, setwords!,
    getpositions, setpositions!, getimages, getmask, getfontsizes, initword!, initwords!

include("qtree.jl")
include("rendering.jl")
include("nlp.jl")
using .Render
using .QTree
using .NLP
include("train.jl")
include("interface.jl")
include("strategy.jl") 
include("utils.jl")

end
