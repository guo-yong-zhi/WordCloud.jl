using WordCloud
mask = rendertext("World", 1000, border=10, color=0.9, backgroundcolor=0.98, type=:svg, font="Georgia-Bold")
words = repeat(["we", "are", "the", "world"], 150)
weights = repeat([1], length(words))
wc = wordcloud(
        words, weights, 
        mask = mask,
        angles = 0,
        colors = ("#006BB0", "#EFA90D", "#1D1815", "#059341", "#DC2F1F"),
        density=0.7,
        ) |> generate!
println("results are saved to lettermask.svg")
paint(wc, "lettermask.svg" , background=false)
wc
#eval# runexample(:lettermask)
#md# ![](lettermask.svg)  