## occupied
function occupied(img::AbstractMatrix, bgvalue=0)
    return sum(img .!= bgvalue)
end

function occupied(imgs::AbstractVector, bgvalue=0)
    return sum(p->occupied(p, bgvalue), imgs)
end

function text_occupied(text, weight, scale; radius=1)
    imgs = []
    for (c, sz) in zip(text, weight)
#         print(c)
        img = Render.rendertext(string(c), sz * scale, border=radius)
        img = Render.textmask(img, img[1], radius=radius)
        push!(imgs, img)
    end
    return occupied(imgs)
end

## prepare
function preparebackground(img, bgcolor)
    maskqt = maskqtree(mask.|>Gray) |> buildqtree!
    groundsize = size(maskqt[1], 1)
    groundoccupied = occupied(mask .!= bgcolor)
    return img, maskqt, groundsize, groundoccupied
end

ele_expend(e) = Base.Iterators.repeated(e)
ele_expend(l::Vector) = Base.Iterators.cycle(l)
ele_expend(t::Tuple) = IterGen(st->rand(t))

struct IterGen
    generator
end
Base.iterate(it::IterGen, state=0) = it.generator(state),state+1

function prepare_texts(texts, weights, colors, angles, groundsize; bgcolor=(0,0,0,0), border=1)
    ts = []
    imgs = []
    mimgs = []
    for (txt,sz,color,an) in zip(texts, weights, colors, angles)
#         print(c)
        img, mimg = rendertext(string(txt),sz, color=color, bgcolor=bgcolor,
            angle=an, border=border, returnmask=true)
        t = ShiftedQtree(mimg, groundsize) |> buildqtree!
        push!(ts, t)
        push!(imgs, img)
        push!(mimgs, mimg)
    end
    return imgs, mimgs, ts
end

## weight_scale
function cal_weight_scale(text, weight, target; initial_scale=64)
    input = initial_scale
    output = text_occupied(text, weight, input)
    return output, sqrt(target / output) * input # 假设output=k*input^2
end

function find_weight_scale(text, weight, ground_size; initial_scale=0, filling_rate=0.3, max_iter=5, error=0.05)
    if initial_scale <= 0
        initial_scale = √(ground_size/length(text))
    end
    @assert sum(weight.^2) / length(weight) ≈ 1.0
    target_lower = (filling_rate - error) * ground_size
    target_upper = (filling_rate + error) * ground_size
    step = 0
    sc = initial_scale
    while true
        tg, sc = cal_weight_scale(text, weight, filling_rate * ground_size, initial_scale=sc)
        @show sc, tg, tg / ground_size
        if step >= max_iter
            println("find_weight_scale reach max_iter")
            break
        end
        if target_lower <= tg <= target_upper
            break
        end
    end
    return sc
end

function max_collisional_index(qtrees, mask)
    l = length(qtrees)
    for i in l:-1:1
        for j in 0:i-1
            getqtree(i) = i==0 ? mask : qtrees[i]
            c, cp = collision(getqtree(i), getqtree(j))
            if c
                return i
            end
        end
    end
    nothing
end

function max_collisional_index_rand(qtrees, mask)
    l = length(qtrees)
    for i in l:-1:1
        if rand() > 0.8
            continue
        end
        for j in 0:i-1
            getqtree(i) = i==0 ? mask : qtrees[i]
            c, cp = collision(getqtree(i), getqtree(j))
            if c
                return i
            end
        end
    end
    nothing
end

