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
    a = rand((0, (0,90),(0,90,45),(0,-90),(0,-45,-90),-90:90))
    println("angles = ", a)
    a
end

import ImageTransformations.imresize
"""
## examples
* loadmask("res/heart.jpg")  
* loadmask("res/heart.jpg", 256, 256) #resize to 256*256  
* loadmask("res/heart.jpg", ratio=0.3) #scale 0.3  
* loadmask("res/heart.jpg", color="red", ratio=2) #set forecolor color  
* loadmask("res/heart.jpg", color="red", transparentcolor=(1,1,1)) #set forecolor color with transparentcolor  
"""
function loadmask(img::AbstractMatrix, args...; color=:original, backgroundcolor=:original, transparentcolor=:auto, kargs...)
    if color!=:original || backgroundcolor!=:original
        img = ARGB.(img)
        transparentcolor = transparentcolor==:auto ? img[1] : parsecolor(transparentcolor)
        mask = img.!=transparentcolor
        if color!=:original
            color = parsecolor(color)
            m = @view img[mask]
            m .= convert.(typeof(img[1]), Colors.alphacolor.(color, Colors.alpha.(m))) #保持透明度
        end
        if backgroundcolor!=:original
            backgroundcolor = parsecolor(backgroundcolor)
            m = @view img[.~mask]
            m .= convert.(typeof(img[1]), Colors.alphacolor.(backgroundcolor, Colors.alpha.(m))) #保持透明度
        end
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
    mask
    qtrees
    maskqtree
    params::Dict{Symbol,Any}
end

"""
## kargs examples
### style kargs
* colors = "black" #all same color  
* colors = ("black", (0.5,0.5,0.7), "yellow", "#ff0000", 0.2) #choose entries randomly  
* colors = ["black", (0.5,0.5,0.7), "yellow", "red", (0.5,0.5,0.7), 0.2, ......] #use entries sequentially in cycle  
* angles = 0 #all same angle  
* angles = (0, 90, 45) #choose entries randomly  
* angles = 0:180 #choose entries randomly  
* angles = [0, 22, 4, 1, 100, 10, ......] #use entries sequentially in cycle  
* fillingrate = 0.5  
* border = 1  
### mask kargs
* mask = loadmask("res/heart.jpg", 256, 256) #see doc of `loadmask`  
* mask = loadmask("res/heart.jpg", color="red", ratio=2) #see doc of `loadmask`  
* mask = shape(ellipse, 800, 600, color="white", bgcolor=(0,0,0,0)) #see doc of `shape`  
* transparentcolor = ARGB32(0,0,0,0) #set the transparent color in mask  
"""
wordcloud(wordsweights::Tuple; kargs...) = wordcloud(wordsweights...; kargs...)
wordcloud(counter::AbstractDict; kargs...) = wordcloud(keys(counter)|>collect, values(counter)|>collect; kargs...)
wordcloud(counter::AbstractVector{<:Pair}; kargs...) = wordcloud(first.(counter), last.(counter); kargs...)

function wordcloud(words::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}; 
                colors=randomscheme(), angles=randomangles(), font="",
                fillingrate=0.65, border=1, minfontsize=:auto, kargs...)
    
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
    if !haskey(params, :mask)
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
        @show maskcolor
        mask = randommask(maskcolor)
        transparentcolor = get(params, :transparentcolor, ARGB(1, 1, 1, 0)) |> parsecolor
    else
        mask = params[:mask]
    end
    transparentcolor = get(params, :transparentcolor, mask[1]) |> parsecolor
    mask, maskqtree, groundsize, groundoccupied = preparebackground(mask, transparentcolor)
#     params[:mask] = mask
#     params[:maskqtree] = maskqtree
    params[:groundsize] = groundsize
    params[:groundoccupied] = groundoccupied
    @assert groundoccupied > 0
       
    if minfontsize==:auto
        minfontsize = min(8, sqrt(groundoccupied/length(words)/8))
        println("set minfontsize to $minfontsize")
        @show groundoccupied, length(words)
    end
    weights = weights ./ √(sum(weights.^2 .* length.(words)) / length(weights))
    params[:weights] = weights
    scale = find_weight_scale(words, weights, groundoccupied, border=border, initialscale=0, 
    fillingrate=fillingrate, maxiter=5, error=0.03, minfontsize=minfontsize)
    params[:scale] = scale
    params[:fillingrate] = fillingrate
    println("set fillingrate to $fillingrate, with scale=$scale")
    imgs, mimgs, qtrees = prepareforeground(words, weights * scale, colors, angles, groundsize, 
    bgcolor=(0, 0, 0, 0), border=border, font=font, minfontsize=minfontsize);
    params[:mimgs] = mimgs
    params[:border] = border
    params[:font] = font
    params[:minfontsize] = minfontsize
    params[:completed] = false
    params[:epoch] = 0
    placement!(deepcopy(maskqtree), qtrees)
    wordcloud(words, weights, imgs, mask, qtrees, maskqtree, params)
end
Base.getindex(wc::wordcloud, inds...) = wc.words[inds...]=>wc.weights[inds...]
Base.lastindex(wc::wordcloud) = lastindex(wc.words)
iscompleted(wc::wordcloud) = wc.params[:completed]
function getposition(wc)
    msy, msx = getshift(wc.maskqtree)
    pos = getshift.(wc.qtrees)
    map(p->(p[2]-msx+1, p[1]-msy+1), pos)
end
QTree.placement!(wc::wordcloud) = placement!(deepcopy(wc.maskqtree), wc.qtrees)
function paint(wc::wordcloud, args...; kargs...)
    resultpic = convert.(ARGB32, wc.mask)#.|>ARGB32
    overlay!(resultpic, wc.imgs, getposition(wc))
    if !(isempty(args) && isempty(kargs))
        resultpic = convert.(ARGB{Colors.N0f8}, resultpic)
        resultpic = imresize(resultpic, args...; kargs...)
    end
    resultpic
end

function paint(wc::wordcloud, file, args...; kargs...)
    img = paint(wc, args...; kargs...)
    ImageMagick.save(file, img)
    img
end

function record(wc::wordcloud, label::AbstractString, gif_callback=x->x)
#     @show size(n1)
    resultpic = overlay!(paint(wc), 
        rendertextoutlines(label, 32, color="black", linecolor="white", linewidth=1), 20, 20)
    gif_callback(resultpic)
end

"""
# Positional Args
* wc: the wordcloud to train
* nepoch: training epoch nums
# Keyword Args
* retry: shrink & retrain times, default 3
* patient: number of epochs before teleporting & number of identical teleportation before giving up
* trainer: appoint a training engine
"""
function generate!(wc::wordcloud, args...; retry=3, krags...)
    ep, nc = -1, -1
    for r in 1:retry
        # fr = feelingoccupied(wc.params[:mimgs])/wc.params[:groundoccupied]
        if r != 1
            sc = wc.params[:scale] * 0.95
            rescale!(wc, sc)
        end
        println("#$r. scale = $(wc.params[:scale])")
        ep, nc = train!(wc.qtrees, wc.maskqtree, args...; krags...)
        wc.params[:epoch] += ep
        if nc == 0
            break
        end
    end
    @show ep, nc
    if nc == 0
        wc.params[:completed] = true
    else #check
        colllist = first.(listcollision(wc.qtrees, wc.maskqtree))
        get_text(i) = i>0 ? wc.words[i] : "#MASK#"
        collwords = [(get_text(i), get_text(j)) for (i,j) in colllist]
        if length(colllist) > 0
            wc.params[:completed] = false
            println("have $(length(colllist)) collision.",
            " try setting a larger `nepoch` and `retry`, or lower `fillingrate` in `wordcloud` to fix that")
            println("$collwords")
        else
            wc.params[:completed] = true
        end
    end
    wc
end

function generate_animation!(wc::wordcloud, args...; outputdir="gifresult", overwrite=false, callbackstep=1, kargs...)
    if overwrite
        try `rm -r $(outputdir)`|>run catch end
    end
    try `mkdir $(outputdir)`|>run catch end
    gif = GIF(outputdir)
    record(wc, "0", gif)
    re = generate!(wc, args...; callbackstep=callbackstep, callbackfun=ep->record(wc, string(ep), gif), kargs...)
    Render.generate(gif)
    re
end

function ignore(fun, wc::wordcloud, mask::AbstractArray{Bool})
    mem = [wc.words, wc.weights, wc.imgs, wc.qtrees, 
            wc.params[:colors], wc.params[:angles], wc.params[:mimgs]]
    mask = .!mask
    wc.words = @view wc.words[mask]
    wc.weights = @view wc.weights[mask]
    wc.imgs = @view wc.imgs[mask]
    wc.qtrees = @view wc.qtrees[mask]
    wc.params[:colors] = @view wc.params[:colors][mask]
    wc.params[:angles] = @view wc.params[:angles][mask]
    wc.params[:mimgs] = @view wc.params[:mimgs][mask]
    r = nothing
    try
        r = fun()
    finally
        wc.words = mem[1]
        wc.weights = mem[2]
        wc.imgs = mem[3]
        wc.qtrees = mem[4]
        wc.params[:colors] = mem[5]
        wc.params[:angles] = mem[6]
        wc.params[:mimgs] = mem[7]    
    end
    r
end

function pin(fun, wc::wordcloud, mask::AbstractArray{Bool})
    maskqtree = wc.maskqtree
    wcmask = wc.mask
    maskqtree2 = deepcopy(maskqtree)
    QTree.overlap!.(Ref(maskqtree2), wc.qtrees[mask])
    wc.maskqtree = maskqtree2
    resultpic = convert.(ARGB32, wc.mask)
    wc.mask = overlay!(resultpic, wc.imgs[mask], getposition(wc)[mask])
    r = nothing
    try
        r = ignore(fun, wc, mask)
    finally
        wc.maskqtree = maskqtree
        wc.mask = wcmask
    end
    r
end

function ignore(fun, wc, ws::AbstractString)
    ignore(fun, wc, wc.words .== ws)
end

function ignore(fun, wc, ws::AbstractSet{<:AbstractString})
    ignore(fun, wc, wc.words .∈ Ref(ws))
end

function ignore(fun, wc, ws::AbstractArray{<:AbstractString})
    ignore(fun, wc, Set(ws))
end

function pin(fun, wc, ws::AbstractString)
    pin(fun, wc, wc.words .== ws)
end

function pin(fun, wc, ws::AbstractSet{<:AbstractString})
    pin(fun, wc, wc.words .∈ Ref(ws))
end

function pin(fun, wc, ws::AbstractArray{<:AbstractString})
    pin(fun, wc, Set(ws))
end

Base.show(io::IO, m::MIME"image/png", wc::wordcloud) = Base.show(io, m, paint(wc::wordcloud))
Base.show(io::IO, m::MIME"text/plain", wc::wordcloud) = print(io, "wordcloud(", wc.words, ") #", length(wc.words), "words")
# Base.show(io::IO, wc::wordcloud) = print(io, "wordcloud(", wc.words, ") #", length(wc.words), "words")
