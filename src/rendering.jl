module Render
export rendertext, overlay!,
    shape, ellipse, box, squircle, star, ngon, bezistar, bezingon, ellipse_area, box_area, squircle_area,
    star_area, ngon_area, GIF, generate, parsecolor, rendertextoutlines,
    colorschemes, torgba, imagemask, outline, padding, dilate!, imresize, recolor!, recolor
export issvg, save, load, tobitmap, SVGImageType, svgstring
using Luxor
using Colors
using ColorSchemes
using FileIO
using ImageTransformations

# because of float error, (randommask(color=Gray(0.3))|>tobitmap)[300,300]|>torgba != Gray(0.3)|>torgba
parsecolor(c) = ARGB{Colors.N0f8}(parse(Colorant, c))
parsecolor(tp::Tuple) = ARGB{Colors.N0f8}(tp...)
parsecolor(gray::Real) = ARGB{Colors.N0f8}(Gray(gray))
parsecolor(sc::Symbol) = parsecolor.(colorschemes[sc].colors)
parsecolor(sc::AbstractArray) = parsecolor.(sc)

issvg(d) = d isa Drawing && d.surfacetype == :svg
const SVGImageType = Drawing
Base.broadcastable(s::SVGImageType) = Ref(s)
Base.size(s::SVGImageType) = (s.height, s.width)
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
function tobitmap(svg::SVGImageType)
    Drawing(ceil(svg.width), ceil(svg.height), :image)
    placeimage(svg)
    m = image_as_matrix()
    finish()
    m
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

"a, b, c, d are all inclusive"
function crop(img::SVGImageType, a, b, c, d)
    imgnew = Drawing(d - c + 1, b - a + 1, :svg)
    placeimage(img, Point(-c + 1, -a + 1))
    finish()
    imgnew
end
"a, b, c, d are all inclusive"
crop(img::AbstractMatrix, a, b, c, d) = img[a:b, c:d]

function imresize(img::AbstractMatrix, sz...; ratio=1)
    rt = ratio isa Number ? ratio : reverse(ratio)
    if isempty(sz)
        ImageTransformations.imresize(img; ratio=rt)
    else
        sz = (last(sz), first(sz)) .* ratio
        # given single number as sz, ImageTransformations will resize the height only
        # given both sz and ratio, ImageTransformations will ignore the ratio
        ImageTransformations.imresize(img, ceil.(Int, sz)...)
    end
end
function imresize(svg::SVGImageType, sz...; ratio=1)
    sz0 = reverse(size(svg))
    sznew = isempty(sz) ? sz0 : sz
    sznew = sznew .* ratio .* (1, 1)
    svgnew = Drawing(sznew..., :svg)
    scale((sznew ./ sz0)...)
    placeimage(svg)
    finish()
    svgnew
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
        svg = Drawing(l, l, :svg) # svg is slow
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
        mat = tobitmap(svg)
    end
    #     bgcolor = Luxor.ARGB32(bgcolor...) #https://github.com/JuliaGraphics/Luxor.jl/issues/107
    bgcolor = mat[1]
    box = boundingbox(mat, bgcolor, border=border)
    mat = crop(mat, box...)
    if type == :bitmap
        return mat
    elseif type == :svg
        return crop(svg, box...)
    else
        return mat, crop(svg, box...)
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
imagemask(img, istransparent::Function) = .!istransparent.(torgba.(img))
imagemask(img, transparent::AbstractArray{Bool,2}) = .!transparent
function imagemask(img, transparent=:auto)
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
imagemask(img::SVGImageType, transparent) = imagemask(tobitmap(img), transparent)

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
img: a bitmap image
linewidth: 0 <= linewidth
color: line color
transparent: color of the background
smoothness: 0 <= smoothness <= 1
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

function padding(img::AbstractMatrix, r=maximum(size(img)) ÷ 10; backgroundcolor=:auto)
    color = convert(eltype(img), parsecolor(_backgroundcolor(img, backgroundcolor)))
    r = ceil.(Int, r)
    bg = fill(color, size(img) .+ 2 .* r)
    overlay!(bg, img, reverse((0, 0) .+ r)...)
end
function padding(img::SVGImageType, r=maximum(size(img)) ÷ 10; backgroundcolor=(0, 0, 0, 0))
    color = parsecolor(backgroundcolor)
    sz = size(img) .+ 2 .* ceil.(Int, r)
    m2 = Drawing(reverse(sz)..., :svg)
    origin()
    background(color)
    placeimage(img, centered=true)
    finish()
    m2
end
"return the overlapping view of img1 and img2 when img2's top left corner at img1's (x, y)"
function overlappingarea(img1, img2, x=1, y=1)
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
"put img2 on img1 at (x, y)"
function overlay!(img1::AbstractMatrix, img2::AbstractMatrix, x=1, y=1)# 左上角重合时(x=1,y=1)
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

function overlay(imgs, poss; backgroundcolor=(1, 1, 1, 0), size=size(imgs[1]))
    d = Drawing(size..., :svg)
    Luxor.background(parsecolor(backgroundcolor))
    placeimage.(imgs, (Point(x - 1, y - 1) for (x, y) in poss))# (x,y)=(1,1)时左上角重合，此时Point(0,0)
    finish()
    d
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
generate a box, ellipse, squircle, ngon, star, bezingon or bezistar svg image
## Examples
* shape(box, 80, 50) #80*50 box
* shape(box, 80, 50, cornerradius=4) #box with cornerradius=4
* shape(squircle, 80, 50, rt=0.7) #squircle or superellipse. rt=0, rectangle; rt=1, ellipse; rt=2, rhombus
* shape(ngon, 120, 100, npoints=12, orientation=π/6) #regular dodecagon (12 corners) oriented by π/6 
* shape(star, 120, 100, npoints=5) #pentagram (5 tips)
* shape(star, 120, 100, npoints=5, starratio=0.7, orientation=π/2) #0.7 specifies the ratio of the smaller radius of the star and the larger; oriented by π/2
* shape(ellipse, 80, 50, color="red") #80*50 red ellipse
* shape(box, 80, 50, backgroundcolor=(0,1,0), backgroundsize=(100, 100)) #80*50 box on 100*100 green background
* shape(squircle, 80, 50, outline=3, linecolor="red", backgroundcolor="gray") #add a red outline to the squircle
outline: an Integer  
padding: an Integer or a tuple of two Integers  
backgroundsize: a tuple of two Integers
color, linecolor, backgroundcolor: anything that can be parsed to a color
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
    d
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
