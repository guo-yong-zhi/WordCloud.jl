function occupied(img::AbstractMatrix)
    return sum(img .!= 0)
end

function occupied(imgs::AbstractVector)
    return sum(occupied, imgs)
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