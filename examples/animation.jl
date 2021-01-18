using CSV
using DataFrames
using WordCloud

df = CSV.File(pkgdir(WordCloud)*"/res/guxiang_frequency.txt", header=false)|> DataFrame;
texts = df[!, "Column2"]
weights = df[!, "Column3"]

wc = wordcloud(texts, weights, fillingrate=0.8)
println("save results to guxiang_animation")
gifdirectory = "guxiang_animation"
generate_animation!(wc, 100, outputdir=gifdirectory)
wc