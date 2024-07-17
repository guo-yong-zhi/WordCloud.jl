#md# Hyperlinks can be embedded using wrapper SVG tag pairs, such as `<a href="https://www.google.com/search?q=$w">` and `</a>`. 
#md# The function `configsvgimages!` provides this capability.
using WordCloud
wc = wordcloud(open(pkgdir(WordCloud) * "/LICENSE")) |> generate!
for w in getwords(wc)
    configsvgimages!(wc, w, wrappers="a"=>("href"=>"https://www.google.com/search?q=$w"))
end
println("results are saved to hyperlink.svg")
paint(wc, "hyperlink.svg")
wc
#eval# runexample(:hyperlink)
#md# ![hyperlink](hyperlink.svg)  