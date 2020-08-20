using WordCloud
using Test
using Random

include("test_qtree.jl")

@testset "WordCloud.jl" begin
    # Write your tests here.
    img, img_m = WordCloud.rendertext("test", 88.3, color="blue", angle = 20, border=1, returnmask=true)
    texts = [Random.randstring(rand(1:8)) for i in 1:rand(100:1000)]
    weights = randexp(length(texts)) .* 1000 .+ randexp(length(texts)) .* 200 .+ rand(20:100, length(texts));
    wc = wordcloud(texts, weights, filling_rate=0.45)
    paint(wc)
    @show generate(wc)
    paint(wc::wordcloud, "test.jpg")
    @test isempty(WordCloud.outofbounds(wc.maskqtree, wc.qtrees))
end

