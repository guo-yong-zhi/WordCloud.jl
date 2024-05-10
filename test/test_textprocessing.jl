@testset "textprocessing.jl" begin
    text = "So dim, so dark, So dense, so dull, So damp, so dank, so dead! The weather, now warm, now cold, Makes it harder Than ever to forget!"
    c = countwords(text, language="_default_")
    @test c["so"] == 4
    @test c["Makes"] == 1
    WordCloud.TextProcessing.casemerge!(c)
    @test "so" in keys(c)
    @test !("So" in keys(c)) # casemerge!
    words, weights = WordCloud.TextProcessing.processtext(c)
    @test !("to" in words) # stopwords

    lemmatizer_eng = WordCloud.TextProcessing.lemmatizer_eng
    groupwords! = WordCloud.TextProcessing.groupwords!
    @test lemmatizer_eng("Cars") == "Car"
    @test lemmatizer_eng("monkeys") == "monkey"
    @test lemmatizer_eng("politics") == "politics"
    @test lemmatizer_eng("less") == "less"
    @test lemmatizer_eng("makes") == "make"
    @test lemmatizer_eng("does") == "do"
    @test lemmatizer_eng("shoes") == "shoe"
    @test lemmatizer_eng("buses") == "bus"
    @test lemmatizer_eng("classes") == "class"
    @test lemmatizer_eng("closes") == "close"
    @test lemmatizer_eng("licenses") == "license"
    @test lemmatizer_eng("babies") == "baby"
    @test lemmatizer_eng("studies") == "study"
    @test lemmatizer_eng("dies") == "die"
    @test lemmatizer_eng("series") == "series"
    @test lemmatizer_eng("wolves") == "wolf"
    @test lemmatizer_eng("knives") == "knife"
    @test lemmatizer_eng("ourselves") == "ourselves"
    @test lemmatizer_eng("loves") == "love"
    @test lemmatizer_eng("lives") in ("life", "live")
    @test lemmatizer_eng("cos") == "cos"
    @test lemmatizer_eng("中文") == "中文"
    @test groupwords!(Dict("dog" => 1, "dogs" => 2), lemmatizer_eng) == Dict("dog" => 3)
    @test groupwords!(Dict("cat" => 1, "dogs" => 2), lemmatizer_eng) == Dict("dog" => 2, "cat" => 1)

    @test countwords(" cat cats dogs Dog dog dogs is \t", language="english")|>values|>sum == 7 # count, no-stopwords
    @test countwords(["# 1994 "]) |> isempty # pure punctuation and number string
    @test countwords(["\t# 1994年"]) |>keys|>only == "# 1994年"
    @test countwords([" # 1994 "], regexp=r"(?:\S[\s\S]*)?\w(?:[\s\S]*\S)?")|>keys|>only == "# 1994"
    @test processtext([" # 1994 "], regexp=r"(?:\S[\s\S]*)?\w(?:[\s\S]*\S)?")[1]|>only == "# 1994"
    @test processtext([" # 1994 "], regexp=nothing)[1]|>only == " # 1994 "
    @test length(processtext("cat cats dogs Dog\tdog dogs is", language="eng")[1]) == 2 # lemmatizer, stopwords
    @test length(processtext(split("cat cats dogs Dog dog is"), language="eng")[1]) == 2 # lemmatizer, stopwords
    @test processtext(["cat" => 3, "Dog" => 1, "dog" => 2])[2] |> diff |> only |> iszero # casemerge
    @test processtext("word cloud", language="eng") == processtext(["word","cloud"], [12,12], language="eng") == processtext([("word", 3), ("cloud", 3)], language="eng")
    @test processtext(["dogs ", " （"], language="eng")[1] |> only == "dog" # lemmatizer
    @test processtext(["dogs ", " （"], language="eng", regexp=nothing)[1] |> length == 2 # lemmatizer
    @test processtext(["dogs "=>1, "is"=>1.5], language="eng")[1] |> only == "dogs " # no-lemmatizer, stopwords
    @test processtext(countwords(["dogs "=>1, "\t（"=>2], language="en"), language="eng")[1] |> only == "dog" # lemmatizer
    @test processtext(["dogs "=>1, " （"=>2], language="eng", process=countwords)[1] |> only == "dog" # lemmatizer
    @test processtext(countwords(["  《dogs 》 "=>1, " （"=>2, " 《\t》 "=>2], language="eng"), language="en")[1] |> only == "《dogs 》" # lemmatizer
    # settokenizer! ...
    WordCloud.settokenizer!("mylang", t->split(t, "a"))
    @test Set(processtext("bananais", language="mylang")[1]) == Set(["b", "n", "is"])
    WordCloud.setlemmatizer!("mylang", uppercase)
    @test Set(processtext("bananais", language="mylang")[1]) == Set(["B", "N", "IS"])
    WordCloud.setstopwords!("mylang", ["B", "WW"])
    @test Set(processtext("bananais", language="mylang")[1]) == Set(["N", "IS"])
    
    pm = WordCloud.TextProcessing.powermeanwith1
    @test pm(1, -12.34) == 1
    @test abs(pm(7, 1e-8) - sqrt(7)) < 1e-6
    @test pm(9, 0) == 3.
    @test pm(17, 1) ≈ 9
    @test pm(2, -1) ≈ 2/(1/2+1)
    @test pm(Inf, -1) ≈ 2
    @test abs(pm(12.5, 2-1e-8) - sqrt(12.5^2/2+1/2)) < 1e-6
    @test pm(π, Inf) ≈ π
    @test pm(7π, -Inf) == 1.
end