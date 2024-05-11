using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud) * "/res/alice.txt"), maxweight=1, maxnum=300), 
    # mask = pad(WordCloud.tobitmap(shape(ellipse, 600, 500, color=(0.98, 0.97, 0.99), backgroundcolor=0.97)), 0.1),
    mask=shape(ellipse, 600, 500, color=(0.98, 0.97, 0.99), backgroundcolor=0.97, backgroundsize=(700, 550)),
    masksize=:original,
    colors=:seaborn_icefire_gradient,
    angles=-90:90,
    state=identity, # turn off the useless initialize! and layout! in advance
)

setwords!(wc, "Alice", "Alice in Wonderland") # replace the word 'Alice' with 'Alice in Wonderland'
setangles!(wc, "Alice in Wonderland", 0) # make it horizontal
setcolors!(wc, "Alice in Wonderland", "purple");
setfontsizes!(wc, "Alice in Wonderland", size(wc.mask, 2) / length("Alice in Wonderland"))
initialize!(wc, "Alice in Wonderland")
r = size(wc.mask, 2) / size(getimages(wc, "Alice in Wonderland"), 2) * 0.95
setfontsizes!(wc, "Alice in Wonderland", r * size(wc.mask, 2) / length("Alice in Wonderland")) # set a big font size
initialize!(wc, "Alice in Wonderland") # init it after adjust it's style
setpositions!(wc, "Alice in Wonderland", reverse(size(wc.mask)) .÷ 2, mode=setcenter!) # center it

pin(wc, "Alice in Wonderland") do
    initialize!(wc) # init inside `pin` to reset the size of other words
    generate!(wc)
end

println("results are saved to custom.svg")
paint(wc, "custom.svg")
wc
#eval# runexample(:custom)
#md# ![](custom.svg)  