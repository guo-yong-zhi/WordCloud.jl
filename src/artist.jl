using Random
SansSerifFonts = ["Trebuchet MS", "Heiti TC", "微軟正黑體", "Arial Unicode MS", "Droid Fallback Sans", "sans-serif", "Helvetica", "Verdana", "Hei",
"Arial", "Tahoma", "Trebuchet MS", "Microsoft Yahei", "Comic Sans MS", "Impact", "Segoe Script", "STHeiti", "Apple LiGothic", "MingLiU", "Ubuntu", 
"Segoe UI", "DejaVu Sans", "DejaVu Sans Mono", "Noto Sans CJK"]
SerifFonts = ["Baskerville", "Times New Roman", "華康儷金黑 Std", "華康儷宋 Std",  "DFLiKingHeiStd-W8", "DFLiSongStd-W5", "DejaVu Serif", "SimSun",
    "Hiragino Mincho Pro", "LiSong Pro", "新細明體", "serif", "Georgia", "STSong", "FangSong", "KaiTi", "STKaiti", "Courier New"]
CandiFonts = union(SansSerifFonts, SerifFonts)
CandiWeights = ["", " Regular", " Normal", " Medium", " Bold", " Light"]
function checkfonts(fonts::AbstractVector)
    fname = tempname()
    r = Bool[]
    open(fname, "w") do f
        redirect_stderr(f) do
            p = position(f)
            for font in fonts
                rendertext("a", 1 + rand(), font=font) # 相同字体相同字号仅warning一次，故首次执行最准
                # flush(f) #https://en.cppreference.com/w/cpp/io/c/fseek The standard C++ file streams guarantee both flushing and unshifting 
                seekend(f)
                p2 = position(f)
                push!(r, p2 == p)
                p = p2
            end
        end
    end
    return r
end
checkfonts(f) = checkfonts([f]) |> only
function filterfonts(;fonts=CandiFonts, weights=CandiWeights)
    candi = ["$f$w" for w in weights, f in fonts] |> vec
    candi[checkfonts(candi)]
end
AvailableFonts = filterfonts()
push!(AvailableFonts, "")

Schemes_colorbrewer = filter(s -> occursin("colorbrewer", colorschemes[s].category), collect(keys(colorschemes)))
Schemes_colorbrewer =  filter(s -> (occursin("Accent", String(s)) 
        || occursin("Dark", String(s))
        || occursin("Paired", String(s))
        || occursin("Pastel", String(s))
        || occursin("Set", String(s))
        || occursin("Spectral", String(s))
        || occursin("BuPu", String(s))
        || occursin("PuOr", String(s))
        || occursin("RdPu", String(s))
        ), Schemes_colorbrewer)
Schemes_seaborn = filter(s -> occursin("seaborn", colorschemes[s].category), collect(keys(colorschemes)))
Schemes_tableau = filter(s -> occursin("tableau", colorschemes[s].category), collect(keys(colorschemes)))
Schemes_cvd = filter(s -> occursin("cvd", colorschemes[s].category), collect(keys(colorschemes)))
Schemes = [Schemes_colorbrewer..., Schemes_seaborn..., Schemes_tableau..., Schemes_cvd...]

function displayschemes()
    for scheme in Schemes
        display(scheme)
        colors = Render.colorschemes[scheme].colors
        display(colors)
    end
end
function randomscheme()
    if rand() < 0.95
        scheme = rand(Schemes)
        c = Render.colorschemes[scheme].colors
        colors = randsubseq(c, rand())
        colors = isempty(colors) ? c : colors
        @show (scheme, length(colors))
    else
        colors = rand((0, 1, 0, 1, 0, 1, (0,1), rand(), (rand(), rand())))
        @show colors
    end
    (colors...,)
end
function randommask(sz::Number=800; kargs...)
    s = sz * sz * (0.5+rand()/2)
    ratio = (0.5+rand()/2)
    ratio = ratio>0.9 ? 1.0 : ratio
    h = round(Int, sqrt(s*ratio))
    w = round(Int, h/ratio)
    randommask(w, h; kargs...)
end
function randommask(sz; kargs...)
    randommask(sz...; kargs...)
end
function randommask(w, h, args...; maskshape=:rand, kargs...)
    ran = Dict(box=>0.2, squircle=>0.7, ellipse=>1, :rand=>rand())[maskshape]
    if ran <= 0.2
        return randombox(w, h, args...; kargs...)
    elseif ran <= 0.7
        return randomsquircle(w, h, args...; kargs...)
    else
        return randomellipse(w, h, args...; kargs...)
    end
end
function randombox(w, h, r=:rand; kargs...)
    if r == :rand
        r = rand() * 0.5 - 0.05 # up to 0.45
        r = r < 0. ? 0. : r # 10% for 0.
        r = round(Int, h*r)
    end
    println("shape(box, $w, $h, $r", join([", $k=$(repr(v))" for (k,v) in kargs]), ")")
    return shape(box, w, h, r; kargs...)
end
function randomsquircle(w, h; rt=:rand, kargs...)
    if rt == :rand
        if rand()<0.8
            rt = rand()
        else
            ran = rand()
            if ran < 0.5
                rt = 2
            else
                rt = 1 + 1.5rand()
            end
        end
    end
    println("shape(squircle, $w, $h, rt=$rt", join([", $k=$(repr(v))" for (k,v) in kargs]), ")")
    return shape(squircle, w, h, rt=rt; kargs...)
end
function randomellipse(w, h; kargs...)
    println("shape(ellipse, $w, $h", join([", $k=$(repr(v))" for (k,v) in kargs]), ")")
    return shape(ellipse, w, h; kargs...)
end
function randomangles()
    a = rand((-1, 1)) .* rand((0, (0,90), (0,90,45), (0,90,45,-45), (0,45,-45), (45,-45), -90:90, 0:90))
    println("angles = ", a)
    a
end
function randommaskcolor(colors)
    colors = parsecolor.(unique(colors))
    try
        g = Gray.(colors) |> sort
        m = g[1]
        M = g[end]
        if length(g) > 1
            d = diff(g)
            I = maximum(d)
            i = findlast(isequal(I), d)
        else
            I = 0
            i = -1
        end
        # @show I, m, M
        if I > 3(1 - M) && I > 3m
            middle = (g[i]+g[i+1])/2
            th1 = clamp(max(g[i]+0.15, middle-rand(0:0.001:0.05)), 0, middle)
            th2 = clamp(min(g[i+1]-0.15, middle+rand(0:0.001:0.05)), middle, 1)
            default = middle
        elseif sum(g)/length(g) < 0.7 && (m+M)/2 < 0.7 && !(m>2(1-M))#明亮
            th1 = clamp(max(M+0.15, rand(0.85:0.001:1.0)), 0, 1)
            th2 = clamp(th1+0.1, 0, 1)
            default = 1.0
        else    #黑暗
            th2 = clamp(min(m-0.15, rand(0.0:0.001:0.3)), 0, 1) #对深色不敏感，+0.15
            th1 = clamp(th2-0.15, 0, 1)
            default = 0.0
        end
        maskcolor = rand((default, (rand(th1:0.001:th2), rand(th1:0.001:th2), rand(th1:0.001:th2))))
        # @show maskcolor
        return maskcolor
    catch e
        @show e
        @show "colors sum failed",colors
        return "white"
    end
end
function randomlinecolor(colors)
    if rand() < 0.8
        linecolor = rand((colors[1], colors[1], rand(colors)))
    else
        linecolor = (rand(), rand(), rand(), min(1., 0.5+rand()/2))
    end
    linecolor
end
randomoutline() = rand((0, 0, 0, rand((1,2,3,4,5))))
function randomfont()
    font = rand(AvailableFonts)
    @show font
    font
end
