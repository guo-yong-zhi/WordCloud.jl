#md# This package does not come with an integrated Japanese tokenizer. You can leverage the [`TinySegmenter.jl`](https://github.com/JuliaStrings/TinySegmenter.jl) package instead.
using WordCloud
import TinySegmenter
WordCloud.settokenizer!("jpn", TinySegmenter.tokenize)

wc = wordcloud("花は桜木、人は武士", language="jpn") |> generate! # the argumet `language` is optional

println("results are saved to japanese.svg")
paint(wc, "japanese.svg")
wc
#eval# runexample(:japanese)
#md# ![](japanese.svg)  