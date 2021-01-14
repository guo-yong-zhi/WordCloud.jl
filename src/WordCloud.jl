module WordCloud
export wordcloud, shape, ellipse, box, paint, loadmask, process, outline, padding,
    train!, Momentum, generate!, generate_animation!
export record, parsecolor, placement!, imageof, bitor, take, ignore, pin, runexample, showexample
export getstate, getcolor, getangle, getweight, setcolor!, setangle!, setweight!, 
    getposition, setposition!, getimage, initword!

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
