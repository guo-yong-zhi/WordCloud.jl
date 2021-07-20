include(joinpath(dirname(@__DIR__), "src", "WordCloud.jl"))
using Documenter, .WordCloud

Documenter.makedocs(
    clean = true,
    doctest = true,
    modules = Module[MyCoolPackage],
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
