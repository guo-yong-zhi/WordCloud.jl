## occupied
import Statistics.quantile
function occupied(img::AbstractMatrix, bgvalue=img[1])
    return sum(img .!= bgvalue)
end

function occupied(imgs::AbstractVector, bgvalue=imgs[1][1])
    if isempty(imgs) return 0 end
    return sum(p->occupied(p, bgvalue), imgs)
end
function boxoccupied(img::AbstractMatrix, border=0)
    return (size(img, 1)-2border) * (size(img, 2)-2border)
end
function boxoccupied(imgs::AbstractVector, border=0)
    if isempty(imgs) return 0 end
    return sum(p->boxoccupied(p, border), imgs)
end
function feelingoccupied(imgs, border=0, bgvalue=imgs[1][1])
    s = boxoccupied.(imgs, border)
    th = 10quantile(s, 0.1)
    bigind = findall(x->x>th, s)
#     @show length(bigind)
    er = (sum(s[bigind]) - occupied(imgs[bigind], bgvalue)) * 0.25 #兼顾大字的内隙和小字的占据
    sum(s) - er
end

function textoccupied(words, fontsizes, fonts)
    border=1
    imgs = []
    for (c, sz, ft) in zip(words, fontsizes, fonts)
#         print(c)
        img = Render.rendertext(string(c), sz, backgroundcolor=(0,0,0,0), font=ft, border=border)
        push!(imgs, img)
    end
    feelingoccupied(imgs, border) #border>0 以获取背景色imgs[1]
end

## prepare
function maskqtree(pic::AbstractMatrix{UInt8})
    m = log2(max(size(pic)...)*1.1)
    s = 2^ceil(Int, m)
    qt = ShiftedQtree(pic, s, default=QTree.FULL)
#     @show size(pic),m,s
    a, b = size(pic)
    setrshift!(qt[1], (s-a)÷2)
    setcshift!(qt[1], (s-b)÷2)
    return qt
end
function maskqtree(pic::AbstractMatrix, bgcolor=pic[1])
    pic = map(x -> x==bgcolor ? QTree.FULL : QTree.EMPTY, pic)
    maskqtree(pic)
end
function preparebackground(img, bgcolor)
    maskqt = maskqtree(img, bgcolor) |> buildqtree!
    groundsize = size(maskqt[1], 1)
    groundoccupied = occupied(img, bgcolor)
    @assert groundoccupied==occupied(QTree.kernel(maskqt[1]), QTree.FULL)
    return img, maskqt, groundsize, groundoccupied
end

function prepareword(word, fontsize, color, angle; backgroundcolor=(0,0,0,0), font="", border=0)
    rendertext(string(word), fontsize, color=color, backgroundcolor=backgroundcolor,
        angle=angle, border=border, font=font, type=:both)
end

wordmask(img, bgcolor, border) = dilate(img.!=img[1], border) 
#https://github.com/JuliaGraphics/Luxor.jl/issues/107

## weight_scale
function cal_weight_scale(words, fontsizes, fonts, target, initialscale)
    input = initialscale
    output = textoccupied(words, fontsizes, fonts)
    return output, sqrt(target/output) * input# 假设output=k*input^2
end

function find_weight_scale!(wc::WC; initialscale=0, density=0.3, maxiter=5, error=0.05)
    ground_size = wc.params[:groundoccupied]
    words = wc.words
    if initialscale <= 0
        initialscale = √(ground_size/length(words)/0.4*density) #初始值假设字符的字面框面积占正方格比率为0.4（低估了汉字）
    end
    @assert sum(wc.weights.^2 .* length.(words)) / length(wc.weights) ≈ 1.0
    target_lower = (density - error) * ground_size
    target_upper = (density + error) * ground_size
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
        tg, sc = cal_weight_scale(words, getfontsizes(wc, words), fonts, density*ground_size, sc)
        println("scale=$(wc.params[:scale]), density=$(tg/ground_size)")
        if target_lower <= tg <= target_upper
            break
        end
        
    end
#     @show textoccupied(words, weights, sc, radius=border)
    wc.params[:scale] = sc
    return sc
end

