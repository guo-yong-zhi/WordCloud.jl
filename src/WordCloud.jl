module WordCloud
export wordcloud, shape, ellipse, box, paint, loadmaskimg
export record, parsecolor, train!, Momentum, placement!, generate, generate_animation,imageof,bitor拉人个人
include("qtree.jl")
include("rendering.jl")
using .Render
using .QTree
include("train.jl")
include("interface.jl")
include("strategy.jl")
include("utils.jl")

end
