module Render
export rendertext, textmask, overlay!, shape, ellipse, box, GIF, generate, parsecolor

using Luxor
using Colors
using ColorSchemes
using ImageMagick

parsecolor(c) = parse(Colorant, c)
parsecolor(tp::Tuple) = ARGB32(tp...)
parsecolor(gray::Real) = Gray(gray)

function backgroundclip(p::AbstractMatrix, bgcolor; border=0)
    a = c = 1
    b = d = 0
    while all(p[a,:] .== bgcolor) && a < size(p, 1)
        a += 1
    end
    while all(p[end-b,:] .== bgcolor) && b < size(p, 1)
        b += 1
    end
    a = max(1, a-border)
    b = min(size(p, 1), max(size(p, 1)-b+border, a))
    p = p[a:b, :]
    while all(p[:,c] .== bgcolor) && c < size(p, 2)
        c += 1
    end
    while all(p[:, end-d] .== bgcolor) && d < size(p, 2)
        d += 1
    end
    # @show a,b,c,d,border,bgcolor
    # @show c, d, p
    c = max(1, c-border)
    d = min(size(p, 2), max(size(p, 2)-d+border, c))
    return p[:, c:d]
end

function rendertext(str::AbstractString, size::Real; color="black", bgcolor=(0,0,0,0), angle=0, font="", border=0, returnmask=false)
    l = length(str) + 1
    l = ceil(Int, size*l + 2border + 2)
    Drawing(l, l, :image)
    origin()
    bgcolor = parsecolor(bgcolor)
    bgcolor = background(bgcolor)
    bgcolor = Luxor.ARGB32(bgcolor...)
    setcolor(parsecolor(color))
    setfont(font, size)
    settext(str, halign="center", valign="center"; angle=angle)
    mat = image_as_matrix()
    finish()
    mat = backgroundclip(mat, mat[1], border=border)
    if returnmask
        return mat, textmask(mat, mat[1], radius=border)
    else
        return mat
    end
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
function overlay!(img1::AbstractMatrix, img2::AbstractMatrix, x=1, y=1)
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
shape(box, 80, 50) #80*50 box
shape(box, 80, 50, 4) #box with cornerradius=4
shape(ellipse, 80, 50, color="red") #80*50 red ellipse
"""
function shape(shape_, width, height, args...; color="white", bgcolor=(0,0,0,0))
    Drawing(width, height, :image)
    origin()
    bgcolor = parsecolor(bgcolor)
    background(bgcolor)
    setcolor(parsecolor(color))
    shape_(Point(0,0), width, height, args..., :fill)
    mat = image_as_matrix()
    finish()
    mat
end

using Printf
function gif_callback_factory()
    counter = Iterators.Stateful(0:typemax(Int))
    pic->save(gifdirectory*@sprintf("/%010d.png", popfirst!(counter)), pic)
end
function try_gif_gen(gifdirectory)
    try
        pipeline(`ffmpeg -f image2 -i $(gifdirectory)/%010d.png -vf 
            palettegen -y $(gifdirectory)/result-palette.png`, stdout=devnull, stderr=devnull) |> run
        pipeline(`ffmpeg -framerate 4 -f image2 -i $(gifdirectory)/%010d.png 
            -i $(gifdirectory)/result-palette.png -lavfi paletteuse -y $(gifdirectory)/result.gif`,
            stdout=devnull, stderr=devnull) |> run
    catch e
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
generate(gif::GIF) = try_gif_gen(gif.directory)
end