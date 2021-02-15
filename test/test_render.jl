@testset "rendering.jl" begin
    img = WordCloud.rendertext("test", 88.3, color="blue", angle = 20, border=2)
    mat, svg = WordCloud.rendertext(Random.randstring(rand(1:8)), rand(5:50), angle=rand(0:180), type=:both)
    @test all(WordCloud.svg2bitmap(svg).≈ mat)
end