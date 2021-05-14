function initqtree!(wc, i::Integer; backgroundcolor=(0,0,0,0), border=wc.params[:border])
    img = wc.imgs[i]
    mimg = wordmask(img, backgroundcolor, border)
    t = qtree(mimg, wc.params[:groundsize])
    c = isassigned(wc.qtrees, i) ? getcenter(wc.qtrees[i]) : wc.params[:groundsize] ÷ 2
    setcenter!(t, c)
    wc.qtrees[i] = t
end
initqtree!(wc, i; kargs...) = initqtree!.(wc, index(wc, i); kargs...)
"Initialize word's images and other resources with specified style"
function initimages!(wc, i::Integer; backgroundcolor=(0,0,0,0), border=wc.params[:border],
                    fontsize=getfontsizes(wc, i), color=wc.params[:colors][i],
                    angle = wc.params[:angles][i], font=getfonts(wc, i))
    img, svg = prepareword(wc.words[i], fontsize, color, angle,
        font=font, backgroundcolor=backgroundcolor, border=border)
    wc.imgs[i] = img
    wc.svgs[i] = svg
    initqtree!(wc, i, backgroundcolor=backgroundcolor, border=border)
    nothing
end
initimages!(wc, i; kargs...) = initimage!.(wc, index(wc, i); kargs...)
function initimages!(wc::WC; maxiter=5, error=0.02)
    params = wc.params
    
    si = sortperm(wc.weights, rev=true)
    words = wc.words[si]
    weights = wc.weights[si]
    weights = weights ./ √(sum(weights.^2 .* length.(words)) / length(weights))
    wc.words .= words
    wc.weights .= weights
    wc.params[:colors] .= wc.params[:colors][si]
    wc.params[:angles] .= wc.params[:angles][si]
    wc.params[:indsmap] = nothing

    scale = find_weight_scale!(wc, density=params[:density], maxiter=maxiter, error=error)
    println("density set to $(params[:density]), with scale=$scale, font minimum is $(getfontsizes(wc, length(wc.words)))")
    initimage!.(wc, 1:length(words))
    setstate!(wc, nameof(initimages!))
    wc
end
initimage! = initimages!
"""
* placement!(wc)
* placement!(wc, style=:uniform)
* placement!(wc, style=:gathering)
* placement!(wc, style=:gathering, level=5) #`level` controls the intensity of gathering, typically between 4 and 6, defaults to 5.
* placement!(wc, style=:gathering, level=6, p=4) #`p` refers to p-norm (Minkowski distance), defaults to 2. 
p=1 produces a rhombus, p=2 produces an ellipse, p>2 produces a rectangle with rounded corners. 
When you have set `style=:gathering`, you should disable teleporting in `generate!` at the same time(`generate!(wc, patient=-1)`).
"""
function placement!(wc::WC; style=:uniform, kargs...)
    if STATEIDS[getstate(wc)] < STATEIDS[:initimages!]
        initimages!(wc)
    end
    @assert style in [:uniform, :gathering]
    if length(wc.qtrees) > 0
        if style == :gathering
            if wc.maskqtree[1][(wc.params[:groundsize].÷2)] == QTree.EMPTY && (length(wc.qtrees)<2 
                || (length(wc.qtrees)>=2 && prod(kernelsize(wc.qtrees[2]))/prod(kernelsize(wc.qtrees[1])) < 0.5))
                setcenter!(wc.qtrees[1],  wc.params[:groundsize] .÷ 2)
                ind = Stuffing.placement!(deepcopy(wc.maskqtree), wc.qtrees, 2:length(wc.qtrees)|>collect; 
                    roomfinder=findroom_gathering, kargs...)
            else
                ind = Stuffing.placement!(deepcopy(wc.maskqtree), wc.qtrees; roomfinder=findroom_gathering, kargs...)
            end
        else
            ind = Stuffing.placement!(deepcopy(wc.maskqtree), wc.qtrees; roomfinder=findroom_uniform, kargs...)
        end
        if ind === nothing error("no room for placement") end
    end
    setstate!(wc, nameof(placement!))
    wc
end

"rescale!(wc::WC, ratio::Real)\nRescale all words's size. set `ratio`<1 to shrink, set `ratio`>1 to expand."
function rescale!(wc::WC, ratio::Real)
    qts = wc.qtrees
    centers = getcenter.(qts)
    wc.params[:scale] *= ratio
    initimage!.(wc, 1:length(wc.words))
    setcenter!.(wc.qtrees, centers)
    wc
end

recolor_reset!(wc, i::Integer) = initimage!(wc, i)
recolor_reset!(wc, w=:; kargs...) = recolor_reset!.(wc, index(wc, w); kargs...)

function recolor_average!(wc, i::Integer; background=getmask(wc))
    bg = background
    img = getimages(wc, i)
    x,y = getpositions(wc, i)
    bg, img = Render.overlappingarea(bg, img, x, y)
    m = wordmask(img, (0,0,0,0),0)
    bkv = @view bg[m]
    c = sum(bkv) / length(bkv)
    initimage!(wc, i, color=c)
end
recolor_average!(wc, w=:; kargs...) = recolor_average!.(wc, index(wc, w); kargs...)

function recolor_blending!(wc, i::Integer; alpha=0.5, background=getmask(wc))
    bg = background
    img = getimages(wc, i)
    x,y = getpositions(wc, i)
    bg, img = Render.overlappingarea(bg, img, x, y)
    m = wordmask(img, (0,0,0,0), 0)
    bg = @view bg[m]
    img = @view img[m]
    alphas = Colors.alpha.(img)
    img .= Render.overlay.(img, convert.(eltype(img), Colors.alphacolor.(bg, alpha)))
    img .= Colors.alphacolor.(img, alphas)
    nothing
end
recolor_blending!(wc, w=:; kargs...) = recolor_blending!.(wc, index(wc, w); kargs...)

function recolor_clipping!(wc, i::Integer; background=getmask(wc))
    bg = background
    img = getimages(wc, i)
    x,y = getpositions(wc, i)
    bg, img = Render.overlappingarea(bg, img, x, y)
    m = wordmask(img, (0,0,0,0), 0)
    bg = @view bg[m]
    img = @view img[m]
    img .= convert.(eltype(img), Colors.alphacolor.(bg, Colors.alpha.(img)))
    nothing
end
recolor_clipping!(wc, w=:; kargs...) = recolor_clipping!.(wc, index(wc, w); kargs...)
"""
recolor the words in `wc` in different styles with the background picture.
The styles supported are `:average`, `:clipping`, `:blending`, and :reset (to undo all effects of others).
e.g.  
* recolor!(wc, style=:average) # `background` is optional
* recolor!(wc, style=:clipping, background=blur(getmask(wc))) # `background` is optional
* recolor!(wc, style=:blending, alpha=0.3) # `background` and `alpha` are optional
* recolor!(wc, style=:reset)

The effects of `:average` and `:clipping` are only determined by the `background`. But the effect of `:blending` is also affected by the previous word color. Therefore, `:blending` can also be used in combination with others
The results of `clipping` and `blending` can not be exported as SVG files, use PNG instead. 
"""
function recolor!(wc, args...; style=:average, kargs...)
    if style == :average
        recolor_average!(wc, args...; kargs...)
    elseif style == :blending
        recolor_blending!(wc, args...; kargs...)
    elseif style == :clipping
        recolor_clipping!(wc, args...; kargs...)
    elseif style == :reset
        recolor_reset!(wc, args...; kargs...)
    else
        error("unknown style $style")
    end
    nothing
end
"""
# Positional Args
* wc: the wordcloud to fit
* nepoch: training epoch nums
# Keyword Args
* patient: number of epochs before teleporting, set to `-1` to disable teleporting
* trainer: appoint a training engine
"""
function fit!(wc, args...; krags...)
    if STATEIDS[getstate(wc)] < STATEIDS[:placement!]
        placement!(wc)
    end
    qtrees = [wc.maskqtree, wc.qtrees...]
    ep, nc = train!(qtrees, args...; krags...)
    wc.params[:epoch] += ep
    if nc == 0
        setstate!(wc, nameof(fit!))
    else
        setstate!(wc, nameof(placement!))
    end
    wc
end
function printcollisions(wc)
    qtrees = [wc.maskqtree, wc.qtrees...]
    colllist = first.(batchcollision(qtrees))
    get_text(i) = i>1 ? wc.words[i-1] : "#MASK#"
    collwords = [(get_text(i), get_text(j)) for (i,j) in colllist]
    if length(colllist) > 0
        println("have $(length(colllist)) collisions.",
        " try setting a larger `nepoch` and `retry`, or lower `density` in `wordcloud` to fix that")
        println("$collwords")
    end
end
"""
# Positional Args
* wc: the wordcloud to fit
* nepoch: training epoch nums
# Keyword Args
* retry: shrink & retrain times, defaults to 3, set to `1` to disable shrinking
* patient: number of epochs before teleporting, set to `-1` to disable teleporting
* trainer: appoint a training engine
"""
function generate!(wc::WC, args...; retry=3, krags...)
    if STATEIDS[getstate(wc)] < STATEIDS[:placement!]
        placement!(wc)
    end
    for r in 1:retry
        if r != 1
            rescale!(wc, 0.97)
            dens = textoccupied(getwords(wc), getfontsizes(wc), getfonts(wc))/wc.params[:groundoccupied]
            println("#$r. try scale = $(wc.params[:scale]). The density is reduced to $dens")
        else
            println("#$r. scale = $(wc.params[:scale])")
        end
        fit!(wc, args...; krags...)
        if getstate(wc) == :fit!
            break
        end
    end
    if STATEIDS[getstate(wc)] >= STATEIDS[:fit!]
        println("$(wc.params[:epoch]) epochs")
        setstate!(wc, nameof(generate!))
        # @assert isempty(outofkernelbounds(wc.maskqtree, wc.qtrees))
        # colllist = first.(batchcollision(qtrees))
        # @assert length(colllist) == 0
    else #check
        printcollisions(wc)
    end
    wc
end

function generate_animation!(wc::WC, args...; outputdir="gifresult", overwrite=outputdir!="gifresult", callbackstep=1, kargs...)
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

STATES = nameof.([wordcloud, initimages!, placement!, fit!, generate!])
STATEIDS = Dict([s=>i for (i,s) in enumerate(STATES)])


"""
keep some words and ignore the others, then execute the function. It's the opposite of `ignore`.
* keep(fun, wc, ws::String) #keep a word
* keep(fun, wc, ws::Set{String}) #kepp all words in ws
* keep(fun, wc, ws::Vector{String}) #keep all words in ws
* keep(fun, wc, inds::Union{Integer, Vector{Integer}})
* keep(fun, wc::WC, mask::AbstractArray{Bool}) #keep words. length(mask)==length(wc.words)
"""
function keep(fun, wc::WC, mask::AbstractArray{Bool})
    mem = [wc.words, wc.weights, wc.imgs, wc.svgs, wc.qtrees, 
            wc.params[:colors], wc.params[:angles], wc.params[:wordids], wc.params[:indsmap]]
    wc.words = @view wc.words[mask]
    wc.weights = @view wc.weights[mask]
    wc.imgs = @view wc.imgs[mask]
    wc.svgs = @view wc.svgs[mask]
    wc.qtrees = @view wc.qtrees[mask]
    wc.params[:colors] = @view wc.params[:colors][mask]
    wc.params[:angles] = @view wc.params[:angles][mask]
    wc.params[:wordids] = @view wc.params[:wordids][mask]
    wc.params[:indsmap] = nothing
    r = nothing
    try
        r = fun()
    finally
        wc.words = mem[1]
        wc.weights = mem[2]
        wc.imgs = mem[3]
        wc.svgs = mem[4]
        wc.qtrees = mem[5]
        wc.params[:colors] = mem[6]
        wc.params[:angles] = mem[7]
        wc.params[:wordids] = mem[8]
        wc.params[:indsmap] = mem[9]
    end
    r
end
 
"""
pin some words as if they were part of the background, then execute the function.
* pin(fun, wc, ws::String) #pin a word
* pin(fun, wc, ws::Set{String}) #pin all words in ws
* pin(fun, wc, ws::Vector{String}) #pin all words in ws
* pin(fun, wc, inds::Union{Integer, Vector{Integer}})
* pin(fun, wc::WC, mask::AbstractArray{Bool}) #pin words. length(mask)==length(wc.words)
"""           
function pin(fun, wc::WC, mask::AbstractArray{Bool})
    maskqtree = wc.maskqtree
    wcmask = wc.mask
    groundoccupied = wc.params[:groundoccupied]
    
    maskqtree2 = deepcopy(maskqtree)
    Stuffing.overlap!(maskqtree2, wc.qtrees[mask])
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

function keep(fun, wc, ind::Integer)
    mask = falses(length(wc.words))
    mask[ind] = 1
    keep(fun, wc, mask)
end
function keep(fun, wc, inds::AbstractArray{<:Integer})
    mask = falses(length(wc.words))
    mask[inds] .= 1
    keep(fun, wc, mask)
end
function keep(fun, wc, ws)
    keep(fun, wc, index(wc, ws))
end

"""
ignore some words as if they don't exist, then execute the function. It's the opposite of `keep`.
* ignore(fun, wc, ws::String) #ignore a word
* ignore(fun, wc, ws::Set{String}) #ignore all words in ws
* ignore(fun, wc, ws::Vector{String}) #ignore all words in ws
* ignore(fun, wc, inds::Union{Integer, Vector{Integer}})
* ignore(fun, wc::WC, mask::AbstractArray{Bool}) #ignore words. length(mask)==length(wc.words)
"""
function ignore(fun, wc::WC, mask::AbstractArray{Bool})
    keep(fun, wc, .!mask)
end
function ignore(fun, wc, ind::Integer)
    mask = falses(length(wc.words))
    mask[ind] = 1
    ignore(fun, wc, mask)
end
function ignore(fun, wc, inds::AbstractArray{<:Integer})
    mask = falses(length(wc.words))
    mask[inds] .= 1
    ignore(fun, wc, mask)
end
function ignore(fun, wc, ws)
    ignore(fun, wc, index(wc, ws))
end

function pin(fun, wc, ind::Integer)
    mask = falses(length(wc.words))
    mask[ind] = 1
    pin(fun, wc, mask)
end
function pin(fun, wc, inds::AbstractArray{<:Integer})
    mask = falses(length(wc.words))
    mask[inds] .= 1
    pin(fun, wc, mask)
end
function pin(fun, wc, ws)
    pin(fun, wc, index(wc, ws))
end
