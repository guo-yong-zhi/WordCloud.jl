module Render
export rendertext, textmask

using Luxor

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

function rendertext(str::AbstractString, size::Real; color="black", bkcolor=(0,0,0,0), angle=0, font="WenQuanYi Micro Hei", border=0)
    l = length(str) + 1
    l = ceil(Int, size*l + 2border)
    Drawing(l, l, :image)
    origin()
    if bkcolor isa Tuple
        bkcolor = background(bkcolor...)
    else
        bkcolor = background(bkcolor)
    end
    bkcolor = Luxor.ARGB32(bkcolor...)
    setcolor(color)
    setfont(font, size)
    settext(str, halign="center", valign="center"; angle=angle)
    mat = image_as_matrix()
    finish()
    mat
    mat = backgroundclip(mat, mat[1], border=border)
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

function textmask(pic, bkcolor; radius=0)
    mask = pic .!= bkcolor
    dilate(mask, radius)
end

end