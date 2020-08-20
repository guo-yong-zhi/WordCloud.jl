FULL = WordCloud.QTree.FULL
EMPTY = WordCloud.QTree.EMPTY
HALF = WordCloud.QTree.HALF
function testqtree(qt)
    for l in 2:WordCloud.levelnum(qt)
        for i in 1:size(qt[l], 1)
            for j in 1:size(qt[l], 2)
                c = [qt[l-1, 2i, 2j], qt[l-1, 2i-1, 2j], qt[l-1, 2i, 2j-1], qt[l-1, 2i-1, 2j-1]]
                if qt[l, i, j] == FULL
                    @test all(c .== FULL)
                elseif qt[l, i, j] == EMPTY
                    @test all(c .== EMPTY)
                elseif qt[l, i, j] == HALF
                    @test !(all(c .== FULL) || all(c .== EMPTY))
                else
                    error(qt[l, i, j], (l, i, j))
                end
            end
        end
    end
end

@testset "qtree.jl" begin
    # Write your tests here.
    qt = WordCloud.ShiftedQtree(rand((0,0,1), rand(50:300), rand(50:300)))|>WordCloud.buildqtree!
    @test qt[1][-10,-15] == EMPTY
    @test_throws BoundsError qt[1][-10,-15] = EMPTY
    qt2 = WordCloud.ShiftedQtree(rand((0,0,1), size(qt[1])))|>WordCloud.buildqtree!
    testqtree(qt)
    WordCloud.shift!(qt, 3, 2, 5)
    WordCloud.setshift!(qt2, 4, 1, 2)
    testqtree(qt)
    testqtree(qt2)
    WordCloud.QTree.overlap!(qt2, qt)
    testqtree(qt2)
    qt = WordCloud.ShiftedQtree(rand((0,0,1), 1, 1))|>WordCloud.buildqtree!
    @test WordCloud.QTree.levelnum(qt) == 1
    qt = WordCloud.ShiftedQtree(rand((0,0,1), 1, 2))|>WordCloud.buildqtree!
    @test WordCloud.QTree.levelnum(qt) == 2
    @test_throws AssertionError qt = WordCloud.ShiftedQtree(rand((0,0,1), 0, 0))|>WordCloud.buildqtree!
end