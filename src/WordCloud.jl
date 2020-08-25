module WordCloud
export wordcloud, shape, ellipse, box, paint, loadmask
export record, parsecolor, train!, Momentum, placement!, generate, generate_animation, imageof, bitor, process
include("qtree.jl")
include("rendering.jl")
include("nlp.jl")
using .Render
using .NLP
include("train.jl")
include("interface.jl")
include("strategy.jl")
include("utils.jl")

end
