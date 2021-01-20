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
load a img as mask, recolor, or resize, etc
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
## Positional Arguments
Positional arguments are used to specify words and weights, and can be in different forms, such as Tuple or Dict, etc.
* words::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}
* words_weights::Tuple
* counter::AbstractDict
* counter::AbstractVector{<:Pair}
## Optional Keyword Arguments
### style keyword arguments
* colors = "black" #all same color  
* colors = ("black", (0.5,0.5,0.7), "yellow", "#ff0000", 0.2) #choose entries randomly  
* colors = ["black", (0.5,0.5,0.7), "yellow", "red", (0.5,0.5,0.7), 0.2, ......] #use entries sequentially in cycle  
* colors = :seaborn_dark #using a preset scheme. see `WordCloud.colorschemes` for all supported Symbol
* angles = 0 #all same angle  
* angles = (0, 90, 45) #choose entries randomly  
* angles = 0:180 #choose entries randomly  
* angles = [0, 22, 4, 1, 100, 10, ......] #use entries sequentially in cycle  
* fillingrate = 0.5 #default 0.65  
* border = 1  
### mask keyword arguments
* mask = loadmask("res/heart.jpg", 256, 256) #see doc of `loadmask`  
* mask = loadmask("res/heart.jpg", color="red", ratio=2) #see doc of `loadmask`  
* mask = shape(ellipse, 800, 600, color="white", bgcolor=(0,0,0,0)) #see doc of `shape`  
* transparentcolor = ARGB32(0,0,0,0) #set the transparent color in mask  
### other keyword arguments
The keyword argument `run` is a function. It will be called after the `wordcloud` object constructed.
* run = placement! #default setting, will initialize word's position
* run = generate! #get result directly
* run = initwords! #only initialize resources, such as rendering word images
* run = x->nothing #do nothing
---
* After getting the `wordcloud` object, these steps are needed to get the result picture: initwords! -> placement! -> generate! -> paint
* You can skip `placement!` and/or `initwords!`, and the default action will be performed
"""
wordcloud(wordsweights::Tuple; kargs...) = wordcloud(wordsweights...; kargs...)
wordcloud(counter::AbstractDict; kargs...) = wordcloud(keys(counter)|>collect, values(counter)|>collect; kargs...)
wordcloud(counter::AbstractVector{<:Pair}; kargs...) = wordcloud(first.(counter), last.(counter); kargs...)

function wordcloud(words::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}; 
                colors=randomscheme(), angles=randomangles(), run=placement!, kargs...)
    
    @assert length(words) == length(weights) > 0
    params = Dict{Symbol, Any}(kargs...)
#     @show params
    colors = colors isa Symbol ? (colorschemes[:seaborn_dark].colors..., ) : colors
    colors_o = colors
    colors = Iterators.take(iter_expand(colors), length(words)) |> collect
    params[:colors] = colors

    angles = Iterators.take(iter_expand(angles), length(words)) |> collect
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
    params[:groundsize] = groundsize
    params[:groundoccupied] = groundoccupied
    @assert groundoccupied > 0
    minfontsize = get(params, :minfontsize, :auto)
    if minfontsize==:auto
        minfontsize = min(8, sqrt(groundoccupied/length(words)/8))
        println("set minfontsize to $minfontsize")
        @show groundoccupied length(words)
        params[:minfontsize] = minfontsize
    end
    get!(params, :border, 1)
    get!(params, :fillingrate, 0.65)
    get!(params, :font, "")
    
    params[:state] = nameof(wordcloud)
    params[:epoch] = 0
    params[:indsmap] = nothing
    l = length(words)
    wc = wordcloud(words, float.(weights), Vector(undef, l), mask, Vector(undef, l), maskqtree, params)
    run(wc)
    wc
end

Base.getindex(wc::wordcloud, inds...) = wc.words[inds...]=>wc.weights[inds...]
Base.lastindex(wc::wordcloud) = lastindex(wc.words)
Base.broadcastable(wc::wordcloud) = Ref(wc)
getstate(wc::wordcloud) = wc.params[:state]
setstate!(wc::wordcloud, st::Symbol) = wc.params[:state] = st
function getindsmap(wc::wordcloud)
    if wc.params[:indsmap] === nothing
        wc.params[:indsmap] = Dict(zip(wc.words, Iterators.countfrom(1)))
    end
    wc.params[:indsmap]
end
function index(wc::wordcloud, w::AbstractString)
    getindsmap(wc)[w]
end
index(wc::wordcloud, w::AbstractVector) = index.(wc, w)
index(wc::wordcloud, i) = i
getdoc = "The 1st arg is a wordcloud, the 2nd arg can be a word string(list) or a standard supported index and ignored to return all."
setdoc = "The 1st arg is a wordcloud, the 2nd arg can be a word string(list) or a standard supported index, the 3rd arg is the value to assign."
@doc getdoc getcolors(wc::wordcloud, w=:) = wc.params[:colors][index(wc, w)]
@doc getdoc getangles(wc::wordcloud, w=:) = wc.params[:angles][index(wc, w)]
@doc getdoc getwords(wc::wordcloud, w=:) = wc.words[index(wc, w)]
@doc getdoc getweights(wc::wordcloud, w=:) = wc.weights[index(wc, w)]
@doc setdoc setcolors!(wc::wordcloud, w, c) = @view(wc.params[:colors][index(wc, w)]) .= parsecolor(c)
@doc setdoc setangles!(wc::wordcloud, w, a::Union{Number, AbstractVector{<:Number}}) = @view(wc.params[:angles][index(wc, w)]) .= a
@doc setdoc 
function setwords!(wc::wordcloud, w, v::Union{AbstractString, AbstractVector{<:AbstractString}})
    m = getindsmap(wc)
    @assert !any(v .∈ Ref(keys(m)))
    i = index(wc, w)
    Broadcast.broadcast((old,new)->m[new]=pop!(m,old), wc.words[i], v)
    @view(wc.words[i]) .= v
    v
end
@doc setdoc setweights!(wc::wordcloud, w, v::Union{Number, AbstractVector{<:Number}}) = @view(wc.weights[index(wc, w)]) .= v
@doc getdoc getimages(wc::wordcloud, w=:) = wc.imgs[index(wc, w)]
@doc getdoc getfontsizes(wc::wordcloud, w=:) = max.(wc.params[:minfontsize], wc.weights[index(wc, w)] * wc.params[:scale])

getmask(wc::wordcloud) = wc.mask

@doc getdoc * " Keyword argment `type` can be `getshift` or `getcenter`."
function getpositions(wc::wordcloud, w=:; type=getshift)
    msy, msx = getshift(wc.maskqtree)
    pos = type.(wc.qtrees[index(wc, w)])
    pos = eltype(pos) <: Number ? Ref(pos) : pos
    Broadcast.broadcast(p->(p[2]-msx+1, p[1]-msy+1), pos)
end

@doc setdoc * " Keyword argment `type` can be `setshift!` or `setcenter!`."
function setpositions!(wc::wordcloud, w, x_y; type=setshift!)
    x, y = x_y
    msy, msx = getshift(wc.maskqtree)
    type(wc.qtrees[index(wc, w)], (y-1+msy, x-1+msx))
    x_y
end
            
"Initialize word's images and other resources with specified style"
function initword!(wc, w, sz=wc.weights[index(wc, w)]*wc.params[:scale]; 
        bgcolor=(0,0,0,0), border=wc.params[:border], font=wc.params[:font], minfontsize=wc.params[:minfontsize])
    i = index(wc, w)
    params = wc.params
    img, mimg, tree = prepareword(wc.words[i], max(sz, minfontsize), params[:colors][i], params[:angles][i], params[:groundsize], 
    bgcolor=bgcolor, border=border, font=font)
    wc.imgs[i] = img
    wc.qtrees[i] = tree
    nothing
end

function initword!(wc::wordcloud)
    params = wc.params
    mask = wc.mask
    
    si = sortperm(wc.weights, rev=true)
    words = wc.words[si]
    weights = wc.weights[si]
    weights = weights ./ √(sum(weights.^2 .* length.(words)) / length(weights))
    wc.words .= words
    wc.weights .= weights
    wc.params[:colors] .= wc.params[:colors][si]
    wc.params[:angles] .= wc.params[:angles][si]
    wc.params[:indsmap] = nothing

    scale = find_weight_scale(words, weights, params[:groundoccupied], border=params[:border], initialscale=0, 
    fillingrate=params[:fillingrate], maxiter=5, error=0.03, font=params[:font], minfontsize=params[:minfontsize])
    println("set fillingrate to $(params[:fillingrate]), with scale=$scale")
    params[:scale] = scale
    initword!.(wc, 1:length(words))
    params[:state] = nameof(initwords!)
    wc
end
initwords!(wc::wordcloud) = initword!(wc)

function QTree.placement!(wc::wordcloud)
    if getstate(wc) == nameof(wordcloud)
        initwords!(wc)
    end
    placement!(deepcopy(wc.maskqtree), wc.qtrees)
    wc.params[:state] = nameof(placement!)
    wc
end

"rescale!(wc::wordcloud, ratio::Real)\nRescale all words's size. set `ratio`<1 to shrink, set `ratio`>1 to expand."
function rescale!(wc::wordcloud, ratio::Real)
    qts = wc.qtrees
    centers = getcenter.(qts)
    wc.params[:scale] *= ratio
    initword!.(wc, 1:length(wc.words))
    setcenter!.(wc.qtrees, centers)
    wc
end

"like `paint` but export svg"
function paintsvg(wc::wordcloud; background=true)
    if background == false || background === nothing
        sz = size(wc.mask)
    else
        error("not implement yet, please use `background=false` instead")
        if background == true
            nothing
        end
        nothing
    end
    drawtextsvg(getwords(wc), getfontsizes(wc), getpositions(wc, type=getcenter), getangles(wc), getcolors(wc), wc.params[:font],
                background=background, size=sz)        
end
function paintsvg(wc::wordcloud, file, args...; kargs...)
    img = paintsvg(wc, args...; kargs...)
    save(file, img)
    img
end

"""
# examples
* paint(wc::wordcloud)
* paint(wc::wordcloud, background=false) #no background
* paint(wc::wordcloud, background=outline(wc.mask)) #use a new background
* paint(wc::wordcloud, ratio=0.5) #resize the result
* paint(wc::wordcloud, "result.png", ratio=0.5) #save as png file, other bitmap formats may also work
* paint(wc::wordcloud, "result.svg") #save as svg file
"""
function paint(wc::wordcloud, args...; background=true, kargs...)
    if background == true
        background = wc.mask
    elseif background == false || background === nothing
        background = fill(ARGB32(1,1,1,0), size(wc.mask))
    end
    resultpic = convert.(ARGB32, background)#.|>ARGB32
    overlay!(resultpic, wc.imgs, getpositions(wc))
    if !(isempty(args) && isempty(kargs))
        resultpic = convert.(ARGB{Colors.N0f8}, resultpic)
        resultpic = imresize(resultpic, args...; kargs...)
    end
    resultpic
end

function paint(wc::wordcloud, file, args...; kargs...)
    if endswith(file, r".svg|.SVG")
        img = paintsvg(wc, args...; kargs...)
    else
        img = paint(wc, args...; kargs...)
    end
    save(file, img)
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
* patient: number of epochs before teleporting
* trainer: appoint a training engine
"""
function generate!(wc::wordcloud, args...; retry=3, krags...)
    if getstate(wc) != nameof(placement!) && getstate(wc) != nameof(generate!)
        placement!(wc)
    end
    ep, nc = -1, -1
    for r in 1:retry
        # fr = feelingoccupied(wc.params[:mimgs])/wc.params[:groundoccupied]
        if r != 1
            rescale!(wc, 0.95)
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
        wc.params[:state] = nameof(generate!)
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
            wc.params[:state] = nameof(generate!)
        end
    end
    wc
end

function generate_animation!(wc::wordcloud, args...; outputdir="gifresult", overwrite=false, callbackstep=1, kargs...)
    if overwrite
        try rm(outputdir, force=true, recursive=true) catch end
    end
    try mkpath(outputdir) catch end
    gif = GIF(outputdir)
    record(wc, "0", gif)
    re = generate!(wc, args...; callbackstep=callbackstep, callbackfun=ep->record(wc, string(ep), gif), kargs...)
    Render.generate(gif)
    re
end

"""
ignore some words as if they don't exist, then execute the function.
* ignore(fun, wc, ws::String) #ignore a word
* ignore(fun, wc, ws::Set{String}) #ignore all words in ws
* ignore(fun, wc, ws::Array{String}) #ignore all words in ws
* ignore(fun, wc::wordcloud, mask::AbstractArray{Bool}) #ignore words. length(mask)==length(wc.words)
"""
function ignore(fun, wc::wordcloud, mask::AbstractArray{Bool})
    mem = [wc.words, wc.weights, wc.imgs, wc.qtrees, 
            wc.params[:colors], wc.params[:angles], wc.params[:indsmap]]
    mask = .!mask
    wc.words = @view wc.words[mask]
    wc.weights = @view wc.weights[mask]
    wc.imgs = @view wc.imgs[mask]
    wc.qtrees = @view wc.qtrees[mask]
    wc.params[:colors] = @view wc.params[:colors][mask]
    wc.params[:angles] = @view wc.params[:angles][mask]
    wc.params[:indsmap] = nothing
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
        wc.params[:indsmap] = mem[7]
    end
    r
end
 
"""
pin some words as if they were part of the background, then execute the function.
* pin(fun, wc, ws::String) #pin a word
* pin(fun, wc, ws::Set{String}) #pin all words in ws
* pin(fun, wc, ws::Array{String}) #pin all words in ws
* pin(fun, wc::wordcloud, mask::AbstractArray{Bool}) #pin words. length(mask)==length(wc.words)
"""           
function pin(fun, wc::wordcloud, mask::AbstractArray{Bool})
    maskqtree = wc.maskqtree
    wcmask = wc.mask
    groundoccupied = wc.params[:groundoccupied]
    
    maskqtree2 = deepcopy(maskqtree)
    QTree.overlap!.(Ref(maskqtree2), wc.qtrees[mask])
    wc.maskqtree = maskqtree2
    resultpic = convert.(ARGB32, wc.mask)
    wc.mask = overlay!(resultpic, wc.imgs[mask], getpositions(wc, mask))
    wc.params[:groundoccupied] = occupied(QTree.kernel(wc.maskqtree[1]), QTree.FULL)
    r = nothing
    try
        r = ignore(fun, wc, mask)
    finally
        wc.maskqtree = maskqtree
        wc.mask = wcmask
        wc.params[:groundoccupied] = groundoccupied
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

runexample(example=:alice) = evalfile(pkgdir(WordCloud)*"/examples/$(example).jl")
showexample(example=:alice) = read(pkgdir(WordCloud)*"/examples/$(example).jl", String)|>print
examples = join([":"*e[1:end-3] for e in basename.(readdir(pkgdir(WordCloud)*"/examples")) if endswith(e, ".jl")], ", ")
@doc "optional value: [" * examples * "]" runexample
@doc "optional value: [" * examples * "]" showexample

Base.show(io::IO, m::MIME"image/png", wc::wordcloud) = Base.show(io, m, paint(wc::wordcloud))
Base.show(io::IO, m::MIME"text/plain", wc::wordcloud) = print(io, "wordcloud(", wc.words, ") #", length(wc.words), "words")
# Base.show(io::IO, wc::wordcloud) = print(io, "wordcloud(", wc.words, ") #", length(wc.words), "words")
