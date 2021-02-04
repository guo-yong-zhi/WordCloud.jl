module TextProcessing
export countwords, processtext, html2text, stopwords_en, stopwords_cn, stopwords
dir = @__DIR__
stopwords_en = Set(readlines(dir * "/../res/stopwords_en.txt"))
stopwords_cn = Set(readlines(dir * "/../res/stopwords_cn.txt"))
stopwords = stopwords_en ∪ stopwords_cn
function splitwords(text::AbstractString, regexp=r"\w[\w']+")
    words = findall(regexp, text)
    words = [endswith(text[i], "'s") ? text[i][1:end - 2] : text[i] for i in words]
end

function countwords(words::AbstractVector{<:AbstractString}; regexp=r"\w[\w']+", counter=Dict{String,Int}())
    for w in words
        m = match(regexp, w)
        if m !== nothing
            mm = m.match
            counter[mm] = get!(counter, mm, 0) + 1
        end
    end
    counter
end

countwords(text::AbstractString; regexp=r"\w[\w']+", kargs...) = countwords(splitwords(text, regexp); kargs...)

raw"""
countwords(text; regexp=r"\w[\w']+", counter=Dict{String,Int}(), kargs...)
Count words in text. And use `regexp` to split. And save results in `counter`. 
`text` can be a String, a Vector of String, or a opend file(IO)
"""
function countwords(textfile::IO; counter=Dict{String,Int}(), kargs...)
    for l in eachline(textfile)
        countwords(l;counter=counter, kargs...)
    end
    counter
end
        
# function countwords(textfiles::AbstractVector{<:IO};counter=Dict{String,Int}(), kargs...)
#     for f in textfiles
#         countwords(f;counter=counter, kargs...)
#     end
#     counter
# end
"""
processtext the text, filter the words, and adjust the weights. return processtexted words vector and weights vector.
## Positional Arguments
* text: string, a vector of words, or a opend file(IO)
* Or, a counter::Dict{<:AbstractString, <:Number}
## Optional Keyword Arguments
* stopwords: a words Set
* minlength, maxlength: min and max length of a word to be included
* minfrequency: minimum frequency of a word to be included
* maxnum: maximum number of words
* minweight, maxweight: within 0 ~ 1, set to adjust extreme weight
"""
function processtext(counter::Dict{<:AbstractString, <:Number}; 
    stopwords=stopwords,
    minlength=2, maxlength=30,
    minfrequency=0,
    maxnum=500,
    minweight=1/maxnum, maxweight=minweight*20)
    stopwords = Set(stopwords)
    println("$(sum(values(counter))) words")
    println("$(length(counter)) different words")
    for (w, c) in counter
        if (c < minfrequency 
            || length(w) < minlength || length(w) > maxlength 
            || lowercase(w) in stopwords || w in stopwords)
            delete!(counter, w)
        end
    end
    words = keys(counter) |> collect
    weights = values(counter) |> collect
    println("$(length(words)) legal words")
    maxnum = min(maxnum, length(weights))
    inds = partialsortperm(weights, 1:maxnum, rev=true)
    words = words[inds]
    weights = weights[inds]
    @assert !isempty(weights)
#     weights = sqrt.(weights)
    weights = weights ./ sum(weights)
#     min_i = findfirst(x->x<minweight, weights)
#     if min_i !== nothing
#         min_i = max(1, min_i-1)
#         words = words[1:min_i]
#         weights = weights[1:min_i]
#         weights = weights ./ sum(weights)
#     end
#     println("$(length(words)) non-tiny words")
    m = weights .> maxweight
    weights[m] .= log1p.(weights[m] .- maxweight)./10 .+ maxweight
    weights .+= minweight
    println("$(sum(m)) huge words")
    words, weights
end

function processtext(text; regexp=r"\w[\w']+", counter=Dict{String,Int}(), kargs...)
    processtext(countwords(text, regexp=regexp, counter=counter); kargs...)
end
processtext(fun::Function; kargs...) = processtext(fun(); kargs...)

function html2text(content::AbstractString)
    patterns = [
        r"<[\s]*?script[^>]*?>[\s\S]*?<[\s]*?/[\s]*?script[\s]*?>"=>" ",
        r"<[\s]*?style[^>]*?>[\s\S]*?<[\s]*?/[\s]*?style[\s]*?>"=>" ",
        "<br>"=>"\n",
        r"<[^>]+>"=>" ",
        "&quot;"=>"\"",
        "&amp;"=>"&",
        "&lt;"=>"<",
        "&gt;"=>">",
        r"&#?\w{1,6};"=>" ",
    ]
    for p in patterns
        content = replace(content, p)
    end
    content
end
html2text(file::IO) = html2text(read(file, String))
end 
