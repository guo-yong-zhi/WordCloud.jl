using WordCloud
using Random
#md# ![butterfly.png](https://raw.githubusercontent.com/guo-yong-zhi/WordCloud.jl/master/res/butterfly.png) 
istrans = c -> maximum(c[1:3]) * (c[4] / 255) < 128
background, mask = loadmask(pkgdir(WordCloud) * "/res/butterfly.png", transparent=istrans, return_bitmask=true)
showmask(background, mask, highlight=(1, 0, 0, 0.7))
#md# `showmask` might be helpful to find a proper `istrans` function. `using Images` may be required.
words = [randstring(1) for i in 1:600]
weights = randexp(length(words)) .+ 1

wc = wordcloud(
    words, weights,
    mask=background,
    maskcolor=:original,
    colors="LimeGreen",
    angles=-30,
    density=0.4,
    transparent=istrans,
    spacing=1,
) |> generate!;
background2 = loadmask(getmask(wc), color=0.99)
#md# ## average style
recolor!(wc, style=:average)
avgimg = paint(wc, background=background2)
#md# ## clipping style
recolor!(wc, style=:clipping)
clipimg = paint(wc, background=background2)
#md# ## blending style
recolor!(wc, style=:reset)
recolor!(wc, style=:blending, alpha=0.5) # blending with origin color - LimeGreen
blendimg = paint(wc, background=background2)
#md# ## mix style
#md# styles can also be mixed
# setcolors!(wc, :, "LimeGreen")
recolor!(wc, style=:reset)
recolor!(wc, 1:3:length(words), style=:average) # vector index is ok
recolor!(wc, 2:3:length(words), style=:clipping)
recolor!(wc, 3:3:length(words), style=:blending)
setcolors!(wc, 200:250, "black")
recolor!(wc, 200:250, style=:reset)
setcolors!(wc, 1, "black")
recolor!(wc, 1, style=:reset) # single index is ok
mixstyleimg = paint(wc, background=background2)
#md# 
h, w = size(avgimg)
lw = 21
lc = eltype(avgimg)(parsecolor(0.1))
vbar = zeros(eltype(avgimg), (h, lw))
hbar = zeros(eltype(avgimg), (lw, 2w + lw))
vbar[:, lw ÷ 2 + 1] .= lc
hbar[lw ÷ 2 + 1, :] .= lc
image = [avgimg vbar clipimg; hbar; blendimg vbar mixstyleimg]
println("results are saved to recolor.png")
WordCloud.save("recolor.png", image)
wc
#eval# runexample(:recolor)
#md# ![recolor](recolor.png)  