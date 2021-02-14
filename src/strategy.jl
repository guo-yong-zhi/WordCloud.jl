## occupied
function occupied(img::AbstractMatrix, bgvalue=0)
    return sum(img .!= bgvalue)
end

function occupied(imgs::AbstractVector, bgvalue=0)
    if isempty(imgs) return 0 end
    return sum(p->occupied(p, bgvalue), imgs)
end
function box_occupied(img::AbstractMatrix)
    return size(img, 1) * size(img, 2)
end
function box_occupied(imgs::AbstractVector)
    if isempty(imgs) return 0 end
    return sum(box_occupied, imgs)
end
function feelingoccupied(imgs)
    imgs = sort(imgs, by=prod∘size, rev=true)
    m = length(imgs) ÷ 100
    occupied(imgs[1:m])/4 + 3box_occupied(imgs[1:m])/4 + box_occupied(imgs[m+1:end]) #兼顾大字的内隙和小字的占据
end

function text_occupied(words, fontsizes, fonts; border=0)
    imgs = []
    for (c, sz, ft) in zip(words, fontsizes, fonts)
#         print(c)
        img = Render.rendertext(string(c), sz, bgcolor=(0,0,0,0),font=ft, border=border)
        push!(imgs, wordmask(img, (0,0,0,0), border))
    end
    feelingoccupied(imgs)
end

## prepare
function preparebackground(img, bgcolor)
    maskqt = maskqtree(img, bgcolor) |> buildqtree!
    groundsize = size(maskqt[1], 1)
    groundoccupied = occupied(img, bgcolor)
    @assert groundoccupied==occupied(QTree.kernel(maskqt[1]), QTree.FULL)
    return img, maskqt, groundsize, groundoccupied
end

iter_expand(e) = Base.Iterators.repeated(e)
iter_expand(l::Vector) = Base.Iterators.cycle(l)
iter_expand(r::AbstractRange) = IterGen(st->rand(r))
iter_expand(t::Tuple) = IterGen(st->rand(t))

struct IterGen
    generator
end
Base.iterate(it::IterGen, state=0) = it.generator(state),state+1
Base.length(it::IterGen) = typemax(Int)

function prepareword(word, fontsize, color, angle, groundsize; bgcolor=(0,0,0,0), font="", border=0)
    rendertext(string(word), fontsize, color=color, bgcolor=bgcolor,
        angle=angle, border=border, font=font, returnsvg=true)
end

wordmask(img, bgcolor, border) = dilate(img.!=img[1], border) 
#https://github.com/JuliaGraphics/Luxor.jl/issues/107

## weight_scale
function cal_weight_scale(words, fontsizes, fonts, target, initialscale; border=0, kargs...)
    input = initialscale
    output = text_occupied(words, fontsizes, fonts; border=border, kargs...)
#     @show input,output 
    return output, sqrt(target/output) * (input+2border) - 2border# 假设output=k*(input+2border)^2
end

function find_weight_scale!(wc::WC; initialscale=0, fillingrate=0.3, maxiter=5, error=0.05, kargs...)
    ground_size = wc.params[:groundoccupied]
    words = wc.words
    if initialscale <= 0
        initialscale = √(ground_size/length(words))
    end
    @assert sum(wc.weights.^2 .* length.(words)) / length(wc.weights) ≈ 1.0
    target_lower = (fillingrate - error) * ground_size
    target_upper = (fillingrate + error) * ground_size
    step = 0
    sc = initialscale
    fonts = getfonts(wc, words)
    while true
        step = step + 1
        if step > maxiter
            @warn "find_weight_scale reach maxiter. This may be caused by too small background image or too many words or too big `minfontsize`."
            break
        end
        wc.params[:scale] = sc
        tg, sc = cal_weight_scale(words, getfontsizes(wc, words), fonts, 
        fillingrate*ground_size, sc; kargs...)
        println("scale=$sc, fillingrate=$(tg/ground_size)")
        if target_lower <= tg <= target_upper
            break
        end
        
    end
#     @show text_occupied(words, weights, sc, radius=border)
    wc.params[:scale] = sc
    return sc
end

function max_collisional_index(qtrees, mask)
    l = length(qtrees)
    getqtree(i) = i==0 ? mask : qtrees[i]
    for i in l:-1:1
        for j in 0:i-1
            cp = collision(getqtree(i), getqtree(j))
            if cp[1] >= 0
                return i
            end
        end
    end
    nothing
end

function max_collisional_index_rand(qtrees, mask; collpool)
    l = length(collpool)
    b = l - floor(Int, l / 8 * randexp()) #从末尾1/8起
    sort!(collpool)
    getqtree(i) = i==0 ? mask : qtrees[i]
    for k in b:-1:1
        i, j = collpool[k]
        cp = collision(getqtree(i), getqtree(j))
        if cp[1] >= 0
            return j
        end
    end
    for k in l:-1:b+1
        i, j = collpool[k]
        cp = collision(getqtree(i), getqtree(j))
        if cp[1] >= 0
            return j
        end
    end
    return nothing
end

function collisional_indexes_rand(qtrees, mask, collpool::Vector{Tuple{Int,Int}})
    cinds = Vector{Int}()
    l = length(collpool)
    if l == 0
        return cinds
    end
    keep = (l ./ 8 .* randexp(l)) .> l:-1:1 #约保留1/8
    if !any(keep)
        keep[end] = 1
    end
    sort!(collpool, by=x->x[2])
#     @show collpool keep
    getqtree(i) = i==0 ? mask : qtrees[i]
    for (i, j) in @view collpool[keep]
        if j in cinds
            continue
        end
        cp = collision(getqtree(i), getqtree(j))
        if cp[1] >= 0
            push!(cinds, j)
        end
    end
    return cinds
end
function collisional_indexes_rand(qtrees, mask, collpool::Vector{QTree.ColItemType})
    collisional_indexes_rand(qtrees, mask, first.(collpool))
end
