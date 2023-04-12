using WordCloud
#md# Sometimes you want a high-density output, and you may do it like this:
#md# ```julia
#md# wc = wordcloud(
#md#     processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
#md#     mask = shape(box, 500, 400, cornerradius=10),
#md#     colors = :Dark2_3,
#md#     angles = (0, 90), #spacing = 2,
#md#     density = 0.7) |> generate!
#md# paint(wc, "highdensity.png")
#md# ```
#md# But you may find that doesn't work. 
#md# This is because the minimum gap between two words is set to 2 pixel, which is controlled by the parameter `spacing` of `wordcloud`. 
#md# While, when the picture is small, 1 pixel is relatively more expensive. You can set `spacing=0` or `spacing=1`. Or alternatively, this can be mitigated with a larger picture:
wc = wordcloud(
    processtext(open(pkgdir(WordCloud) * "/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask=shape(box, 500 * 2, 400 * 2, cornerradius=10 * 2),
    colors=:Dark2_3,
    angles=(0, 90),
    density=0.7) |> generate!
paint(wc, "highdensity.png", ratio=0.5)
#md# 
println("results are saved to highdensity.png")
wc
#eval# runexample(:highdensity)
#md# ![highdensity](highdensity.png)  