using Random
SansSerifFonts = ["Trebuchet MS", "Heiti TC", "微軟正黑體", "Arial Unicode MS", "Droid Fallback Sans", "sans-serif", "Helvetica", "Verdana", "Hei",
    "Arial", "Tahoma", "Microsoft Yahei", "Comic Sans MS", "Impact", "Segoe Script", "STHeiti", "Apple LiGothic", "MingLiU", "Ubuntu", "Segoe UI", 
    "DejaVu Sans", "DejaVu Sans Mono", "Noto Sans CJK", "Arial Black", "Gadget", "cursive", "Charcoal", "Lucida Sans Unicode", "Lucida Grande", "Geneva"]
SerifFonts = ["Baskerville", "Times New Roman", "Times", "華康儷金黑 Std", "華康儷宋 Std",  "DFLiKingHeiStd-W8", "DFLiSongStd-W5", "DejaVu Serif", "SimSun",
    "Hiragino Mincho Pro", "LiSong Pro", "新細明體", "serif", "Georgia", "STSong", "FangSong", "KaiTi", "STKaiti", "Courier", "Courier New", "monospace",
    "Palatino Linotype", "Book Antiqua", "Palatino", "Lucida Console", "Monaco"]
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
        ), Schemes_colorbrewer)
Schemes_seaborn = filter(s -> occursin("seaborn", colorschemes[s].category), collect(keys(colorschemes)))
Schemes_tableau = filter(s -> occursin("tableau", colorschemes[s].category), collect(keys(colorschemes)))
Schemes_cvd = filter(s -> occursin("cvd", colorschemes[s].category), collect(keys(colorschemes)))
Schemes_gnuplot = filter(s -> occursin("gnuplot", colorschemes[s].category), collect(keys(colorschemes)))
Schemes_MetBrewer = filter(s -> occursin("MetBrewer", colorschemes[s].category), collect(keys(colorschemes)))
Schemes_general = [:bluegreenyellow, :cmyk, :darkrainbow, :deepsea, :dracula, :fall, :rainbow, :turbo]
Schemes = [Schemes_colorbrewer; Schemes_seaborn; Schemes_tableau; Schemes_cvd; Schemes_gnuplot; Schemes_MetBrewer; Schemes_general]

function displayschemes()
    for scheme in Schemes
        display(scheme)
        colors = Render.colorschemes[scheme].colors
        display(colors)
    end
end
function randomscheme(wordsnum=100)
    if rand() < 0.95
        scheme = rand(Schemes)
        C = Render.colorschemes[scheme]
        if length(C) < 64 && rand() < 0.95
            colors = randsubseq(C.colors, rand())
            isempty(colors) && (colors = C.colors)
            print("color scheme: ", repr(scheme), ", random size: ", length(colors))
        else
            if rand() < 0.3
                a, b = minmax(rand(1:lastindex(C)), rand(1:lastindex(C)))
                b - a < length(C)÷10 && (a = 1; b = lastindex(C))
                rg = range(a, b; step=1)
                print("color scheme: ", repr(scheme), ", random range: $a:$b")
                rand() > 0.5 && (rg = reverse(rg); print(", reversed"))
                colors = C.colors[rg]
            else
                a, b = round.(minmax(rand(), rand()), digits=3)
                b - a < 0.1 && (a = 0.; b = 1.)
                rg = range(a, b, length=max(2, wordsnum))
                print("color scheme: ", repr(scheme), ", random range: $a:$b")
                rand() > 0.5 && (rg = reverse(rg); print(", reversed"))
                colors = get.(Ref(C), rg)
            end
        end
        if rand() > 0.5
            colors = tuple(colors...)
            print(", shuffled")
        end
        print("\n")
    else
        colors = rand((0, 1, 0, 1, 0, 1, rand(), (rand(), rand())))
        @show colors
    end
    colors
end
function randomwh(sz::Number=800)
    s = sz * sz
    ratio = (9/16 + rand()*7/16)
    ratio > 0.9 && (ratio = 1.0)
    h = round(Int, sqrt(s * ratio))
    w = round(Int, h / ratio)
    w, h
end
randomwh(sz::Tuple) = sz
randomwh(arg...) = arg
equalwh(sz::Number=800) = sz, sz
equalwh(sz::Tuple) = sz
equalwh(arg...) = arg
function randommask(args...; maskshape=:rand, kargs...)
    rd = Dict(squircle => 0.4, box => 0.6, ellipse => 0.8, ngon => 0.9, star => 1)
    ran = get(rd, maskshape, rand())
    if ran <= 0.4
        return randomsquircle(randomwh(args...)...; kargs...)
    elseif ran <= 0.6
        return randombox(randomwh(args...)...; kargs...)
    elseif ran <= 0.8
        return randomellipse(randomwh(args...)...; kargs...)
    elseif ran <= 0.9
        return randomngon(equalwh(args...)...; kargs...)
    else
        return randomstar(equalwh(args...)...; kargs...)
    end
end
function showcallshape(args...; kargs...)
    ags = [string(args[1]), repr.(args[2:end])..., ("$k=$(repr(v))" for (k, v) in kargs)...]
    println("shape(", join(ags, ", "), ")")
end
function randombox(w, h; cornerradius=:rand, keeparea=false, kargs...)
    if cornerradius == :rand
        r = rand() * 0.5 - 0.05 # up to 0.45
        r < 0. && (r = 0.) # 10% for 0.
        r = round(Int, h * r)
    else
        r = cornerradius
    end
    sc = keeparea ? sqrt(w*h/box_area(w, h, cornerradius=r)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc); r = round(Int, r*sc)
    showcallshape(box, w, h; cornerradius=r, kargs...)
    return shape(box, w, h; cornerradius=r, kargs...)
end
function randomsquircle(w, h; rt=:rand, keeparea=false, kargs...)
    if rt == :rand
        if rand() < 0.8
            rt = rand()
        else
            ran = rand()
            if ran < 0.5
                rt = 2
            else
                rt = 1 + 1.5rand()
            end
        end
        rt = round(rt, digits=3)
    end
    sc = keeparea ? sqrt(w*h/squircle_area(w, h, rt=rt)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    showcallshape(squircle, w, h, rt=rt; kargs...)
    return shape(squircle, w, h, rt=rt; kargs...)
end
function randomellipse(w, h; keeparea=false, kargs...)
    sc = keeparea ? sqrt(w*h/ellipse_area(w, h)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    showcallshape(ellipse, w, h; kargs...)
    return shape(ellipse, w, h; kargs...)
end
function randomorientation(n)
    if n == 3
        ori = rand((0, π/2, π/3))
    elseif n % 2 == 0
        ori = rand((0, π/n))
    else
        ori = 0
    end
    return ori
end
function randomngon(w, h; npoints=:rand, orientation=:rand, keeparea=false, kargs...)
    npoints == :rand && (npoints = rand(3:12))
    orientation == :rand && (orientation = randomorientation(npoints))
    sc = keeparea ? sqrt(w*h/ngon_area(w, h, npoints=npoints)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    showcallshape(ngon, w, h; npoints=npoints, orientation=orientation, kargs...)
    return shape(ngon, w, h; npoints=npoints, orientation=orientation, kargs...)
end
function randomstar(w, h; npoints=:rand, starratio=:rand, orientation=:rand, keeparea=false, kargs...)
    npoints == :rand && (npoints = rand(5:12))
    orientation == :rand && (orientation = randomorientation(npoints))
    if starratio == :rand
        starratio = cos(π/npoints) * (0.7 + 0.25rand())
        starratio = round(starratio, digits=3)
    end
    sc = keeparea ? sqrt(w*h/star_area(w, h, npoints=npoints, starratio=starratio)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    showcallshape(star, w, h; npoints=npoints, starratio=starratio, orientation=orientation, kargs...)
    return shape(star, w, h; npoints=npoints, starratio=starratio, orientation=orientation, kargs...)
end
function randomangles()
    θ = rand((30, 45, 60))
    st = rand((5, 10, 15))
    angles = rand((0, (0, 90), (0, 45, 90), (0, 45, 90, -45), -90:90, -90:st:90,
        -5:5, (0, θ, -θ), (θ, -θ), -θ:θ, -θ:st:θ))
    if length(angles) > 1 && rand() > 0.5
        0 in angles && maximum(abs, angles)>10 && (angles = angles .- first(angles))
        if angles isa Tuple
            angles = collect(angles)
            println("angles = ", angles)
        else
            println("angles = collect($angles)")
            angles = collect(angles)
        end
    else
        rand() > 0.7 && (angles =  -1 .* angles)
        println("angles = ", angles)
    end
    angles
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
            middle = (g[i] + g[i + 1]) / 2
            th1 = clamp(max(g[i] + 0.15, middle - rand(0:0.001:0.05)), 0, middle)
            th2 = clamp(min(g[i + 1] - 0.15, middle + rand(0:0.001:0.05)), middle, 1)
            default = middle
        elseif sum(g) / length(g) < 0.7 && (m + M) / 2 < 0.7 && !(m > 2(1 - M))# 明亮
            th1 = clamp(max(M + 0.15, rand(0.85:0.001:1.0)), 0, 1)
            th2 = clamp(th1 + 0.1, 0, 1)
            default = 1.0
        else    # 黑暗
            th2 = clamp(min(m - 0.15, rand(0.0:0.001:0.3)), 0, 1) # 对深色不敏感，+0.15
            th1 = clamp(th2 - 0.15, 0, 1)
            default = 0.0
        end
        maskcolor = rand((default, 
        (round(rand(th1:0.001:th2), digits=3),
        round(rand(th1:0.001:th2), digits=3),
        round(rand(th1:0.001:th2), digits=3))))
        # @show maskcolor
        return maskcolor
    catch e
        @show e
    @show "colors sum failed", colors
        return "white"
    end
end
function randomlinecolor(colors)
    if rand() < 0.8
        linecolor = rand((colors[1], colors[1], rand(colors)))
    else
        linecolor = (
            round(rand(), digits=3), 
            round(rand(), digits=3), 
            round(rand(), digits=3), 
            min(1., round(0.5 + rand()/2, digits=3)))
    end
    linecolor
end
randomoutline() = rand((0, 0, 0, rand(2:10)))
function randomfonts()
    if rand() < 0.8
        fonts = rand(AvailableFonts)
    else
        fonts = rand(AvailableFonts, 2 + floor(Int, 2randexp()))
        rand() > 0.5 && (fonts = tuple(fonts...))
    end
    @show fonts
    fonts
end
