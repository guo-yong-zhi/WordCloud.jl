using WordCloud
wc = wordcloud(
    process(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"], maxweight=1, maxnum=200), 
    mask = padding(shape(ellipse, 600, 500, color=(0.98, 0.97, 0.99), bgcolor=0.97), 0.1),
    colors = (WordCloud.colorschemes[:seaborn_dark].colors..., ),
    angles = -90:90,
    run=x->x, #turn off the useless initword! and placement! in advance
)

setangle!(wc, "Alice", 0)
setcolor!(wc, "Alice", "purple");
initword!(wc, "Alice", 2size(wc.mask, 2)/length("Alice"))
setposition!(wc, "Alice", reverse((size(wc.mask) .- size(getimage(wc, "Alice"))) .÷ 2))

pin(wc, "Alice") do
    initword!(wc)
    generate!(wc)
end
paint(wc, "specifystyle.png")
wc