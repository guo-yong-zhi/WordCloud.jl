using WordCloud
words = (1:200).%10 .|> string
weights = (1:200).%11 .+ 1
#md# ### SVG
#md# You already have or want to manually generate a SVG mask with outline, you should set a proper transparent region
svgmask = shape(squircle, 300, 200, outline=3, linecolor="navy", color="AliceBlue")
wc1 = wordcloud(
    words, weights,
    mask = svgmask,
    transparent = c->c!=WordCloud.torgba("AliceBlue"), #the outline should be regarded as transparent too
) |> generate!
#md# Or, if you set the `maskcolor` in `wordcloud`, the transparent will be automatically set correctly.
#md# ```julia
#md# wc1 = wordcloud(
#md#     words, weights,
#md#     maskshape = squircle, rt=0.5,
#md#     masksize = (300, 200),
#md#     maskcolor = "AliceBlue",
#md#     outline = 3, linecolor = "navy"
#md# ) |> generate!
#md# ```
paint(wc1, "outline.svg")
println("results are saved to outline.svg")
#md# ### Bitmap
#md# If you already have a bitmap mask without outline, you can outline it before painting
bitmapmask = WordCloud.svg2bitmap(shape(squircle, 300, 200, color="AliceBlue", backgroundsize=(312, 212)))
wc2 = wordcloud(
    words, weights,
    mask = bitmapmask,
) |> generate!
paint(wc2, "outline.png", background=outline(bitmapmask, color="navy", linewidth=3, smoothness=0.8))
println("results are saved to outline.png")
#md# 
wc1, wc2
#eval# runexample(:outline)
#md# ![](outline.svg)  
#md# ![](outline.png)  