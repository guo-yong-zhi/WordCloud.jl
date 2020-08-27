using WordCloud
using Test
using Random

include("test_qtree.jl")

@testset "nlp.jl" begin
    text = "So dim, so dark, So dense, so dull, So damp, so dank, So dead! The weather, now warm, now cold, Makes it harder Than ever to forget!"
    c = WordCloud.NLP.countwords(text)
    @test c["so"] == 3
    words,weights = WordCloud.NLP.process(c)
    @test !("So" in words)
end

@testset "WordCloud.jl" begin
    img, img_m = WordCloud.rendertext("test", 88.3, color="blue", angle = 20, border=1, returnmask=true)
    words = [Random.randstring(rand(1:8)) for i in 1:rand(100:1000)]
    weights = randexp(length(words)) .* 1000 .+ randexp(length(words)) .* 200 .+ rand(20:100, length(words));
    wc = wordcloud(words, weights, filling_rate=0.45)
    paint(wc)
    generate!(wc)
    paint(wc::wordcloud, "test.jpg")
    @test isempty(WordCloud.outofbounds(wc.maskqtree, wc.qtrees))

    wordcloud(["singleword"=>12], maskimg=shape(box, 200, 150, 40, color=0.15), filling_rate=0.5) #singleword & Pair
    wordcloud(process("giving a single word is ok. giving several words is ok too"), 
            maskimg=shape(box, 20, 15, 0, color=0.15), filling_rate=0.5, transparentcolor=(1,1,1,0)) #String & small mask
    placement!(wc)
end

