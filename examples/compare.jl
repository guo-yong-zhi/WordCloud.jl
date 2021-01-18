using WordCloud

stwords = ["us", "will"];

println("==Obama's==")
cs = WordCloud.randomscheme()
as = WordCloud.randomangles()
fr = 0.65 #not too high
wca = wordcloud(
    process(open(pkgdir(WordCloud)*"/res/Barack Obama's First Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords), 
    colors = cs,
    angles = as,
    fillingrate = fr) |> generate!

println("==Trump's==")
wcb = wordcloud(
    process(open(pkgdir(WordCloud)*"/res/Donald Trump's Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords),
    mask = getmask(wca),
    colors = cs,
    angles = as,
    fillingrate = fr,
    run = x->nothing, #turn off the useless initword! and placement! in advance
)

samewords = getword(wca) ∩ getword(wcb)
println(length(samewords), " same words")

for w in samewords
    setcolor!(wcb, w, getcolor(wca, w))
    setangle!(wcb, w, getangle(wca, w))
end
#Follow these steps to generate result: initword! -> placement! -> generate!
initword!(wcb)

println("=ignore defferent words=")
ignore(wcb, getword(wcb) .∉ Ref(samewords)) do
    @assert Set(wcb.words) == Set(samewords)
    centers = getposition.(wca, samewords, type=getcenter)
    setposition!.(wcb, samewords, centers, type=setcenter!) #manually initialize the position,
    setstate!(wcb, :placement!) #and set the state flag
    generate!(wcb, 1000, patient=-1, retry=1) #patient=-1 means no teleport; retry=1 means no rescale
end

println("=pin same words=")
pin(wcb, samewords) do
    placement!(wcb)
    generate!(wcb, 1000, retry=1) #allow teleport but don‘t allow rescale
end

if getstate(wcb) != :generate!
    println("=overall tuning=")
    generate!(wcb, 1000, patient=-1, retry=2) #allow rescale but don‘t allow teleport
end

ma = paint(wca)
mb = paint(wcb)
h,w = size(ma)
space = fill(mb[1], (h, w÷20))
try mkdir("address_compare") catch end
println("save results to address_compare")
WordCloud.ImageMagick.save("address_compare/compare.png", [ma space mb])

gif = WordCloud.GIF("address_compare")
record(wca, "Obama", gif)
record(wcb, "Trump", gif)
WordCloud.Render.generate(gif, framerate=1)
wca, wcb