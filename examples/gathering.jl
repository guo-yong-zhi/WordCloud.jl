#md# By setting `style=:gathering` in the `layout!` function, larger words will be positioned closer to the center.
using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud) * "/res/alice.txt"), stopwords_extra=["said"]), 
    angles=0, density=0.55,
    mask=squircle, rt=2.5 * rand(),
    state=initialize!)
layout!(wc, style=:gathering, level=5, centralword=true)
pin(wc, "Alice") do # keep "Alice" in the center
    generate!(wc, reposition=0.7) # exclude the top 30% of words from repositioning
end
println("results are saved to gathering.svg")
paint(wc, "gathering.svg")
wc
#eval# runexample(:gathering)
#md# ![](gathering.svg)  