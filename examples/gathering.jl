#md# Big words will be placed closer to the center
using WordCloud
rt = 2.5 * rand()
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    angles=0, density=0.55,
    maskshape=squircle, rt=rt,
    run = initimages!)
placement!(wc, style=:gathering, level=5, rt=rt)
generate!(wc, patient=-1)
println("results are saved to gathering.svg")
paint(wc, "gathering.svg")
wc
#eval# runexample(:gathering)
#md# ![](gathering.svg)  