using Test

@testset "multithreading" begin
    using Luxor # hide

    tempdir = mktempdir(; cleanup=false)
    cd(tempdir)

    function make_drawings(i::Int)
        println("Working on thread ", Threads.threadid())
        w = 300
        h = 300
        filename = "sample" * string(i) * ".png"
        Drawing(w, h, filename)
        origin()
        background("black")
        setopacity(0.5)
        fontsize(250)
        sethue("grey40")
        text(string(i), halign=:center, valign=:middle)
        for k in 1:50
            pg1 = polycross(rand(BoundingBox()), rand(60:120), 4, vertices=true)
            pg2 = polycross(rand(BoundingBox()), rand(60:120), 4, vertices=true)
            pg3 = polyintersect(pg1, pg2)
            for p in pg3
                randomhue()
                poly(p, :fill)
            end
        end
        finish()
        return
    end
    make_drawings(0) # remove this line, and the test will success
    Threads.@threads :static for i = 1:10 # change 10 to 8, and the test will success
        make_drawings(i)
    end


end
