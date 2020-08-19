module WordCloud
export wordcloud, shape, ellipse, box, paint, loadmaskimg
export record, parsecolor, train!, Momentum, placement!, generate, generate_animation,imageof
include("qtree.jl")
include("rendering.jl")
include("strategy.jl")
using .Render
using .QTree
include("train.jl")
include("interface.jl")
include("utils.jl")

end
