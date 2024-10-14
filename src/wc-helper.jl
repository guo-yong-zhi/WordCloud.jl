using Colors
const DEFAULTSYMBOLS = [:original, :auto, :default]
iter_expand(e) = Base.Iterators.repeated(e)
iter_expand(l::Vector) = Base.Iterators.cycle(l)
iter_expand(r::AbstractRange) = IterGen(st->rand(r))
iter_expand(t::Tuple) = IterGen(st->rand(t))
struct IterGen
    generator
end
Base.iterate(it::IterGen, state=0) = it.generator(state),state+1
Base.IteratorSize(it::IterGen) = Base.IsInfinite()

function volume_factor(img, args...)
    sc = sqrt(prod(size(img)) / occupancy(imagemask(img, args...)))
    isinf(sc) ? 1 : sc
end
"""
Load an image as a mask, recolor it, or resize it, among other options.
## Examples
* loadmask(open("res/heart.jpg"), 256, 256) # resize to 256*256  
* loadmask("res/heart.jpg", ratio=0.3) # scaled by 0.3  
* loadmask("res/heart.jpg", color="red", ratio=2) # set forecolor  
* loadmask("res/heart.jpg", transparent=rgba->maximum(rgba[1:3])*(rgba[4]/255)>128) # set transparent using a Function 
* loadmask("res/heart.jpg", color="red", transparent=(1,1,1)) # set forecolor and transparent  
* loadmask("res/heart.svg") # only a subset of arguments is supported
padding: an Integer or a tuple of two Integers.  
For other keyword arguments like outline, linecolor, and smoothness, refer to the function [`outline`](@ref).
"""
function loadmask(img::AbstractMatrix{<:TransparentRGB}, args...; 
    color=:auto, backgroundcolor=:auto, transparent=:auto, 
    outline=0, linecolor="black", smoothness=0.5, padding=0, return_bitmask=false,
    preservevolume=false, ratio=1)
    copied = false
    if !(isempty(args) && all(ratio .== 1))
        vf = preservevolume ? volume_factor(img, transparent) : 1
        img = imresize(img, args...; ratio=ratio .* vf)
        copied = true
    end
    backgroundcolor ∉ DEFAULTSYMBOLS && (backgroundcolor = parsecolor(backgroundcolor))
    if padding != 0 # padding before cal imagemask
        bc = backgroundcolor in DEFAULTSYMBOLS ? :auto : backgroundcolor
        img = pad(img, padding, backgroundcolor=bc)
    end
    if return_bitmask || color ∉ DEFAULTSYMBOLS || backgroundcolor ∉ DEFAULTSYMBOLS
        mask = imagemask(img, transparent)
    end
    if color ∉ DEFAULTSYMBOLS || backgroundcolor ∉ DEFAULTSYMBOLS
        copied || (img = copy(img))
        if color ∉ DEFAULTSYMBOLS
            color = parsecolor(color)
            alpha(color) == 1 || @warn "the alpha channel is ignored"
            m = @view img[mask]
            Render.recolor!(m, color) # 保持透明度
        end
        if backgroundcolor ∉ DEFAULTSYMBOLS
            m = @view img[.~mask]
            m .= convert.(eltype(img), backgroundcolor) # 不保持透明度
        end
    end

    if outline > 0
        img = Render.outline(img, linewidth=outline, color=linecolor, smoothness=smoothness, 
        transparent=transparent)
    end
    return_bitmask ? (img, mask) : img
end
function loadmask(img::AbstractMatrix{<:Colorant}, args...; kargs...)
    loadmask(ARGB.(img), args...; kargs...)
end
function loadmask(img::SVG, args...; 
    padding=0, transparent=:auto, linecolor=:auto, return_bitmask=false, ratio=1, preservevolume=false, kargs...)
    if !all(kv->(last(kv) in DEFAULTSYMBOLS || kv==(:outline=>0)), kargs)
        @warn "editing svg file is not supported: $kargs"
    end
    if !(isempty(args) && all(ratio .== 1))
        vf = preservevolume ? volume_factor(img, transparent) : 1
        img = imresize(img, args...; ratio=ratio .* vf)
    end
    if padding != 0
        bc = get(kargs, :backgroundcolor, (0,0,0,0))
        bc in DEFAULTSYMBOLS && (bc = (0,0,0,0))
        img = pad(img, padding, backgroundcolor=bc)
    end
    return_bitmask ? (img, nothing) : img
end
function loadmask(file, args...; kargs...)
    mask = Render.load(file)
    loadmask(mask, args...; kargs...)
end

"Similar to [`paint`](@ref), but exports SVG"
function paintsvg(wc::WC; background=true)
    imgs = getsvgimages(wc)
    poss = getpositions(wc)
    if background == false || background === nothing
        sz = size(wc.mask)
        bgcolor = (1,1,1,0)
    else
        if background == true
            bgcolor = getbackgroundcolor(wc)
            bgcolor in DEFAULTSYMBOLS && (bgcolor = (1,1,1,0))
            background = getsvgmask(wc)
            if background === nothing
                background = getmask(wc)
            end
        else
            bgcolor = (1,1,1,0)
        end
        if !(background isa SVG)
            @warn "Embedding bitmap into SVG. Set `background=false` in `paintsvg` to remove the background."
            background = tosvg(background)
        end
        imgs = Iterators.flatten(((background,), imgs))
        poss = Iterators.flatten((((1, 1),), poss))
        sz = size(background)
    end
    Render.overlay(imgs, poss, backgroundcolor=bgcolor, size=reverse(sz))
end
function paintsvg(wc::WC, file, args...; kargs...)
    img = paintsvg(wc, args...; kargs...)
    Render.save(file, img)
    img
end

"""
Paint the [`wordcloud`](@ref) generated object into an image or an SVG file.
See also: [`paintsvg`](@ref)
# Examples
* paint(wc::WC)
* paint(wc::WC, background=false) # without background
* paint(wc::WC, background=outline(wc.mask)) # use a different background
* paint(wc::WC, ratio=0.5) # resize the output
* paint(wc::WC, "result.png", ratio=0.5) # save as png file
* paint(wc::WC, "result.svg") # save as svg file
"""
function paint(wc::WC, args...; background=true, kargs...)
    if background == true
        bgcolor = getbackgroundcolor(wc)
        bgcolor in DEFAULTSYMBOLS && (bgcolor = (1,1,1,0))
        background = fill(convert(eltype(wc.mask), parsecolor(bgcolor)), size(wc.mask))
        overlay!(background, wc.mask)
    elseif background == false || background === nothing
        background = fill(convert(eltype(wc.mask), parsecolor((1,1,1,0))), size(wc.mask))
    else
        background = copy(background)
    end
    overlay!(background, wc.imgs, getpositions(wc))
    if !(isempty(args) && isempty(kargs))
        background = ARGB.(background) # https://github.com/JuliaImages/ImageTransformations.jl/issues/97
        background = imresize(background, args...; kargs...)
    end
    background
end

function paint(wc::WC, file, args...; kargs...)
    if endswith(file, r".svg|.SVG")
        img = paintsvg(wc, args...; kargs...)
    else
        img = paint(wc, args...; kargs...)
    end
    Render.save(file, img)
    img
end

"""
Generate a word cloud image from text. This function acts as a convenient shortcut for `paint(generate!(wordcloud(...))...)`. 
It accepts the same arguments as [`wordcloud`](@ref) and [`paint`](@ref). 
# other arguments
- quiet: suppresses the output of the generation process. defaults to true.

See also: [`paintsvgcloud`](@ref)
# Examples
* paintcloud("holly bible")
* paintcloud("holly bible", "result.svg", quiet=false)
* paintcloud(["holly", "bible"], [0.7, 0.3], "result.png", background=false)
* paintcloud("holly bible", angles=(0, 90), ratio=0.5)
"""
function paintcloud(args...; quiet=true, paintfunc=paint, kargs...)
    if length(args) > 1 && last(args) isa AbstractString
        args_w, args_p = args[1:end-1], args[end:end]
    else
    	args_w, args_p = args, ()
    end
    pkw = (:background, :ratio)
    kargs_w = filter(kw -> first(kw) ∉ pkw, kargs)
    kargs_p = filter(kw -> first(kw) ∈ pkw, kargs)
    if quiet
        redirect_stdio(stdout=devnull, stderr=devnull) do
            paintfunc(generate!(wordcloud(args_w...; kargs_w...)), args_p...; kargs_p...)
        end
    else
        paintfunc(generate!(wordcloud(args_w...; kargs_w...)), args_p...; kargs_p...)
    end
end
"Similar to [`paintcloud`](@ref), but exports SVG"
function paintsvgcloud(args...; paintfunc=paintsvg, kargs...)
    paintcloud(args...; paintfunc=paintfunc, kargs...)
end

function frame(wc::WC, label::AbstractString, args...; kargs...)
    overlay!(paint(wc, args...; kargs...), rendertextoutlines(label, 32, color="black", linecolor="white", linewidth=1), 20, 20)
end

function record(func::Function, wc::WC, args...; outputdir="record_output", overwrite=false, filter=i->true, kargs...)
    if overwrite
        rm(outputdir, force=true, recursive=true)
    end
    gif = GIF(outputdir)
    callback = i -> (filter(i) && gif(frame(wc, string(i))))
    callback(0)
    re = func(wc, args...; callback=callback, kargs...)
    Render.generate(gif)
    re
end
record(outputdir::AbstractString, args...; kargs...) = record(args...; outputdir=outputdir, kargs...)
macro record(x...)
    kwargs = [Expr(:kw, e.args...) for e in x[1:end-1] if e isa Expr]
    args = [e for e in x[1:end-1] if !(e isa Expr)]
    esc(:(record($(args...), $(x[end].args...), $(kwargs...))))
end

function svgimage_wrap!(wc::WC, i::Integer, wrappers)
    svg = getsvgimages(wc, i)
    svg = svg_wrap(svg, wrappers)
    setsvgimages!(wc, i, svg)
end
function svgimages_add!(wc::WC, i::Integer, children)
    svg = getsvgimages(wc, i)
    svg = svg_add(svg, children)
    setsvgimages!(wc, i, svg)
end
"""
For editing SVGs of words.  
The 1st argument is wordcloud, the 2nd optional argument is index which can be string, number, list, or any other standard supported index.  
There are two kinds of keyword arguments, `children` and `wrappers`. 
The nodes in `children` will be linked under the root node of the SVG. 
The nodes in `wrappers` will be inserted between the SVG root node and all its child nodes. The children will be wraped by the wrapper node.
A node is represented as a String Pair. e.g.
* child `"title"=>"word"` for `<title>word</title>`
* child `"title"=>("word", :lang=>"en-us")` for `<title lang="en-us">word</title>`
* child `"animate" => ["attributeName"=>"opacity", "to"=>"0", "dur"=>"6s"]` for `<animate attributeName="opacity" to="0" dur="6s"/>`
* wrapper `"a"=>("href"=>"https://www.google.com")` for `<a href="https://www.google.com">` and `</a>`
Arguments `children` and `wrappers` can be a Pair, or a Tuple of Pairs to add multiple nodes to a SVG. 
Again, giving a list of Tuples of Pairs is ok to edit multiple SVGs corresponding to the index argument.
"""
function configsvgimages!(wc, w=:, args...; children=nothing, wrappers=nothing)
    if children !== nothing
        children isa AbstractVector || (children = Ref(children))
        svgimages_add!.(wc, index(wc, w), children, args...)
    end
    if wrappers !== nothing
        wrappers isa AbstractVector || (wrappers = Ref(wrappers))
        svgimage_wrap!.(wc, index(wc, w), wrappers, args...)
    end
end
runexample(example=:random) = @time evalfile(pkgdir(WordCloud)*"/examples/$(example).jl")
showexample(example=:random) = read(pkgdir(WordCloud)*"/examples/$(example).jl", String)|>print
const EXAMPLES = [e[1:prevind(e, end, 3)] for e in basename.(readdir(pkgdir(WordCloud)*"/examples")) if endswith(e, ".jl")]
const _EXAMPLE_DOC = "Available values: [" * join(":" .* EXAMPLES, ", ") * "]"
@doc _EXAMPLE_DOC runexample
@doc _EXAMPLE_DOC showexample
function runexamples(examples=EXAMPLES)
    println(length(examples), " examples: ", examples)
    for (i,e) in enumerate(examples)
        println("="^20, "\n# ",i,"/",length(examples), "\t", e, "\n", "="^20)
        runexample(e)
    end
end
