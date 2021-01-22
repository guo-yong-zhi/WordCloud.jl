using WordCloud
manualdir = joinpath(dirname(Sys.BINDIR), "share/doc/julia/html/en/manual")
basedir = joinpath(dirname(Sys.BINDIR), "share/doc/julia/html/en/base")
stdlibdir = joinpath(dirname(Sys.BINDIR), "share/doc/julia/html/en/stdlib")
docs = [
    readdir(manualdir, join=true)..., 
    readdir(basedir, join=true)..., 
    readdir(stdlibdir, join=true)..., 
    ]
counter = Dict{String,Int}()
words_weights = processtext(maxnum=1000, maxweight=1) do
    for doc in docs
        content = html2text(open(doc))
        countwords(content, counter=counter)
    end
    counter
end
wc = wordcloud(words_weights, fillingrate=0.75)
setangles!(wc, "julia", 0)
initword!(wc, "julia")
setpositions!(wc, "julia", reverse(size(wc.mask)) .÷ 2, type=setcenter!)
pin(()->generate!(wc), wc, "julia")
println("results are saved to juliadoc.svg")
paint(wc, "juliadoc.svg", background=false)
wc
