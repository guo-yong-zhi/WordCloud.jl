module TextProcessing
export countwords, processtext, html2text, STOPWORDS, casemerge!, rescaleweights, settokenizer!, setlemmatizer!, setstopwords!, detect_language

using StopWords
using LanguageIdentification

include("wordlists.jl")

"only handles the simple cases of plural nouns and third person singular verbs"
function lemmatizer_eng(word)
    if (!endswith(word, "s")) || endswith(word, "ss") # quick return
        return word
    end
    w = lowercase(word)
    if w in S_ENDING_WORDS || (length(word) <= 3 && w == word) || uppercase(word) == word
        return word
    elseif endswith(w, "ies") && !(w[1:prevind(w, end, 1)] in XE_ENDING_WORDS)
        return word[1:prevind(word, end, 3)] * "y"
    elseif endswith(w, "ses")
        wh = w[1:prevind(w, end, 2)]
        if wh in S_ENDING_WORDS || endswith(wh, "ss")
            return word[1:prevind(word, end, 2)]
        end
    elseif endswith(w, r"xes|ches|shes|oes") && !(w[1:prevind(w, end, 1)] in XE_ENDING_WORDS)
        return word[1:prevind(word, end, 2)]
    elseif endswith(w, "ves")
        wh = w[1:prevind(w, end, 3)]
        wordh = word[1:prevind(word, end, 3)]
        if wh * "fe" in F_ENDING_WORDS
            return wordh * "fe"
        elseif wh * "f" in F_ENDING_WORDS
            return wordh * "f"
        end
    end
    return word[1:prevind(word, end, 1)]
end

function lemmatize!(d::AbstractDict, lemmatizer)
    for w in keys(d)
        w2 = lemmatizer(w)
        if w2 != w && (w2 in keys(d) || lowercase(w2) in keys(d) || d[w] < 3)
            d[w2] = get(d, w2, 0) + d[w]
            pop!(d, w)
        end
    end
    d
end

function tokenizer(text::AbstractString, regexp=r"\w+")
    [text[i] for i in findall(regexp, text)]
end

function tokenizer_eng(text::AbstractString, regexp=r"\b\w+(?:'\w+)*\b")
    indices = findall(regexp, text)
    [endswith(text[i], "'s") ? text[i][1:prevind(text[i], end, 2)] : text[i] for i in indices]
end

# ISO 639-3 macrolanguages
const STOPWORDS = stopwords
const TOKENIZERS = Dict(
    "_default_" => tokenizer,
    "eng" => tokenizer_eng,
)
const LEMMATIZERS = Dict(
    "_default_" => identity,
    "eng" => lemmatizer_eng,
)

"""
    settokenizer!(lang::AbstractString, str_to_list_func)  

Customize tokenizer for language `lang`
"""
function settokenizer!(lang::AbstractString, str_to_list_func)
    TOKENIZERS[StopWords.normcode(String(lang))] = str_to_list_func
end
"""
    setstopwords!(lang::AbstractString, str_set)  

Customize stopwords for language `lang`
"""
function setstopwords!(lang::AbstractString, str_set)
    STOPWORDS[StopWords.normcode(String(lang))] = str_set
end
"""
    setlemmatizer!(lang::AbstractString, str_to_str_func)  

Customize lemmatizer for language `lang`
"""
function setlemmatizer!(lang::AbstractString, str_to_str_func)
    LEMMATIZERS[StopWords.normcode(String(lang))] = str_to_str_func
end

@doc raw"""
    countwords(text_or_counter; counter=Dict{String,Int}(), language=:auto, regexp=r"(?:\S[\s\S]*)?[^0-9_\W](?:[\s\S]*\S)?")  

Count words in text. And save results into `counter`.  
`text_or_counter` can be a String, a Vector of Strings, an opend file (IO) or a Dict.  
`regexp` is a regular expression to partially match and filter words. For example, `regexp=r"\S(?:[\s\S]*\S)?"` will trim whitespaces then eliminate empty words.  
"""
function countwords(words, counts; language=:auto,
    regexp=r"(?:\S[\s\S]*)?[^0-9_\W](?:[\s\S]*\S)?", counter=Dict{String,Int}())
    # strip whitespace and filter out pure punctuation and number string
    language = detect_language(words, language)
    for (w, c) in zip(words, counts)
        if regexp !== nothing
            m = match(regexp, w)
            if m !== nothing
                w = m.match
                counter[w] = get(counter, w, 0) + c
            end
        else
            counter[w] = get(counter, w, 0) + c
        end
    end
    lemmatizer_ = get(LEMMATIZERS, language, LEMMATIZERS["_default_"])
    lemmatize!(counter, lemmatizer_)
    counter
end
function countwords(text::AbstractString; language=:auto, kargs...)
    language = detect_language(text, language)
    if !haskey(TOKENIZERS, language)
        @warn "No built-in tokenizer for $(language)!"
    end
    tokenizer_ = get(TOKENIZERS, language, TOKENIZERS["_default_"])
    countwords(tokenizer_(text); language=language, kargs...)
end
countwords(words::AbstractVector{<:AbstractString}; kargs...) = countwords(words, Iterators.repeated(1); kargs...)
countwords(counter::AbstractDict{<:AbstractString,<:Real}; kargs...) = countwords(keys(counter), values(counter); kargs...)
countwords(wordscounts::Tuple; kargs...) = countwords(wordscounts...; kargs...)
function countwords(counter::AbstractVector{<:Union{Pair,Tuple,AbstractVector}}; kargs...)
    countwords(first.(counter), [v[2] for v in counter]; kargs...)
end
function countwords(textfile::IO; counter=Dict{String,Int}(), kargs...)
    for l in eachline(textfile)
        countwords(l; counter=counter, kargs...)
    end
    counter
end

function casemerge!(d)
    for w in keys(d)
        if length(w) > 0 && isuppercase(w[1]) && islowercase(w[end])
            w2 = lowercase(w)
            if w2 != w && w2 in keys(d)
                if d[w2] < d[w]
                    w, w2 = w2, w
                end
                d[w2] += d[w]
                pop!(d, w)
            end
        end
    end
    d
end

function powermeanwith1(x, p)
    x = float(x)
    xp = x^p
    if xp == 1.0
        return sqrt(x)
    elseif isinf(xp)
        return exp(log(x) - log(2) / p)
    else
        return exp((log((xp / 2 + 1 / 2))) / p)
    end
end

function _rescaleweights(dict, func=identity, p=0)
    newdict = Dict(k => func(v) / powermeanwith1(length(k), p) for (k, v) in dict)
    sc = sum(values(dict)) / sum(values(newdict))
    for k in keys(newdict)
        newdict[k] *= sc
    end
    newdict
end

"""
    rescaleweights(func=identity, p=0)

This function takes word length into account. Therefore, the rescaled weights can be used as font size coefficients.  
The function `func(w::Real)->Real` is used to remap the weight, expressed as `weight = func(weight)`; `p` represents the exponent of the power mean.
We set `weight = powermean(1*fontsize, wordlength*fontsize) = ((fontsize^p + (wordlength*fontsize)^p)/2) ^ (1/p)`.  
That is, `weight = fontsize * powermean(1, wordlength)`.  
Overall, this gives us `fontsize = func(weight) / powermean(1, wordlength)`.  
When p is -Inf, the power mean is the minimum value, resulting in `fontsize=weight`. 
When p is Inf, the power mean is the maximum value, resulting in `fontsize=weight/wordlength`.
When p is -1, the power mean is the harmonic mean. When p is 0, the power mean is the geometric mean, preserving the word area. 
When p is 1, the power mean is the arithmetic mean. When p is 2, the power mean is the root mean square, preserving the diagonal length.  
"""
rescaleweights(func=identity, p=0) = dict -> _rescaleweights(dict, func, p)

function _detect_language(text, language=:auto)
    language = langid(text)
    println("Language: $language")
    return language
end
function detect_language(text, language=:auto)
    language !== :auto && return StopWords.normcode(language)
    _detect_language(text, language)
end
function detect_language(text::IO, language=:auto)
    language !== :auto && return StopWords.normcode(language)
    p = position(text)
    l = _detect_language(text, language)
    seek(text, p)
    return l
end

@doc raw"""
Process the text, filter the words, and adjust the weights. Return a vector of words and a vector of weights.
## Positional Arguments
* text_or_counter: a string, a vector of words, an opened file (IO), a Dict{<:String, <:Real}, a Vector{Pair}, a Vector{Tuple}, or two Vectors.
## Optional Keyword Arguments
* language: language of the text, default is `:auto`. 
* stopwords: a set of words, default is `:auto` which means decided by language.  
* stopwords_extra: an additional set of stopwords. By setting this while keeping the `stopwords` argument as `:auto`, the built-in stopword list will be preserved.
* minlength, maxlength: minimum and maximum length of a word to be included
* minfrequency: minimum frequency of a word to be included
* maxnum: maximum number of words, default is 500
* minweight, maxweight: within 0 ~ 1, set to adjust extreme weight
* regexp: a regular expression to partially match and filter words. For example, `regexp=r"\S(?:[\s\S]*\S)?"` will trim whitespaces then eliminate empty words. This argument is not available when `text_or_counter` is a counter.
* process: a function to process word count dict, default is `rescaleweights(identity, 0) ∘ casemerge!`
"""
function processtext(counter::AbstractDict{<:AbstractString,<:Real};
    language=:auto,
    stopwords=:auto,
    stopwords_extra=nothing,
    minlength=1, maxlength=30,
    minfrequency=0,
    maxnum=500,
    minweight=:auto, maxweight=:auto,
    process=rescaleweights(identity, 0) ∘ casemerge!)

    language = detect_language(keys(counter), language)
    if !haskey(STOPWORDS, language)
        @warn "No built-in stopwords for $(language)!"
    end
    stopwords == :auto && (stopwords = get(STOPWORDS, language, nothing))
    stopwords === nothing && (stopwords = Set{String}())
    stopwords isa AbstractSet || (stopwords = Set(stopwords))
    stopwords_extra === nothing || (stopwords = stopwords ∪ stopwords_extra)
    counter = process(counter)
    print("Total words: $(round(sum(values(counter)), digits=2)). ")
    print("Unique words: $(length(counter)). ")
    for (w, c) in counter
        if (c < minfrequency
            || length(w) < minlength || length(w) > maxlength
            || w in stopwords || lowercase(w) in stopwords)
            delete!(counter, w)
        end
    end
    words = keys(counter) |> collect
    weights = values(counter) |> collect
    println("After filtration: $(length(words)).")
    maxnum = min(maxnum, length(weights))
    inds = partialsortperm(weights, 1:maxnum, rev=true)
    words = words[inds]
    weights = weights[inds]
    print("The top $(length(words)) words are kept. ")
    @assert !isempty(weights)
    weights = weights ./ sum(weights)
    minweight == :auto && (minweight = min(0.01, 1 / length(words)))
    maxweight == :auto && (maxweight = max(20minweight, 10 / length(words)))
    m = weights .> maxweight
    weights[m] .= log1p.(weights[m] .- maxweight) ./ 10 .+ maxweight
    weights .+= minweight
    nhuge = sum(m)
    if nhuge == 1
        print("The weight of the biggest word $(repr(only(words[m]))) has been reduced.")
    elseif nhuge > 1
        print("The weights of the biggest $nhuge words have been reduced.")
    end
    print("\n")
    words, weights
end

function processtext(text; language=:auto, kargs...)
    language = detect_language(text, language)
    cwkw = (:counter, :regexp)
    processtext(
        countwords(text; language=language, filter(kw -> first(kw) ∈ cwkw, kargs)...);
        language=language,
        filter(kw -> first(kw) ∉ cwkw, kargs)...)
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
        "<br>" => "\n",
        r"""<(?:[^>]*?=\s*(?:"[^"]*"|'[^']*'))*[^>]*>""" => " ",
    ]
    for p in patterns
        content = replace(content, p) # single pass not work
    end
    patterns = [
        "&nbsp;" => " ",
        "&quot;" => "\"",
        "&amp;" => "&",
        "&lt;" => "<",
        "&gt;" => ">",
        r"&#?\w{1,6};" => " ",
    ]
    replace(content, patterns...)
end
html2text(file::IO) = html2text(read(file, String))
end
