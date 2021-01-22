"Initialize word's images and other resources with specified style"
function initword!(wc, w; bgcolor=(0,0,0,0), border=wc.params[:border])
    i = index(wc, w)
    params = wc.params
    svg, img, mimg, tree = prepareword(wc.words[i], getfontsizes(wc, w), params[:colors][i], params[:angles][i],
        params[:groundsize], font=getfonts(wc, w), bgcolor=bgcolor, border=border)
    wc.imgs[i] = img
    wc.svgs[i] = svg
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
initwords! = initword!
        
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
    mem = [wc.words, wc.weights, wc.imgs, wc.svgs, wc.qtrees, 
            wc.params[:colors], wc.params[:angles], wc.params[:indsmap]]
    mask = .!mask
    wc.words = @view wc.words[mask]
    wc.weights = @view wc.weights[mask]
    wc.imgs = @view wc.imgs[mask]
    wc.svgs = @view wc.svgs[mask]
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
        wc.svgs = mem[4]
        wc.qtrees = mem[5]
        wc.params[:colors] = mem[6]
        wc.params[:angles] = mem[7]
        wc.params[:indsmap] = mem[8]
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
