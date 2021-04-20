mutable struct WC
    words
    weights
    imgs
    svgs
    mask
    svgmask
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
* colors = :seaborn_dark #using a preset scheme. see `WordCloud.colorschemes` for all supported Symbol. and `WordCloud.displayschemes() may be helpful.`
* angles = 0 #all same angle  
* angles = (0, 90, 45) #choose entries randomly  
* angles = 0:180 #choose entries randomly  
* angles = [0, 22, 4, 1, 100, 10, ......] #use entries sequentially in cycle  
* density = 0.55 #default 0.5  
* border = 1  
### mask keyword arguments
* mask = loadmask("res/heart.jpg", 256, 256) #see doc of `loadmask`  
* mask = loadmask("res/heart.jpg", color="red", ratio=2) #see doc of `loadmask`  
* mask = shape(ellipse, 800, 600, color="white", backgroundcolor=(0,0,0,0)) #see doc of `shape`  
* transparentcolor = (1,0,0) #set the transparent color in mask  
* transparentcolor = nothing #no transparent color  
* transparentcolor = c->(c[1]+c[2]+c[3])/3*(c[4]/255)>128) #set transparentcolor with a Function. `c` is a (r,g,b,a) Tuple.
### other keyword arguments
The keyword argument `run` is a function. It will be called after the `wordcloud` object constructed.
* run = placement! #default setting, will initialize word's position
* run = generate! #get result directly
* run = initimages! #only initialize resources, such as rendering word images
* run = x->nothing #do nothing
---
* After getting the `wordcloud` object, these steps are needed to get the result picture: initimages! -> placement! -> generate! -> paint
* You can skip `placement!` and/or `initimages!`, and the default action will be performed
"""
wordcloud(wordsweights::Tuple; kargs...) = wordcloud(wordsweights...; kargs...)
wordcloud(counter::AbstractDict; kargs...) = wordcloud(keys(counter)|>collect, values(counter)|>collect; kargs...)
wordcloud(counter::AbstractVector{<:Pair}; kargs...) = wordcloud(first.(counter), last.(counter); kargs...)

function wordcloud(words::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}; 
                colors=randomscheme(), angles=randomangles(), run=placement!, kargs...)
    
    @assert length(words) == length(weights) > 0
    params = Dict{Symbol, Any}(kargs...)
#     @show params
    colors = colors isa Symbol ? (colorschemes[colors].colors..., ) : colors
    colors_o = colors
    colors = Iterators.take(iter_expand(colors), length(words)) |> collect
    params[:colors] = Any[colors...]

    angles = Iterators.take(iter_expand(angles), length(words)) |> collect
    params[:angles] = angles
    
    if !haskey(params, :mask)
        maskcolor = chooseabgcolor(colors_o)
        @show maskcolor
        mask = randommask(maskcolor)
        transparentcolor = get(params, :transparentcolor, ARGB(1, 1, 1, 0))
    else
        mask = params[:mask]
    end
    svgmask = nothing
    if issvg(mask)
        svgmask = mask
        mask = svg2bitmap(mask)
    end
    transparentcolor = get(params, :transparentcolor, mask[1])
    mask, maskqtree, groundsize, groundoccupied = preparebackground(mask, transparentcolor)
    params[:groundsize] = groundsize
    params[:groundoccupied] = groundoccupied
    if groundoccupied == 0
        error("Have you set the right `transparentcolor`? e.g. `transparentcolor=mask[1,1]`")
    end
    @assert groundoccupied > 0
    minfontsize = get(params, :minfontsize, :auto)
    if minfontsize==:auto
        minfontsize = min(8, sqrt(groundoccupied/length(words)/8))
        println("set minfontsize to $minfontsize")
        @show groundoccupied length(words)
        params[:minfontsize] = minfontsize
    end
    get!(params, :border, 1)
    get!(params, :density, 0.5)
    get!(params, :font, "")
    
    params[:state] = nameof(wordcloud)
    params[:epoch] = 0
    params[:indsmap] = nothing
    params[:custom] = Dict(:fontsize=>Dict(), :font=>Dict())
    params[:scale] = -1
    l = length(words)
    wc = WC(words, float.(weights), Vector(undef, l), Vector{SVGImageType}(undef, l), 
    mask, svgmask, Vector(undef, l), maskqtree, params)
    run(wc)
    wc
end

Base.getindex(wc::WC, inds...) = wc.words[inds...]=>wc.weights[inds...]
Base.lastindex(wc::WC) = lastindex(wc.words)
Base.broadcastable(wc::WC) = Ref(wc)
getstate(wc::WC) = wc.params[:state]
setstate!(wc::WC, st::Symbol) = wc.params[:state] = st
function getindsmap(wc::WC)
    if wc.params[:indsmap] === nothing
        wc.params[:indsmap] = Dict(zip(wc.words, Iterators.countfrom(1)))
    end
    wc.params[:indsmap]
end
function index(wc::WC, w::AbstractString)
    getindsmap(wc)[w]
end
index(wc::WC, w::AbstractVector) = index.(wc, w)
index(wc::WC, i::Colon) = eachindex(wc.words)
index(wc::WC, i) = i
getdoc = "The 1st arg is a wordcloud, the 2nd arg can be a word string(list) or a standard supported index and ignored to return all."
setdoc = "The 1st arg is a wordcloud, the 2nd arg can be a word string(list) or a standard supported index, the 3rd arg is the value to assign."
@doc getdoc getcolors(wc::WC, w=:) = wc.params[:colors][index(wc, w)]
@doc getdoc getangles(wc::WC, w=:) = wc.params[:angles][index(wc, w)]
@doc getdoc getwords(wc::WC, w=:) = wc.words[index(wc, w)]
@doc getdoc getweights(wc::WC, w=:) = wc.weights[index(wc, w)]
@doc setdoc setcolors!(wc::WC, w, c) = @view(wc.params[:colors][index(wc, w)]) .= parsecolor(c)
@doc setdoc setangles!(wc::WC, w, a::Union{Number, AbstractVector{<:Number}}) = @view(wc.params[:angles][index(wc, w)]) .= a
@doc setdoc 
function setwords!(wc::WC, w, v::Union{AbstractString, AbstractVector{<:AbstractString}})
    m = getindsmap(wc)
    @assert !any(v .∈ Ref(keys(m)))
    i = index(wc, w)
    Broadcast.broadcast((old,new)->m[new]=pop!(m,old), wc.words[i], v)
    @view(wc.words[i]) .= v
    v
end
@doc setdoc setweights!(wc::WC, w, v::Union{Number, AbstractVector{<:Number}}) = @view(wc.weights[index(wc, w)]) .= v
@doc getdoc getimages(wc::WC, w=:) = wc.imgs[index(wc, w)]
@doc getdoc getsvgimages(wc::WC, w=:) = wc.svgs[index(wc, w)]

@doc setdoc 
function setimages!(wc::WC, w, v::AbstractMatrix; backgroundcolor=v[1], border=wc.params[:border])
    @view(wc.imgs[index(wc, w)]) .= Ref(v)
    initqtree!(wc, w)
    v
end
setimages!(wc::WC, w, v::AbstractVector) = setimages!.(wc, index(wc,w), v)
@doc setdoc
function setsvgimages!(wc::WC, w, v)
    @view(wc.svgs[index(wc, w)]) .= v
    setimages!(wc::WC, w, svg2bitmap.(v))
end

@doc getdoc
function getfontsizes(wc::WC, w=:)
    words = getwords(wc, w)
    Broadcast.broadcast(words) do word
        cf = wc.params[:custom][:fontsize]
        if word in keys(cf)
            return cf[word]
        else
            return max(wc.params[:minfontsize], getweights(wc, word)*wc.params[:scale])
        end
    end
end
@doc setdoc
function setfontsizes!(wc::WC, w, v::Union{Number, AbstractVector{<:Number}})
    push!.(Ref(wc.params[:custom][:fontsize]), w .=> v)
end
@doc getdoc
function getfonts(wc::WC, w=:)
    words = getwords(wc, w)
    get.(Ref(wc.params[:custom][:font]), words, wc.params[:font])
end
@doc setdoc
function setfonts!(wc::WC, w, v::Union{AbstractString, AbstractVector{<:AbstractString}})
    push!.(Ref(wc.params[:custom][:font]), w .=> v)
end
getmask(wc::WC) = wc.mask
getsvgmask(wc::WC) = wc.svgmask

@doc getdoc * " Keyword argment `type` can be `getshift` or `getcenter`."
function getpositions(wc::WC, w=:; type=getshift)
    Stuffing.getpositions(wc.maskqtree, wc.qtrees, index(wc, w), type=type)
end

@doc setdoc * " Keyword argment `type` can be `setshift!` or `setcenter!`."
function setpositions!(wc::WC, w, x_y; type=setshift!)
    Stuffing.setpositions!(wc.maskqtree, wc.qtrees, index(wc, w), x_y, type=type)
end

Base.show(io::IO, m::MIME"image/png", wc::WC) = Base.show(io, m, paint(wc::WC))
Base.show(io::IO, m::MIME"text/plain", wc::WC) = print(io, "wordcloud(", wc.words, ") #", length(wc.words), "words")
# Base.show(io::IO, wc::WC) = print(io, "wordcloud(", wc.words, ") #", length(wc.words), "words")
