using Colors
using ImageMagick

function randomscheme()
    scheme = rand(Render.schemes)
    colors = Render.colorschemes[scheme].colors
    @show (scheme, length(colors))
    (colors...,)
end
function randommask(color, sz=800)
    s = sz * sz * (0.5+rand()/2)
    ratio = (0.5+rand()/2)
    ratio = ratio>0.9 ? 1.0 : ratio
    h = round(Int, sqrt(s*ratio))
    w = round(Int, h/ratio)
    if rand() > 0.5
        return shape(box, w, h, round(Int, h*(0.05+rand()/5)), color=color, bgcolor=ARGB(1, 1, 1, 0))
    else
        return shape(ellipse, w, h, color=color, bgcolor=ARGB(1, 1, 1, 0))
    end
end
function randomangles()
    a = rand((0, (0,90),(0,90,45), -90:90))
end

import ImageTransformations.imresize
"""
loadmaskimg("res/heart.jpg")  
loadmaskimg("res/heart.jpg", 256, 256) #resize to 256*256  
loadmaskimg("res/heart.jpg", ratio=0.3) #scale 0.3  
loadmaskimg("res/heart.jpg", color="red", ratio=2) #set forecolor color  
loadmaskimg("res/heart.jpg", color="red", transparentcolor=(1,1,1)) #set forecolor color with transparentcolor  
"""
function loadmaskimg(img::AbstractMatrix, args...; color=:original, transparentcolor=:auto, kargs...)
    if color!=:original
        color = parsecolor(color)
        transparentcolor = transparentcolor==:auto ? img[1] : parsecolor(transparentcolor)
        m = @view img[img.!=transparentcolor]
        m .= convert.(typeof(img[1]), Colors.alphacolor.(color, Colors.alpha.(m))) #保持透明度
    end
    if !(isempty(args) && isempty(kargs))
        img = imresize(img, args...; kargs...)
    end
    img
end
function loadmaskimg(path, args...; kargs...)
    loadmaskimg(ImageMagick.load(path),  args...; kargs...)
end

mutable struct wordcloud
    texts
    weights
    imgs
    maskimg
    qtrees
    maskqtree
    params::Dict{Symbol,Any}
end

"""
## kargs example
### style kargs
colors = "black" #all same color  
colors = ("black", (0.5,0.5,0.7), "yellow", "#ff0000") #choose randomly  
colors = ["black", (0.5,0.5,0.7), "yellow", "red", (0.5,0.5,0.7), ......] #use sequentially in cycle  
angles = 0 #all same angle  
angles = (0, 90, 45) #choose randomly  
angles = 0:180 #choose randomly  
angles = [0, 22, 4, 1, 100, 10, ......] #use sequentially in cycle  
filling_rate = 0.5  
border = 1  
### mask kargs
maskimg = loadmaskimg("res/heart.jpg", 256, 256) #see doc of `loadmaskimg`  
maskimg = loadmaskimg("res/heart.jpg", color="red", ratio=2) #see doc of `loadmaskimg`  
maskimg = shape(ellipse, 800, 600, color="white", bgcolor=(0,0,0,0)) #see doc of `shape`  
transparentcolor = ARGB32(0,0,0,0) #set the transparent color in maskimg  
"""
function wordcloud(texts::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}; 
                colors=randomscheme(), angles=randomangles(), font="",
                filling_rate=0.5, border=1, kargs...)
    
    @assert length(texts) == length(weights)
    params = Dict{Symbol, Any}(kargs...)
#     @show params
    si = sortperm(weights, rev=true)
    texts = texts[si]
    weights = weights[si]
    
    colors_o = colors
    colors = Iterators.take(iter_expand(colors), length(texts)) |> collect
    colors = colors[si]
    params[:colors] = colors

    angles = Iterators.take(iter_expand(angles), length(texts)) |> collect
    angles = angles[si]
    params[:angles] = angles
    params[:font] = font
    if !haskey(params, :maskimg)
        maskcolor = "white"
        try
#             maskcolor = RGB(1,1,1) - RGB(sum(colors_o)/length(colors_o)) #补色
            maskcolor = sum(Gray.(parsecolor.(colors_o)))/length(colors_o)<0.7 ? "white" : "black" #黑白
#             @show sum(colors_o)/length(colors_o)
        catch
            @show "colors sum failed",colors_o
            maskcolor = "black"
        end
        maskimg = randommask(maskcolor)
        transparentcolor = get(params, :transparentcolor, ARGB(1, 1, 1, 0))
    else
        maskimg = params[:maskimg]
    end
    transparentcolor = get(params, :transparentcolor, maskimg[1])
    maskimg, maskqtree, groundsize, groundoccupied = preparebackground(maskimg, transparentcolor)
    params[:maskimg] = maskimg
    params[:maskqtree] = maskqtree
    params[:groundsize] = groundsize
    params[:groundoccupied] = groundoccupied

    weights = weights ./ √(sum(weights.^2) / length(weights))
    params[:weights] = weights
    scale = find_weight_scale(texts, weights, groundoccupied, border=border, initial_scale=0, 
    filling_rate=filling_rate, max_iter=5, error=0.03)
    params[:scale] = scale
    params[:filling_rate] = filling_rate
    imgs, mimgs, qtrees = prepareforeground(texts, weights * scale, colors, angles, groundsize, 
    bgcolor=(0, 0, 0, 0), border=border, font=font);
    params[:border] = border
    params[:font] = font
    placement!(deepcopy(maskqtree), qtrees)
    wordcloud(texts, weights, imgs, maskimg, qtrees, maskqtree, params)
end

function getposition(wc)
    msy, msx = getshift(wc.maskqtree)
    pos = getshift.(wc.qtrees)
    map(p->(p[2]-msx+1, p[1]-msy+1), pos)
end

function paint(wc::wordcloud, args...; kargs...)
    resultpic = convert.(ARGB32, wc.maskimg)#.|>ARGB32
    overlay!(resultpic, wc.imgs, getposition(wc))
    if !(isempty(args) && isempty(kargs))
        resultpic = imresize(resultpic, args...; kargs...)
    end
    resultpic
end

function paint(wc::wordcloud, file)
    ImageMagick.save(file, paint(wc))
end

function record(wc::wordcloud, ep::Number, gif_callback)
    resultpic = overlay!(paint(wc), rendertext(string(ep), 32), 10, 10)
    gif_callback(resultpic)
end

function generate(wc::wordcloud, nepoch::Number=600, args...; trainer=trainepoch_gen!, optimiser=Momentum(η=1/4, ρ=0.5), patient=10, krags...)
    ep, nc = train_with_teleport!(wc.qtrees, wc.maskqtree, nepoch, args...; trainer=trainer, optimiser=optimiser, patient=patient, krags...)
end

function generate_animation(wc::wordcloud, args...; outputdir="gifresult", callbackstep=1, kargs...)
    try `mkdir $(outputdir)`|>run catch end
    gif = GIF(outputdir)
    record(wc, 0, gif)
    ep, nc = generate(wc, args...; callbackstep=callbackstep, callbackfun=ep->record(wc, ep, gif), kargs...)
    Render.generate(gif)
    ep, nc
end