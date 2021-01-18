module WordCloud
export wordcloud, shape, ellipse, box, paint, loadmask, process, outline, padding,
    train!, Momentum, generate!, generate_animation!
export getshift, getcenter, setshift!, setcenter!
export record, parsecolor, placement!, rescale!, imageof, bitor, take, ignore, pin, runexample, showexample
export getstate, setstate!, getcolor, getangle, getword, getweight, setcolor!, setangle!, setweight!, setword!,
    getposition, setposition!, getimage, getmask, initword!

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
