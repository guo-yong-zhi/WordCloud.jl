## occupancy
import Statistics.mean
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
function cumsum2d!(B, A)
    cumsum!(B, A, dims=1)
    cumsum!(B, B, dims=2)
end
function sum2d(S, a, b, c, d)
    a = min(a-1, lastindex(S, 1))
    b = min(b-1, lastindex(S, 2))
    c = min(c, lastindex(S, 1))
    d = min(d, lastindex(S, 2))
    ans = 0
    a>0 && b>0 && (ans += @inbounds S[a, b])
    c>0 && d>0 && (ans += @inbounds S[c, d])
    a>0 && d>0 && (ans -= @inbounds S[a, d])
    c>0 && b>0 && (ans -= @inbounds S[c, b])
    return ans
end
function dilatedoccupancy(img::AbstractMatrix, r, bgvalue=img[1], border=0)
    mask = img .!= bgvalue
    S = cumsum2d!(similar(mask, Int), mask)
    sum(sum2d(S, i-r, j-r, i+r, j+r)>0 for i in 1+border:size(S, 1)-border for j in 1+border:size(S, 2)-border; init=0)
end
function dilatedoccupancy(imgs::AbstractVector, r, bgvalue=imgs[1][1], border=0)
    if isempty(imgs) return 0 end
    return sum(p -> dilatedoccupancy(p, r, bgvalue, border), imgs)
end
function feelingoccupancy(imgs, border=0, bgvalue=imgs[1][1])
    s = minimum.(size.(imgs))
    r = round(Int, mean(@view(s[end-end÷10:end]))/3*2)
    big = s .> 3r
    oc = dilatedoccupancy(@view(imgs[big]), r, bgvalue, border) + boxoccupancy(@view(imgs[.!big]), border)
    oc * 0.93
end

function wordsoccupancy!(wc)
    words = wc.words
    fonts = getfonts(wc)
    angles = getangles(wc) ./ 180 .* π
    border = 1
    sizemax = size(wc.mask) .* √(getparameter(wc, :contentarea) / prod(size(wc.mask))) .* 0.8
    check = getparameter(wc, :maxfontsize0) == :auto
    imgs = []
    for i in 1:3
        empty!(imgs)
        fontsizes = getfontsizes(wc)
        success = true
        for (c, sz, ft, θ) in zip(words, fontsizes, fonts, angles)
            img = Render.rendertext(string(c), sz, backgroundcolor=(0, 0, 0, 0), font=ft, border=border)
            a, b = size(img)
            imsz = max(a*abs(cos(θ)), b*abs(sin(θ))), max(a*abs(sin(θ)), b*abs(cos(θ)))
            if check && i < 3 && any(imsz .> sizemax)
                mfz = sz * minimum(sizemax ./ imsz) * 0.95
                if mfz < getparameter(wc, :maxfontsize)
                    setparameter!(wc, mfz, :maxfontsize)
                    println("The word \"$c\"($sz) is too big. Set maxfontsize = $mfz.")
                    success = false
                    break
                end
            end
            push!(imgs, img)
        end
        success && break
    end
    feelingoccupancy(imgs, border) # border>0 以获取背景色img[1]
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

wordmask(img, bgcolor, border) = dilate!(alpha.(img) .!= 0, border)
# use `alpha` instead of `convert(eltype(img), parsecolor(bgcolor))`
# https://github.com/JuliaGraphics/Luxor.jl/issues/107
function ternary_wordmask(img, bgcolor, border)
    tmask = fill(Stuffing.EMPTY, size(img))
    m0 = alpha.(img) .!= 0
    m1 = dilate!(copy(m0), border)
    tmask[m1] .= Stuffing.MIX
    tmask[m0] .= Stuffing.FULL
    tmask
end

function contentsize_proposal(words, weights)
    weights = weights ./ (sum(weights) / length(weights)) #权重为平均值的单词为中等大小的单词。weights不平方，即按条目平均，而不是按面积平均
    12 * √sum(length.(words) .* weights .^ 2) #中等大小的单词其每个字母占据12 pixel*12 pixel 
end

## findscale!
function scaleiterstep(x₀, y₀, x₁, y₁, y)
    x₀ = x₀^2
    x₁ = x₁^2
    x = ((x₁ - x₀) * y + x₀ * y₁ - x₁ * y₀) / (y₁ - y₀) # 假设y=k*x^2+b，割线法
    (x > 0) ? √x : (√min(x₀, x₁)) / 2
end

function findscale!(wc::WC; initialscale=0, density=0.3, maxiter=5, tolerance=0.05)
    area = getparameter(wc, :contentarea)
    words = wc.words
    if initialscale <= 0
        initialscale = √(area / length(words) / 0.4 * density) # 初始值假设字符的字面框面积占正方格比率为0.4（低估了汉字）
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
    sc0 = 0.
    tg0 = 0.
    oneway_count = 1
    while true
        step = step + 1
        if step > maxiter
            @warn "The `findscale!` has performed `maxiter`($maxiter) iterations. The set `density` is not reached. This may be caused by too small background, too big `minfontsize` or unsuitable number of words."
            break
        end
        # cal tg1
        setparameter!(wc, sc1, :scale)
        tg1 = wordsoccupancy!(wc)
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
        sc2 = scaleiterstep(sc0, tg0, sc1, tg1, target)
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
                error("`findscale!` failed")
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
