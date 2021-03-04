function initqtree!(wc, i::Integer; backgroundcolor=(0,0,0,0), border=wc.params[:border])
    img = wc.imgs[i]
    mimg = wordmask(img, backgroundcolor, border) 
    t = ShiftedQtree(mimg, wc.params[:groundsize])
    c = isassigned(wc.qtrees, i) ? getcenter(wc.qtrees[i]) : wc.params[:groundsize] .÷ 2
    setcenter!(t, c)
    t |> buildqtree!
    wc.qtrees[i] = t
end
initqtree!(wc, i; kargs...) = initqtree!.(wc, index(wc, i); kargs...)
"Initialize word's images and other resources with specified style"
function initimage!(wc, i::Integer; backgroundcolor=(0,0,0,0), border=wc.params[:border])
    params = wc.params
    img, svg = prepareword(wc.words[i], getfontsizes(wc, i), params[:colors][i], params[:angles][i],
        params[:groundsize], font=getfonts(wc, i), backgroundcolor=backgroundcolor, border=border)
    wc.imgs[i] = img
    wc.svgs[i] = svg
    initqtree!(wc, i, backgroundcolor=backgroundcolor, border=border)
    nothing
end
initimage!(wc, i; kargs...) = initimage!.(wc, index(wc, i); kargs...)
function initimage!(wc::WC; maxiter=5, error=0.01)
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

    scale = find_weight_scale!(wc, density=params[:density], maxiter=maxiter, error=error)
    println("density set to $(params[:density]), with scale=$scale, font minimum is $(getfontsizes(wc, wc.words[end]))")
    initimage!.(wc, 1:length(words))
    params[:state] = nameof(initimages!)
    wc
end
initimages! = initimage!
"""
* placement!(wc)
* placement!(wc, style=:uniform)
* placement!(wc, style=:gathering)
* placement!(wc, style=:gathering, level=5) #`level` controls the intensity of gathering, typically between 4 and 6, defaults to 5.
* placement!(wc, style=:gathering, level=6, p=1) #`p` refers to p-norm (Minkowski distance), defaults to 2. 
p=1 produces a rhombus, p=2 produces an ellipse, p>2 produces a rectangle with rounded corners.
"""
function placement!(wc::WC; style=:uniform, kargs...)
    if getstate(wc) == nameof(wordcloud)
        initimages!(wc)
    end
    @assert style in [:uniform, :gathering]
    if style == :gathering
        if wc.maskqtree[1][(wc.params[:groundsize].÷2)] == EMPTY && (length(wc.qtrees)<2 
            || (length(wc.qtrees)>=2 && prod(kernelsize(wc.qtrees[2]))/prod(kernelsize(wc.qtrees[1])) < 0.5))
            setcenter!(wc.qtrees[1],  wc.params[:groundsize] .÷ 2)
            QTree.placement!(deepcopy(wc.maskqtree), wc.qtrees, 2:length(wc.qtrees)|>collect, 
                roomfinder=findroom_gathering; kargs...)
        else
            QTree.placement!(deepcopy(wc.maskqtree), wc.qtrees, roomfinder=findroom_gathering; kargs...)
        end
    else
        QTree.placement!(deepcopy(wc.maskqtree), wc.qtrees, roomfinder=findroom_rand; kargs...)
    end
    wc.params[:state] = nameof(placement!)
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

"""
# Positional Args
* wc: the wordcloud to train
* nepoch: training epoch nums
# Keyword Args
* retry: shrink & retrain times, default 3
* patient: number of epochs before teleporting
* trainer: appoint a training engine
"""
function generate!(wc::WC, args...; retry=3, krags...)
    if getstate(wc) != nameof(placement!) && getstate(wc) != nameof(generate!)
        placement!(wc)
    end
    ep, nc = -1, -1
    for r in 1:retry
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
        @assert isempty(outofbounds(wc.maskqtree, wc.qtrees))
    else #check
        colllist = first.(listcollision(wc.qtrees, wc.maskqtree))
        get_text(i) = i>0 ? wc.words[i] : "#MASK#"
        collwords = [(get_text(i), get_text(j)) for (i,j) in colllist]
        if length(colllist) > 0
            wc.params[:completed] = false
            println("have $(length(colllist)) collisions.",
            " try setting a larger `nepoch` and `retry`, or lower `density` in `wordcloud` to fix that")
            println("$collwords")
        else
            wc.params[:state] = nameof(generate!)
        end
    end
    wc
end

function generate_animation!(wc::WC, args...; outputdir="gifresult", overwrite=false, callbackstep=1, kargs...)
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
* ignore(fun, wc::WC, mask::AbstractArray{Bool}) #ignore words. length(mask)==length(wc.words)
"""
function ignore(fun, wc::WC, mask::AbstractArray{Bool})
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
* pin(fun, wc::WC, mask::AbstractArray{Bool}) #pin words. length(mask)==length(wc.words)
"""           
function pin(fun, wc::WC, mask::AbstractArray{Bool})
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
