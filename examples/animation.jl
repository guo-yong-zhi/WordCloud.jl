using CSV
using DataFrames
using WordCloud

df = CSV.File(pkgdir(WordCloud)*"/res/guxiang_frequency.txt", header=false)|> DataFrame;
words = df[!, "Column2"]
weights = df[!, "Column3"]

wc = wordcloud(words, weights, density=0.65)
gifdirectory = "guxiang_animation"
#eval# try rm("guxiang_animation", force=true, recursive=true) catch end 
generate_animation!(wc, 100, outputdir=gifdirectory)
println("results are saved in guxiang_animation")
wc
#eval# runexample(:animation)
#md# ![](guxiang_animation/result.gif)  