using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"], maxweight=1, maxnum=300), 
    # mask = padding(WordCloud.svg2bitmap(shape(ellipse, 600, 500, color=(0.98, 0.97, 0.99), backgroundcolor=0.97)), 0.1),
    mask = shape(ellipse, 600, 500, color=(0.98, 0.97, 0.99), backgroundcolor=0.97, backgroundsize=(700, 550)),
    colors = :seaborn_icefire_gradient,
    angles = -90:90,
    run=x->x, #turn off the useless initimage! and placement! in advance
)

setwords!(wc, "Alice", "Alice in Wonderland") # replace the word 'Alice' with 'Alice in Wonderland'
setangles!(wc, "Alice in Wonderland", 0) # make it horizontal
setcolors!(wc, "Alice in Wonderland", "purple");
setfontsizes!(wc, "Alice in Wonderland", size(wc.mask, 2)/length("Alice in Wonderland"))
initimage!(wc, "Alice in Wonderland")
r = size(wc.mask, 2)/size(getimages(wc, "Alice in Wonderland"), 2) * 0.95
setfontsizes!(wc, "Alice in Wonderland", r*size(wc.mask, 2)/length("Alice in Wonderland")) # set a big font size
initimage!(wc, "Alice in Wonderland") # init it after adjust it's style
setpositions!(wc, "Alice in Wonderland", reverse(size(wc.mask)) .÷ 2, type=setcenter!) # center it

pin(wc, "Alice in Wonderland") do
    initimages!(wc) #init inside `pin` to reset the size of other words
    generate!(wc)
end

println("results are saved to specifiedstyle.svg")
paint(wc, "specifiedstyle.svg")
wc
#eval# runexample(:specifiedstyle)
#md# ![](specifiedstyle.svg)  