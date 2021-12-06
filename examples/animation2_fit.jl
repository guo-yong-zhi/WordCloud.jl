#md# This animation shows the process of fitting the layout.
using CSV
using DataFrames
using WordCloud

df = CSV.File(pkgdir(WordCloud) * "/res/guxiang_frequency.txt", header=false) |> DataFrame;
words = df[!, "Column2"]
weights = df[!, "Column3"]

wc = wordcloud(words, weights, density=0.65)
gifdirectory = "animation2_fit"
record(generate!, wc, 100, outputdir=gifdirectory)
println("results are saved in animation2_fit")
wc
#eval# runexample(:animation2_fit)
#md# ![](animation2_fit/result.gif)  