#md# Big words will be placed closer to the center
using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    angles = 0,
    density = 0.7,
    run = initimages!)
placement!(wc, style=:gathering, level=5)
generate!(wc)
println("results are saved to gathering.svg")
paint(wc, "gathering.svg")
wc
#eval# runexample(:gathering)
#md# ![](gathering.svg)  