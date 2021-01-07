using CSV
using DataFrames
using WordCloud

df = CSV.File("res/guxiang_frequency.txt", header=false)|> DataFrame;
texts = df[!, "Column2"]
weights = df[!, "Column3"]

wc = wordcloud(texts, weights, 
#     colors = ("red", 0.7, "#00ff00"),
    mask=shape(box, 400, 300, 40, color=0.15), 
    fillingrate=0.8)

gifdirectory = "guxiang_animation"
generate_animation!(wc, 100, optimiser=Momentum(η=1/4, ρ=0.5), patient=10, retry=2, outputdir=gifdirectory)