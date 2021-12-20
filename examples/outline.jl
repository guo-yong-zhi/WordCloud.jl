using WordCloud
words = (1:200) .% 10 .|> string
weights = (1:200) .% 11 .+ 1
#md# ### SVG
#md# You can directly set the `outline` and `maskcolor` in `wordcloud`
wc1 = wordcloud(
    words, weights,
    mask = squircle, rt=0.5,
    masksize = (300, 200),
    maskcolor = "AliceBlue",
    outline = 6, linecolor = "navy"
) |> generate!
#md# Or if you already have a SVG mask with outline, you should set a proper transparent region in `wordcloud`
svgmask = shape(squircle, 300, 200, outline=6, linecolor="navy", color="AliceBlue")
wc1 = wordcloud(
    words, weights,
    mask = svgmask,
    transparent=c -> c != WordCloud.torgba("AliceBlue"), # the outline should be regarded as transparent too
) |> generate!

paint(wc1, "outline.svg")
println("results are saved to outline.svg")
#md# ![](outline.svg)  
#md# ### Bitmap
#md# If you already have a bitmap mask without outline, you can outline it before painting
bitmapmask = WordCloud.tobitmap(shape(squircle, 300, 200, color="AliceBlue", backgroundsize=(312, 212)))
wc2 = wordcloud(
    words, weights,
    mask = bitmapmask,
) |> generate!
paint(wc2, "outline.png", background=outline(bitmapmask, color="navy", linewidth=6, smoothness=0.8))
println("results are saved to outline.png")
#md# ![](outline.png)  
wc1, wc2
#eval# runexample(:outline)