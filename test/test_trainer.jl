@testset "train.jl" begin
    x = rand(Float64, 1000) * 1000;
    @test sum(floor.(Int, log2.(x))) == sum(WordCloud.Trainer.intlog2.(x))

    lru = WordCloud.Trainer.LRU{Int}()
    for i in 1:10
        push!(lru, i)
    end
    for i in 10:-2:2
        push!(lru, i)
    end
    push!(lru, 1)
    @test WordCloud.Trainer.take(lru) == [1,2,4,6,8,10,9,7,5,3]
    lru = WordCloud.Trainer.LRU{Int}(WordCloud.Trainer.IntMap{Int}(10))
    for i in 1:10
        push!(lru, i)
    end
    for i in 10:-2:2
        push!(lru, i)
    end
    push!(lru, 1)
    @test WordCloud.Trainer.take(lru) == [1,2,4,6,8,10,9,7,5,3]
    @test WordCloud.Trainer.take(lru, 3) == [1,2,4]
    push!.(lru, 7:9)
    @test WordCloud.Trainer.take(lru, 3) == [9,8,7]

    words = [Random.randstring(rand(1:8)) for i in 1:rand(100:1000)]
    weights = randexp(length(words)) .* 1000 .+ randexp(length(words)) .* 200 .+ rand(20:100, length(words));
    wc = wordcloud(words, weights, density=0.45)
    generate!(wc, trainer=WordCloud.trainepoch_P2!)
    placement!(wc)
    generate!(wc, trainer=WordCloud.trainepoch_Px!)
    placement!(wc)
    generate!(wc, 100, optimiser=(t, Δ)->Δ./4, patient=5, retry=5)
end