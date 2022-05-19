mutable struct WC
    words
    weights
    imgs
    svgs
    mask
    svgmask
    qtrees #::Vector{Stuffing.QTrees.U8SQTree} be Any to keep the SubArray from @view
    maskqtree #::Stuffing.QTrees.U8SQTree
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
* colors = :seaborn_dark #using a preset scheme. see `WordCloud.colorschemes` for all supported Symbols. and `WordCloud.displayschemes()` may be helpful.
* angles = 0 #all same angle  
* angles = (0, 90, 45) #choose entries randomly  
* angles = 0:180 #choose entries randomly  
* angles = [0, 22, 4, 1, 100, 10, ......] #use entries sequentially in cycle  
* fonts = "Serif Bold" #all same font  
* fonts = ("Arial", "Times New Roman", "Tahoma") #choose entries randomly  
* fonts = ["Arial", "Times New Roman", "Tahoma", ......] #use entries sequentially in cycle  
* density = 0.55 #default 0.5  
* spacing = 1  #minimum spacing between words

### mask keyword arguments
* mask = loadmask("res/heart.jpg", 256, 256) #see the doc of `loadmask`  
* mask = loadmask("res/heart.jpg", color="red", ratio=2) #see the doc of `loadmask`
* mask = "res/heart.jpg" #shorthand for loadmask("res/heart.jpg")
* mask = shape(ellipse, 800, 600, color="white", backgroundcolor=(0,0,0,0)) #See the doc of `shape`.
* mask = box #mask can also be one of `box`, `ellipse`, `squircle`, `ngon` and `star`.  See the doc of `shape`. 
* masksize: Can be a tuple `(width, height)` or just a single number as a side length hint. 
* backgroundsize: See `shape`. Need to be used with `masksize` to specify the padding size.
* maskcolor: like "black", "#ff0000", (0.5,0.5,0.7), 0.2, or :default, :original (keep it unchanged), :auto (auto recolor the mask).
* backgroundcolor: like "black", "#ff0000", (0.5,0.5,0.7), 0.2, or :default, :original, :maskcolor, :auto (random choose between :original and :maskcolor)
* outline, linecolor, smoothness: See function `shape` and `outline`. 
* transparent = (1,0,0) #set the transparent color in mask  
* transparent = nothing #no transparent color  
* transparent = c->(c[1]+c[2]+c[3])/3*(c[4]/255)>128) #set transparent with a Function. `c` is a (r,g,b,a) Tuple.
---NOTE
Some arguments depend on whether or not the `mask` is given or the type of the given `mask`.

### other keyword arguments
* style, centeredword, reorder, rt, level: config the style of `placewords!`. See the doc of `placewords!`.  
* state = placewords! #default setting, will initialize word's position
* state = generate! #get result directly
* state = initwords! #only initialize resources, such as rendering word images
* state = identity #do nothing
The keyword argument `state` is a function. It will be called after the `wordcloud` object constructed. This will set the object to a specific state.
---NOTE
* After getting the `wordcloud` object, these steps are needed to get the result picture: initwords! -> placewords! -> generate! -> paint
* You can skip `placewords!` and/or `initwords!`, and these operations will be performed automatically with default parameters
"""
wordcloud(wordsweights::Tuple; kargs...) = wordcloud(wordsweights...; kargs...)
wordcloud(counter::AbstractDict; kargs...) = wordcloud(keys(counter) |> collect, values(counter) |> collect; kargs...)
wordcloud(counter::AbstractVector{<:Union{Pair,Tuple,AbstractVector}}; kargs...) = wordcloud(first.(counter), [v[2] for v in counter]; kargs...)
wordcloud(text; kargs...) = wordcloud(processtext(text); kargs...)
wordcloud(words, weight::Number; kargs...) = wordcloud(words, repeat([weight], length(words)); kargs...)
function wordcloud(words::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}; 
                colors=:auto, angles=:auto, 
                mask=:auto, fonts=:auto,
                transparent=:auto, minfontsize=:auto, maxfontsize=:auto, spacing::Integer=1, density=0.5,
                state=placewords!, style=:auto, centeredword=:auto, reorder=:auto, level=:auto, kargs...)
    @assert length(words) == length(weights) > 0
    params = Dict{Symbol,Any}()

    # parameters for placewords!
    params[:style] = style
    params[:centeredword] = centeredword
    params[:reorder] = reorder
    params[:level] = level

    colors, angles, mask, svgmask, fonts, transparent = getstylescheme(words, weights; colors=colors, angles=angles, 
                                                    mask=mask, fonts=fonts, transparent=transparent, params=params, kargs...)
    params[:colors] = Any[colors...]
    params[:angles] = angles
    params[:transparent] = transparent
    mask, maskqtree, groundsize, contentarea = preparemask(mask, transparent)
    params[:groundsize] = groundsize
    params[:contentarea] = contentarea
    if contentarea == 0
        error("Have you set the right `transparent`? e.g. `transparent=mask[1,1]`")
    end
    contentsize = round(Int, √contentarea)
    avgsize = round(Int, sqrt(contentarea / length(words)))
    println("mask size: $(size(mask, 1))×$(size(mask, 2)), content area: $(contentsize)² ($(avgsize)²/word)")
    params[:maxfontsize0] = maxfontsize
    if maxfontsize == :auto
        maxfontsize = minimum(size(mask))
    end
    @assert contentarea > 0
    if minfontsize == :auto
        minfontsize = min(maxfontsize, 8, sqrt(contentarea / length(words) / 8))
        #只和单词数量有关，和单词长度无关。不管单词多长，字号小了依然看不见。
    end
    println("set fontsize ∈ [$minfontsize, $maxfontsize]")
    params[:minfontsize] = minfontsize
    params[:maxfontsize] = maxfontsize
    params[:spacing] = spacing
    params[:density] = density
    params[:fonts] = fonts
    
    params[:state] = nameof(wordcloud)
    params[:epoch] = 0
    params[:word2index] = nothing
    params[:id2index] = nothing
    params[:custom] = Dict(:fontsize => Dict())
    params[:scale] = -1
    params[:wordids] = collect(1:length(words))
    l = length(words)
    wc = WC(copy(words), float.(weights), Vector(undef, l), Vector{SVGImageType}(undef, l), 
    mask, svgmask, Vector{Stuffing.QTrees.U8SQTree}(undef, l), maskqtree, params)
    if state != wordcloud
        state(wc)
    end
    wc
end
function getstylescheme(words, weights; colors=:auto, angles=:auto, mask=:auto,
                masksize=:default, maskcolor=:default, keepmaskarea=:auto,
                backgroundcolor=:default, padding=:default,
                outline=:default, linecolor=:auto, fonts=:auto,
                transparent=:auto, params=Dict{Symbol,Any}(), kargs...)
    merge!(params, kargs)
    colors in DEFAULTSYMBOLS && (colors = randomscheme(length(words)))
    angles in DEFAULTSYMBOLS && (angles = randomangles())
    maskcolor0 = maskcolor
    backgroundcolor0 = backgroundcolor
    colors isa Symbol && (colors = (colorschemes[colors].colors...,))
    colors = Iterators.take(iter_expand(colors), length(words)) |> collect
    angles = Iterators.take(iter_expand(angles), length(words)) |> collect
    if mask == :auto || mask isa Function
        if maskcolor in DEFAULTSYMBOLS
            if backgroundcolor in DEFAULTSYMBOLS || backgroundcolor == :maskcolor
                maskcolor = randommaskcolor(colors)
            else
                maskcolor = backgroundcolor
            end
        end
        if keepmaskarea in DEFAULTSYMBOLS
            keepmaskarea = masksize in DEFAULTSYMBOLS
        end
        masksize in DEFAULTSYMBOLS && (masksize = contentsize_proposal(words, weights))
        if backgroundcolor in DEFAULTSYMBOLS
            backgroundcolor = maskcolor0 in DEFAULTSYMBOLS ? rand(((1, 1, 1, 0), :maskcolor)) : (1, 1, 1, 0)
        end
        backgroundcolor == :maskcolor && @show backgroundcolor
        kg = []
        if outline in DEFAULTSYMBOLS
            if maskcolor0 in DEFAULTSYMBOLS && backgroundcolor0 in DEFAULTSYMBOLS
                outline = randomoutline()
            else
                outline = 0
            end
        end
        if linecolor in DEFAULTSYMBOLS && outline != 0
            linecolor = randomlinecolor(colors)
        end
        if outline != 0
            push!(kg, :outline => outline)
            push!(kg, :linecolor => linecolor)
        end
        padding in DEFAULTSYMBOLS && (padding = round(Int, maximum(masksize) ÷ 10))
        mask, maskkw = randommask(masksize; maskshape=mask, color=maskcolor, padding=padding,
         keeparea=keepmaskarea, returnkwargs=true, kg..., kargs...)
        merge!(params, maskkw)
        transparent = c -> c != torgba(maskcolor)
    else
        ms = masksize in DEFAULTSYMBOLS ? () : masksize
        if maskcolor == :auto && !issvg(loadmask(mask))
            maskcolor = randommaskcolor(colors)
            println("Recolor the mask with color $maskcolor.")
        end
        if backgroundcolor == :auto
            if maskcolor == :default
                backgroundcolor = randommaskcolor(colors)
                maskcolor = backgroundcolor
            else
                backgroundcolor = rand(((1, 1, 1, 0), :maskcolor, :original))
            end
        end
        bc = backgroundcolor
        if backgroundcolor ∉ [:default, :original]
            @show backgroundcolor
            bc = (1, 1, 1, 0) # to remove the original background in mask
        end
        if outline == :auto
            outline = randomoutline()
            outline != 0 && @show outline
        elseif outline in DEFAULTSYMBOLS
        outline = 0
        end
        if linecolor in DEFAULTSYMBOLS && outline != 0
            linecolor = randomlinecolor(colors)
        end
        padding in DEFAULTSYMBOLS && (padding = 0)
        mask, binarymask = loadmask(mask, ms...; color=maskcolor, transparent=transparent, backgroundcolor=bc, 
            outline=outline, linecolor=linecolor,padding=padding, return_binarymask=true, kargs...)
        binarymask === nothing || (transparent = .!binarymask)
    end
    # under this line: both mask == :auto or not
    if transparent == :auto
        if maskcolor ∉ DEFAULTSYMBOLS
            transparent = c -> c[4] == 0 || c[1:3] != WordCloud.torgba(maskcolor)[1:3] #ignore the alpha channel when alpha!=0
        end
    end
    params[:masksize] = masksize
    params[:maskcolor] = maskcolor
    params[:backgroundcolor] = backgroundcolor
    params[:outline] = outline
    params[:linecolor] = linecolor
    params[:padding] = padding
    svgmask = nothing
    if issvg(mask)
        svgmask = mask
        mask = tobitmap(mask)
        if maskcolor ∉ DEFAULTSYMBOLS && (:outline ∉ keys(params) || params[:outline] <= 0)
            Render.recolor!(mask, maskcolor) # tobitmap后有杂色 https://github.com/JuliaGraphics/Luxor.jl/issues/160
        end
    end
    fonts in DEFAULTSYMBOLS && (fonts = randomfonts())
    fonts = Iterators.take(iter_expand(fonts), length(words)) |> collect
    colors, angles, mask, svgmask, fonts, transparent
end
Base.length(wc::WC) = length(wc.words)
Base.getindex(wc::WC, i::Integer) = wc.words[i] => wc.weights[i]
Base.getindex(wc::WC, i) = getindex.(wc, index(wc, i))
Base.lastindex(wc::WC) = lastindex(wc.words)
Base.broadcastable(wc::WC) = Ref(wc)
getstate(wc::WC) = wc.params[:state]
setstate!(wc::WC, st::Symbol) = wc.params[:state] = st
struct ID{T} 
    id::T
end
wordids(wc, i::Integer) = wc.params[:wordids][i]
wordids(wc, w) = wordids.(wc, index(wc, w))
wordids(wc, id::ID) = id.id
wordids(wc, id::ID{Colon}) = sort(wc.params[:wordids])
function id2index(wc::WC)
    if wc.params[:id2index] === nothing
        wc.params[:id2index] = Dict(zip(wc.params[:wordids], Iterators.countfrom(1)))
    end
    wc.params[:id2index]
end
function index(wc::WC, id::ID)
    mp = id2index(wc)
    getindex.(Ref(mp), wordids(wc, id))
end
function word2index(wc::WC)
    if wc.params[:word2index] === nothing
        wc.params[:word2index] = Dict(zip(wc.words, Iterators.countfrom(1)))
    end
    wc.params[:word2index]
end
function index(wc::WC, w::AbstractString)
    word2index(wc)[w]
end
index(wc::WC, w::AbstractVector) = index.(wc, w)
index(wc::WC, i::Colon) = eachindex(wc.words)
index(wc::WC, i) = i

getparameter(wc, args...) = getindex(wc.params, args...)
setparameter!(wc, args...) = setindex!(wc.params, args...)
hasparameter(wc, args...) = haskey(wc.params, args...)
getdoc = "The 1st argument is wordcloud, the 2nd argument is index which can be string, number, list, or any other standard supported index. And the index argument can be ignored to get all values."
setdoc = "The 1st argument is wordcloud, the 2nd argument is index which can be string, number, list, or any other standard supported index, the 3rd argument is the value to assign."
@doc getdoc getcolors(wc::WC, w=:) = wc.params[:colors][index(wc, w)]
@doc getdoc getangles(wc::WC, w=:) = wc.params[:angles][index(wc, w)]
@doc getdoc getfonts(wc::WC, w=:) = wc.params[:fonts][index(wc, w)]
@doc getdoc getwords(wc::WC, w=:) = wc.words[index(wc, w)]
@doc getdoc getweights(wc::WC, w=:) = wc.weights[index(wc, w)]
@doc setdoc setcolors!(wc::WC, w, c) = @view(wc.params[:colors][index(wc, w)]) .= parsecolor(c)
@doc setdoc setangles!(wc::WC, w, a::Union{Number,AbstractVector{<:Number}}) = @view(wc.params[:angles][index(wc, w)]) .= a
@doc setdoc
function setfonts!(wc::WC, w, v::Union{AbstractString,AbstractVector{<:AbstractString}})
    @view(wc.params[:fonts][index(wc, w)]) .= v
end
@doc setdoc 
function setwords!(wc::WC, w, v::Union{AbstractString,AbstractVector{<:AbstractString}})
    m = word2index(wc)
    @assert !any(v .∈ Ref(keys(m)))
    i = index(wc, w)
    Broadcast.broadcast((old, new) -> m[new] = pop!(m, old), wc.words[i], v)
    @view(wc.words[i]) .= v
    v
end
@doc setdoc setweights!(wc::WC, w, v::Union{Number,AbstractVector{<:Number}}) = @view(wc.weights[index(wc, w)]) .= v
@doc getdoc getimages(wc::WC, w=:) = wc.imgs[index(wc, w)]
@doc getdoc getsvgimages(wc::WC, w=:) = wc.svgs[index(wc, w)]

@doc setdoc 
function setimages!(wc::WC, w, v::AbstractMatrix)
    @view(wc.imgs[index(wc, w)]) .= Ref(v)
    initqtree!(wc, w)
    v
end
setimages!(wc::WC, w, v::AbstractVector) = setimages!.(wc, index(wc, w), v)
@doc setdoc
function setsvgimages!(wc::WC, w, v)
    @view(wc.svgs[index(wc, w)]) .= v
    setimages!(wc::WC, w, tobitmap.(v))
end

@doc getdoc
function getfontsizes(wc::WC, w=:)
    inds = index(wc, w)
    ids = wordids(wc, inds)
    Broadcast.broadcast(inds, ids) do ind, id
        cf = wc.params[:custom][:fontsize]
        if id in keys(cf)
            return cf[id]
        else
            return clamp(getweights(wc, ind) * wc.params[:scale], wc.params[:minfontsize], wc.params[:maxfontsize])
        end
    end
end
@doc setdoc
function setfontsizes!(wc::WC, w, v::Union{Number,AbstractVector{<:Number}})
    push!.(Ref(wc.params[:custom][:fontsize]), wordids(wc, w) .=> v)
end
getmask(wc::WC) = wc.mask
getsvgmask(wc::WC) = wc.svgmask
getmaskcolor(wc::WC) = getparameter(wc, :maskcolor)
function getbackgroundcolor(wc::WC)
    c = getparameter(wc, :backgroundcolor)
    c == :maskcolor ? getmaskcolor(wc) : c
end
setbackgroundcolor!(wc::WC, v) = (setparameter!(wc, v, :backgroundcolor); v)
@doc getdoc * " Keyword argment `type` can be `getshift` or `getcenter`."
function getpositions(wc::WC, w=:; type=getshift)
    Stuffing.getpositions(wc.maskqtree, wc.qtrees, index(wc, w), type=type)
end

@doc setdoc * " Keyword argment `type` can be `setshift!` or `setcenter!`."
function setpositions!(wc::WC, w, x_y; type=setshift!)
    Stuffing.setpositions!(wc.maskqtree, wc.qtrees, index(wc, w), x_y, type=type)
end

Base.show(io::IO, m::MIME"image/png", wc::WC) = Base.show(io, m, paint(wc::WC))
Base.show(io::IO, m::MIME"image/svg+xml", wc::WC) = Base.show(io, m, paintsvg(wc::WC))
Base.show(io::IO, m::MIME"text/plain", wc::WC) = print(io, "wordcloud(", wc.words, ") #", length(wc), "words")
function Base.showable(::MIME"image/png", wc::WC)
    STATEIDS[getstate(wc)] >= STATEIDS[:initwords!] && showable("image/png", zeros(ARGB, (1, 1)))
end
function Base.showable(::MIME"image/svg+xml", wc::WC)
    STATEIDS[getstate(wc)] >= STATEIDS[:initwords!] && (wc.svgmask !== nothing || !showable("image/png", wc))
end
Base.show(io::IO, wc::WC) = Base.show(io, "text/plain", wc)
