using WordCloud
#md# Sometimes you want a high-density output, and you may do it like this:
#md# ```julia
#md# wc = wordcloud(
#md#     processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
#md#     mask = shape(box, 400, 300, 10),
#md#     colors = :Dark2_3,
#md#     angles = (0, 90),
#md#     density = 0.75) |> generate!
#md# paint(wc, "highdensity.png")
#md# ```
#md# But you may find that doesn't work. That is because there should be at least 1 pixel gap between two words, which is controlled by the `border` parameter (default 1) in `wordcloud`. While, when the picture is small, 1 pixel is expensive. So, that can be done as follows:
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask = shape(box, 400*2, 300*2, 10*2),
    colors = :Dark2_3,
    angles = (0, 90),
    density = 0.75) |> generate!
paint(wc, "highdensity.png", ratio=0.5)
#md# 
println("results are saved to highdensity.png")
wc
#eval# runexample(:highdensity)
#md# ![highdensity](highdensity.png)  