using CSV
using DataFrames
using WordCloud

df = CSV.File(pkgdir(WordCloud)*"/res/guxiang_frequency.txt", header=false)|> DataFrame;
words = df[!, "Column2"]
weights = df[!, "Column3"]

wc = wordcloud(words, weights, fillingrate=0.8)
gifdirectory = "guxiang_animation"
generate_animation!(wc, 100, outputdir=gifdirectory)
println("results are saved in guxiang_animation")
wc