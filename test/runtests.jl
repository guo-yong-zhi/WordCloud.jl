using WordCloud
using Test
using Random

include("test_qtree.jl")
include("test_lru.jl")
@testset "textprocessing.jl" begin
    text = "So dim, so dark, So dense, so dull, So damp, so dank, So dead! The weather, now warm, now cold, Makes it harder Than ever to forget!"
    c = WordCloud.TextProcessing.countwords(text)
    @test c["so"] == 3
    words,weights = WordCloud.TextProcessing.processtext(c)
    @test !("So" in words)
end

@testset "WordCloud.jl" begin
    # @show pwd()
    words = [Random.randstring(rand(1:8)) for i in 1:rand(100:1000)]
    weights = randexp(length(words)) .* 1000 .+ randexp(length(words)) .* 200 .+ rand(20:100, length(words));
    wc = wordcloud(words, weights, fillingrate=0.6)
    paint(wc)
    generate!(wc)
    paint(wc, "test.jpg", background=outline(wc.mask, color=(1, 0, 0.2, 0.7), linewidth=2))
    paint(wc, "test.svg")
    @test isempty(WordCloud.outofbounds(wc.maskqtree, wc.qtrees))

    clq = WordCloud.QTree.listcollision_qtree(wc.qtrees, wc.maskqtree)
    cln = WordCloud.QTree.listcollision_native(wc.qtrees, wc.maskqtree)
    @test Set(first.(clq)) == Set(first.(cln))

    wordcloud(["singleword"=>12], maskimg=shape(box, 200, 150, 40, color=0.15), fillingrate=0.6, run=generate!) #singleword & Pair
    wordcloud(processtext("giving a single word is ok. giving several words is ok too"), 
            maskimg=shape(box, 20, 15, 0, color=0.15), fillingrate=0.5, transparentcolor=(1,1,1,0)) #String & small mask
    placement!(wc)
    wc = wordcloud(
            processtext(open("../res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"], maxnum=300), 
            mask = loadmask("../res/alice_mask.png", color="#faeef8", backgroundcolor=0.97),
            colors = (WordCloud.colorschemes[:Set1_5].colors..., ),
            angles = (0, 90),
            fillingrate = 0.6);
    rescale!(wc, 1.23)
    pin(wc, ["little", "know"]) do 
        @test length(wc.words)==298
        setpositions!(wc, "time", (0,0), type=setcenter!)
    end
    @test WordCloud.QTree.kernelsize(wc.qtrees[WordCloud.index(wc, "time")]) == size(getimages(wc, "time"))
    @test .-reverse(size(getimages(wc, "time"))) .÷ 2 == getpositions(wc, ["time", getwords(wc, 9)])[1]
    w = getweights(wc, getwords(wc, [1,2]))
    setwords!(wc, [1,2], ["zz","yy"])
    @test getweights(wc, "zz") == w[1]
end

