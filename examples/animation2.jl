#md# This animation shows the process of fitting the layout.
using CSV
using DataFrames
using WordCloud

df = CSV.File(pkgdir(WordCloud) * "/res/guxiang_frequency.txt", header=false) |> DataFrame;
words = df[!, "Column2"]
weights = df[!, "Column3"]

wc = wordcloud(words, weights, density=0.5)
gifdirectory = "animation2"
@record gifdirectory overwrite=true generate!(wc, 100, optimiser=WordCloud.Momentum())
println("results are saved in animation2")
wc
#eval# runexample(:animation2)
#md# ![](animation2/animation.gif)  