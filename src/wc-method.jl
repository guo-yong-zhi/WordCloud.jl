using Random
function initqtree!(wc, i::Integer; backgroundcolor=(0, 0, 0, 0), spacing=getparameter(wc, :spacing))
    img = wc.imgs[i]
    mimg = ternary_wordmask(img, backgroundcolor, spacing)
    t = qtree(mimg, wc.params[:groundsize])
    c = isassigned(wc.qtrees, i) ? getcenter(wc.qtrees[i]) : wc.params[:groundsize] ÷ 2
    setcenter!(t, c)
    wc.qtrees[i] = t
end
initqtree!(wc, i; kargs...) = initqtree!.(wc, index(wc, i); kargs...)
"Initialize the images and other resources associated with words using the specified style."
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
    initword!(wc, :)
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
            ratio = volumeproposal(wc.words, wc.weights) / √getparameter(wc, :volume)
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
The `placewords!` function is employed to establish an initial layout for the word cloud.
* placewords!(wc)
* placewords!(wc, style=:uniform)
* placewords!(wc, style=:gathering)
* placewords!(wc, style=:gathering, level=5) # The `level` parameter controls the intensity of gathering, typically ranging from 4 to 6. The default value is 5.
* placewords!(wc, style=:gathering, level=6, rt=0) # rt=0 for rectangle, rt=1 for ellipse, rt=2 for rhombus. The default value is 1.  
There is also a keyword argument `centralword` available. For example, `centralword=1`, `centralword="Alice"` or `centralword=false`.
When you have set `style=:gathering`, you should also disable repositioning in `generate!`, especially for big words. For example, `generate!(wc, reposition=0.7)`.
The keyword argument `reorder` is a function used to reorder the words, which affects the order of placement. For example, you can use `reverse` or `WordCloud.shuffle`.
"""
function placewords!(wc::WC; style=:auto, rt=:auto, centralword=:auto, reorder=:auto, level=:auto, callback=x->x, kargs...)
    if STATEIDS[getstate(wc)] < STATEIDS[:initwords!]
        initwords!(wc)
    end
    @assert style in [:uniform, :gathering, :auto]
    centralword == :auto && hasparameter(wc, :centralword) && (centralword = getparameter(wc, :centralword))
    if centralword == :auto || centralword === true
        max_i = argmax(wc.weights)
        max_i2 = length(wc)>1 ? partialsortperm(wc.weights, 2, rev=true) : max_i
        if centralword == :auto
            c = wc.params[:groundsize] ÷ 2 # can't wc.maskqtree[1][end÷2]. 1D index goes wrong.
            kernelsize = Stuffing.kernelsize
            centralword = wc.maskqtree[1][c, c] == QTrees.EMPTY && (
                length(wc.qtrees) < 2 
                || (wc.weights[max_i2] / wc.weights[max_i] < 0.5 
                    && prod(kernelsize(wc.qtrees[max_i2])) / prod(kernelsize(wc.qtrees[max_i])) < 0.5))
        end
        if centralword # Bool
            centralword = max_i
        end
        # false or Int
    end
    arg = ()
    qtrees = wc.qtrees
    if centralword !== false # Bool, Int or string...
        centralword = index(wc, centralword)
        setcenter!(wc.qtrees[centralword],  wc.params[:groundsize] .÷ 2)
        println("center the word $(repr(getwords(wc, centralword)))")
        arg = (2:length(wc.qtrees) |> collect,)
        qtrees = [wc.qtrees[i] for i in eachindex(wc.qtrees) if i != centralword]
        callback(1)
    end
    reorder == :auto && hasparameter(wc, :reorder) && (reorder = getparameter(wc, :reorder))
    reorder == :auto && (reorder=identity)
    qtrees = reorder(qtrees)
    centralword !== false && (qtrees = [wc.qtrees[centralword], qtrees...])
    if length(wc.qtrees) > 0 + (centralword !== false)
        style == :auto && hasparameter(wc, :style) && (style = getparameter(wc, :style))
        style == :auto && (style = rand()<0.8 ? :uniform : :gathering)
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
            level == :auto && hasparameter(wc, :level) && (level = getparameter(wc, :level))
            level == :auto && (level=5)
            ind = Stuffing.place!(deepcopy(wc.maskqtree), qtrees, arg...; 
                    roomfinder=findroom_gathering, p=p, level=level, callback=callback, kargs...)
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

"rescale!(wc::WC, ratio::Real)\nResize all words proportionally. Use a ratio < 1 to shrink the size, and a ratio > 1 to expand the size."
function rescale!(wc::WC, ratio::Real)
    qts = wc.qtrees
    centers = getcenter.(qts)
    wc.params[:scale] *= ratio
    initword!(wc, :)
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
    bg, img = Render.intersection_region(bg, img, x, y)
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
    bg, img = Render.intersection_region(bg, img, x, y)
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
    bg, img = Render.intersection_region(bg, img, x, y)
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
    bg, img = Render.intersection_region(bg, img, x, y)
    m = wordmask(img, (0, 0, 0, 0), 0)
    bg = @view bg[m]
    img = @view img[m]
    img .= convert.(eltype(img), Colors.alphacolor.(bg, Colors.alpha.(img)))
    nothing
end
recolor_clipping!(wc, w=:; kargs...) = recolor_clipping!.(wc, index(wc, w); kargs...)
"""
Recolor the words according to the pixel color in the background image.
The styles supported are `:average`, `:main`, `:clipping`, `:blending`, and :reset (to undo all effects of the other styles).
## Examples
* recolor!(wc, style=:average)
* recolor!(wc, style=:main)
* recolor!(wc, style=:clipping, background=blur(getmask(wc))) # The `background` parameter is optional
* recolor!(wc, style=:blending, alpha=0.3) # The `alpha` parameter is optional
* recolor!(wc, style=:reset)

The effects of `:average`, `:main`, and `:clipping` are determined solely by the background. However, the effect of `:blending` is also influenced by the previous color of the word. Therefore, `:blending` can also be used in combination with other styles. 
The results of `clipping` and `blending` cannot be exported as SVG files; PNG should be used instead.
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
# Positional Arguments
* wc: the word cloud object to be fitted
* epochs: the number of training epochs
# Keyword Arguments
* patience: the number of epochs before repositioning
* reposition: a boolean value that determines whether repositioning is enabled or disabled. Additionally, it can accept a float value p (0 ≤ p ≤ 1) to indicate the repositioning ratio, an integer value n to specify the minimum index for repositioning, a function index::Int -> repositionable::Bool to customize the repositioning behavior, or a whitelist for specific indexes.
* trainer: specify a training engine
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
    if length(colllist) > 0
        @warn "Have $(length(colllist)) collisions. Try setting a larger `epochs` and `retry`, or lower `density` and `spacing` in `wordcloud` to fix it."
        print("These words collide: ")
        foreach(ij->print(get_text(ij[1]), " & ", get_text(ij[2]), ", "), colllist)
        println()
    end
end

"""
# Positional Arguments
* wc: the word cloud object to be fitted
* epochs: the number of training epochs
# Keyword Arguments
* retry: the number of attempts for shrinking and retraining, default is 3; set to 1 to disable shrinking
* patience: the number of epochs before repositioning
* reposition: a boolean value that determines whether repositioning is enabled or disabled. Additionally, it can accept a float value p (0 ≤ p ≤ 1) to indicate the repositioning ratio, an integer value n to specify the minimum index for repositioning, a function index::Int -> repositionable::Bool to customize the repositioning behavior, or a whitelist for specific indexes.
* trainer: specify a training engine
"""
function generate!(wc::WC, args...; retry=3, krags...)
    if STATEIDS[getstate(wc)] < STATEIDS[:placewords!]
        placewords!(wc)
    end
    for r in 1:retry
        if r != 1
            println("Aborted after $(getparameter(wc, :epoch)) epochs.")
            sp = getparameter(wc, :spacing)
            if iseven(r) && sp > 1
                setparameter!(wc, sp - 1, :spacing)
                initqtree!(wc, :)
                println("▸$r. Try setting spacing = $(getparameter(wc, :spacing))")
            else
                rescale!(wc, 0.97)
                dens = wordsoccupancy!(wc) / getparameter(wc, :volume)
                println("▸$r. Try setting scale = $(getparameter(wc, :scale)). The density will be reduced to $dens")
                printfontsizes(wc)
            end
        else
            println("▸$r. Set spacing = $(getparameter(wc, :spacing)); scale = $(getparameter(wc, :scale))")
        end
        fit!(wc, args...; krags...)
        if getstate(wc) == :fit!
            break
        end
    end
    if STATEIDS[getstate(wc)] >= STATEIDS[:fit!]
        println("Completed after $(getparameter(wc, :epoch)) epochs.")
        setstate!(wc, nameof(generate!))
    else # check
        println("Failed after $(getparameter(wc, :epoch)) epochs.")
        printcollisions(wc)
    end
    wc
end

STATES = nameof.([wordcloud, initwords!, placewords!, fit!, generate!])
STATEIDS = Dict([s => i for (i, s) in enumerate(STATES)])


"""
Retain specific words and ignore the rest, and then execute the function. It functions as the opposite of ignore.
* keep(fun, wc, ws::String) # keep a word
* keep(fun, wc, ws::Set{String}) # keep all words in ws
* keep(fun, wc, ws::Vector{String}) # keep all words in ws
* keep(fun, wc, inds::Union{Integer, Vector{Integer}})
* keep(fun, wc::WC, mask::AbstractArray{Bool}) # keep words. The `mask` must have the same length as `wc`
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
Fix specific words as if they were part of the background, and then execute the function.
* pin(fun, wc, ws::String) # pin an single  word
* pin(fun, wc, ws::Set{String}) # pin all words in ws
* pin(fun, wc, ws::Vector{String}) # pin all words in ws
* pin(fun, wc, inds::Union{Integer, Vector{Integer}})
* pin(fun, wc::WC, mask::AbstractArray{Bool}) # pin words. # pin words. The `mask` must have the same length as `wc`.
"""           
function pin(fun, wc::WC, mask::AbstractArray{Bool})
    maskqtree = wc.maskqtree
    wcmask = wc.mask
    volume = wc.params[:volume]
    
    maskqtree2 = deepcopy(maskqtree)
    Stuffing.overlap!(maskqtree2, wc.qtrees[mask])
    wc.maskqtree = maskqtree2
    resultpic = copy(wc.mask)
    wc.mask = overlay!(resultpic, wc.imgs[mask], getpositions(wc, mask))
    wc.params[:volume] = occupancy(QTrees.kernel(wc.maskqtree[1]), QTrees.FULL)
    r = nothing
    try
        r = ignore(fun, wc, mask)
    finally
        wc.maskqtree = maskqtree
        wc.mask = wcmask
    wc.params[:volume] = volume
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
Exclude specific words as if they do not exist, and then execute the function. It functions as the opposite of `keep`.
* ignore(fun, wc, ws::String) # ignore a word
* ignore(fun, wc, ws::Set{String}) # ignore all words in ws
* ignore(fun, wc, ws::Vector{String}) # ignore all words in ws
* ignore(fun, wc, inds::Union{Integer, Vector{Integer}})
* ignore(fun, wc::WC, mask::AbstractArray{Bool}) # ignore words. The `mask` must have the same length as `wc`
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
