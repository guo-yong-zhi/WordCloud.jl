using WordCloud

stwords = ["us", "will"];
println("Obama's")
cs = WordCloud.randomscheme()
as = WordCloud.randomangles()
fr = 0.6 #not too high
wca = wordcloud(
    process(open("res/Barack Obama's First Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords), 
    colors = cs,
    angles = as,
    filling_rate = fr) |> generate!
println("Trump's")
tb, wb = process(open("res/Donald Trump's Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords)
samemask = tb .∈ Ref(wca.words)
println(sum(samemask), " same words")
csb = Iterators.take(WordCloud.iter_expand(cs), length(tb)) |> collect
asb = Iterators.take(WordCloud.iter_expand(as), length(tb)) |> collect
wainds = Dict(zip(wca.words, Iterators.countfrom(1)))
for i in 1:length(tb)
    if samemask[i]
        ii = wainds[tb[i]]
        csb[i] = wca.params[:colors][ii]
        asb[i] = wca.params[:angles][ii]
    end
end
wcb = wordcloud(
    (tb,wb), 
    mask = wca.mask,
    colors = csb,
    angles = asb,
    filling_rate = fr)
for i in 1:length(tb)
    if samemask[i]
        ii = wainds[tb[i]]
        cxy = WordCloud.QTree.center(wca.qtrees[ii])
        WordCloud.QTree.setcenter!(wcb.qtrees[i], cxy)
    end
end
println("ignore defferent words")
ignore(wcb, .!samemask) do
    generate!(wcb, 1000, patient=-1, retry=1) #patient=-1 means no teleport; retry=1 means no rescale
end
println("pin same words")
pin(wcb, samemask) do
    placement!(wcb)
    generate!(wcb, 1000, retry=1) #allow teleport but don‘t allow rescale
end
println("overall tuning")
generate!(wcb, 1000, patient=-1, retry=2) #allow rescale but don‘t allow teleport

ma = paint(wca)
mb = paint(wcb)
h,w = size(ma)
space = loadmask(shape(box, w÷20, h))
space .= WordCloud.ARGB(0,0,0,0)
WordCloud.ImageMagick.save("compare.png", [ma space mb])