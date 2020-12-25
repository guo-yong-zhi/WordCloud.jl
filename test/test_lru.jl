@testset "lru.jl" begin
    lru = WordCloud.LRU{Int}()
    for i in 1:10
        push!(lru, i)
    end
    for i in 10:-2:2
        push!(lru, i)
    end
    push!(lru, 1)
    @test WordCloud.take(lru) == [1,2,4,6,8,10,9,7,5,3]
    lru = WordCloud.LRU{Int}(WordCloud.IntMap{Int}(10))
    for i in 1:10
        push!(lru, i)
    end
    for i in 10:-2:2
        push!(lru, i)
    end
    push!(lru, 1)
    @test WordCloud.take(lru) == [1,2,4,6,8,10,9,7,5,3]
    @test WordCloud.take(lru, 3) == [1,2,4]
    push!.(lru, 7:9)
    @test WordCloud.take(lru, 3) == [9,8,7]
end