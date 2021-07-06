#md# The positions of words can be initialized with pre-trained word vectors.
#md# ### Words
using WordCloud
stwords = ["us", "will"];
words_weights = processtext(open(pkgdir(WordCloud)*"/res/Barack Obama's First Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords)
words_weights = Dict(zip(words_weights...))
#md# ### Embeddings
using Embeddings
using TSne
const embtable = load_embeddings(GloVe{:en})
const get_word_index = Dict(word=>ii for (ii,word) in enumerate(embtable.vocab))
function get_embedding(word)
    ind = get_word_index[word]
    emb = embtable.embeddings[:,ind]
    return emb
end
wordvec = Dict()
for k in keys(words_weights)
    if k in keys(get_word_index)
        wordvec[k] = get_embedding(k)
    elseif lowercase(k) in keys(get_word_index)
        wordvec[k] = get_embedding(lowercase(k))
    else
        pop!(words_weights, k)
        println("remove ", k)
    end
end
embedded = tsne(hcat(values(wordvec)...)', 2)
#md# ### WordCloud
wc = wordcloud(
    words_weights,
    maskshape = box,
    masksize = (1000, 1000, 0),
    run = initimages!
)

pos = embedded
mean = sum(pos, dims=1) / size(pos, 1)
r = maximum(sqrt.(pos[:,1].^2 + pos[:,2].^2 ))
pos = (pos .- mean) ./ 2r
sz = collect(size(wc.mask))'
pos = round.(Int, pos .* sz .+ sz ./ 2)

setpositions!(wc, keys(wordvec)|>collect, eachrow(pos), type=setcenter!)
setstate!(wc, :placement!)
generate!(wc, teleporting=false)
println("results are saved to embedding.png")
paint(wc, "embedding.png")
wc
#eval# runexample(:embedding)
#md# ![](embedding.png)  
