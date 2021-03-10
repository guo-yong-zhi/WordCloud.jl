testqtree = WordCloud.testqtree

@testset "qtree.jl" begin
    qt = WordCloud.ShiftedQtree(rand((0,0,1), rand(50:300), rand(50:300)))|>WordCloud.buildqtree!
    @test qt[1][-10,-15] == WordCloud.EMPTY
    @test_throws BoundsError qt[1][-10,-15] = WordCloud.EMPTY
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

    qt = WordCloud.ShiftedQtree(rand((0,0,0,1), rand(50:300), rand(50:300)), 512)|>WordCloud.buildqtree!
    li = WordCloud.QTree.locate(qt)
    @test qt[li]!=WordCloud.QTree.EMPTY
    for l in WordCloud.levelnum(qt)
        if l >= li[1]
            @test sum(qt[li[1]].!=WordCloud.QTree.EMPTY) <= 1
        else
            @test sum(qt[li[1]-1].!=WordCloud.QTree.EMPTY) > 1
        end
    end
    
    words = [Random.randstring(rand(1:8)) for i in 1:rand(100:1000)]
    weights = randexp(length(words)) .* 1000 .+ randexp(length(words)) .* 200 .+ rand(20:100, length(words));
    wc = wordcloud(words, weights, density=0.7)
    clq = WordCloud.QTree.batchcollision_qtree(wc.qtrees, wc.maskqtree)
    cln = WordCloud.QTree.batchcollision_native(wc.qtrees, wc.maskqtree)
    @test Set(Set.(first.(clq))) == Set(Set.(first.(cln)))
end