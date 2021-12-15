using WordCloud
#md# ### Generate a word cloud first
push!(WordCloud.stopwords, "said")
wc = wordcloud(open(pkgdir(WordCloud) * "/res/alice.txt")) |> generate!
#md# ### Add hyperlinks for each tag
#md# This can be done by adding a wrapper SVG node `<a>`
#md# * SVG ElementNode: `<a href="https://www.google.com/search?q=$w">` and `</a>`
configsvgimages!(wc, wrappers = ["a" => ("href" => "https://www.google.com/search?q=$w") for w in getwords(wc)])
#md# ### Add flicker, rotation animations and tooltips
#md# These things can be done by adding child nodes `<animate>`, `<animateTransform>` and `<title>`.
#md# * SVG ElementNode: `<animate attributeName="opacity" values="1;0.5;1" dur="6s" repeatCount="indefinite"/>`
#md# * SVG ElementNode: `<animateTransform attributeName="transform" type="rotate" from="0 $(w/2) $(h/2)" to="360 $x $y" dur="6s" repeatCount="indefinite"/>`
#md# * SVG TextNode: `<title>$word</title>`
flicker = "animate" => ["attributeName" => "opacity", "values" => "1;0.5;1", "dur" => "6s", "repeatCount" => "indefinite"]
h, w = getmask(wc) |> size
for word in getwords(wc)
    x, y = getpositions(wc, word, type = getcenter)
    rotation = "animateTransform" => [
        "attributeName" => "transform",
        "type" => "rotate",
        "from" => "0 $(w/2) $(h/2)",
        "to" => "360 $x $y",
        "dur" => "6s",
        "repeatCount" => "indefinite"
    ]
    title = "title" => word
    configsvgimages!(wc, word, children = (flicker, rotation, title))
end
println("results are saved to svgconfig.svg")
paint(wc, "svgconfig.svg")
wc
#eval# runexample(:svgconfig)
#md# ![svgconfig](svgconfig.svg)  