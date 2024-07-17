using WordCloud
#md# ### Generate a word cloud first
wc = wordcloud(open(pkgdir(WordCloud) * "/res/alice.txt")) |> generate!
#md# ### Add hyperlinks for each tag
#md# This can be done by adding a wrapper SVG node `<a>`
#md# * SVG ElementNode: `<a href="https://www.google.com/search?q=$w">` and `</a>`
configsvgimages!(wc, wrappers = ["a" => ("href" => "https://www.google.com/search?q=$w") for w in getwords(wc)])
#md# ### Add animate and tooltips
#md# These things can be done by adding child nodes `<animate>` and `<title>`.
#md# * SVG ElementNode: `<animate attributeName="opacity" values="1;0.5;1" dur="1s" repeatCount="indefinite"/>`
#md# * SVG TextNode: `<title>$word</title>`
for word in getwords(wc)
    animate = "animate" => [:attributeName => "opacity", :values => "1;0.5;1", 
                            :begin => "$(rand(0:1000))ms", :dur => "1s", :repeatCount => "indefinite"]
    title = "title" => word
    configsvgimages!(wc, word, children=(animate, title))
end
println("results are saved to svgconfig.svg")
paint(wc, "svgconfig.svg")
wc
#eval# runexample(:svgconfig)
#md# ![svgconfig](svgconfig.svg)  