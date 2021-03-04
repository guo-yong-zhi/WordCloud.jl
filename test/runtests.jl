using WordCloud
using Test
using Random

include("test_qtree.jl")
include("test_trainer.jl")
include("test_render.jl")
include("test_textprocessing.jl")


@testset "WordCloud.jl" begin
    # @show pwd()
    words = [Random.randstring(rand(1:8)) for i in 1:rand(100:1000)]
    weights = randexp(length(words)) .* 1000 .+ randexp(length(words)) .* 200 .+ rand(20:100, length(words));
    wc = wordcloud(words, weights, density=0.45)
    paint(wc)
    generate!(wc)
    placement!(wc)
    generate!(wc, 100, optimiser=(t, Δ)->Δ./4, patient=5, retry=5)
    paint(wc, "test.jpg", background=outline(wc.mask, color=(1, 0, 0.2, 0.7), linewidth=2))
    paint(wc, "test.svg")
    @test isempty(WordCloud.outofbounds(wc.maskqtree, wc.qtrees))

    wordcloud(["singleword"=>12], maskimg=shape(box, 200, 150, 40, color=0.15), density=0.45, run=generate!) #singleword & Pair
    wordcloud(processtext("giving a single word is ok. giving several words is ok too"), 
            maskimg=shape(box, 20, 15, 0, color=0.15), density=0.45, transparentcolor=(1,1,1,0)) #String & small mask
    placement!(wc, style=:gathering)

    wc = runexample(:random)
    @test getstate(wc) == :generate!
    @test wc.params[:groundoccupied] == WordCloud.occupied(WordCloud.QTree.kernel(wc.maskqtree[1]), WordCloud.QTree.FULL)
    @test wc.params[:groundoccupied] == WordCloud.occupied(wc.mask .!= wc.mask[1])

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
end

