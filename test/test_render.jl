@testset "rendering.jl" begin
    img = WordCloud.rendertext("test", 88.3, color="blue", angle=20, border=2)
    mat, svg = WordCloud.rendertext(Random.randstring(rand(1:8)), rand(5:50), angle=rand(0:180), type=:both)
    @test all(WordCloud.tobitmap(svg) .≈ mat)
    @test all(WordCloud.tobitmap(svg) .≈ WordCloud.tobitmap(WordCloud.tosvg(mat)))

    for i in 1:20
        @test 0.9 < WordCloud.Render.gamma(i+1) / prod(1:i) < 1.1
    end

    h = 300+300rand()
    w = 300+300rand()
    sh = WordCloud.Render.shape(ellipse, h, w,color=0)
    true_area = WordCloud.occupancy(WordCloud.imagemask(WordCloud.tobitmap(sh), (0, 0, 0, 0)), false)
    @test 0.8 < WordCloud.ellipse_area(h, w) / true_area < 1.2

    h = 300+300rand()
    w = 300+300rand()
    r = 10 + 140rand()
    sh = WordCloud.Render.shape(box, h, w, cornerradius=r,color=0)
    true_area = WordCloud.occupancy(WordCloud.imagemask(WordCloud.tobitmap(sh), (0, 0, 0, 0)), false)
    @test 0.8 < WordCloud.box_area(h, w, cornerradius=r) / true_area < 1.2

    h = 300+300rand()
    w = 300+300rand()
    rt = 3rand()
    sh = WordCloud.Render.shape(squircle, h, w, rt=rt,color=0)
    true_area = WordCloud.occupancy(WordCloud.imagemask(WordCloud.tobitmap(sh), (0, 0, 0, 0)), false)
    @test 0.8 < WordCloud.squircle_area(h, w, rt=rt) / true_area < 1.2

    h = 300+300rand()
    w = 300+300rand()
    npoints = rand(3:10)
    sh = WordCloud.Render.shape(ngon, h, w, npoints=npoints, color=0)
    true_area = WordCloud.occupancy(WordCloud.imagemask(WordCloud.tobitmap(sh), (0, 0, 0, 0)), false)
    @test 0.8 < WordCloud.ngon_area(h, w, npoints=npoints) / true_area < 1.2

    h = 300+300rand()
    w = 300+300rand()
    npoints = rand(3:10)
    starratio = 0.3 + 0.7rand()
    sh = WordCloud.Render.shape(star, h, w, npoints=npoints, starratio=starratio, color=0)
    true_area = WordCloud.occupancy(WordCloud.imagemask(WordCloud.tobitmap(sh), (0, 0, 0, 0)), false)
    WordCloud.star_area(h, w, npoints=npoints, starratio=starratio) / true_area 
end