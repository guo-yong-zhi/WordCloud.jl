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
loadmask("res/heart.jpg")  
loadmask("res/heart.jpg", 256, 256) #resize to 256*256  
loadmask("res/heart.jpg", ratio=0.3) #scale 0.3  
loadmask("res/heart.jpg", color="red", ratio=2) #set forecolor color  
loadmask("res/heart.jpg", color="red", transparentcolor=(1,1,1)) #set forecolor color with transparentcolor  
"""
function loadmask(img::AbstractMatrix, args...; color=:original, transparentcolor=:auto, kargs...)
    if color!=:original
        img = ARGB.(img)
        color = parsecolor(color)
        transparentcolor = transparentcolor==:auto ? img[1] : parsecolor(transparentcolor)
        m = @view img[img.!=transparentcolor]
        m .= convert.(typeof(img[1]), Colors.alphacolor.(color, Colors.alpha.(m))) #保持透明度
    end
    if !(isempty(args) && isempty(kargs))
        img = imresize(img, args...; kargs...)
    end
    println("mask size ", size(img))
    img
end
function loadmask(path, args...; kargs...)
    loadmask(ImageMagick.load(path),  args...; kargs...)
end

mutable struct wordcloud
    words
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
colors = ("black", (0.5,0.5,0.7), "yellow", "#ff0000", 0.2) #choose entries randomly  
colors = ["black", (0.5,0.5,0.7), "yellow", "red", (0.5,0.5,0.7), 0.2, ......] #use entries sequentially in cycle  
angles = 0 #all same angle  
angles = (0, 90, 45) #choose entries randomly  
angles = 0:180 #choose entries randomly  
angles = [0, 22, 4, 1, 100, 10, ......] #use entries sequentially in cycle  
filling_rate = 0.5  
border = 1  
### mask kargs
maskimg = loadmask("res/heart.jpg", 256, 256) #see doc of `loadmask`  
maskimg = loadmask("res/heart.jpg", color="red", ratio=2) #see doc of `loadmask`  
maskimg = shape(ellipse, 800, 600, color="white", bgcolor=(0,0,0,0)) #see doc of `shape`  
transparentcolor = ARGB32(0,0,0,0) #set the transparent color in maskimg  
"""
wordcloud(wordsweights::Tuple; kargs...) = wordcloud(wordsweights...; kargs...)
wordcloud(counter::AbstractDict; kargs...) = wordcloud(keys(counter)|>collect, values(counter)|>collect; kargs...)
wordcloud(counter::AbstractVector{<:Pair}; kargs...) = wordcloud(first.(counter), last.(counter); kargs...)

function wordcloud(words::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}; 
                colors=randomscheme(), angles=randomangles(), font="",
                filling_rate=0.5, border=1, kargs...)
    
    @assert length(words) == length(weights) > 0
#     @show words,weights
    params = Dict{Symbol, Any}(kargs...)
#     @show params
    si = sortperm(weights, rev=true)
    words = words[si]
    weights = weights[si]
    
    colors_o = colors
    colors = Iterators.take(iter_expand(colors), length(words)) |> collect
    colors = colors[si]
    params[:colors] = colors

    angles = Iterators.take(iter_expand(angles), length(words)) |> collect
    angles = angles[si]
    params[:angles] = angles
    params[:font] = font
    if !haskey(params, :maskimg)
        maskcolor = "white"
        try
#             maskcolor = RGB(1,1,1) - RGB(sum(colors_o)/length(colors_o)) #补色
            if sum(Gray.(parsecolor.(colors_o)))/length(colors_o)<0.7 #黑白
                maskcolor = rand((1.0, (rand(0.9:0.01:1.0), rand(0.9:0.01:1.0), rand(0.9:0.01:1.0))))
            else
                maskcolor = rand((0.0, (rand(0.0:0.01:0.1), rand(0.0:0.01:0.1), rand(0.0:0.01:0.1))))
            end
#             @show sum(colors_o)/length(colors_o)
        catch
            @show "colors sum failed",colors_o
            maskcolor = "black"
        end
        maskimg = randommask(maskcolor)
        transparentcolor = get(params, :transparentcolor, ARGB(1, 1, 1, 0)) |> parsecolor
    else
        maskimg = params[:maskimg]
    end
    transparentcolor = get(params, :transparentcolor, maskimg[1]) |> parsecolor
    maskimg, maskqtree, groundsize, groundoccupied = preparebackground(maskimg, transparentcolor)
#     params[:maskimg] = maskimg
#     params[:maskqtree] = maskqtree
    params[:groundsize] = groundsize
    params[:groundoccupied] = groundoccupied
    @assert groundoccupied > 0

    weights = weights ./ √(sum(weights.^2 .* length.(words)) / length(weights))
    params[:weights] = weights
    scale = find_weight_scale(words, weights, groundoccupied, border=border, initial_scale=0, 
    filling_rate=filling_rate, max_iter=5, error=0.03)
    params[:scale] = scale
    params[:filling_rate] = filling_rate
    println("set filling_rate to $filling_rate")
    imgs, mimgs, qtrees = prepareforeground(words, weights * scale, colors, angles, groundsize, 
    bgcolor=(0, 0, 0, 0), border=border, font=font);
    params[:mimgs] = mimgs
    params[:border] = border
    params[:font] = font
    placement!(deepcopy(maskqtree), qtrees)
    wordcloud(words, weights, imgs, maskimg, qtrees, maskqtree, params)
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

function record(wc::wordcloud, ep::Number, gif_callback=x->x)
#     @show size(n1)
    resultpic = overlay!(paint(wc), 
        rendertextoutlines(string(ep), 32, color="black", linecolor="white", linewidth=1), 20, 20)
    gif_callback(resultpic)
end

function generate(wc::wordcloud, nepoch::Number=100, args...; retry=3,
    trainer=trainepoch_gen!, optimiser=Momentum(η=1/4, ρ=0.5), patient=10, krags...)
    ep, nc = -1, -1
    for r in 1:retry
        # fr = feelingoccupied(wc.params[:mimgs])/wc.params[:groundoccupied]
        println("#$r. scale = $(wc.params[:scale])")
        ep, nc = train_with_teleport!(wc.qtrees, wc.maskqtree, nepoch, args...; 
            trainer=trainer, optimiser=optimiser, patient=patient, krags...)
        if nc == 0
            break
        end
        sc = wc.params[:scale] * 0.95
        rescale!(wc, sc)
    end
    @show ep, nc
    if nc != 0
        colllist = listcollision(wc.qtrees, wc.maskqtree)
        get_text(i) = i>0 ? wc.words[i] : "#MASK#"
        collwords = [(get_text(i), get_text(j)) for (i,j) in colllist]
        if length(colllist) > 0
            println("have $(length(colllist)) collision.",
            " try setting a larger `nepoch` and `retry`, or lower `filling_rate` in `wordcloud` to fix that")
            println("$collwords")
        end
    end
    wc
end

function generate_animation(wc::wordcloud, args...; outputdir="gifresult", callbackstep=1, kargs...)
    try `mkdir $(outputdir)`|>run catch end
    gif = GIF(outputdir)
    record(wc, 0, gif)
    re = generate(wc, args...; callbackstep=callbackstep, callbackfun=ep->record(wc, ep, gif), kargs...)
    Render.generate(gif)
    re
end

Base.show(io::IO, m::MIME"image/png", wc::wordcloud) = Base.show(io, m, paint(wc::wordcloud))
Base.show(io::IO, m::MIME"text/plain", wc::wordcloud) = print(io, "wordcloud(", wc.words, ") #", length(wc.words), "words")
# Base.show(io::IO, wc::wordcloud) = print(io, "wordcloud(", wc.words, ") #", length(wc.words), "words")
