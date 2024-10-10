using Random
import Fontconfig: list, Pattern, format
using StopWords

const FONT_NAMES::Dict{String, Vector{String}} = Dict{String, Vector{String}}()
const FONT_WEIGHTS::Vector{String} = ["", " Regular", " Normal", " Medium", " Bold", " Light"]

function listfonts(lang="")
    if !isempty(lang)
        ps = list(Pattern(lang=lang))
    else
        ps = list(Pattern())
    end
    return [format(p, "%{family[0]}") for p in ps]
end
function reverse_dict(d)
    rd = Dict{String, Vector{String}}()
    for (k, v) in d
        get!(rd, v) do
            String[]
        end
        push!(rd[v], k)
    end
    return rd
end
const _ID_PART1 = reverse_dict(StopWords.part1_id)
const _MID_IID = reverse_dict(StopWords.iid_mid)
function expandlangcode(c)
    c in StopWords.id_all || (c = get(StopWords.name_id, c, c))
    c in StopWords.id_all || (c = get(StopWords.name_id, titlecase(c), c))
    cs = []
    for c1 in Iterators.flatten((get(_MID_IID, c, []), [c]))
        for c2 in Iterators.flatten((get(_ID_PART1, c1, []), [c1]))
            push!(cs, c2)
        end
    end
    cs
end
function fontsof(lang)
    union((listfonts(l) for l in expandlangcode(lang))...)
end
function getfontcandidates(lang)
    lang = StopWords.normcode(String(lang))
    if haskey(FONT_NAMES, lang)
        return FONT_NAMES[lang]
    else
        fs = fontsof(lang)
        push!(fs, "")
        FONT_NAMES[lang] = fs
        return fs
    end
end

"""
    setfontcandidates!(lang::AbstractString, str_list)  

Customize font candidates for language `lang`
"""
function setfontcandidates!(lang::AbstractString, str_list)
    FONT_NAMES[StopWords.normcode(String(lang))] = str_list
end

function getcolorschemes()
    schemes_colorbrewer = filter(s -> occursin("colorbrewer", colorschemes[s].category), collect(keys(colorschemes)))
    schemes_colorbrewer =  filter(s -> (occursin("Accent", String(s)) 
            || occursin("Dark", String(s))
            || occursin("Paired", String(s))
            || occursin("Pastel", String(s))
            || occursin("Set", String(s))
            || occursin("Spectral", String(s))
            ), schemes_colorbrewer)
    schemes_seaborn = filter(s -> occursin("seaborn", colorschemes[s].category), collect(keys(colorschemes)))
    schemes_tableau = filter(s -> occursin("tableau", colorschemes[s].category), collect(keys(colorschemes)))
    schemes_cvd = filter(s -> occursin("cvd", colorschemes[s].category), collect(keys(colorschemes)))
    schemes_gnuplot = filter(s -> occursin("gnuplot", colorschemes[s].category), collect(keys(colorschemes)))
    schemes_MetBrewer = filter(s -> occursin("MetBrewer", colorschemes[s].category), collect(keys(colorschemes)))
    schemes_general = [:bluegreenyellow, :cmyk, :darkrainbow, :deepsea, :dracula, :fall, :rainbow, :turbo]
    [schemes_colorbrewer; schemes_seaborn; schemes_tableau; schemes_cvd; schemes_gnuplot; schemes_MetBrewer; schemes_general]
end
const COLOR_SCHEMES = getcolorschemes()
function displayschemes()
    for scheme in COLOR_SCHEMES
        display(scheme)
        colors = Render.colorschemes[scheme].colors
        display(colors)
    end
end
function gradient(weights_or_num; colorscheme=rand(COLOR_SCHEMES), section=(0,1))
    @assert length(section) == 2
    a,b = section
    @assert a <= b
    C = Render.colorschemes[colorscheme]
    if weights_or_num isa Number
        inds = range(a, b, length=max(2, weights_or_num))
    else
        weights = float.(weights_or_num)
        length(weights) < 2 && (weights = [1.,1.])
        weights[1] = 0.
        cumsum!(weights, weights)
        weights[end] != 0. && (weights ./= weights[end])
        weights .*= b - a
        weights .+= a
        inds = weights
    end
    return get.(Ref(C), inds)
end
function randomcolorscheme(weights_or_num=100)
    if rand() < 0.95
        scheme = rand(COLOR_SCHEMES)
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
                print("color scheme: ", repr(scheme))
                if (!(weights_or_num isa Number)) && rand() < 0.3
                    weights_or_num = length(weights_or_num)
                end
                if weights_or_num isa Number
                    print(", index based gradient")
                else
                    print(", weight based gradient")
                end
                a, b = round.(minmax(rand(), rand()), digits=3)
                rand() < 0.2 && (a = 0.; b = 1.)
                print(", random section: $a:$b")
                colors = gradient(weights_or_num; colorscheme=scheme, section=(a,b))
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
# function randomfilteredcolorscheme(args...; filter=colors->Gray(parsecolor(randommaskcolor(colors)))>0.5, maxiter=100)
#     for _ in 1:maxiter
#         colors = randomcolorscheme(args...)
#         filter(colors) && return colors
#     end
#     @warn "randomfilteredcolorscheme reach the `maxiter`."
#     return colors
# end
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
function randommask(args...; maskshape=:rand, returnkwargs=false, kargs...)
    rd = Dict(squircle => 0.4, box => 0.6, ellipse => 0.8, 
    ngon => 0.85, star => 0.9, bezingon => 0.92, bezistar => 1)
    if maskshape ∉ keys(rd) && maskshape isa Function
        s, k = maskshape(args...; kargs...), kargs
    else
        ran = get(rd, maskshape, rand())
        if ran <= 0.4
            s, k = randomsquircle(randomwh(args...)...; kargs...)
        elseif ran <= 0.6
            s, k = randombox(randomwh(args...)...; kargs...)
        elseif ran <= 0.8
            s, k = randomellipse(randomwh(args...)...; kargs...)
        elseif ran <= 0.85
            s, k = randomngon(equalwh(args...)...; kargs...)
        elseif ran <= 0.9
            s, k = randomstar(equalwh(args...)...; kargs...)
        elseif ran <= 0.92
            s, k = randombezingon(equalwh(args...)...; kargs...)
        else
            s, k = randombezistar(equalwh(args...)...; kargs...)
        end
    end
    return returnkwargs ? (s, k) : s
end
function callshape(args...; kargs...)
    ags = [string(args[1]), repr.(args[2:end])..., ("$k=$(repr(v))" for (k, v) in kargs)...]
    println("shape(", join(ags, ", "), ")")
    shape(args...; kargs...), kargs
end
function randombox(w, h; cornerradius=:rand, preservevolume=false, kargs...)
    if cornerradius == :rand
        r = rand() * 0.5 - 0.05 # up to 0.45
        r < 0. && (r = 0.) # 10% for 0.
        r = round(Int, h * r)
    else
        r = cornerradius
    end
    sc = preservevolume ? sqrt(w*h/box_area(w, h, cornerradius=r)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc); r = round(Int, r*sc)
    return callshape(box, w, h; cornerradius=r, kargs...)
end
function randomsquircle(w, h; rt=:rand, preservevolume=false, kargs...)
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
    sc = preservevolume ? sqrt(w*h/squircle_area(w, h, rt=rt)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    return callshape(squircle, w, h, rt=rt; kargs...)
end
function randomellipse(w, h; preservevolume=false, kargs...)
    sc = preservevolume ? sqrt(w*h/ellipse_area(w, h)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    return callshape(ellipse, w, h; kargs...)
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
function randomngon(w, h; npoints=:rand, orientation=:rand, preservevolume=false, kargs...)
    npoints == :rand && (npoints = rand(3:12))
    orientation == :rand && (orientation = randomorientation(npoints))
    sc = preservevolume ? sqrt(w*h/ngon_area(w, h, npoints=npoints)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    return callshape(ngon, w, h; npoints=npoints, orientation=orientation, kargs...)
end
function randomstar(w, h; npoints=:rand, starratio=:rand, orientation=:rand, preservevolume=false, kargs...)
    npoints == :rand && (npoints = rand(5:12))
    orientation == :rand && (orientation = randomorientation(npoints))
    if starratio == :rand
        starratio = cos(π/npoints) * (0.7 + 0.25rand())
        starratio = round(starratio, digits=3)
    end
    sc = preservevolume ? sqrt(w*h/star_area(w, h, npoints=npoints, starratio=starratio)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    return callshape(star, w, h; npoints=npoints, starratio=starratio, orientation=orientation, kargs...)
end
function randombezingon(w, h; npoints=:rand, orientation=:rand, preservevolume=false, kargs...)
    npoints == :rand && (npoints = rand((3,3,4)))
    orientation == :rand && (orientation = randomorientation(npoints))
    sc = preservevolume ? sqrt(w*h/ngon_area(w, h, npoints=npoints)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    return callshape(bezingon, w, h; npoints=npoints, orientation=orientation, kargs...)
end
function randombezistar(w, h; npoints=:rand, starratio=:rand, orientation=:rand, preservevolume=false, kargs...)
    npoints == :rand && (npoints = rand(3:12))
    orientation == :rand && (orientation = randomorientation(npoints))
    if starratio == :rand
        starratio = cos(π/npoints) * (0.7 + 0.25rand())
        starratio = round(starratio, digits=3)
    end
    sc = preservevolume ? sqrt(w*h/star_area(w, h, npoints=npoints, starratio=starratio)) : 1
    w = round(Int, w*sc); h = round(Int, h*sc)
    return callshape(bezistar, w, h; npoints=npoints, starratio=starratio, orientation=orientation, kargs...)
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
function randomfonts(lang="")
    if rand() < 0.8
        fonts = rand(getfontcandidates(lang))
        fonts = fonts * rand(FONT_WEIGHTS)
    else
        fonts = rand(getfontcandidates(lang), 2 + floor(Int, 2randexp()))
        fonts = [f * rand(FONT_WEIGHTS) for f in fonts]
        rand() > 0.5 && (fonts = tuple(fonts...))
    end
    @show fonts
    fonts
end
