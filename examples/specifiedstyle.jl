using WordCloud
wc = wordcloud(
    processtext(open("res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"], maxweight=1, maxnum=300), 
    mask = padding(shape(ellipse, 600, 500, color=(0.98, 0.97, 0.99), bgcolor=0.97), 0.1),
    colors = :seaborn_dark,
    angles = -90:90,
    run=x->x, #turn off the useless initword! and placement! in advance
)

setword!(wc, "Alice", "Alice in Wonderland") # replace the word 'Alice' with 'Alice in Wonderland'
setangle!(wc, "Alice in Wonderland", 0) # make it horizontal
setcolor!(wc, "Alice in Wonderland", "purple");
initword!(wc, "Alice in Wonderland", 2size(wc.mask, 2)/length("Alice in Wonderland")) # set a big font size
setposition!(wc, 1, reverse(size(wc.mask)) .÷ 2, type=setcenter!) # center it

pin(wc, "Alice in Wonderland") do
    initwords!(wc) #init inside `pin` to reset the size of other words
    generate!(wc)
end

println("results are saved to specifiedstyle.png")
paint(wc, "specifiedstyle.png")
wc