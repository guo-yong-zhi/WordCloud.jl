using Documenter
using WordCloud

Documenter.makedocs(
    clean = true,
    doctest = true,
    repo = "",
    highlightsig = true,
    sitename = "WordCloud.jl",
    expandfirst = [],
    pages = [
        "Index" => "index.md",
    ],
)

deploydocs(;
    repo  =  "github.com/guo-yong-zhi/WordCloud.jl.git",
)
