using WordCloud
wc = wordcloud(
    process(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask = loadmask(pkgdir(WordCloud)*"/res/alice_mask.png", color="#faeef8"),
    colors = (WordCloud.colorschemes[:Set1_5].colors..., ),
    angles = (0, 90),
    fillingrate = 0.7) |> generate!
paint(wc, "alice.png")