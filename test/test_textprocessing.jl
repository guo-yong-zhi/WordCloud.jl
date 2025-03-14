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

    tokenizer_eng = WordCloud.TextProcessing.tokenizer_eng
    tokenizer_default = WordCloud.TextProcessing.tokenizer
    @test tokenizer_default(" a man の 书本\n 1234") .|> strip == ["a", "man", "の", "书本", "1234"]
    @test tokenizer_eng(" a book in 1994\n") .|> strip == ["a", "book", "in", "1994"]
    @test tokenizer_eng(" the 'best-book' in 1994\n") .|> strip == ["the", "best", "book", "in", "1994"]
    @test tokenizer_eng("")|>collect == tokenizer_eng(" ")|>collect == tokenizer_eng(" ,")|>collect == []
    @test tokenizer_eng(" a _int_var3") .|> strip == ["a", "_int_var3"]
    @test tokenizer_eng("bob's book") .|> strip == ["bob", "book"]
    @test tokenizer_eng("bob's 'book' 'book'") .|> strip == ["bob", "book", "book"]
    @test tokenizer_eng("abc'de fg'h'ij k'l") .|> strip == ["abc'de", "fg'h'ij", "k'l"]
    @test tokenizer_eng("abc'de', fg'h'ij' k'l'") .|> strip == ["abc'de", "fg'h'ij", "k'l"]
    @test tokenizer_eng(" abc'de'. fg'h'ij',k'l'") .|> strip == ["abc'de", "fg'h'ij", "k'l"]
    
    lemmatizer_eng = WordCloud.TextProcessing.lemmatizer_eng
    lemmatize! = WordCloud.TextProcessing.lemmatize!
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
    @test lemmatize!(Dict("dog" => 1, "dogs" => 2), lemmatizer_eng) == Dict("dog" => 3)
    @test lemmatize!(Dict("cat" => 1, "dogs" => 2), lemmatizer_eng) == Dict("dog" => 2, "cat" => 1)
    @test lemmatize!(Dict("Meggs" => 10), lemmatizer_eng) == Dict("Meggs" => 10)

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
    # stopwords_extra
    @test length(processtext("word cloud is a cloud", language="en", stopwords=nothing)[1]) == 4
    @test length(processtext("word cloud is a cloud", language="en", stopwords=("cloud", ""))[1]) == 3
    @test length(processtext("word cloud is a cloud", language="en", stopwords_extra=[])[1]) == 2
    @test processtext("word cloud is a cloud", language="en", stopwords_extra=["word"])[1] |> only == "cloud"
    # settokenizer! ...
    WordCloud.settokenizer!("mylang", t->split(t, "a"))
    WordCloud.setstopwords!("mylang", [])
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

    htstr = """&pound;abcd<div x-component-name="DisasterSokuho" x-component-data="{&quot;earthquake&quot;:&quot;&lt;!-- 地震速報のメッセージを消しました （2024-04-25 12:00:08）-->\n&quot;,&quot;tsunami&quot;:&quot;&lt;!-- 津波速報のメッセージを消しました （2024-04-25 12:05:35）-->\n&quot;}"><div class="tYQVs"><div>"""
    @test strip(html2text(htstr)) == "abcd"
    htstr = """<div x-component-name='code1:<' x-component-data="code2:>">"""
    @test strip(html2text(htstr)) == ""
    htstr = """<p>abc</p><pre data-code-wrap="julia">"""
    @test strip(html2text(htstr)) == "abc"
    htstr= """<span class="reference-text">"<a rel="nofollow" class="external text" href="不应该出现">something</a>." <i>"""
    @test replace(html2text(htstr), r"\s"=>"") == "\"something.\""
end