using WordCloud
using HTTP

url = "https://en.wikipedia.org/wiki/Julia_(programming_language)"
content = HTTP.request("GET", url, connect_timeout=20).body |> String
wc = wordcloud(content|>html2text|>processtext)|>generate!
println("results are saved to fromweb.png")
paint(wc, "fromweb.png")
wc