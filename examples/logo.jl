#md# It is the code to draw this repo's logo 
using WordCloud
Luxor = WordCloud.Render.Luxor

function cloudshape(height, args...; backgroundcolor=(0, 0, 0, 0))
    height = ceil(height)
    r = height / 2
    d = Luxor.Drawing((2height, height)..., :svg)
    Luxor.origin()
    Luxor.background(ascolor(backgroundcolor))
    Luxor.setcolor(ascolor((0.22, 0.596, 0.149)))
    Luxor.pie(0, 0, r, 0, 2π, :fill)
    Luxor.setcolor(ascolor((0.584, 0.345, 0.698)))
    Luxor.pie(r, r, r, -π, 0, :fill)
    Luxor.setcolor(ascolor((0.796, 0.235, 0.20)))
    Luxor.Luxor.pie(-r, r, r, -π, 0, :fill)
    Luxor.finish()
    WordCloud.SVG(Luxor.svgstring(), d.height, d.width)
end
wc = wordcloud(
    repeat(string.('a':'z'), 5),
    repeat([1], 26 * 5),
    mask=cloudshape(500),
    masksize=:original,
    transparent=(0, 0, 0, 0),
    colors=1,
    angles=-90:0,
    fonts="JuliaMono Black",
    density=0.7,
    )
generate!(wc, 2000, retry=1)
recolor!(wc, style=:main)
println("results are saved to logo.svg")
paint(wc, "logo.svg", background=false)
wc
#eval# runexample(:logo)
#md# ![](logo.svg)  