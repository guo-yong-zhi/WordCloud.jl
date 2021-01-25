module Render
export rendertext, textmask, overlay!, shape, ellipse, box, GIF, generate, parsecolor, rendertextoutlines,
    colorschemes, schemes, outline, padding, imresize
export issvg, save, load, svg2bitmap, SVGImageType
using Luxor
using Colors
using ColorSchemes
using ImageMagick
import ImageTransformations.imresize

save = Luxor.FileIO.save

parsecolor(c) = parse(Colorant, c)
parsecolor(tp::Tuple) = ARGB32(tp...)
parsecolor(gray::Real) = Gray(gray)

issvg(d) = d isa Drawing && d.surfacetype==:svg
const SVGImageType = Drawing
function loadsvg(fn)
    p = readsvg(fn)
    d = Drawing(p.width, p.height, :svg)
    placeimage(p)
    finish()
    d
end

function load(fn)
    if endswith(fn, ".svg")
        loadsvg(fn)
    else
        ImageMagick.load(fn)
    end
end

function svg2bitmap(svg::Drawing)
    d = Drawing(svg.width, svg.height, :image)
    placeimage(svg)
    m=image_as_matrix()
    finish()
    m
end

function boundbox(p::AbstractMatrix, bgcolor; border=0)
    a = c = 1
    b = d = 0
    while a < size(p, 1) && all(p[a,:] .== bgcolor)
        a += 1
    end
    while b < size(p, 1) && all(p[end-b,:] .== bgcolor)
        b += 1
    end
    a = max(1, a-border)
    b = min(size(p, 1), max(size(p, 1)-b+border, a))
    p = @view p[a:b, :]
    while c < size(p, 2) && all(p[:,c] .== bgcolor)
        c += 1
    end
    while d < size(p, 2) && all(p[:, end-d] .== bgcolor)
        d += 1
    end
    # @show a,b,c,d,border,bgcolor
    # @show c, d, p
    c = max(1, c-border)
    d = min(size(p, 2), max(size(p, 2)-d+border, c))
    return a, b, c, d
end

"a, b, c, d are all inclusive"
function clipsvg(m, a, b, c, d)
    m2 = Drawing(d-c+1, b-a+1, :svg)
    placeimage(m, Point(-c+1, -a+1))
    finish()
    m2
end
"a, b, c, d are all inclusive"
clipbitmap(m, a, b, c, d) = m[a:b, c:d]

function drawtext(t, size, pos, angle=0, color="black", font="")
    setcolor(parsecolor(color))
    setfont(font, size)
    settext(t, Point(pos...), halign="center", valign="center"; angle=angle)
end

function rendertext(str::AbstractString, size::Real; 
        pos=(0,0), color="black", bgcolor=(0,0,0,0), angle=0, font="", border=0, returnmask=false)
    l = length(str) + 1
    l = ceil(Int, size*l + 2border + 2)
    svg = Drawing(l, l, :svg)
    origin()
    bgcolor = parsecolor(bgcolor)
    bgcolor = background(bgcolor)

    drawtext(str, size, pos, angle, color, font)
    finish()
    mat = svg2bitmap(svg)
    #     bgcolor = Luxor.ARGB32(bgcolor...) #https://github.com/JuliaGraphics/Luxor.jl/issues/107
    bgcolor = mat[1]
    box = boundbox(mat, bgcolor, border=border)
    svg = clipsvg(svg, box...)
    mat = clipbitmap(mat, box...)
    if returnmask
        return svg, mat, textmask(mat, bgcolor, radius=border)
    else
        return svg, mat
    end
end

function rendertextoutlines(str::AbstractString, size::Real; color="black", bgcolor=(0,0,0,0), 
        linewidth=3, linecolor="white", font="")
    l = length(str)
    Drawing(ceil(Int, 2l*(size + 2linewidth) + 2), ceil(Int, 2*(size + 2linewidth) + 2), :image)
    origin()
    bgcolor = parsecolor(bgcolor)
    bgcolor = background(bgcolor)
    bgcolor = Luxor.ARGB32(bgcolor...)
    setcolor(parsecolor(color))
#     setfont(font, size)
    fontface(font)
    fontsize(size)
    setline(linewidth)
    textoutlines(str, O, :path, halign="center", valign="center")
    fillpreserve()
    setcolor(linecolor)
    strokepath()
    mat = image_as_matrix()
    finish()
    mat = clipbitmap(mat, boundbox(mat, mat[1])...)
end

function dilate(mat, r)
    mat2 = copy(mat)
    mat2[1:end-r, :] .|= mat[1+r:end, :]
    mat2[1+r:end, : ] .|= mat[1:end-r, :]
    mat2[:, 1:end-r] .|= mat[:, 1+r:end]
    mat2[:, 1+r:end] .|= mat[:, 1:end-r]

    mat2[1:end-r, 1:end-r] .|= mat[1+r:end, 1+r:end]
    mat2[1+r:end, 1+r:end ] .|= mat[1:end-r, 1:end-r]
    mat2[1:end-r, 1+r:end ] .|= mat[1+r:end, 1:end-r]
    mat2[1+r:end, 1:end-r ] .|= mat[1:end-r, 1+r:end]
    mat2
end

function outline(img; transparentcolor=:auto, color="black", linewidth=1)
    img = deepcopy(img)
    transparentcolor = transparentcolor==:auto ? img[1] : parsecolor(transparentcolor)
    mask = img .!== convert(typeof(img[1]), transparentcolor)
    mask2 = dilate(mask, 1)
    for r in 2:linewidth #ok with small linewidth
        mask2 .|= dilate(mask, r)
    end
    border = mask2 .& (.!mask)
    img[border] .= convert(typeof(img[1]), parsecolor(color))
    img
end

function padding(img, r=0.1; color=img[1])
    color = convert(typeof(img[1]), parsecolor(color))
    p = round.(Int, size(img) .* r)
    r = fill(color, size(img) .+ 2 .* p)
    overlay!(r, img, reverse(p)...)
end

function textmask(pic, bgcolor; radius=0)
    mask = pic .!= bgcolor
    dilate(mask, radius)
end

function overlay(color1::T, color2::T) where {T}
#     @show color1, color2
    a2 = Colors.alpha(color2)
    if a2 == 0 return color1 end
    if a2 == 1 return color2 end
    a1 = Colors.alpha(color1) |> Float64
    c1 = [Colors.red(color1), Colors.green(color1), Colors.blue(color1)]
    c2 = [Colors.red(color2), Colors.green(color2), Colors.blue(color2)]
    a = a1 + a2 - a1 * a2
    c = (c1 .* a1 .* (1-a2) .+ c2 .* a2) ./ (a>0 ? a : 1)
#     @show c, a
    T(min.(1, c)..., min(1, a))
end
"put img2 on img1 at (x, y)"
function overlay!(img1::AbstractMatrix, img2::AbstractMatrix, x=1, y=1)#左上角重合时(x=1,y=1)
    h1, w1 = size(img1)
    h2, w2 = size(img2)
    img1v = @view img1[max(1,y):min(h1,y+h2-1), max(1,x):min(w1,x+w2-1)]
    img2v = @view img2[max(1,-y+2):min(h2,-y+h1+1), max(1,-x+2):min(w2,-x+w1+1)]
#     @show (h1, w1),(h2, w2),(x,y)
    img1v .= overlay.(img1v, img2v)
    img1
end
function overlay!(img::AbstractMatrix, imgs, pos)
    for (i, p) in zip(imgs, pos)
#         @show pos
        overlay!(img, i, p...)
    end
    img
end

function overlay(imgs::AbstractVector{Drawing}, poss; background=false, size=size(background))
    d = Drawing(size..., :svg)
    bgcolor = Luxor.background(ARGB32(1,1,1,0))
    if !(background == false || background === nothing)
        if !issvg(background)
            @warn "embed bitmap in svg"
        end
        placeimage(background)
    end
    placeimage.(imgs, [Point(x-1,y-1) for (x,y) in poss])#左上角重合时Point(1,1)
    finish()
    d
end

schemes_colorbrewer = filter(s -> occursin("colorbrewer", colorschemes[s].category), collect(keys(colorschemes)))
schemes_colorbrewer =  filter(s -> (occursin("Accent", String(s)) 
        || occursin("Dark", String(s))
        || occursin("Paired", String(s))
        || occursin("Pastel", String(s))
        || occursin("Set", String(s))
        || occursin("Spectral", String(s))
        ), schemes_colorbrewer)
schemes_seaborn = filter(s -> occursin("seaborn", colorschemes[s].category), collect(keys(colorschemes)))
schemes = [schemes_colorbrewer..., schemes_seaborn...]

"""
get box or ellipse image
## Examples
* shape(box, 80, 50) #80*50 box
* shape(box, 80, 50, 4) #box with cornerradius=4
* shape(ellipse, 80, 50, color="red") #80*50 red ellipse
"""
function shape(shape_, width, height, args...; color="white", bgcolor=(0,0,0,0))
    d = Drawing(width, height, :svg)
    origin()
    bgcolor = parsecolor(bgcolor)
    background(bgcolor)
    setcolor(parsecolor(color))
    shape_(Point(0,0), width, height, args..., :fill)
    finish()
    d
end

using Printf
function gif_callback_factory()
    counter = Iterators.Stateful(0:typemax(Int))
    pic->save(gifdirectory*@sprintf("/%010d.png", popfirst!(counter)), pic)
end
function try_gif_gen(gifdirectory; framerate=4)
    try
        pipeline(`ffmpeg -f image2 -i $(gifdirectory)/%010d.png -vf 
            palettegen -y $(gifdirectory)/result-palette.png`, stdout=devnull, stderr=devnull) |> run
        pipeline(`ffmpeg -framerate $(framerate) -f image2 -i $(gifdirectory)/%010d.png 
            -i $(gifdirectory)/result-palette.png -lavfi paletteuse -y $(gifdirectory)/result.gif`,
            stdout=devnull, stderr=devnull) |> run
    catch e
        @warn "You need to have FFmpeg manually installed to use this function."
        @warn e
    end
end
struct GIF
    counter::Base.Iterators.Stateful{UnitRange{Int64},Union{Nothing, Tuple{Int64,Int64}}}
    directory::String
end
function GIF(directory)
    GIF(Iterators.Stateful(0:typemax(Int)), directory)
end
Base.push!(gif::GIF, img) = ImageMagick.save(gif.directory*@sprintf("/%010d.png", popfirst!(gif.counter)), img)
(gif::GIF)(img) = Base.push!(gif, img)
generate(gif::GIF, args...; kargs...) = try_gif_gen(gif.directory, args...; kargs...)
end