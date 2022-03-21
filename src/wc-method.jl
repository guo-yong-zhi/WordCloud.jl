using Random
function initqtree!(wc, i::Integer; backgroundcolor=(0, 0, 0, 0), spacing=getparameter(wc, :spacing))
    img = wc.imgs[i]
    mimg = wordmask(img, backgroundcolor, spacing)
    t = qtree(mimg, wc.params[:groundsize])
    c = isassigned(wc.qtrees, i) ? getcenter(wc.qtrees[i]) : wc.params[:groundsize] ÷ 2
    setcenter!(t, c)
    wc.qtrees[i] = t
end
initqtree!(wc, i; kargs...) = initqtree!.(wc, index(wc, i); kargs...)
"Initialize word's images and other resources with specified style"
function initwords!(wc, i::Integer; backgroundcolor=(0, 0, 0, 0), spacing=getparameter(wc, :spacing),
                    fontsize=getfontsizes(wc, i), color=wc.params[:colors][i],
                    angle=wc.params[:angles][i], font=wc.params[:fonts][i])
    img, svg = prepareword(wc.words[i], fontsize, color, angle,
        font=font, backgroundcolor=backgroundcolor, border=spacing)
    wc.imgs[i] = img
    wc.svgs[i] = svg
    initqtree!(wc, i, backgroundcolor=backgroundcolor, spacing=spacing)
    nothing
end
initwords!(wc, i; kargs...) = initword!.(wc, index(wc, i); kargs...)
function initwords!(wc::WC; maxiter=5, tolerance=0.02)
    params = wc.params
    weights = wc.weights
    wc.weights .= weights ./ √(sum(weights.^2 .* length.(wc.words)) / length(weights))
    si = sortperm(wc.weights, rev=true)
    wc.words = @view wc.words[si]
    wc.weights = @view wc.weights[si]
    wc.imgs = @view wc.imgs[si]
    wc.svgs = @view wc.svgs[si]
    wc.qtrees = @view wc.qtrees[si]
    wc.params[:colors] = @view wc.params[:colors][si]
    wc.params[:angles] = @view wc.params[:angles][si]
    wc.params[:fonts] = @view wc.params[:fonts][si]
    wc.params[:wordids] = @view wc.params[:wordids][si]
    wc.params[:word2index] = nothing
    wc.params[:id2index] = nothing
    println("set density = $(params[:density])")
    findscale!(wc, density=params[:density], maxiter=maxiter, tolerance=tolerance)
    printfontsizes(wc)
    initword!.(wc, 1:length(wc.words))
    setstate!(wc, nameof(initwords!))
    wc
end
initword! = initwords!
function printfontsizes(wc)
    nsmall = findlast(i->getfontsizes(wc, i)<=wc.params[:minfontsize], length(wc):-1:1)
    nsmall === nothing && (nsmall = 0)
    println("fontsize ∈ [$(getfontsizes(wc, length(wc))), $(getfontsizes(wc, 1))]")
    if nsmall > 0
        perc = round(Int, nsmall/length(wc)*100)
        println("$nsmall words($perc%) are limited to the minimum font size.")
        if perc > 70
            msg = "It seems too crowded. Word size may be seriously distorted. You need to reduce the number of words or set a larger mask."
            ratio = contentsize_proposal(wc.words, wc.weights) / √getparameter(wc, :contentarea)
            if ratio > 1.1
                msg = msg * " Recommended mask scaling: ratio=$(round(ratio, digits=3))."
            end
            @warn msg
        end

    end
    if getfontsizes(wc, 1) == wc.params[:maxfontsize]
        @warn "Some words are limited to the maximum font size. Please set a `maxfontsize` in `wordcloud` or set a `maxweight` in `processtext`."
    end
end
"""
* placewords!(wc)
* placewords!(wc, style=:uniform)
* placewords!(wc, style=:gathering)
* placewords!(wc, style=:gathering, level=5) #`level` controls the intensity of gathering, typically between 4 and 6, defaults to 5.
* placewords!(wc, style=:gathering, level=6, rt=0) #rt=0, rectangle; rt=1, ellipse; rt=2, rhombus. defaults to 1.  
There is also a bool keyword argument `centerlargestword`, which can be set to center the largest word.
When you have set `style=:gathering`, you should disable repositioning in `generate!` at the same time, especially for big words. e.g. `generate!(wc, reposition=0.7)`.
The keyword argument `reorder` is a function to reorder the words, which affects the order of placement. Like `reverse`, `WordCloud.shuffle`.
"""
function placewords!(wc::WC; style=rand()<0.8 ? :uniform : :gathering, rt=:auto, centerlargestword=:auto, reorder=identity, callback=x->x, kargs...)
    if STATEIDS[getstate(wc)] < STATEIDS[:initwords!]
        initwords!(wc)
    end
    @assert style in [:uniform, :gathering]
    if centerlargestword == :auto
        c = wc.params[:groundsize] ÷ 2 # can't wc.maskqtree[1][end÷2]. 1D index goes wrong.
        kernelsize = Stuffing.kernelsize
        centerlargestword = wc.maskqtree[1][c, c] == QTrees.EMPTY && (
            length(wc.qtrees) < 2 
            || (length(wc.qtrees) >= 2 
                && wc.weights[2] / wc.weights[1] < 0.5 
                && prod(kernelsize(wc.qtrees[2])) / prod(kernelsize(wc.qtrees[1])) < 0.5))
        if centerlargestword
            println("center the largest word $(repr(getwords(wc, 1)))")
        end
    end
    arg = ()
    if centerlargestword
        setcenter!(wc.qtrees[1],  wc.params[:groundsize] .÷ 2)
        arg = (2:length(wc.qtrees) |> collect,)
        callback(1)
    end
    qtrees = reorder(wc.qtrees)
    if length(wc.qtrees) > 0 + centerlargestword
        if style == :gathering
            if rt == :auto
                if hasparameter(wc, :rt)
                    rt = getparameter(wc, :rt)
                    println("gathering style: use the parameter in wordcloud `:rt=>$rt`")
                else
                    rt = 1
                    println("gathering style: rt = 1, ellipse")
                end
            end
            p = min(50, 2 / rt)
            ind = Stuffing.place!(deepcopy(wc.maskqtree), qtrees, arg...; 
                    roomfinder=findroom_gathering, p=p, callback=callback, kargs...)
        else
            ind = Stuffing.place!(deepcopy(wc.maskqtree), qtrees, arg...;
                    roomfinder=findroom_uniform, callback=callback, kargs...)
        end
        if ind === nothing error("no room for placement") end
    end
    setstate!(wc, nameof(placewords!))
    setparameter!(wc, 0, :epoch)
    wc
end

"rescale!(wc::WC, ratio::Real)\nRescale all words's size. set `ratio`<1 to shrink, set `ratio`>1 to expand."
function rescale!(wc::WC, ratio::Real)
    qts = wc.qtrees
    centers = getcenter.(qts)
    wc.params[:scale] *= ratio
    initword!.(wc, 1:length(wc))
    setcenter!.(wc.qtrees, centers)
    wc
end

recolor_reset!(wc, i::Integer) = initword!(wc, i)
recolor_reset!(wc, w=:; kargs...) = recolor_reset!.(wc, index(wc, w); kargs...)
function counter(iter; C=Dict{eltype(iter),Int}())
    for e in iter
        C[e] = get(C, e, 0) + 1
    end
    C
end
function mostfrequent(iter; C=Dict{eltype(iter),Int}())
    C = counter(iter; C=C)
    argmax(C)
end
function recolor_main!(wc, i::Integer; background=getmask(wc))
    bg = ARGB.(background)
    img = getimages(wc, i)
    x, y = getpositions(wc, i)
    bg, img = Render.overlappingarea(bg, img, x, y)
    m = wordmask(img, (0, 0, 0, 0), 0)
    bkv = @view bg[m]
    c = mostfrequent(bkv)
    initword!(wc, i, color=c)
end
recolor_main!(wc, w=:; kargs...) = recolor_main!.(wc, index(wc, w); kargs...)
function recolor_average!(wc, i::Integer; background=getmask(wc))
    bg = ARGB.(background)
    img = getimages(wc, i)
    x, y = getpositions(wc, i)
    bg, img = Render.overlappingarea(bg, img, x, y)
    m = wordmask(img, (0, 0, 0, 0), 0)
    bkv = @view bg[m]
    c = sum(bkv) / length(bkv)
    initword!(wc, i, color=c)
end
recolor_average!(wc, w=:; kargs...) = recolor_average!.(wc, index(wc, w); kargs...)

function recolor_blending!(wc, i::Integer; alpha=0.5, background=getmask(wc))
    bg = background
    img = getimages(wc, i)
    x, y = getpositions(wc, i)
    bg, img = Render.overlappingarea(bg, img, x, y)
    m = wordmask(img, (0, 0, 0, 0), 0)
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
    x, y = getpositions(wc, i)
    bg, img = Render.overlappingarea(bg, img, x, y)
    m = wordmask(img, (0, 0, 0, 0), 0)
    bg = @view bg[m]
    img = @view img[m]
    img .= convert.(eltype(img), Colors.alphacolor.(bg, Colors.alpha.(img)))
    nothing
end
recolor_clipping!(wc, w=:; kargs...) = recolor_clipping!.(wc, index(wc, w); kargs...)
"""
recolor the words in `wc` in different styles with the background picture.
The styles supported are `:average`, `:main`, `:clipping`, `:blending`, and :reset (to undo all effects of others).
e.g.  
* recolor!(wc, style=:average)
* recolor!(wc, style=:main)
* recolor!(wc, style=:clipping, background=blur(getmask(wc))) # `background` is optional
* recolor!(wc, style=:blending, alpha=0.3) # `background` and `alpha` are optional
* recolor!(wc, style=:reset)

The effects of `:average`, `:main` and `:clipping` are only determined by the `background`. But the effect of `:blending` is also affected by the previous word color. Therefore, `:blending` can also be used in combination with others
The results of `clipping` and `blending` can not be exported as SVG files, use PNG instead. 
"""
function recolor!(wc, args...; style=:average, kargs...)
    if style == :average
        recolor_average!(wc, args...; kargs...)
    elseif style == :main
        recolor_main!(wc, args...; kargs...)
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
* patient: number of epochs before repositioning
* reposition: a Bool value to turn on/off teleport, a Float number `p` between 0~1 indicating the repositioning ratio (Minimum `p`), a Int number `n` equivalent to `i -> i >= n`, a Function index::Int -> doteleport::Boll, or a white list collision.
* trainer: appoint a training engine
"""
function fit!(wc, args...; reposition=true, optimiser=SGD(), krags...)
    reposition isa Union{Function,Number} || (reposition = index(wc, reposition)) # Bool <: Number
    if STATEIDS[getstate(wc)] < STATEIDS[:placewords!]
        placewords!(wc)
    end
    qtrees = [wc.maskqtree, wc.qtrees...]
    ep, nc = train!(qtrees, args...; reposition=reposition, optimiser=optimiser, krags...)
    wc.params[:epoch] += ep
    if nc == 0
        setstate!(wc, nameof(fit!))
        # @assert isempty(outofkernelbounds(wc.maskqtree, wc.qtrees))
        # colllist = first.(totalcollisions(qtrees))
        # @assert length(colllist) == 0
    else
        setstate!(wc, nameof(placewords!))
    end
    wc
end
function printcollisions(wc)
    qtrees = [wc.maskqtree, wc.qtrees...]
    colllist = first.(totalcollisions(qtrees))
    get_text(i) = i > 1 ? wc.words[i - 1] : "#MASK#"
    collwords = [(get_text(i), get_text(j)) for (i, j) in colllist]
    if length(colllist) > 0
        @warn "Have $(length(colllist)) collisions. Try setting a larger `nepoch` and `retry`, or lower `density` and `spacing` in `wordcloud` to fix it."
        println("$collwords")
    end
end

"""
# Positional Args
* wc: the wordcloud to fit
* nepoch: training epoch nums
# Keyword Args
* retry: shrink & retrain times, defaults to 3, set to `1` to disable shrinking
* patient: number of epochs before repositioning
* reposition: a Bool value to turn on/off teleport, a Float number `p` between 0~1 indicating the repositioning ratio (Minimum `p`), a Int number `n` equivalent to `i -> i >= n`, a Function index::Int -> doteleport::Boll, or a white list collision.
* trainer: appoint a training engine
"""
function generate!(wc::WC, args...; retry=3, krags...)
    if STATEIDS[getstate(wc)] < STATEIDS[:placewords!]
        placewords!(wc)
    end
    for r in 1:retry
        if r != 1
            rescale!(wc, 0.97)
            dens = wordsoccupancy!(wc) / wc.params[:contentarea]
            println("▸$r. try scale = $(wc.params[:scale]). The density is reduced to $dens")
            printfontsizes(wc)
        else
            println("▸$r. scale = $(wc.params[:scale])")
        end
        fit!(wc, args...; krags...)
        if getstate(wc) == :fit!
            break
        end
    end
    if STATEIDS[getstate(wc)] >= STATEIDS[:fit!]
        println("$(wc.params[:epoch]) epochs")
        setstate!(wc, nameof(generate!))
    else # check
        printcollisions(wc)
    end
    wc
end

STATES = nameof.([wordcloud, initwords!, placewords!, fit!, generate!])
STATEIDS = Dict([s => i for (i, s) in enumerate(STATES)])


"""
keep some words and ignore the others, then execute the function. It's the opposite of `ignore`.
* keep(fun, wc, ws::String) #keep a word
* keep(fun, wc, ws::Set{String}) #kepp all words in ws
* keep(fun, wc, ws::Vector{String}) #keep all words in ws
* keep(fun, wc, inds::Union{Integer, Vector{Integer}})
* keep(fun, wc::WC, mask::AbstractArray{Bool}) #keep words. length(mask)==length(wc)
"""
function keep(fun, wc::WC, mask::AbstractArray{Bool})
    mem = [wc.words, wc.weights, wc.imgs, wc.svgs, wc.qtrees, 
            wc.params[:colors], wc.params[:angles], wc.params[:fonts], 
            wc.params[:wordids], wc.params[:word2index], wc.params[:id2index]]
    wc.words = @view wc.words[mask]
    wc.weights = @view wc.weights[mask]
    wc.imgs = @view wc.imgs[mask]
    wc.svgs = @view wc.svgs[mask]
    wc.qtrees = @view wc.qtrees[mask]
    wc.params[:colors] = @view wc.params[:colors][mask]
    wc.params[:angles] = @view wc.params[:angles][mask]
    wc.params[:fonts] = @view wc.params[:fonts][mask]
    wc.params[:wordids] = @view wc.params[:wordids][mask]
    wc.params[:word2index] = nothing
    wc.params[:id2index] = nothing
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
        wc.params[:fonts] = mem[8]
        wc.params[:wordids] = mem[9]
        wc.params[:word2index] = mem[10]
        wc.params[:id2index] = mem[11]
    end
    r
end
 
"""
pin some words as if they were part of the background, then execute the function.
* pin(fun, wc, ws::String) #pin a word
* pin(fun, wc, ws::Set{String}) #pin all words in ws
* pin(fun, wc, ws::Vector{String}) #pin all words in ws
* pin(fun, wc, inds::Union{Integer, Vector{Integer}})
* pin(fun, wc::WC, mask::AbstractArray{Bool}) #pin words. length(mask)==length(wc)
"""           
function pin(fun, wc::WC, mask::AbstractArray{Bool})
    maskqtree = wc.maskqtree
    wcmask = wc.mask
    contentarea = wc.params[:contentarea]
    
    maskqtree2 = deepcopy(maskqtree)
    Stuffing.overlap!(maskqtree2, wc.qtrees[mask])
    wc.maskqtree = maskqtree2
    resultpic = copy(wc.mask)
    wc.mask = overlay!(resultpic, wc.imgs[mask], getpositions(wc, mask))
    wc.params[:contentarea] = occupancy(QTrees.kernel(wc.maskqtree[1]), QTrees.FULL)
    r = nothing
    try
        r = ignore(fun, wc, mask)
    finally
        wc.maskqtree = maskqtree
        wc.mask = wcmask
    wc.params[:contentarea] = contentarea
    end
    r
end

function keep(fun, wc, ind::Integer)
    mask = falses(length(wc))
    mask[ind] = 1
    keep(fun, wc, mask)
end
function keep(fun, wc, inds::AbstractArray{<:Integer})
    mask = falses(length(wc))
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
* ignore(fun, wc::WC, mask::AbstractArray{Bool}) #ignore words. length(mask)==length(wc)
"""
function ignore(fun, wc::WC, mask::AbstractArray{Bool})
    keep(fun, wc, .!mask)
end
function ignore(fun, wc, ind::Integer)
    mask = falses(length(wc))
    mask[ind] = 1
    ignore(fun, wc, mask)
end
function ignore(fun, wc, inds::AbstractArray{<:Integer})
    mask = falses(length(wc))
    mask[inds] .= 1
    ignore(fun, wc, mask)
end
function ignore(fun, wc, ws)
    ignore(fun, wc, index(wc, ws))
end

function pin(fun, wc, ind::Integer)
    mask = falses(length(wc))
    mask[ind] = 1
    pin(fun, wc, mask)
end
function pin(fun, wc, inds::AbstractArray{<:Integer})
    mask = falses(length(wc))
    mask[inds] .= 1
    pin(fun, wc, mask)
end
function pin(fun, wc, ws)
    pin(fun, wc, index(wc, ws))
end
