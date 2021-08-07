using WordCloud
using HTTP

url = "http://en.wikipedia.org/wiki/Special:random"
try
    resp = HTTP.request("GET", url, redirect=true)
    println(resp.request)
    content = resp.body |> String
    wc = wordcloud(content |> html2text |> processtext) |> generate!
    println("results are saved to fromweb.png")
    paint(wc, "fromweb.png")
    wc
catch e
    println(e)
end
#eval# runexample(:fromweb)
#md# ![](fromweb.png)  