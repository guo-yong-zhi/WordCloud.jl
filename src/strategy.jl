## occupied
function occupied(img::AbstractMatrix, bgvalue=0)
    return sum(img .!= bgvalue)
end

function occupied(imgs::AbstractVector, bgvalue=0)
    return sum(p->occupied(p, bgvalue), imgs)
end

function text_occupied(texts, weights, scale; radius=0)
    imgs = []
    for (c, sz) in zip(texts, weights)
#         print(c)
        img = Render.rendertext(string(c), sz * scale, border=radius)
        img = Render.textmask(img, img[1], radius=radius)
        push!(imgs, img)
    end
    return occupied(imgs)
end

## prepare
function preparebackground(img, bgcolor)
    maskqt = maskqtree(img, bgcolor) |> buildqtree!
    groundsize = size(maskqt[1], 1)
    groundoccupied = occupied(img, bgcolor)
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

function prepareforeground(texts, weights, colors, angles, groundsize; bgcolor=(0,0,0,0), font="", border=0)
    ts = []
    imgs = []
    mimgs = []
    for (txt,sz,color,an) in zip(texts, weights, colors, angles)
#         print(c)
        img, mimg = rendertext(string(txt),sz, color=color, bgcolor=bgcolor,
            angle=an, border=border, font=font, returnmask=true)
        t = ShiftedQtree(mimg, groundsize) |> buildqtree!
        push!(ts, t)
        push!(imgs, img)
        push!(mimgs, mimg)
    end
    return imgs, mimgs, ts
end

## weight_scale
function cal_weight_scale(texts, weights, target; initial_scale=64, border=0)
    input = initial_scale
    output = text_occupied(texts, weights, input, radius=border)
    return output, sqrt(target/output) * (input+2border) - 2border# 假设output=k*(input+2border)^2
end

function find_weight_scale(texts, weights, ground_size; border=0, initial_scale=0, filling_rate=0.3, max_iter=5, error=0.05)
    if initial_scale <= 0
        initial_scale = √(ground_size/length(texts))
    end
    @assert sum(weights.^2) / length(weights) ≈ 1.0
    target_lower = (filling_rate - error) * ground_size
    target_upper = (filling_rate + error) * ground_size
    step = 0
    sc = initial_scale
    while true
        tg, sc = cal_weight_scale(texts, weights, filling_rate * ground_size, initial_scale=sc, border=border)
        @show sc, tg, tg / ground_size
        if step >= max_iter
            @warn "find_weight_scale reach max_iter"
            break
        end
        if target_lower <= tg <= target_upper
            break
        end
    end
#     @show text_occupied(texts, weights, sc, radius=border)
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

# function max_collisional_index_rand(qtrees, mask)
#     l = length(qtrees)
#     b = l - floor(Int, l / 8 * randexp()) #从末尾1/8起
#     getqtree(i) = i==0 ? mask : qtrees[i]
#     for i in b:-1:1
#         for j in 0:i-1
#             cp = collision(getqtree(i), getqtree(j))
#             if cp[1] >= 0
#                 return i
#             end
#         end
#     end
#     for i in l:-1:b+1
#         for j in 0:i-1
#             cp = collision(getqtree(i), getqtree(j))
#             if cp[1] >= 0
#                 return i
#             end
#         end
#     end
#     nothing
# end

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
function collisional_indexes_rand(qtrees, mask; collpool)
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

function rescale!(wc::wordcloud, scale::Real)
    qts = wc.qtrees
    center(qt) = getshift(qt) .+ kernelsize(qt) .÷ 2
    centers = center.(qts)
    imgs, mimgs, qtrees = prepareforeground(wc.texts, wc.weights * scale, 
        wc.params[:colors], wc.params[:angles], wc.params[:groundsize], 
    bgcolor=(0, 0, 0, 0), border=wc.params[:border], font=wc.params[:font])
    wc.imgs = imgs
    wc.qtrees = qtrees
    wc.params[:scale] = scale
    lefttop(center, qt) = center .- kernelsize(qt) .÷  2
    setshift!.(qtrees, 1, lefttop.(centers, qtrees))
    wc
end