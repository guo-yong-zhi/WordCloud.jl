using WordCloud
using Test
using Random

include("test_render.jl")
include("test_textprocessing.jl")


@testset "WordCloud.jl" begin
    #@show pwd()
    # overall test
    wc = runexample(:random)
    @test getstate(wc) == :generate!
    @test isempty(WordCloud.outofbounds(wc.maskqtree, wc.qtrees))
    paint(wc)
    paint(wc, "test.jpg", background=outline(wc.mask, color=(1, 0, 0.2, 0.7), linewidth=2), ratio=0.5)
    paint(wc, "test.svg")
    @test getparameter(wc, :maskoccupying) == WordCloud.occupying(WordCloud.QTree.kernel(wc.maskqtree[1]), WordCloud.QTree.FULL)
    @test getparameter(wc, :maskoccupying) == WordCloud.occupying(wc.mask .!= wc.mask[1])
    
    # placement!
    placement!(wc, style=:gathering)
    words = ["." for i in 1:500]
    weights = [1 for i in 1:length(words)]
    @test_throws ErrorException begin #no room
        wc = wordcloud(words, weights, maskshape=ellipse, masksize=(5,5), backgroundsize=(10,10), density=1000, angles=0)
        placement!(wc)
    end

    # wordcloud factory
    wc = wordcloud(["singleword"=>12], mask=shape(box, 200, 150, 40, color=0.15), density=0.45, run=generate!) #singleword & Pair
    wc = wordcloud(processtext("giving a single word is ok. giving several words is ok too"), 
            mask=shape(squircle, 200, 150, color=0.15, rt=2.2), density=0.45, transparentcolor=(1,1,1,0)) #String & small mask
    @test_throws AssertionError wordcloud(["1"],[2,3], density=0.1)|>generate! #length unmatch
    @test_throws AssertionError wordcloud(String[],Int[], density=0.1)|>generate! #empty inputs
    @test_throws AssertionError wordcloud([" ", " "],[2.0, 1], density=0.1) #blank words

    # get&set
    wc = wordcloud(
            processtext(open("../res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"], maxnum=300), 
            mask = loadmask("../res/alice_mask.png", color="#faeef8", backgroundcolor=0.97),
            colors = (WordCloud.colorschemes[:Set1_5].colors..., ),
            angles = (0, 90));
    rescale!(wc, 1.23)
    pin(wc, ["little", "know"]) do 
        @test length(wc.words)==298
        setpositions!(wc, 1, (2,2))
        setpositions!(wc, [1, "Alice", "one"], (-1, -2))
        setpositions!(wc, [1, "Alice", "one"], [(10,10),(10,20),(21,2)])
        setpositions!(wc, "time", (0,0), type=setcenter!)
    end
    @test getpositions(wc, [1, "Alice", "one"])[3] == (21,2)
    @test WordCloud.QTree.kernelsize(wc.qtrees[WordCloud.index(wc, "time")]) == size(getimages(wc, "time"))
    @test .-reverse(size(getimages(wc, "time"))) .÷ 2 == getpositions(wc, ["time", getwords(wc, 9)])[1]
    w = getweights(wc, getwords(wc, [1,2]))
    setwords!(wc, [1,2], ["zz","yy"])
    @test getweights(wc, "zz") == w[1]
    setimages!(wc, [1,2], wc.imgs[[4,5]])
    setimages!(wc, 1, wc.imgs[[4,5]])
    setimages!(wc, 1, wc.imgs[4])
    setsvgimages!(wc, 1, wc.svgs[6])
    setsvgimages!(wc, 6, wc.svgs[6]) #the results of setsvgimages! and initimage! may not be identical
    @test wc.imgs[1] == wc.imgs[6]

    for s = [:reset, :average, :clipping, :blending, :reset]
        recolor!(wc, style=s)
    end

    #utils
    wc.qtrees[1][1]|>imageof
    bg = getmask(wc)
    istrans = c->maximum(c[1:3])<128
    mask = WordCloud.backgroundmask(bg, istrans)
    s = showmask(bg, mask)
    @test all(bg[mask] .== s[mask])
    @test all(bg[.!mask] .!= s[.!mask])
end

