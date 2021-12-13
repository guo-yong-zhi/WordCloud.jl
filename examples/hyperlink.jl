#md# Hyperlinks can be attached with wrapper SVG tag pairs like `<a href="https://www.google.com/search?q=$w">` and `</a>`. 
#md# The function `configsvgimages!` provides this capability.
using WordCloud
push!(WordCloud.stopwords, "said")
wc = wordcloud(open(pkgdir(WordCloud) * "/res/alice.txt")) |> generate!
for w in getwords(wc)
    configsvgimages!(wc, w, wrappers="a"=>("href", "https://www.google.com/search?q=$w"))
end
println("results are saved to hyperlink.svg")
paint(wc, "hyperlink.svg")
wc
#eval# runexample(:hyperlink)
#md# ![hyperlink](hyperlink.svg)  