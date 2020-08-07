module Render
export rendertext, textmask, overlay!, shape

using Luxor
using Colors
using ColorSchemes

function backgroundclip(p::AbstractMatrix, bgcolor; border=0)
    a = c = 1
    b = d = 0
    while all(p[a,:] .== bgcolor) && a < size(p, 1)
        a += 1
    end
    while all(p[end-b,:] .== bgcolor) && b < size(p, 1)
        b += 1
    end
    p = p[a-border:end-b+border, :]
    while all(p[:,c] .== bgcolor) && c < size(p, 2)
        c += 1
    end
    while all(p[:, end-d] .== bgcolor) && d < size(p, 2)
        d += 1
    end
#     @show a,b,c,d,border,bgcolor
    return p[:, c-border:end-d+border]
end

function rendertext(str::AbstractString, size::Real; color="black", bgcolor=(0,0,0,0), angle=0, font="", border=0, returnmask=false)
    l = length(str) + 1
    l = ceil(Int, size*l + 2border)
    Drawing(l, l, :image)
    origin()
    if bgcolor isa Tuple
        bgcolor = background(bgcolor...)
    else
        bgcolor = background(bgcolor)
    end
    bgcolor = Luxor.ARGB32(bgcolor...)
    setcolor(color)
    setfont(font, size)
    settext(str, halign="center", valign="center"; angle=angle)
    mat = image_as_matrix()
    finish()
    bgcolor = mat[1] #bgcolor(1,0,0,0) will be image_as_matrix trans to (0,0,0,0)
    mat = backgroundclip(mat, bgcolor, border=border)
    if returnmask
        return mat, textmask(mat, bgcolor, radius=border)
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

function overlay(color1, color2)
#     @show color1, color2
    c1 = [Colors.red(color1), Colors.green(color1), Colors.blue(color1)]
    c2 = [Colors.red(color2), Colors.green(color2), Colors.blue(color2)]
    a1 = Colors.alpha(color1)
    a2 = Colors.alpha(color2) 
    a = a1 + a2 - a1 * a2
    c = (c1 .* a1 .* (1-a2) .+ c2 .* a2) ./ (a>0 ? a : 1)
#     c = max.(1., c)
#     a = max(1., a)
#     @show (c..., a>1), a1, a2, c1, c2
    typeof(color1)(c..., a)
end

"put img2 on img1 at (x, y)"
function overlay!(img1, img2, x=1, y=1)
    h1, w1 = size(img1)
    h2, w2 = size(img2)
    h3 = min(h2, h1-y+1)
    w3 = min(w2, w1-x+1)
    img1v = @view img1[y:y+h3-1, x:x+w3-1]
    img2v = @view img2[1:h3, 1:w3]
    img1v .= overlay.(img1v, img2v)
    img1
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
shape(ellipse, 80, 50, color="red") #80*50 ellipse
"""
function shape(shape_, width, height, args...; color="white", bgcolor=(0,0,0,0))
    Drawing(width, height, :image)
    origin()
    if bgcolor isa Tuple
        bgcolor = background(bgcolor...)
    else
        bgcolor = background(bgcolor)
    end
    setcolor(color)
    shape_(Point(0,0), width, height, args..., :fill)
    mat = image_as_matrix()
    finish()
    mat
end

end