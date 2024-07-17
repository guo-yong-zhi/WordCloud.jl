module Render
export rendertext, overlay!,
    shape, ellipse, box, squircle, star, ngon, bezistar, bezingon, ellipse_area, box_area, squircle_area,
    star_area, ngon_area, GIF, generate, parsecolor, rendertextoutlines,
    colorschemes, torgba, imagemask, outline, pad, dilate!, imresize, recolor!, recolor
export issvg, save, load, tobitmap, tosvg, SVG, svg_wrap, svg_add, svg_stack
using Luxor
using Colors
using ColorSchemes
using FileIO
using  ImageTransformations
include("svg.jl")
# because of float error, (randommask(color=Gray(0.3))|>tobitmap)[300,300]|>torgba != Gray(0.3)|>torgba
parsecolor(c) = ARGB{Colors.N0f8}(parse(Colorant, c))
parsecolor(tp::Tuple) = ARGB{Colors.N0f8}(tp...)
parsecolor(gray::Real) = ARGB{Colors.N0f8}(Gray(gray))
parsecolor(sc::Symbol) = parsecolor.(colorschemes[sc].colors)
parsecolor(sc::AbstractArray) = parsecolor.(sc)

Base.size(s::Drawing) = (s.height, s.width)
issvg(d) = d isa SVG
tosvg(s::SVG) = s
function tosvg(img::AbstractMatrix)
    d = Drawing(size(img)..., :svg)
    Luxor.background(1, 1, 1, 0)
    placeimage(img)
    finish()
    SVG(svgstring(), d.height, d.width)
end
tobitmap(img::AbstractMatrix) = img
function tobitmap(svg::SVG)
    p = readsvg(string(svg))
    Drawing(ceil(p.width), ceil(p.height), :image)
    placeimage(p)
    m = image_as_matrix()
    finish()
    m
end

function loadsvg(svg)
    p = readsvg(svg)
    d = Drawing(p.width, p.height, :svg)
    placeimage(p)
    finish()
    SVG(svgstring(), d.height, d.width)
end
function load(fn::AbstractString)
    if endswith(fn, r".svg|.SVG")
        loadsvg(fn)
    else
        r = FileIO.load(fn)
        r isa AbstractMatrix && collect(r)
    end
end
function load(file::IO)
    try
        r = FileIO.load(file)
        r isa AbstractMatrix && collect(r)
    catch
        seekstart(file)
        loadsvg(read(file, String))
    end
end

function boundingbox(p::AbstractMatrix, bgcolor; border=0)
    a = c = 1
    b = d = 0
    while a < size(p, 1) && all(@view(p[a, :]) .== bgcolor)
        a += 1
    end
    while b < size(p, 1) && all(@view(p[end-b, :]) .== bgcolor)
        b += 1
    end
    a = max(1, a - border)
    b = min(size(p, 1), max(size(p, 1) - b + border, a))
    p = @view p[a:b, :]
    while c < size(p, 2) && all(@view(p[:, c]) .== bgcolor)
        c += 1
    end
    while d < size(p, 2) && all(@view(p[:, end-d]) .== bgcolor)
        d += 1
    end
    # @show a,b,c,d,border,bgcolor
    # @show c, d, p
    c = max(1, c - border)
    d = min(size(p, 2), max(size(p, 2) - d + border, c))
    return a, b, c, d
end

function cropdrawing_tosvg(m, a, b, c, d) # a, b, c, d are all inclusive
    m2 = Drawing(d - c + 1, b - a + 1, :svg)
    placeimage(m, Point(-c + 1, -a + 1))
    finish()
    SVG(svgstring(), m2.height, m2.width)
end
crop(img::AbstractMatrix, a, b, c, d) = img[a:b, c:d] # a, b, c, d are all inclusive

function imresize(img::AbstractMatrix, sz...; ratio=1)
    rt = ratio isa Number ? ratio : reverse(ratio)
    if isempty(sz)
        ImageTransformations.imresize(img; ratio=rt)
    elseif length(sz) == 1
        sz1 = size(img)
        sz2 = sz1 .* only(sz) ./ sqrt(prod(sz1)) .* ratio
        # given single number as sz, ImageTransformations will resize the height only
        # given both sz and ratio, ImageTransformations will ignore the ratio
        ImageTransformations.imresize(img, ceil.(Int, sz2)...)
    else
        sz2 = reverse(sz) .* ratio
        ImageTransformations.imresize(img, ceil.(Int, sz2)...)
    end
end
function imresize(svg::SVG, sz...; ratio=1)
    sz1 = reverse(size(svg))
    if isempty(sz)
        sz2 = sz1
    elseif length(sz) == 1
        sz2 = sz1 .* only(sz) ./ sqrt(prod(sz1))
    else
        sz2 = sz
    end
    sz2 = sz2 .* ratio
    svgnew = Drawing(sz2..., :svg)
    scale((sz2 ./ sz1)...)
    placeimage(readsvg(string(svg)))
    finish()
    SVG(svgstring(), svgnew.height, svgnew.width)
end

function drawtext(t, size, pos, angle=0, color="black", font="")
    setcolor(parsecolor(color))
    setfont(font, size)
    settext(t, Point(pos...), halign="center", valign="center"; angle=angle)
end

function rendertext(str::AbstractString, size::Real;
    pos=(0, 0), color="black", backgroundcolor=(0, 0, 0, 0), angle=0, font="", border=0, type=:bitmap)
    @assert type in (:svg, :bitmap, :both)
    l = length(str) + 1
    l = ceil(Int, size * l + 2border + 2)
    if type == :bitmap
        Drawing(l, l, :image)
    else
        drawing = Drawing(l, l, :svg) # svg is slow
    end
    origin()
    bgcolor = parsecolor(backgroundcolor)
    bgcolor = background(bgcolor)

    drawtext(str, size, pos, angle, color, font)
    if type == :bitmap
        mat = image_as_matrix()
    end
    finish()
    if type != :bitmap
        mat = tobitmap(SVG(svgstring(), drawing.height, drawing.width))
    end
    #     bgcolor = Luxor.ARGB32(bgcolor...) #https://github.com/JuliaGraphics/Luxor.jl/issues/107
    bgcolor = mat[1]
    box = boundingbox(mat, bgcolor, border=border)
    mat = crop(mat, box...)
    if type == :bitmap
        return mat
    elseif type == :svg
        return cropdrawing_tosvg(drawing, box...)
    else
        return mat, cropdrawing_tosvg(drawing, box...)
    end
end

function rendertextoutlines(str::AbstractString, size::Real; color="black", bgcolor=(0, 0, 0, 0),
    linewidth=3, linecolor="white", font="")
    l = length(str)
    Drawing(ceil(Int, 2l * (size + 2linewidth) + 2), ceil(Int, 2 * (size + 2linewidth) + 2), :image)
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
    mat = crop(mat, boundingbox(mat, mat[1])...)
end

function torgba(c)
    c = Colors.RGBA{Colors.N0f8}(parsecolor(c))
    rgba = (Colors.red(c), Colors.green(c), Colors.blue(c), Colors.alpha(c))
    reinterpret.(UInt8, rgba)
end
torgba(img::AbstractArray) = torgba.(img)
function _backgroundcolor(img, c=:auto)
    if c == :auto
        return img[1] == img[end] && any(c -> c != img[1], img) ? img[1] : (0, 0, 0, 0)
    else
        return c
    end
end
imagemask(img::AbstractArray{Bool,2}) = img
imagemask(img::AbstractMatrix, istransparent::Function) = .!istransparent.(torgba.(img))
imagemask(img::AbstractMatrix, transparent::AbstractArray{Bool,2}) = .!transparent
function imagemask(img::AbstractMatrix, transparent=:auto)
    if transparent == :auto
        if img[1] == img[end] && any(c -> c != img[1], img)
            transparent = img[1]
        else
            transparent = nothing
        end
    end
    if transparent === nothing
        return trues(size(img))
    end
    img .!= convert(eltype(img), parsecolor(transparent))
end
imagemask(img::SVG, istransparent::Function) = imagemask(tobitmap(img), istransparent)
imagemask(img::SVG, transparent::AbstractArray{Bool,2}) = .!transparent
imagemask(img::SVG, transparent=:auto) = imagemask(tobitmap(img), transparent)

function dilate!(mat, r)
    r == 0 && return mat
    mat2 = copy(mat)
    @views for _ in 1:r
        mat2[1:end-1, :] .|= mat[1+1:end, :]
        mat2[1+1:end, :] .|= mat[1:end-1, :]
        mat2[:, 1:end-1] .|= mat[:, 1+1:end]
        mat2[:, 1+1:end] .|= mat[:, 1:end-1]

        mat2[1:end-1, 1:end-1] .|= mat[1+1:end, 1+1:end]
        mat2[1+1:end, 1+1:end] .|= mat[1:end-1, 1:end-1]
        mat2[1:end-1, 1+1:end] .|= mat[1+1:end, 1:end-1]
        mat2[1+1:end, 1:end-1] .|= mat[1:end-1, 1+1:end]
        mat .= mat2
    end
    mat
end

function dilate2(mat, r; smoothness=0.5) # better and slower
    @assert smoothness >= 0
    m = zeros(size(mat) .+ 2)
    m[2:end-1, 2:end-1] .= mat
    # 立方 ∫∫ x^2+y^2 dx dy
    s = max(7, 171 * smoothness) # 13*4+7*4+91, smoothness是平滑系数，0-1，越大越圆但边缘越模糊，越小越方但边缘越清晰
    # s < 7 无意义，反而增加溢出风险
    # 权重 1/1 : 1/13 : 1/7
    o = 91 / s # 1 / ((0.5^3-(-0.5)^3) * 2)
    p = 7 / s # 1 / ((1.5^3-0.5^3) * 2)
    q = 13 / s # 1 / ((1.5^3-0.5^3) + (0.5^3-(-0.5)^3))

    for _ in 1:r
        @views m[2:end-1, 2:end-1] .= (
            o * m[2:end-1, 2:end-1] .+ # 中
            q * m[1:end-2, 2:end-1] .+ q * m[3:end, 2:end-1] .+ # 上下
            q * m[2:end-1, 1:end-2] .+ q * m[2:end-1, 3:end] .+ # 左右
            p * m[1:end-2, 1:end-2] .+ p * m[3:end, 3:end] .+ # 主对角
            p * m[1:end-2, 3:end] .+ p * m[3:end, 1:end-2] # 副对角
        )
    end
    return min.(1.0, m[2:end-1, 2:end-1])
end
"""
## Positional Arguments
* img: a bitmap image
## Keyword Arguments
* linewidth: 0 <= linewidth 
* color: line color
* transparent: the color of the transparent area, default is :auto
* smoothness: 0 <= smoothness <= 1, smoothness of the line, default is 0.5
"""
function outline(img; transparent=:auto, color="black", linewidth=2, smoothness=0.5)
    @assert linewidth >= 0
    mask = imagemask(img, transparent)
    r = 2 * linewidth * smoothness
    # @show r
    mask2 = dilate2(mask, max(linewidth, round(r)), smoothness=smoothness)
    c = ARGB(parsecolor(color)) # https://github.com/JuliaGraphics/Colors.jl/issues/500
    bg = convert.(eltype(img), coloralpha.(c, mask2))
    bg = overlay!(copy(img), bg)
    @views bg[mask] .= overlay.(bg[mask], img[mask])
    bg
end

function pad(img::AbstractMatrix, r=maximum(size(img)) ÷ 10; backgroundcolor=:auto)
    color = convert(eltype(img), parsecolor(_backgroundcolor(img, backgroundcolor)))
    r = ceil.(Int, r)
    bg = fill(color, size(img) .+ 2 .* r)
    overlay!(bg, img, reverse((0, 0) .+ r)...)
end

function pad(img::SVG, r=maximum(size(img)) ÷ 10; backgroundcolor=(0, 0, 0, 0))
    color = parsecolor(backgroundcolor)
    sz = size(img) .+ 2 .* ceil.(Int, r)
    p = readsvg(string(img))
    m2 = Drawing(reverse(sz)..., :svg)
    origin()
    background(color)
    placeimage(p, centered=true)
    finish()
    SVG(svgstring(), m2.height, m2.width)
end
"Return the intersecting region `view`s of img1 and img2, where img2 is positioned in img1 with its top left corner located at coordinates (x, y)."
function intersection_region(img1, img2, x=1, y=1)
    h1, w1 = size(img1)
    h2, w2 = size(img2)
    img1v = @view img1[max(1, y):min(h1, y + h2 - 1), max(1, x):min(w1, x + w2 - 1)]
    img2v = @view img2[max(1, -y + 2):min(h2, -y + h1 + 1), max(1, -x + 2):min(w2, -x + w1 + 1)]
    img1v, img2v
end

function overlay(color1::TransparentRGB, color2::TransparentRGB)
    #     @show color1, color2
    a2 = Colors.alpha(color2)
    if a2 == 0
        return color1
    end
    if a2 == 1
        return color2
    end
    a1 = Colors.alpha(color1) |> Float64
    c1 = (Colors.red(color1), Colors.green(color1), Colors.blue(color1))
    c2 = (Colors.red(color2), Colors.green(color2), Colors.blue(color2))
    a = a1 + a2 - a1 * a2
    c = (c1 .* a1 .* (1 - a2) .+ c2 .* a2) ./ ifelse(a > 0, a, 1)
    #     @show c, a
    typeof(color1)(min.(1, c)..., min(1, a))
end
"Place img2 onto img1 at coordinates (x, y)."
function overlay!(img1::AbstractMatrix, img2::AbstractMatrix, x=1, y=1)# 左上角重合时(x=1,y=1)
    img1v, img2v = intersection_region(img1, img2, x, y)
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

function overlay(imgs, poss; backgroundcolor=(1, 1, 1, 0), size=size(imgs[1]))
    bg = Drawing(size..., :svg)
    Luxor.background(parsecolor(backgroundcolor))
    finish()
    bg = SVG(svgstring(), bg.height, bg.width)
    # (x,y)=(1,1)时左上角重合，此时Point(0,0)
    svgs = (svg_wrap(img, ["svg"=>[("x", string(x-1)), ("y", string(y-1))]]) for (img, (x, y)) in zip(imgs, poss))
    bg = svg_stack(Iterators.flatten(((bg,), svgs)))
    bg
end
function recolor!(img::AbstractArray, color)
    c = parsecolor(color)
    img .= convert.(eltype(img), Colors.alphacolor.(c, Colors.alpha.(img)))
end
function recolor(img::AbstractArray, color)
    c = parsecolor(color)
    convert.(eltype(img), Colors.alphacolor.(c, Colors.alpha.(img)))
end

function squircle(pos, w, h, args...; kargs...)
    Luxor.squircle(pos, w / 2, h / 2, args...; kargs...)
end
function box(pos, w, h, args...; cornerradius=0, kargs...)
    Luxor.box(pos, w, h, cornerradius, args...; kargs...)
end
function ngon(pos, w, h, args...; npoints=5, orientation=0, kargs...)
    r = min(w, h) / 2
    orientation = orientation - π / 2 # 尖朝上
    Luxor.ngon(pos, r, npoints, orientation, args...; kargs...)
end
function star(pos, w, h, args...; npoints=5, starratio=0.5, orientation=0, kargs...)
    r = min(w, h) / 2
    orientation = orientation - π / 2 # 尖朝上
    Luxor.star(pos, r, npoints, starratio, orientation, args...; kargs...)
end
function bezingon(pos, w, h, args...; npoints=3, orientation=0, kargs...)
    r = min(w, h) / 2
    orientation = orientation - π / 2 # 尖朝上
    pts = Luxor.ngon(pos, r, npoints, orientation, vertices=true)
    drawbezierpath(makebezierpath(pts), args...; kargs...)
end
function bezistar(pos, w, h, args...; npoints=5, starratio=0.5, orientation=0, kargs...)
    r = min(w, h) / 2
    orientation = orientation - π / 2 # 尖朝上
    pts = Luxor.star(pos, r, npoints, starratio, orientation, vertices=true)
    drawbezierpath(makebezierpath(pts), args...; kargs...)
end
ellipse_area(h, w) = π * h * w / 4
function box_area(h, w; cornerradius=0)
    r = cornerradius
    @assert min(h, w) >= 2r
    h * w + (π - 4) * r * r
end
function squircle_area(h, w; rt)
    @assert rt < 100
    h * w * (gamma(1 + rt / 2))^2 / gamma(1 + rt)
end
gamma(z) = √(2π / z) * (1 / ℯ * (z + 1 / (12z - 1 / (10z))))^z
function ngon_area(h, w; npoints=5)
    r = min(w, h) / 2
    θ = 2π / npoints
    (r * r * sin(θ)) * npoints / 2
end
function star_area(h, w; npoints=5, starratio=0.5)
    r = min(w, h) / 2
    r2 = r * starratio
    θ = π / npoints
    (r * r2 * sin(θ)) * npoints
end

"""
Generate an SVG image of a box, ellipse, squircle, ngon, star, bezingon, or bezistar.
## Positional Arguments
* shape: one of `box`, `ellipse`, `squircle`, `ngon`, `star`, `bezingon`, or `bezistar`
* width: width of the shape
* height: height of the shape
## Keyword Arguments
* outline: an integer indicating the width of the outline
* padding: an integer or a tuple of two integers indicating the padding size
* backgroundsize: a tuple of two integers indicating the size of the background
* color, linecolor, backgroundcolor: any value that can be parsed as a color. 
* npoints, starratio, orientation, cornerradius, rt: see the Examples section below
## Examples
* shape(box, 80, 50) # box with dimensions 80*50
* shape(box, 80, 50, cornerradius=4) # box with corner radius 4
* shape(squircle, 80, 50, rt=0.7) # squircle or superellipse. rt=0 for rectangle, rt=1 for ellipse, rt=2 for rhombus.
* shape(ngon, 120, 100, npoints=12, orientation=π/6) # regular dodecagon (12 corners) oriented by π/6 
* shape(star, 120, 100, npoints=5) # pentagram (5 tips)
* shape(star, 120, 100, npoints=5, starratio=0.7, orientation=π/2) # 0.7 specifies the ratio of the smaller and larger radii; oriented by π/2
* shape(ellipse, 80, 50, color="red") # red ellipse with dimensions 80*50
* shape(box, 80, 50, backgroundcolor=(0,1,0), backgroundsize=(100, 100)) # 80*50 box on a 100*100 green background
* shape(squircle, 80, 50, outline=3, linecolor="red", backgroundcolor="gray") # add a red outline to the squircle
"""
function shape(shape_, width, height, args...;
    outline=0, linecolor="black", padding=0,
    color="white", backgroundcolor=(0, 0, 0, 0), backgroundsize=(width + 2outline, height + 2outline) .+ 2 .* padding,
    kargs...)
    d = Drawing(ceil.(backgroundsize)..., :svg)
    origin()
    background(parsecolor(backgroundcolor))
    if outline > 0
        setline(outline)
        setcolor(parsecolor(linecolor))
        shape_(Point(0, 0), width, height, args...; action=:stroke, kargs...)
    end
    setcolor(parsecolor(color))
    shape_(Point(0, 0), width, height, args...; action=:fill, kargs...)
    finish()
    SVG(svgstring(), d.height, d.width)
end

using Printf
function try_gif_gen(gifdirectory; framerate=4)
    try
        pipeline(`ffmpeg -f image2 -i $(gifdirectory)/%010d.png -vf 
            palettegen -y $(gifdirectory)/palette.png`, stdout=devnull, stderr=devnull) |> run
        pipeline(`ffmpeg -framerate $(framerate) -f image2 -i $(gifdirectory)/%010d.png 
            -i $(gifdirectory)/palette.png -lavfi paletteuse -y $(gifdirectory)/animation.gif`,
            stdout=devnull, stderr=devnull) |> run
        try
            rm("$(gifdirectory)/palette.png", force=true)
        catch
        end
    catch e
        @warn "You need to have FFmpeg manually installed to use this function."
        @warn e
    end
end
struct GIF
    counter::Base.Iterators.Stateful{UnitRange{Int64},Union{Nothing,Tuple{Int64,Int64}}}
    directory::String
end
function GIF(directory)
    ispath(directory) && @warn "Directory `$directory` already exists."
    mkpath(directory)
    GIF(Iterators.Stateful(0:typemax(Int)), directory)
end
Base.push!(gif::GIF, img) = save(gif.directory * @sprintf("/%010d.png", popfirst!(gif.counter)), img)
(gif::GIF)(img) = Base.push!(gif, img)
generate(gif::GIF, args...; kargs...) = try_gif_gen(gif.directory, args...; kargs...)
end
