@testset "textprocessing.jl" begin
    text = "So dim, so dark, So dense, so dull, So damp, so dank, so dead! The weather, now warm, now cold, Makes it harder Than ever to forget!"
    c = countwords(text)
    @test c["so"] == 4
    @test c["Makes"] == 1
    WordCloud.TextProcessing.casemerge!(c)
    @test "so" in keys(c)
    @test !("So" in keys(c)) # casemerge!
    words, weights = WordCloud.TextProcessing.processtext(c)
    @test !("to" in words) # stopwords
    @test lemmatize("Cars") == "Car"
    @test lemmatize("monkeys") == "monkey"
    @test lemmatize("politics") == "politics"
    @test lemmatize("less") == "less"
    @test lemmatize("makes") == "make"
    @test lemmatize("does") == "do"
    @test lemmatize("shoes") == "shoe"
    @test lemmatize("buses") == "bus"
    @test lemmatize("classes") == "class"
    @test lemmatize("closes") == "close"
    @test lemmatize("licenses") == "license"
    @test lemmatize("babies") == "baby"
    @test lemmatize("studies") == "study"
    @test lemmatize("dies") == "die"
    @test lemmatize("series") == "series"
    @test lemmatize("wolves") == "wolf"
    @test lemmatize("knives") == "knife"
    @test lemmatize("ourselves") == "ourselves"
    @test lemmatize("loves") == "love"
    @test lemmatize("lives") in ("life", "live")
    @test lemmatize("cos") == "cos"
    @test lemmatize("中文") == "中文"

    @test lemmatize!(Dict("dog" => 1, "dogs" => 2)) == Dict("dog" => 3)
    @test lemmatize!(Dict("cat" => 1, "dogs" => 2)) == Dict("dog" => 2, "cat" => 1)
    @test length(processtext(["cat" => 1, "dog" => 1, "dogs" => 3, "Dogs" => 2, "Dog" => 1])[1]) == 2
    @test processtext(["cat" => 3, "Dog" => 1, "dogs" => 2])[2] |> diff |> only |> iszero
    @test processtext("word cloud") == processtext(["word","cloud"], [12,12]) == processtext([("word", 3), ("cloud", 3)])
end