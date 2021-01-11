using WordCloud
using Random

words = [Random.randstring(rand(1:8)) for i in 1:500]
weights = randexp(length(words)) .* 2000 .+ rand(20:100, length(words));
wc = wordcloud(words, weights, mask=shape(ellipse, 500, 500, color=0.15), angles=(0,90,45)) |> generate!