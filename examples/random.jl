using WordCloud
using Random
words = [randstring(rand(1:8)) for i in 1:300]
weights = randexp(length(words)) .* 1000 .+ rand(1:100, length(words))
wordcloud(words, weights) |> generate!