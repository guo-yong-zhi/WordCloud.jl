@testset "rendering.jl" begin
    svg,mat = rendertext(Random.randstring(rand(1:8)), rand(5:50), angle=rand(0:180))
    all(svg2bitmap(svg).≈ mat)
end