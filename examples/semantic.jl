#md# ### Words
using WordCloud
words_weights = processtext(open(pkgdir(WordCloud) * "/res/Barack Obama's First Inaugural Address.txt"))
words_weights = Dict(zip(words_weights...))
#md# ### Embedding
#md# The positions of words can be initialized with pre-trained word vectors so that similar words will appear near each other.
using Embeddings
using TSne
const EMB = load_embeddings(GloVe{:en})
const WORDS_INDICES = Dict(word => ii for (ii, word) in enumerate(EMB.vocab))
function get_embedding(word)
    ind = WORDS_INDICES[word]
    emb = EMB.embeddings[:,ind]
    return emb
end
wordvec = Dict()
for k in keys(words_weights)
    if k in keys(WORDS_INDICES)
        wordvec[k] = get_embedding(k)
    elseif lowercase(k) in keys(WORDS_INDICES)
        wordvec[k] = get_embedding(lowercase(k))
    else
        pop!(words_weights, k)
        println("remove ", k)
    end
end
words = keys(wordvec) |> collect
vectors = hcat(values(wordvec)...)
embedded = tsne(vectors', 2)
#md# 
wc = wordcloud(
    words_weights,
    mask=box,
    masksize=(1000, 1000),
    cornerradius=0,
    density=0.3,
    colors=0.3,
    backgroundcolor=:maskcolor,
    state=initialize!,
    # angles = (0, 45), fonts = "Eras Bold ITC", maskcolor=0.98,
)

pos = embedded
mean = sum(pos, dims=1) / size(pos, 1)
r = maximum(sqrt.(pos[:,1].^2 + pos[:,2].^2))
pos = (pos .- mean) ./ 2r
sz = collect(reverse(size(wc.mask)))'
sz0 = collect(getparameter(wc, :masksize)[1:2])'
pos = round.(Int, pos .* sz0 .+ sz ./ 2)

setpositions!(wc, words, eachrow(pos), mode=setcenter!)
setstate!(wc, :layout!)
generate!(wc, reposition=false)
paint(wc, "semantic_embedding.png")
#md# ![](semantic_embedding.png)  
#md# ### Clustering
#md# Words can be further colored according to semantic clustering
using Clustering
V = embedded
G = V * V'
H = sum(V.^2, dims=2)
D = max.(0, (H .+ H' .- 2G))
D ./= sum(D) / length(D)
D .= .√D # the distance matrix
tree = hclust(D, linkage=:ward)
lb = cutree(tree, h=3, k=8)
println("$(length(lb)) words are divided into $(length(unique(lb))) groups")
#md# 
colors = ascolor(:seaborn_dark)
setcolors!(wc, words, colors[lb .% length(colors) .+ 1])
recolor!(wc, style=:reset)
paint(wc, "semantic_clustering.png")
#md# ![](semantic_clustering.png)  
wc
#eval# runexample(:semantic)
