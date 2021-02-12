using WordCloud
function drawjuliacircle(sz)
    juliacirclessvg = WordCloud.Render.Drawing(sz, sz, :svg)
    WordCloud.Render.origin()
    WordCloud.Render.background(0,0,0,0)
    WordCloud.Render.juliacircles(sz÷4)
    WordCloud.Render.finish()
    juliacirclessvg
end

docs = (readdir(joinpath(dirname(Sys.BINDIR), "share/doc/julia/html/en", dir), join=true) for dir in ["manual", "base", "stdlib"])
docs = docs |> Iterators.flatten

words, weights = processtext(maxnum=300, maxweight=1) do
    counter = Dict{String,Int}()
    for doc in docs
        content = html2text(open(doc))
        countwords(content, counter=counter)
    end
    counter
end

wc = wordcloud(
    [words..., "∴"], #add a placeholder for julia-logo
    [weights..., weights[1]], 
    fillingrate=0.8,
    mask = shape(box, 900, 300, 0, color=0.95, backgroundcolor=(0,0,0,0)),
    colors = ((0.796,0.235,0.20), (0.584,0.345,0.698), (0.22,0.596,0.149)),
    angles = (0, -45, 45),
    # font = "Georgia",
    transparentcolor=(0,0,0,0),
)
setangles!(wc, "julia", 0)
setcolors!(wc, "julia", (0.796,0.235,0.20))
# setfonts!(wc, "julia", "forte")
initword!(wc, "julia")
juliacircles = drawjuliacircle(getfontsizes(wc, "∴")|>round)
setsvgimages!(wc, "∴", juliacircles) #replace image
sz1 = size(getimages(wc, "julia"))
sz2 = size(getimages(wc, "∴"))
p = (size(wc.mask) .- (sz2[1], sz1[2]+sz2[2])) .÷ 2
setpositions!(wc, "∴", reverse(p))
setpositions!(wc, "julia", getpositions(wc, "∴") .+ (size(getimages(wc, "∴"), 2), 0))

pin(wc, ["julia", "∴"]) do
    placement!(wc)
    generate!(wc, 2000)
end
println("results are saved to juliadoc.svg")
# paint(wc, "juliadoc.png")
paint(wc, "juliadoc.svg")
wc
