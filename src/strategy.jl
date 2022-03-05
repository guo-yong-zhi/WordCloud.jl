## occupancy
import Statistics.quantile
function occupancy(img::AbstractMatrix, bgvalue=img[1])
    return sum(img .!= bgvalue)
end
function occupancy(imgs::AbstractVector, bgvalue=imgs[1][1])
    if isempty(imgs) return 0 end
    return sum(p -> occupancy(p, bgvalue), imgs)
end
function boxoccupancy(img::AbstractMatrix, border=0)
    return (size(img, 1) - 2border) * (size(img, 2) - 2border)
end
function boxoccupancy(imgs::AbstractVector, border=0)
    if isempty(imgs) return 0 end
    return sum(p -> boxoccupancy(p, border), imgs)
end
function feelingoccupancy(imgs, border=0, bgvalue=imgs[1][1])
    bs = boxoccupancy.(imgs, border)
    os = occupancy.(imgs, bgvalue)
    s = (0.8 * sum(bs) + 0.2 * sum(os)) / 0.93 # 兼顾饱满字体（华文琥珀）和清瘦字体（仿宋）
    # sum(os) ≈ 2/3 sum(bs), 故除以0.93还原到sum(bs)的大小
    th = 10quantile(bs, 0.1)
    bigind = findall(x -> x > th, bs)
#     @show length(bigind)
    er = (sum(bs[bigind]) - sum(os[bigind])) * 0.2 # 兼顾大字的内隙和小字的占据
    (s - er)
end

function textoccupancy(words, fontsizes, fonts)
    border = 1
    imgs = []
    for (c, sz, ft) in zip(words, fontsizes, fonts)
#         print(c)
        img = Render.rendertext(string(c), sz, backgroundcolor=(0, 0, 0, 0), font=ft, border=border)
        push!(imgs, img)
    end
    feelingoccupancy(imgs, border) # border>0 以获取背景色imgs[1]
end

## prepare
function preparemask(img, bgcolor)
    mask = imagemask(img, bgcolor)
    maskqt = maskqtree(mask)
    groundsize = size(maskqt[1], 1)
    contentarea = occupancy(mask, false)
    @assert contentarea == occupancy(QTrees.kernel(maskqt[1]), QTrees.FULL)
    return img, maskqt, groundsize, contentarea
end

function prepareword(word, fontsize, color, angle; backgroundcolor=(0, 0, 0, 0), font="", border=0)
    mat, svg = rendertext(string(word), fontsize, color=color, backgroundcolor=backgroundcolor,
        angle=angle, border=border, font=font, type=:both)
    Render.recolor!(mat, color), svg # 字体边缘有杂色
end

wordmask(img, bgcolor, border) = dilate(alpha.(img) .!= 0, border)
# use `alpha` instead of `convert(eltype(img), parsecolor(bgcolor))`
# https://github.com/JuliaGraphics/Luxor.jl/issues/107

function contentsize_proposal(words, weights)
    weights = weights ./ (sum(weights) / length(weights)) #权重为平均值的单词为中等大小的单词。weights不平方，即按条目平均，而不是按面积平均
    12 * √sum(length.(words) .* weights .^ 2) #中等大小的单词其每个字母占据12 pixel*12 pixel 
end

## weight_scale
function scalestep(x₀, y₀, x₁, y₁, y)
    x₀ = x₀^2
    x₁ = x₁^2
    x = ((x₁ - x₀) * y + x₀ * y₁ - x₁ * y₀) / (y₁ - y₀) # 假设y=k*x^2+b
    (x > 0) ? √x : (√min(x₀, x₁)) / 2
end

function find_weight_scale!(wc::WC; initialscale=0, density=0.3, maxiter=5, tolerance=0.05)
    area = getparameter(wc, :contentarea)
    words = wc.words
        if initialscale <= 0
        initialscale = √(area / length(words) / 0.45 * density) # 初始值假设字符的字面框面积占正方格比率为0.45（低估了汉字）
    end
    @assert sum(wc.weights.^2 .* length.(words)) / length(wc.weights) ≈ 1.0
    target = density * area
    target_lower = (density - tolerance) * area
    target_upper = (density + tolerance) * area
    target = density * area
    best_tar_H = Inf
    best_tar_L = -Inf
    best_scale_H = Inf
    best_scale_L = -Inf
    step = 0
    sc1 = initialscale
    fonts = getfonts(wc)
    sc0 = 0.
    tg0 = 0.
    oneway_count = 1
    while true
        step = step + 1
        if step > maxiter
            @warn "find_weight_scale! reach the `maxiter`. The `density` may be inaccurate. This may be caused by too small background, too many words or too big `minfontsize`."
            break
        end
        # cal tg1
        setparameter!(wc, sc1, :scale)
        tg1 = textoccupancy(words, getfontsizes(wc), fonts)
        dens = tg1 / area
        println("⋯scale=$(getparameter(wc, :scale)), density=$dens\t", dens > density ? "↑" : "↓")
        if tg1 > target
            if best_tar_H > tg1
                best_tar_H = tg1
                best_scale_H = sc1
            end
        else
            if best_tar_L <= tg1
                best_tar_L = tg1
                best_scale_L = sc1
            end
        end
        # cal sc2
        sc2 = scalestep(sc0, tg0, sc1, tg1, target)
#         @show sc0, tg0, sc1, tg1, sc2
        if !(best_scale_L < sc2 < best_scale_H)
            if isfinite(best_tar_H + best_tar_L)
                sc2_ = √((best_scale_H^2 + best_scale_L^2) / 2.)
                println("bisection search takes effect: scale $sc2 -> $sc2_")
                sc2 = sc2_
#                 @show best_scale_L best_scale_H
            elseif isfinite(best_tar_H)
                sc2_ = sc1 * (0.95^oneway_count)
                oneway_count += 1
                println("one-way search takes effect: scale $sc2 -> $sc2_")
                sc2 = sc2_
            elseif isfinite(best_tar_L)
                sc2_ = sc1 / (0.95^oneway_count)
                oneway_count += 1
                println("one-way search takes effect: scale $sc2 -> $sc2_")
                sc2 = sc2_
            else
                error("find_weight_scale! failed")
            end
        end
        if sc2 >= 50initialscale # 防止空白words的输入，计算出sc过大渲染字体耗尽内存
            @warn "Extra large font size detected. The density $density may be unreachable."
            break
        end
        # next iter init
        tg0 = tg1
        sc0 = sc1
        sc1 = sc2
        if target_lower <= tg1 <= target_upper
            break
        end
    end
    setparameter!(wc, sc1, :scale)
    return sc1
end
