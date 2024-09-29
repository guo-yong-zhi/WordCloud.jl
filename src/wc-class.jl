mutable struct WC
    words
    weights
    imgs
    svgs
    mask
    svgmask
    qtrees # ::Vector{Stuffing.QTrees.U8SQTree} be Any to keep the SubArray from @view
    maskqtree # ::Stuffing.QTrees.U8SQTree
    params::Dict{Symbol,Any}
end

"""
## Positional Arguments
The positional arguments are used to specify words and weights in various forms, such as Tuple or Dict.
* words::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}
* words_weights::Tuple
* counter::AbstractDict
* counter::AbstractVector{<:Pair}
## Optional Keyword Arguments
### text-related keyword arguments
For more sophisticated text processing, please utilize the function [`processtext`](@ref).
* language: language of the text, default is `:auto`. 
* stopwords: a set of words, default is `:auto` which means decided by language.  
* stopwords_extra: an additional set of stopwords. By setting this while keeping the `stopwords` argument as `:auto`, the built-in stopword list will be preserved.
* maxnum: maximum number of words, default is 500

### style-related keyword arguments
* colors = "black" # same color for all words  
* colors = ("black", (0.5,0.5,0.7), "yellow", "#ff0000", 0.2) # entries are randomly chosen  
* colors = ["black", (0.5,0.5,0.7), "yellow", "red", (0.5,0.5,0.7), 0.2, ......] # elements are used in a cyclic manner  
* colors = :seaborn_dark # Using a preset scheme. See `WordCloud.colorschemes` for all supported Symbols. `WordCloud.displayschemes()` may be helpful.
* angles = 0 # same angle for all words  
* angles = (0, 90, 45) # randomly select entries  
* angles = 0:180 # randomly select entries  
* angles = [0, 22, 4, 1, 100, 10, ......] # use elements in a cyclic manner  
* fonts = "Serif Bold" # same font for all words  
* fonts = ("Arial", "Times New Roman", "Tahoma") # randomly select entries  
* fonts = ["Arial", "Times New Roman", "Tahoma", ......] # use elements in a cyclic manner  
* minfontsize: The minimum font size in pixel.
* maxfontsize: The maximum font size in pixel.
* avgfontsize: The average font size in pixel, default is 12. It is used to control the size of the generated picture when `masksize` is not specified.
* density = 0.55 # default is 0.5  
* spacing = 1  # minimum spacing between words, default is :auto

### mask-related keyword arguments
* mask = loadmask("res/heart.jpg", 256, 256) # refer to the documentation of [`loadmask`](@ref)  
* mask = loadmask("res/heart.jpg", color="red", ratio=2) # refer to the documentation of [`loadmask`](@ref)
* mask = "res/heart.jpg" # shortcut for loadmask("res/heart.jpg")
* mask = shape(ellipse, 800, 600, color="white", backgroundcolor=(0,0,0,0)) # refer to the documentation of [`shape`](@ref).
* mask = box # mask can also be one of `box`, `ellipse`, `squircle`, `ngon`, `star`, `bezingon` or `bezistar`. Refer to the documentation of [`shape`](@ref). 
* masksize: It can be a tuple `(width, height)`, a single number indicating the side length, or one of the symbols `:original`, `:default`, or `:auto`. 
* backgroundsize: Refer to [`shape`](@ref). It is used with `masksize` to specify the padding size.
* maskcolor: It can take various values that represent colors, such as `"black"`, `"#f000f0"`, `(0.5, 0.5, 0.7)`, or `0.2`. Alternatively, it can be set to one of the following options: `:default`, `:original` (to maintain its original color), or `:auto` (to automatically recolor the mask).
* backgroundcolor: It can take various values that represent colors. Alternatively, it can be set to one of the following options: `:default`, `:original`, `:maskcolor`, or `:auto` (which randomly selects between `:original` and `:maskcolor`).
* outline, linecolor, smoothness: Refer to the [`shape`](@ref) and [`outline`](@ref) functions.
* transparent = (1,0,0) # interpret the color `(1,0,0)` as transparent  
* transparent = nothing # no transparent color  
* transparent = c->(c[1]+c[2]+c[3])/3*(c[4]/255)>128) # set transparency using a function. `c` is an (r,g,b,a) Tuple.
---
* Notes
  * [`getscheme`](@ref) is useful when you want to create a new word cloud with the same style as an existing word cloud.
  * Some arguments depend on whether the `mask` is provided or on the type of the provided `mask`.
### other keyword arguments
* style, centralword, reorder, rt, level: Configure the layout style of word cloud. Refer to the documentation of [`layout!`](@ref).
* The keyword argument `state` is a function. It will be called after the wordcloud object is constructed, which sets the object to a specific state.
  * state = initialize! # only initializes resources, such as word images
  * state = layout! # It is the default setting that initializes the position of words
  * state = generate! # get the result directly
  * state = identity # do nothing
---
* Notes
  * After obtaining the wordcloud object, the following steps are required to obtain the resulting picture: initialize! -> layout! -> generate! -> paint
  * You can skip `initialize!` and/or `layout!`, and these operations will be automatically performed with default parameters
"""
wordcloud(wordsweights::Tuple; kargs...) = wordcloud(wordsweights...; kargs...)
wordcloud(counter::AbstractDict; kargs...) = wordcloud(keys(counter) |> collect, values(counter) |> collect; kargs...)
wordcloud(counter::AbstractVector{<:Union{Pair,Tuple,AbstractVector}}; kargs...) = wordcloud(first.(counter), [v[2] for v in counter]; kargs...)
function wordcloud(text; language=:auto, stopwords=:auto, stopwords_extra=nothing, maxnum=500, kargs...)
    language = detect_language(text, language)
    wordcloud(processtext(text, language=language, stopwords=stopwords, stopwords_extra=stopwords_extra, maxnum=maxnum); language=language, kargs...)
end
wordcloud(words, weight::Number; kargs...) = wordcloud(words, repeat([weight], length(words)); kargs...)
function wordcloud(words::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}; 
                colors=:auto, angles=:auto, 
                mask=:auto, svgmask=nothing, edit_mask=true, masksize=:auto, fonts=:auto, language=:auto,
                transparent=:auto, minfontsize=:auto, maxfontsize=:auto, avgfontsize=12,
                spacing=:auto, density=0.5, state=layout!,
                style=:auto, centralword=:auto, reorder=:auto, level=:auto, rt=:auto, kargs...)
    @assert length(words) == length(weights) > 0
    params = Dict{Symbol,Any}()

    # parameters for layout!
    style != :auto && (params[:style] = style)
    centralword != :auto && (params[:centralword] = centralword)
    reorder != :auto && (params[:reorder] = reorder)
    level != :auto && (params[:level] = level)
    rt != :auto && (params[:rt] = rt)

    colors, angles, mask, svgmask, fonts, transparent = processscheme(words, weights; colors=colors, angles=angles, mask=mask, svgmask=svgmask, edit_mask=edit_mask, masksize=masksize,
                                                    fonts=fonts, avgfontsize=avgfontsize, language=language, transparent=transparent, params=params, kargs...)
    params[:colors] = Any[colors...]
    params[:angles] = angles
    params[:transparent] = transparent
    mask, maskqtree, groundsize, volume = preparemask(mask, transparent)
    params[:groundsize] = groundsize
    params[:volume] = volume
    if volume == 0
        error("Have you set the right `transparent`? e.g. `transparent=mask[1,1]`")
    end
    avgsize = round(Int, sqrt(volume / length(words)))
    @debug "mask size: $(size(mask, 1))×$(size(mask, 2)), volume: $(round(Int, √volume))² ($(avgsize)²/word)"
    params[:maxfontsize0] = maxfontsize
    if maxfontsize == :auto
        maxfontsize = minimum(size(mask))
    end
    @assert volume > 0
    if minfontsize == :auto
        minfontsize = min(maxfontsize, 8, sqrt(volume / length(words) / 8))
        # 只和单词数量有关，和单词长度无关。不管单词多长，字号小了依然看不见。
        # 单词平均长度为4，volume大约为12*12*length(words)，故sqrt(12*12*单词平均长度/8)约等于8.5
    end
    @debug "set fontsize ∈ [$minfontsize, $maxfontsize]"
    params[:minfontsize] = minfontsize
    params[:maxfontsize] = maxfontsize
    params[:avgfontsize] = avgfontsize

    if spacing == :auto
        spacing = Int(masksize == :auto ? avgfontsize ÷ 6 : 2)
    end
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
    wc = WC(copy(words), float.(weights), Vector(undef, l), Vector{SVG}(undef, l), 
    mask, svgmask, Vector{Stuffing.QTrees.U8SQTree}(undef, l), maskqtree, params)
    if state != wordcloud
        state(wc)
    end
    wc
end
function processscheme(words, weights; colors=:auto, angles=:auto, mask=:auto, svgmask=nothing, edit_mask=true,
                masksize=:auto, maskcolor=:default, keepmaskarea=:auto,
                backgroundcolor=:default, padding=:default,
                outline=:default, linecolor=:auto, fonts=:auto, avgfontsize=12, language=:auto,
                transparent=:auto, params=Dict{Symbol,Any}(), kargs...)
    merge!(params, kargs)
    colors in DEFAULTSYMBOLS && (colors = randomscheme(weights))
    angles in DEFAULTSYMBOLS && (angles = randomangles())
    fonts in DEFAULTSYMBOLS && (fonts = randomfonts(detect_language(words, language)))
    maskcolor0 = maskcolor
    backgroundcolor0 = backgroundcolor
    colors isa Symbol && (colors = (colorschemes[colors].colors...,))
    params[:colors_scheme] = colors
    params[:angles_scheme] = angles
    params[:fonts_scheme] = fonts
    colors = Iterators.take(iter_expand(colors), length(words)) |> collect
    angles = Iterators.take(iter_expand(angles), length(words)) |> collect
    fonts = Iterators.take(iter_expand(fonts), length(words)) |> collect
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
        masksize in DEFAULTSYMBOLS && (masksize = volumeproposal(words, weights, avgfontsize))
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
         preservevolume=keepmaskarea, returnkwargs=true, kg..., kargs...)
        merge!(params, maskkw)
        transparent = c -> c != torgba(maskcolor)
    elseif edit_mask
        if masksize == :auto
            ms = volumeproposal(words, weights, avgfontsize)
        elseif masksize in DEFAULTSYMBOLS
            ms = ()
        else
            ms = masksize
        end
        if keepmaskarea in DEFAULTSYMBOLS
            keepmaskarea = masksize == :auto
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
            if maskcolor == :default && backgroundcolor != :maskcolor
                maskcolor = backgroundcolor
            end
        end
        if maskcolor in [:default, :auto] && !issvg(loadmask(mask))
            maskcolor = randommaskcolor(colors)
            println("Recolor the mask with color $maskcolor.")
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
        padding in DEFAULTSYMBOLS && (padding = outline)
        mask, binarymask = loadmask(mask, ms...; color=maskcolor, transparent=transparent, backgroundcolor=bc, 
            outline=outline, linecolor=linecolor, padding=padding, return_bitmask=true, preservevolume=keepmaskarea, kargs...)
        binarymask === nothing || (transparent = .!binarymask)
    else
        mask =  loadmask(mask)
    end
    # under this line: both mask == :auto or not
    if transparent == :auto
        if maskcolor ∉ DEFAULTSYMBOLS
            transparent = c -> c[4] == 0 || c[1:3] != WordCloud.torgba(maskcolor)[1:3] # ignore the alpha channel when alpha!=0
        end
    end
    params[:masksize] = masksize
    params[:maskcolor] = maskcolor
    params[:backgroundcolor] = backgroundcolor
    params[:outline] = outline
    params[:linecolor] = linecolor
    params[:padding] = padding
    if issvg(mask)
        if svgmask === nothing
            svgmask = mask
        end
        mask = tobitmap(mask)
        if maskcolor ∉ DEFAULTSYMBOLS && (:outline ∉ keys(params) || params[:outline] <= 0)
            Render.recolor!(mask, maskcolor) # tobitmap后有杂色 https://github.com/JuliaGraphics/Luxor.jl/issues/160
        end
    end
    colors, angles, mask, svgmask, fonts, transparent
end

"""
    getscheme(wc::WC)
Returns the scheme of an existing word cloud, which can be used to create a new word cloud with the same styling.
e.g., `wc1 = wordcloud("a word cloud"); wc2 = wordcloud("a new word cloud"; getscheme(wc1)...)`
"""
function getscheme(wc::WC)
    sc = [
        :colors => getparameter(wc, :colors_scheme),
        :angles => getparameter(wc, :angles_scheme),
        :fonts => getparameter(wc, :fonts_scheme),
        :mask => wc.mask,
        :svgmask => wc.svgmask,
        :maskcolor => getparameter(wc, :maskcolor),
        :backgroundcolor => getparameter(wc, :backgroundcolor),
        :edit_mask => false,
        :transparent => getparameter(wc, :transparent),
    ]
    for p in (:style, :centralword, :reorder, :level, :rt)
        if hasparameter(wc, p)
            push!(sc, p => getparameter(wc, p))
        end
    end
    sc
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
getdoc = "This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values."
setdoc = "This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index."
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
@doc getdoc * " The keyword argument `mode` can be either `getshift` or `getcenter`."
function getpositions(wc::WC, w=:; mode=getshift)
    Stuffing.getpositions(wc.maskqtree, wc.qtrees, index(wc, w), mode=mode)
end

@doc setdoc * " The keyword argument `mode` can be either `setshift!` or `setcenter!`."
function setpositions!(wc::WC, w, x_y; mode=setshift!)
    Stuffing.setpositions!(wc.maskqtree, wc.qtrees, index(wc, w), x_y, mode=mode)
end

Base.show(io::IO, m::MIME"image/png", wc::WC) = Base.show(io, m, paint(wc::WC))
Base.show(io::IO, m::MIME"image/svg+xml", wc::WC) = Base.show(io, m, paintsvg(wc::WC))
function Base.show(io::IO, m::MIME"text/plain", wc::WC)
    print(io, "wordcloud(")
    print(IOContext(io, :limit => true, :compact => true), wc.words|>collect)
    println(io, ") # ", length(wc), " words")
end
function Base.showable(::MIME"image/png", wc::WC)
    STATEIDS[getstate(wc)] >= STATEIDS[:initialize!] && showable("image/png", zeros(ARGB, (1, 1)))
end
function Base.showable(::MIME"image/svg+xml", wc::WC)
    STATEIDS[getstate(wc)] >= STATEIDS[:initialize!] && (wc.svgmask !== nothing || !showable("image/png", wc))
end
Base.show(io::IO, wc::WC) = Base.show(io, "text/plain", wc)
