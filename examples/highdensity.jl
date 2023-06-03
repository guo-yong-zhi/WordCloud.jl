using WordCloud
#md# In certain scenarios, there might be a need for generating a high-density output, and you might attempt to achieve it using the following code:
#md# ```julia
#md# wc = wordcloud(
#md#     processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
#md#     mask = shape(box, 500, 400, cornerradius=10),
#md#     colors = :Dark2_3,
#md#     angles = (0, 90), # spacing = 2,
#md#     density = 0.7) |> generate!
#md# paint(wc, "highdensity.png")
#md# ```
#md# However, there are situations where it fails to function as intended. 
#md# This is mainly because the minimum gap between two words is set to 2 pixels, controlled by the `spacing` parameter of the `wordcloud` function.  
#md# In cases where the image is small, the cost of 2 pixels becomes relatively higher. To address this issue, you have the option to set `spacing=0` or `spacing=1`. Alternatively, increasing the image size can also alleviate the issue.
wc = wordcloud(
    processtext(open(pkgdir(WordCloud) * "/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask=shape(box, 500 * 2, 400 * 2, cornerradius=10 * 2),
    masksize=:original,
    colors=:Dark2_3,
    angles=(0, 90),
    density=0.7) |> generate!
paint(wc, "highdensity.png", ratio=0.5)
#md# 
println("results are saved to highdensity.png")
wc
#eval# runexample(:highdensity)
#md# ![highdensity](highdensity.png)  