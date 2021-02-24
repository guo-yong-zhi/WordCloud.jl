@testset "textprocessing.jl" begin
    text = "So dim, so dark, So dense, so dull, So damp, so dank, So dead! The weather, now warm, now cold, Makes it harder Than ever to forget!"
    c = WordCloud.TextProcessing.countwords(text)
    @test c["so"] == 3
    words,weights = WordCloud.TextProcessing.processtext(c)
    @test !("So" in words)
    lemmatize = WordCloud.TextProcessing.lemmatize
    @test lemmatize("Cars") == "Car"
    @test lemmatize("makes") == "make"
    @test lemmatize("buses") == "bus"
    @test lemmatize("dies") == "die"
    @test lemmatize("licenses") == "license"
    @test lemmatize("wolves") == "wolf"
    @test lemmatize("knives") == "knife"
    @test lemmatize("closes") == "close"
    @test lemmatize("babies") == "baby"
    @test lemmatize("monkeys") == "monkey"
    @test lemmatize("less") == "less"
    @test lemmatize("does") == "do"
    @test lemmatize("中文") == "中文"
end