module Render
export rendertext, overlay!, shape, ellipse, box, squircle, GIF, generate, parsecolor, rendertextoutlines,
    colorschemes, schemes, torgba, imagemask, outline, padding, dilate, imresize
export issvg, save, load, svg2bitmap, SVGImageType, svgstring
using Luxor
using Colors
using ColorSchemes
using ImageMagick
import ImageTransformations.imresize

save = Luxor.FileIO.save

parsecolor(c) = parse(Colorant, c)
parsecolor(tp::Tuple) = ARGB(tp...)
parsecolor(gray::Real) = Gray(gray)
parsecolor(sc::Symbol) = parsecolor.(colorschemes[sc].colors)

issvg(d) = d isa Drawing && d.surfacetype==:svg
const SVGImageType = Drawing
Base.broadcastable(s::SVGImageType) = Ref(s)
svgstring(d) = String(copy(d.bufferdata))

function loadsvg(svg)
    p = readsvg(svg)
    d = Drawing(p.width, p.height, :svg)
    placeimage(p)
    finish()
    d
end

function load(fn::AbstractString)
    if endswith(fn, r".svg|.SVG")
        loadsvg(fn)
    else
        ImageMagick.load(fn)
    end
end
function load(file::IO)
    try
        ImageMagick.load(file)
    catch
        seekstart(file)
        loadsvg(read(file, String))
    end
end
function svg2bitmap(svg::Drawing)
    Drawing(svg.width, svg.height, :image)
    placeimage(svg)
    m = image_as_matrix()
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
        pos=(0,0), color="black", backgroundcolor=(0,0,0,0), angle=0, font="", border=0, type=:bitmap)
    @assert type in (:svg, :bitmap, :both)
    l = length(str) + 1
    l = ceil(Int, size*l + 2border + 2)
    if type == :bitmap
        Drawing(l, l, :image)
    else
        svg = Drawing(l, l, :svg) #svg is slow
    end
    origin()
    bgcolor = parsecolor(backgroundcolor)
    bgcolor = background(bgcolor)

    drawtext(str, size, pos, angle, color, font)
    if type == :bitmap mat=image_as_matrix() end
    finish()
    if type != :bitmap mat = svg2bitmap(svg) end
    #     bgcolor = Luxor.ARGB32(bgcolor...) #https://github.com/JuliaGraphics/Luxor.jl/issues/107
    bgcolor = mat[1]
    box = boundbox(mat, bgcolor, border=border)
    mat = clipbitmap(mat, box...)
    if type == :bitmap
        return mat
    elseif type == :svg
        return clipsvg(svg, box...)
    else
        return mat, clipsvg(svg, box...)
    end
end

function rendertextoutlines(str::AbstractString, size::Real; color="black", bgcolor=(0,0,0,0), 
        linewidth=3, linecolor="white", font="")
    l = length(str)
    Drawing(ceil(Int, 2l*(size + 2linewidth) + 2), ceil(Int, 2*(size + 2linewidth) + 2), :image)
    origin()
    bgcolor = parsecolor(bgcolor)
    bgcolor = background(bgcolor)
    # bgcolor = Luxor.ARGB32(bgcolor...)
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

function torgba(c)
    c = Colors.RGBA{Colors.N0f8}(parsecolor(c))
    rgba = (Colors.red(c), Colors.green(c), Colors.blue(c), Colors.alpha(c))
    reinterpret.(UInt8, rgba)
end
torgba(img::AbstractArray) = torgba.(img)

imagemask(img::AbstractArray{Bool,2}) = img
function imagemask(img, istransparent::Function)
    .! istransparent.(torgba.(img))
end
function imagemask(img, transparentcolor=:auto)
    if transparentcolor==:auto
        if img[1]==img[end] && any(c->c!=img[1], img)
            transparentcolor = img[1]
        else
            transparentcolor = nothing
        end
    end
    if transparentcolor === nothing
        return trues(size(img))
    end
    img .!= convert(eltype(img), parsecolor(transparentcolor))    
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

function dilate2(mat, r; smoothness=0.5) #better and slower
    @assert smoothness >= 0
    m = zeros(size(mat) .+ 2)
    m[2:end-1, 2:end-1] .= mat
    #立方 ∫∫ x^2+y^2 dx dy
    s = max(7, 171 * smoothness) # 13*4+7*4+91, smoothness是平滑系数，0-1，越大越圆但边缘越模糊，越小越方但边缘越清晰
    # s < 7 无意义，反而增加溢出风险
    #权重 1/1 : 1/13 : 1/7
    o = 91/s # 1 / ((0.5^3-(-0.5)^3) * 2)
    p = 7/s # 1 / ((1.5^3-0.5^3) * 2)
    q = 13/s # 1 / ((1.5^3-0.5^3) + (0.5^3-(-0.5)^3))
    
    for _ in 1:r
        @views m[2:end-1, 2:end-1] .= (
            o*m[2:end-1, 2:end-1] .+ #中

            q*m[1:end-2, 2:end-1] .+ q*m[3:end, 2:end-1] .+ #上下
            q*m[2:end-1, 1:end-2] .+ q*m[2:end-1, 3:end] .+ #左右

            p*m[1:end-2, 1:end-2] .+ p*m[3:end, 3:end] .+ #主对角
            p*m[1:end-2, 3:end] .+ p*m[3:end, 1:end-2] #副对角
        )
    end
    return min.(1., m[2:end-1, 2:end-1])
end
"""
img: a bitmap image
linewidth: 0 <= linewidth
color: line color
transparentcolor: color of the background
smoothness: 0 <= smoothness <= 1
"""
function outline(img; transparentcolor=:auto, color="black", linewidth=2, smoothness=0.5)
    @assert linewidth >= 0
    mask = imagemask(img, transparentcolor)
    r = 4 * linewidth * smoothness
    # @show r
    mask2 = dilate2(mask, max(linewidth, round(r)), smoothness=smoothness)
    c = ARGB(parsecolor(color)) #https://github.com/JuliaGraphics/Colors.jl/issues/500
    bg = convert.(eltype(img), coloralpha.(c, mask2))
    bg = overlay!(copy(img), bg)
    @views bg[mask] .= overlay.(bg[mask], img[mask])
    bg
end

function padding(img, r=0.1; color=img[1])
    color = convert(eltype(img), parsecolor(color))
    p = round.(Int, size(img) .* r)
    r = fill(color, size(img) .+ 2 .* p)
    overlay!(r, img, reverse(p)...)
end

"return the overlapping view of img1 and img2 when img2's top left corner at img1's (x, y)"
function overlappingarea(img1, img2, x=1, y=1)
    h1, w1 = size(img1)
    h2, w2 = size(img2)
    img1v = @view img1[max(1,y):min(h1,y+h2-1), max(1,x):min(w1,x+w2-1)]
    img2v = @view img2[max(1,-y+2):min(h2,-y+h1+1), max(1,-x+2):min(w2,-x+w1+1)]
    img1v, img2v
end
                        
function overlay(color1::TransparentRGB, color2::TransparentRGB)
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
    typeof(color1)(min.(1, c)..., min(1, a))
end
"put img2 on img1 at (x, y)"
function overlay!(img1::AbstractMatrix, img2::AbstractMatrix, x=1, y=1)#左上角重合时(x=1,y=1)
    img1v, img2v = overlappingarea(img1, img2, x, y)
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
    bgcolor = Luxor.background(1, 1, 1, 0)
    if !(background == false || background === nothing)
        placeimage(background)
    end
    placeimage.(imgs, [Point(x-1,y-1) for (x,y) in poss])#(x,y)=(1,1)时左上角重合，此时Point(0,0)
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

function squircle(pos, w, h, args...; kargs...)
    Luxor.squircle(pos, w/2, h/2, args...; kargs...)
end

"""
generate a box, ellipse or squircle svg image
## Examples
* shape(box, 80, 50) #80*50 box
* shape(box, 80, 50, 4) #box with cornerradius=4
* shape(squircle, 80, 50, rt=0.7) #squircle or superellipse. rt=0, rectangle; rt=1, ellipse; rt=2, rhombus.
* shape(ellipse, 80, 50, color="red") #80*50 red ellipse
* shape(box, 80, 50, backgroundcolor=(0,1,0), backgroundsize=(100, 100)) #80*50 box on 100*100 green background
* shape(squircle, 80, 50, outline=3, linecolor="red", backgroundcolor="gray") #add a red outline to the squircle
"""
function shape(shape_, width, height, args...; 
    outline=0, linecolor="black",
    color="white", backgroundcolor=(0,0,0,0), backgroundsize=(width+2outline, height+2outline), 
    kargs...)
    d = Drawing(backgroundsize..., :svg)
    origin()
    background(parsecolor(backgroundcolor))
    if outline>0
        setline(2outline)
        setcolor(parsecolor(linecolor))
        shape_(Point(0,0), width, height, args..., :stroke; kargs...)
    end
    setcolor(parsecolor(color))
    shape_(Point(0,0), width, height, args..., :fill; kargs...)
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