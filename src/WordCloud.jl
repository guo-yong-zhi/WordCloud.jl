module WordCloud
export wordcloud, shape, ellipse, box, paint, loadmask, process,
    train!, Momentum, generate!, generate_animation!, getposition
export record, parsecolor, placement!, imageof, bitor, take
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
