using WordCloud
using Random

background = loadmask(pkgdir(WordCloud)*"/res/butterfly.png")
istrans = c->maximum(c[1:3])*(c[4]/255)<128
mask = WordCloud.imagemask(background, istrans)
showmask(background, mask, highlight=(1,0,0,0.7))
#md# `showmask` might be helpful to find a proper `istrans` function
words = [randstring(1) for i in 1:600]
weights = randexp(length(words)) .+ 1

wc = wordcloud(
    words, weights,
    mask = background,
    colors = "LimeGreen",
    angles = -30,
    density = 0.45,
    transparentcolor = istrans,
    spacing = 1,
) |> generate!;
#md# ## average style
recolor!(wc, style=:average)
avgimg = paint(wc, background=loadmask(background, color=0.99))
#md# ## clipping style
recolor!(wc, style=:clipping)
clipimg = paint(wc, background=loadmask(background, color=0.99))
#md# ## blending style
recolor!(wc, style=:reset)
recolor!(wc, style=:blending, alpha=0.5) #blending with origin color - LimeGreen
blendimg = paint(wc, background=loadmask(background, color=0.99))
#md# ## mix style
#md# styles can also be mixed
# setcolors!(wc, :, "LimeGreen")
recolor!(wc, style=:reset)
recolor!(wc, 1:3:length(words), style=:average) #vector index is ok
recolor!(wc, 2:3:length(words), style=:clipping)
recolor!(wc, 3:3:length(words), style=:blending)
setcolors!(wc, 200:250, "black")
recolor!(wc, 200:250, style=:reset)
setcolors!(wc, 1, "black")
recolor!(wc, 1, style=:reset) #single index is ok
mixstyleimg = paint(wc, background=loadmask(background, color=0.99))
#md# 
h, w = size(avgimg)
lw = 21
lc = eltype(avgimg)(parsecolor(0.1))
vbar = zeros(eltype(avgimg), (h, lw))
hbar = zeros(eltype(avgimg), (lw, 2w+lw))
vbar[:, lw÷2+1] .= lc
hbar[lw÷2+1, :] .= lc
image = [avgimg vbar clipimg; hbar; blendimg vbar mixstyleimg]
println("results are saved to recolor.png")
WordCloud.save("recolor.png", image)
wc
#eval# runexample(:recolor)
#md# ![recolor](recolor.png)  