using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask = loadmask(pkgdir(WordCloud)*"/res/alice_mask.png", color="#faeef8"),
    colors = :Set1_5,
    angles = (0, 90),
    fillingrate = 0.7) |> generate!
println("results are saved to alice.png")
paint(wc, "alice.png", background=outline(wc.mask, color="purple", linewidth=1))
wc