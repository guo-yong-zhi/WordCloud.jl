using WordCloud
using Test
using Random

include("test_render.jl")
include("test_textprocessing.jl")


@testset "WordCloud.jl" begin
    # @show pwd()
    # overall test
    wc = runexample(:random)
    @test getstate(wc) == :generate!
    @test isempty(WordCloud.outofbounds(wc.maskqtree, wc.qtrees))
    paint(wc)
    paint(wc, "test.jpg", background=outline(wc.mask, color=(1, 0, 0.2, 0.7), linewidth=2), ratio=0.5)
    paint(wc, "test.svg", background=WordCloud.tobitmap(wc.mask))
    paint(wc, "test.svg")
    paintsvgcloud("holly bible", "test.svg", quiet=false)
    paintcloud("holly bible", angles=(0, 90), ratio=0.5)
    show(wc)
    @test getparameter(wc, :volume) == WordCloud.occupancy(WordCloud.QTrees.kernel(wc.maskqtree[1]), WordCloud.QTrees.FULL)
    # animation
    setpositions!(wc, :, (-1000,-1000))
    @record "animation1-test" filter=i->i%(2^(i÷100+3))==0 overwrite=true layout!(wc, style=:gathering)
    @record outputdir="animation2-test" filter=i->i%10==0 overwrite=true generate!(wc, 100)

    # layout!
    layout!(wc, style=:gathering)
    words = ["." for i in 1:500]
    weights = [1 for i in 1:length(words)]
    @test_throws ErrorException begin # no room
        wc = wordcloud(words, weights, mask=ellipse, masksize=(5, 5), backgroundsize=(10, 10), density=1000, angles=0, maxfontsize=5)
        layout!(wc)
    end

    # wordcloud factory
    wc = wordcloud(["singleword" => 12], mask=star, masksize=100, density=0.55, state=generate!) # singleword & Pair
    wc = wordcloud([("loooooooooongword", 42)], mask=shape(box, 200, 150, cornerradius=40, color=0.15), maxfontsize=80, density=0.55)
    wc = wordcloud([("loooooooooongword", 42)], mask=shape(box, 200, 150, cornerradius=40, color=0.15), density=0.55)

    wc = wordcloud("giving a single word is ok. giving several words is ok too", 
            mask=shape(squircle, 200, 150, color=0.15, rt=2.2), density=0.45, transparent=(1, 1, 1, 0)) # String & small mask
    @test_throws AssertionError wordcloud(["1"], [2,3], density=0.1) |> generate! # length unmatch
    @test_throws AssertionError wordcloud(String[], Int[], density=0.1) |> generate! # empty inputs
    wc2 = wordcloud("a new word cloud"; getscheme(wc)...)
    @test wc.mask === wc2.mask
    @test wc.svgmask === wc2.svgmask
    @test getscheme(wc) == getscheme(wc2)
    
    ##############no mask file
    wc = wordcloud(["test"], [1], maskcolor="green", outline=5)
    @test WordCloud.alpha(ascolor(getbackgroundcolor(wc))) == 0
    wc = wordcloud(["test"], [1], backgroundcolor="blue", outline=5)
    @test ascolor(getmaskcolor(wc)) == ascolor("blue")
    wc = wordcloud(["test"], [1], maskcolor="green")
    @test getparameter(wc, :outline) == 0
    wc = wordcloud(["test"], [1], backgroundcolor="blue")
    @test getparameter(wc, :outline) == 0
    wc = wordcloud(["test"], [1], masksize=(100, 100), outline=0)
    @test all(size(wc.mask) .> 105)
    wc = wordcloud(["test"], [1], masksize=(100, 100), outline=30, padding=30)
    @test all(size(wc.mask) .> 200)
    ##############svg mask
    svgfile = "test.svg"
    wordcloud(["test"], [1], colors="#DE2910", mask=svgfile, maskcolor=:original)
    wordcloud(["test"], [1], mask=open(svgfile))
    wc = wordcloud(["test"], [1], mask=svgfile, backgroundcolor=0) # warning#can't edit the svg to remove original backgroundcolor, 
    # so it's only work when the svgfile has a transparent background
    wc2 = wordcloud(["test"], [1], mask=open(svgfile), padding=20)
    wc3 = wordcloud(["test"], [1], mask=open(svgfile), padding=(10, -10))
    @test all(size(wc2.mask) .> size(wc.mask))
    @test all(size(wc2.svgmask) .> size(wc.svgmask))
    @test (size(wc3.svgmask) .> size(wc.svgmask)) == (true, false)
    wordcloud(["test"], [1], mask=open(svgfile), padding=10, backgroundcolor="red")# warning#
    ##############png mask
    pngfile = pkgdir(WordCloud) * "/res/heart_mask.png"
    wordcloud(["test"], [1], colors="#DE2910", mask=pngfile, maskcolor=:original)
    wc = wordcloud(["test"], [1], mask=open(pngfile), maskcolor="yellow", ratio=0.5)
    @test getbackgroundcolor(wc) in WordCloud.DEFAULTSYMBOLS
    wc = wordcloud(["test"], [1], mask=pngfile, maskcolor="green", outline=5)
    @test getbackgroundcolor(wc) in WordCloud.DEFAULTSYMBOLS
    @test getparameter(wc, :outline) == 5
    wc = wordcloud(["test"], [1], colors="#DE2910", mask=pngfile, backgroundcolor=0)
    @test getmaskcolor(wc) == getbackgroundcolor(wc)
    wc = wordcloud(["test"], [1], colors="#DE2910", mask=pngfile, maskcolor=1, backgroundcolor=0)
    @test ascolor(getmaskcolor(wc)) == ascolor(1)
    @test ascolor(getbackgroundcolor(wc)) == ascolor(0)
    wordcloud(["test"], [1], mask=pngfile, backgroundcolor=:maskcolor) # backgroundcolor=maskcolor=:default, didn't change anything
    wordcloud(["test"], [1], mask=pngfile, maskcolor="#faeef8", backgroundcolor=:maskcolor)
    wordcloud(["test"], [1], mask=pngfile, maskcolor="#faeef8", backgroundcolor=:maskcolor, outline=3)
    wordcloud(["test"], [1], mask=pngfile, backgroundcolor=:maskcolor, outline=3, smoothness=0.7)
    wc = wordcloud(["test"], [1], mask=open(pngfile), backgroundcolor=:auto)
    @test getmaskcolor(wc) == getbackgroundcolor(wc)
    wc = wordcloud(["test"], [1], mask=open(pngfile), maskcolor=:auto, masksize=:default)
    @test getbackgroundcolor(wc) == :default
    @test size(wc.mask) == (572, 640)
    wc = wordcloud(["test"], [1], mask=pngfile, masksize=(200, 200))
    @test size(wc.mask) == (200, 200)
    wc = wordcloud(["test"], [1], mask=pngfile, ratio=0.3, masksize=:default)
    @test all(size(wc.mask) .< 200)
    wc2 = wordcloud(["test"], [1], mask=pngfile, outline=50, ratio=0.3, masksize=:default)
    @test all(size(wc2.mask) .> size(wc.mask))
    wc3 = wordcloud(["test"], [1], mask=pngfile, padding=(-50, 50), masksize=:default)
    @test (size(wc3.mask) .> (572, 640)) == (false, true)
    wc = wordcloud(["test"], [1], mask=pngfile, padding=100, masksize=:default)
    @test all(size(wc.mask) .> 700)
    # get & set & id
    words, weights = processtext(open("../res/alice.txt"), stopwords_extra=["said"], maxnum=300)
    wc = wordcloud(
            words, weights, 
            mask="../res/alice_mask.png", maskcolor="#faeef8", backgroundcolor=0.97,
            colors=(WordCloud.colorschemes[:Set1_5].colors...,),
            angles=(0, 90));
    rescale!(wc, 1.23)
    @test getwords(wc, WordCloud.ID(2)) == words[2]
    pin(wc, ["head", "voice"]) do 
        @test length(wc) == 298
        setpositions!(wc, 1, (2, 2))
        setpositions!(wc, [1, "Alice", "eye"], (-1, -2))
        setpositions!(wc, [1, "Alice", "eye"], [(10, 10),(10, 20),(21, 2)])
        setpositions!(wc, "time", (0, 0), mode=setcenter!)
        setfontsizes!(wc, [WordCloud.ID(66), "Alice", "eye"], [9, 8, 7.6])
        @test getwords(wc, WordCloud.ID(12:14)) == words[12:14]
    end
    @test getfontsizes(wc, [WordCloud.ID(66), "Alice", "eye"]) == [9, 8, 7.6]
    @test getwords(wc, WordCloud.ID([112,1])) == words[[112,1]]
    @test getpositions(wc, [1, "Alice", "eye"])[3] == (21, 2)
    @test WordCloud.QTrees.kernelsize(wc.qtrees[WordCloud.index(wc, "time")]) == size(getimages(wc, "time"))
    @test .-reverse(size(getimages(wc, "time"))) .÷ 2 == getpositions(wc, ["time", getwords(wc, 9)])[1]
    w = getweights(wc, getwords(wc, [1,2]))
    setwords!(wc, [1,2], ["zz","yy"])
    @test getweights(wc, "zz") == w[1]
    configsvgimages!(wc, wrappers=["a"=>("href"=>"https://www.google.com/search?q=$w") for w in getwords(wc)])
    configsvgimages!(wc, ["zz","yy"], children=("animate"=>["attributeName" => "opacity", "to"=>"0.5", "dur"=>"6s"], "title"=>"tooltip"))
    svgsource = string(paintsvg(wc))
    @test count("www.google.com", svgsource) == length(wc)
    @test count("attributeName", svgsource) == 2
    setimages!(wc, [1,2], wc.imgs[[4,5]])
    setimages!(wc, 1, wc.imgs[[4,5]])
    setimages!(wc, 1, wc.imgs[4])
    setsvgimages!(wc, 1, wc.svgs[6])
    setsvgimages!(wc, 6, wc.svgs[6]) # the results of setsvgimages! and initialize! may not be identical
    @test wc.imgs[1] == wc.imgs[6]

    for s = [:main, :reset, :average, :clipping, :blending, :reset]
        recolor!(wc, style=s)
    end

    # strategy
    imgs = wc.imgs
    @test all(WordCloud.dilatedoccupancy.(imgs, maximum.(size.(imgs))) .== WordCloud.boxoccupancy.(imgs))
    @test WordCloud.occupancy(imgs) == WordCloud.dilatedoccupancy(imgs, 0)

    # utils
    wc.qtrees[1][1] |> imageof
    bg = getmask(wc)
    istrans = c -> maximum(c[1:3]) < 128
    mask = WordCloud.imagemask(bg, istrans)
    s = showmask(bg, mask)
    @test all(bg[mask] .== s[mask])
    @test all(bg[.!mask] .!= s[.!mask])

    # language
    l1 = length(wordcloud("It's easy to generate word clouds"))
    for lang in ["en", "eng", "English"]
        l2 = length(wordcloud("It's easy to generate word clouds", language=lang))
        @test l1 == l2
    end

    # overall
    wordcloud(["中文", "需要", "提前", "分词"], fonts="") |> generate!
    wordcloud(["the"=>1.0, "to"=>0.51, "and"=>0.50,
              "of"=>0.47, "a"=>0.44, "in"=>0.33]) |> generate!
    wordcloud("It's easy to generate word clouds", maxnum=10) |> generate!
    text = "天地玄黄 宇宙洪荒 The universe is vast and boundless. a b c d e f g h i j k l m n o p q"
    wordcloud(text, language="zh", avgfontsize=50, density=0.4, mask=box, backgroundcolor=:maskcolor, angles=0) |> generate!
    # font
    WordCloud.setfontcandidates!("zh", ["CJK"])
    @test WordCloud.getfontcandidates("zh") == WordCloud.getfontcandidates("zho") == ["CJK"]

    @show keys(WordCloud.FONT_NAMES)
end
