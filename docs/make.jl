using Documenter
using WordCloud

Documenter.makedocs(
    clean = true,
    doctest = true,
    modules = Module[WordCloud],
    repo = "",
    highlightsig = true,
    sitename = "WordCloud Documentation",
    expandfirst = [],
    pages = [
        "Index" => "index.md",
    ]
)

deploydocs(;
    repo  =  "github.com/guo-yong-zhi/WordCloud.jl.git",
)
