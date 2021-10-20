module TextProcessing
export countwords, processtext, html2text, stopwords_en, stopwords_cn, stopwords, 
lemmatize, lemmatize!, casemerge!
dir = @__DIR__
stopwords_en = Set(readlines(dir * "/../res/stopwords_en.txt"))
stopwords_cn = Set(readlines(dir * "/../res/stopwords_cn.txt"))
stopwords = stopwords_en ∪ stopwords_cn
include("wordlists.jl")

"only handle the simple case of plural nouns and third person singular verbs"
function lemmatize(word)
    if (!endswith(word, "s")) || endswith(word, "ss") # quick return
        return word
    end
    w = lowercase(word)
    if w in s_ending_words || (length(word) <= 3 && w == word) || uppercase(word) == word
        return word
    elseif endswith(w, "ies") && !(w[1:prevind(w, end, 1)] in xe_ending_words)
        return word[1:prevind(word, end, 3)] * "y"
    elseif endswith(w, "ses")
        wh = w[1:prevind(w, end, 2)]
        if wh in s_ending_words || endswith(wh, "ss")
            return word[1:prevind(word, end, 2)]
        end
    elseif endswith(w, r"xes|ches|shes|oes") && !(w[1:prevind(w, end, 1)] in xe_ending_words)
        return word[1:prevind(word, end, 2)]
    elseif endswith(w, "ves")
        wh = w[1:prevind(w, end, 3)]
        wordh = word[1:prevind(word, end, 3)]
        if wh * "fe" in f_ending_words
            return wordh * "fe"
        elseif wh * "f" in f_ending_words
            return wordh * "f"
        end
    end
    return word[1:prevind(word, end, 1)]
end

function splitwords(text::AbstractString, regexp=r"\w[\w']+")
    words = findall(regexp, text)
    words = [endswith(text[i], "'s") ? text[i][1:prevind(text[i], end, 2)] : text[i] for i in words]
end

function countwords(words::AbstractVector{<:AbstractString}; 
    regexp=r"\w[\w']+", counter=Dict{String,Int}())
    for w in words
        if regexp !== nothing
            m = match(regexp, w)
            if m !== nothing
                w = m.match
                counter[w] = get(counter, w, 0) + 1
            end
        else
            counter[w] = get(counter, w, 0) + 1
        end
    end
    counter
end

function countwords(text::AbstractString; regexp=r"\w[\w']+", kargs...)
    countwords(splitwords(text, regexp); regexp=nothing, kargs...)
end

raw"""
countwords(text; regexp=r"\w[\w']+", lemmatizer=lemmatize, counter=Dict{String,Int}(), kargs...)
Count words in text. And use `regexp` to split. And save results in `counter`. 
`lemmatizer` can be `nothing` or a String-to-String function to do lemmatization.
`text` can be a String, a Vector of String, or a opend file(IO).
"""
function countwords(textfile::IO; counter=Dict{String,Int}(), kargs...)
    for l in eachline(textfile)
        countwords(l; counter=counter, kargs...)
    end
    counter
end
        
# function countwords(textfiles::AbstractVector{<:IO};counter=Dict{String,Int}(), kargs...)
#     for f in textfiles
#         countwords(f;counter=counter, kargs...)
#     end
#     counter
# end

function casemerge!(d)
    for w in keys(d)
        if length(w) > 0 && isuppercase(w[1]) && islowercase(w[end])
            lw = lowercase(w)
            if lw in keys(d) && d[lw] > d[w]
                d[lw] += d[w]
                pop!(d, w)
            end
        end
    end
    d
end

function lemmatize!(d::AbstractDict)
    for w in keys(d)
        lw = lemmatize(w)
        if lw != w
            d[lw] = get(d, lw, 0) + d[w]
            pop!(d, w)
        end
    end
    d
end

"""
processtext the text, filter the words, and adjust the weights. return words vector and weights vector.
## Positional Arguments
* text: string, a vector of words, or a opend file(IO)
* Or counter, a Dict{<:String, <:Real}, a Vector{Pair}, a Vector{Tuple}, or two Vectors
## Optional Keyword Arguments
* stopwords: a words Set
* minlength, maxlength: min and max length of a word to be included
* minfrequency: minimum frequency of a word to be included
* maxnum: maximum number of words
* minweight, maxweight: within 0 ~ 1, set to adjust extreme weight
* process: a function to process word counter, defaults to `casemerge!∘lemmatize!`
"""
function processtext(counter::AbstractDict{<:AbstractString,<:Real}; 
    stopwords=stopwords,
    minlength=1, maxlength=30,
    minfrequency=0,
    maxnum=500,
    minweight=1 / maxnum, maxweight=:auto,
    process=casemerge! ∘ lemmatize!)
    stopwords = stopwords isa AbstractSet ? stopwords : Set(stopwords)
    counter = process(counter)
    print("$(sum(values(counter))) words, ")
    print("$(length(counter)) different words, ")
    for (w, c) in counter
        if (c < minfrequency 
            || length(w) < minlength || length(w) > maxlength 
            || w in stopwords || lowercase(w) in stopwords)
            delete!(counter, w)
        end
    end
    words = keys(counter) |> collect
    weights = values(counter) |> collect
    print("$(length(words)) legal words, ")
    maxnum = min(maxnum, length(weights))
    inds = partialsortperm(weights, 1:maxnum, rev=true)
    words = words[inds]
    weights = weights[inds]
    @assert !isempty(weights)
    weights = weights ./ sum(weights)
    maxweight = maxweight == :auto ? max(20minweight, 20 / maxnum) : maxweight
    m = weights .> maxweight
    weights[m] .= log1p.(weights[m] .- maxweight) ./ 10 .+ maxweight
    weights .+= minweight
    print("$(sum(m)) huge words, ")
    println("keep top $(length(words)) words.")
    words, weights
end

function processtext(text; regexp=r"\w[\w']+", counter=Dict{String,Int}(), kargs...)
    processtext(
        countwords(text, regexp=regexp, counter=counter);
        kargs...)
end
processtext(fun::Function; kargs...) = processtext(fun(); kargs...)
function processtext(words::AbstractVector{T}, weights::AbstractVector{W}; kargs...) where {T,W}
    dict = Dict{T,W}()
    for (word, weight) in zip(words, weights)
        dict[word] = get(dict, word, 0) + weight
    end
    processtext(dict; kargs...)
end
processtext(wordsweights::Tuple; kargs...) = processtext(wordsweights...; kargs...)
function processtext(counter::AbstractVector{<:Union{Pair,Tuple,AbstractVector}}; kargs...)
    processtext(first.(counter), [v[2] for v in counter]; kargs...)
end
function html2text(content::AbstractString)
    patterns = [
        r"<[\s]*?script[^>]*?>[\s\S]*?<[\s]*?/[\s]*?script[\s]*?>" => " ",
        r"<[\s]*?style[^>]*?>[\s\S]*?<[\s]*?/[\s]*?style[\s]*?>" => " ",
        r"<!--[\s\S]*?-->" => " ",
        "<br>" => "\n",
        r"<[\s\S]*?>" => " ",
        "&quot;" => "\"",
        "&amp;" => "&",
        "&lt;" => "<",
        "&gt;" => ">",
        r"&#?\w{1,6};" => " ",
    ]
    for p in patterns
        content = replace(content, p)
    end
    content
end
html2text(file::IO) = html2text(read(file, String))
end 
