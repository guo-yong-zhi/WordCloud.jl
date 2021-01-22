@testset "rendering.jl" begin
    svg, img, img_m = WordCloud.rendertext("test", 88.3, color="blue", angle = 20, border=2, returnmask=true)
    svg, mat = WordCloud.rendertext(Random.randstring(rand(1:8)), rand(5:50), angle=rand(0:180))
    @test all(WordCloud.svg2bitmap(svg).≈ mat)
end