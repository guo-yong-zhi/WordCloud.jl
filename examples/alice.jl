using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask = loadmask(pkgdir(WordCloud)*"/res/alice_mask.png", color="#faeef8"),
    colors = :seaborn_dark,
    angles = (0, 90),
    density = 0.5) |> generate!
println("results are saved to alice.png")
paint(wc, "alice.png", background=outline(wc.mask, color="purple", linewidth=2))
wc
#eval# runexample(:alice)
#md# ![alice](alice.png)  