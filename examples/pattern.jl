#md# The [engine](https://github.com/guo-yong-zhi/Stuffing.jl) is designed for general purpose, so the outputs don't have to be text, and shapes are OK
using WordCloud

sc = WordCloud.randomscheme() |> unique # unique makes Int -> Vector{Int}
l = 200
wc = wordcloud(
    repeat(["placeholder"], l), repeat([1], l), 
    mask=shape(box, 400, 300, color=WordCloud.randommaskcolor(sc)),
    masksize=:original,
    state=identity)
#md# * `words` & `weights` are just placeholders  
#md# * style arguments like `colors`, `angles` and `density` have no effect  
#md# 
#md# And, you should manually initialize images for the placeholders, instead of calling `initwords!`  
dens = 0.6
sz = 3expm1.(rand(l)) .+ 1
sz ./= √(sum(π * (sz ./ 2).^2 ./ dens) / prod(size(wc.mask))) # set a proper size according to the density
## svg version
# shapes = [shape(ellipse, round(sz[i]), round(sz[i]), color=rand(sc)) for i in 1:l]
# setsvgimages!(wc, :, shapes)
## bitmap version
shapes = WordCloud.tobitmap.([shape(ellipse, round(sz[i]), round(sz[i]), color=rand(sc)) for i in 1:l])
setimages!(wc, :, shapes)

setstate!(wc, :initwords!) # set the state flag after manual initialization
@record "pattern_animation" overwrite=true generate!(wc, retry=1, optimiser=WordCloud.Momentum(η=1/8))
# generate!(wc, retry=1, optimiser=WordCloud.Momentum(η=1/8)) # turn off rescale attempts. manually set images can't be rescaled
println("results are saved to pattern.png")
paint(wc, "pattern.png")
wc
#eval# runexample(:pattern)
#md# ![](pattern.png)  
#md# ![](pattern_animation/animation.gif)  