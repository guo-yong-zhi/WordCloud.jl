using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud) * "/res/alice.txt"), stopwords_extra=["said"]), 
    mask=pkgdir(WordCloud) * "/res/alice_mask.png",
    maskcolor="#faeef8",
    colors=:seaborn_dark,
    angles=(0, 90),
    density=0.55,
    spacing = 3,) |> generate!
println("results are saved to alice.png")
paint(wc, "alice.png", background=outline(wc.mask, color="purple", linewidth=4))
wc
#eval# runexample(:alice)
#md# ![alice](alice.png)  