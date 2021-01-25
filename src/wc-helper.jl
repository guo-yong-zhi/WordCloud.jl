using Colors
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
    mask = Render.load(path)
    if issvg(mask)
        if !isempty(args) || !isempty(kargs) 
            @warn "edit svg file is not supported"
        end
        return mask
    end
    loadmask(mask,  args...; kargs...)
end

"like `paint` but export svg"
function paintsvg(wc::WC; background=true)
    if background == false || background === nothing
        sz = size(wc.mask)
    else
        if background == true
            background = getsvgmask(wc)
            if background === nothing
                background = getmask(wc)
            end
        end
        sz = size(wc.mask)
        nothing
    end
    Render.overlay(getsvgimages(wc), getpositions(wc), background=background, size=reverse(sz))
end
function paintsvg(wc::WC, file, args...; kargs...)
    img = paintsvg(wc, args...; kargs...)
    Render.save(file, img)
    img
end

"""
# examples
* paint(wc::WC)
* paint(wc::WC, background=false) #no background
* paint(wc::WC, background=outline(wc.mask)) #use a new background
* paint(wc::WC, ratio=0.5) #resize the result
* paint(wc::WC, "result.png", ratio=0.5) #save as png file, other bitmap formats may also work
* paint(wc::WC, "result.svg") #save as svg file
"""
function paint(wc::WC, args...; background=true, kargs...)
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

function paint(wc::WC, file, args...; kargs...)
    if endswith(file, r".svg|.SVG")
        img = paintsvg(wc, args...; kargs...)
    else
        img = paint(wc, args...; kargs...)
    end
    Render.save(file, img)
    img
end
        
function record(wc::WC, label::AbstractString, gif_callback=x->x)
#     @show size(n1)
    resultpic = overlay!(paint(wc), 
        rendertextoutlines(label, 32, color="black", linecolor="white", linewidth=1), 20, 20)
    gif_callback(resultpic)
end


runexample(example=:alice) = evalfile(pkgdir(WordCloud)*"/examples/$(example).jl")
showexample(example=:alice) = read(pkgdir(WordCloud)*"/examples/$(example).jl", String)|>print
examples = join([":"*e[1:end-3] for e in basename.(readdir(pkgdir(WordCloud)*"/examples")) if endswith(e, ".jl")], ", ")
@doc "optional value: [" * examples * "]" runexample
@doc "optional value: [" * examples * "]" showexample