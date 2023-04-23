using WordCloud
function drawjuliacircle(sz)
    juliacirclessvg = WordCloud.Render.Drawing(sz, sz, :svg)
    WordCloud.Render.origin()
    WordCloud.Render.background(0, 0, 0, 0)
    WordCloud.Render.juliacircles(sz ÷ 4)
    WordCloud.Render.finish()
    juliacirclessvg
end

docs = (readdir(joinpath(dirname(Sys.BINDIR), "share/doc/julia/html/en", dir), join=true) for dir in ["manual", "base", "stdlib"])
docs = docs |> Iterators.flatten

words, weights = processtext(maxnum=400, maxweight=1) do
    counter = Dict{String,Int}()
    for doc in docs
        content = html2text(open(doc))
        countwords(content, counter=counter)
    end
    counter
end

wc = wordcloud(
    [words..., "∴"], # add a placeholder for julia-logo
    [weights..., weights[1]], 
    density=0.55,
    mask=shape(box, 900, 300, cornerradius=0, color=0.95),
    masksize=:original,
    colors=((0.796, 0.235, 0.20), (0.584, 0.345, 0.698), (0.22, 0.596, 0.149)),
    angles=(0, -45, 45),
    # fonts = "Verdana Bold",
    maxfontsize = 300,
)
setangles!(wc, "julia", 0)
# setangles!(wc, "function", 45)
# initword!(wc, "function")
setcolors!(wc, "julia", (0.796, 0.235, 0.20))
# setfonts!(wc, "julia", "forte")
initword!(wc, "julia")
juliacircles = drawjuliacircle(getfontsizes(wc, "∴") |> round)
setsvgimages!(wc, "∴", juliacircles) # replace image
sz1 = size(getimages(wc, "∴"))
sz2 = size(getimages(wc, "julia"))
y1, x1 = (size(wc.mask) .- (sz1[1], sz1[2] + sz2[2])) .÷ 2
y2 = (size(wc.mask, 1) - sz2[1]) ÷ 2
x1 = round(Int, x1 * 0.9)
setpositions!(wc, "∴", (x1, y1))
setpositions!(wc, "julia", (x1 + sz1[2], y2))

pin(wc, ["julia", "∴"]) do
    placewords!(wc)
    generate!(wc, 2000)
end
println("results are saved to juliadoc.svg")
# paint(wc, "juliadoc.png")
paint(wc, "juliadoc.svg")
wc
#eval# runexample(:juliadoc)
#md# ![](juliadoc.svg)  
