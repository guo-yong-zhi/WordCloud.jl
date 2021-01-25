using WordCloud
docs = (readdir(joinpath(dirname(Sys.BINDIR), "share/doc/julia/html/en", dir), join=true) for dir in ["manual", "base", "stdlib"])
docs = docs |> Iterators.flatten

counter = Dict{String,Int}()
words_weights = processtext(maxnum=300, maxweight=1) do
    for doc in docs
        content = html2text(open(doc))
        countwords(content, counter=counter)
    end
    counter
end
wc = wordcloud(
    words_weights, 
    fillingrate=0.8,
    mask = shape(box, 600, 200, 10, color=0.95, bgcolor=(0,0,0,0)),
    colors = ((0.796,0.235,0.20),(0.251,0.388,0.874), (0.584,0.345,0.698), (0.22,0.596,0.149)),
    angles = (0, -45, 45),
)
setangles!(wc, "julia", 0)
setcolors!(wc, "julia", (0.796,0.235,0.20))
initword!(wc, "julia")
setpositions!(wc, "julia", reverse(size(wc.mask)) .÷ 2, type=setcenter!)
pin(()->generate!(wc), wc, "julia")
println("results are saved to juliadoc.svg")
paint(wc, "juliadoc.svg", background=false)
wc
