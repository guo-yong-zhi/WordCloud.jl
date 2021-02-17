using WordCloud
using HTTP

url = "https://en.wikipedia.org/wiki/Julia_(programming_language)"
try
    content = HTTP.request("GET", url).body |> String
    wc = wordcloud(content|>html2text|>processtext)|>generate!
    println("results are saved to fromweb.png")
    paint(wc, "fromweb.png")
    wc
catch e
    println(e)
end
#eval# runexample(:fromweb)
#md# ![](fromweb.png)  