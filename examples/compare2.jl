#md# This is a more symmetrical and accurate way to generate comparison wordclouds, but it may be more time consuming.  
#md# ### Prepare two wordcloud objects
using WordCloud

stwords = ["us", "will"];
cs = WordCloud.randomscheme() #:Set1_8#
as = WordCloud.randomangles() #(0,90,45,-45)#
dens = 0.5 #not too high
wca = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/Barack Obama's First Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords), 
    colors = cs,
    angles = as,
    density = dens,
    run = x->nothing, #turn off the initimage! and placement! in advance
)
wcb = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/Donald Trump's Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords),
    mask = getsvgmask(wca),
    colors = cs,
    angles = as,
    density = dens,
    run = x->nothing, 
)
#md# ### Make the same words the same style
samewords = getwords(wca) ∩ getwords(wcb)
println(length(samewords), " same words")
for w in samewords
    setcolors!(wcb, w, getcolors(wca, w))
    setangles!(wcb, w, getangles(wca, w))
end
#md# ### Put the same words at same position
initimages!(wca)
initimages!(wcb)
keep(wca, samewords) do
    placement!(wca)
    fit!(wca, 1000) #patient=-1 means no teleport; retry=1 means no rescale
end
pin(wca, samewords) do
    placement!(wca) #place other words
end
centers = getpositions(wca, samewords, type=getcenter)
setpositions!(wcb, samewords, centers, type=setcenter!) #manually initialize the position,
pin(wcb, samewords) do
    placement!(wcb) #place other words
end
#md# ### Fit them all
function syncposition(samewords, pos, wca, wcb)
    pos2 = getpositions(wca, samewords, type=getcenter)
    if pos != pos2
        setpositions!(wcb, samewords, pos2, type=setcenter!)
        setstate!(wcb, :placement!)
    end
    pos2
end
function pinfit!(wc, samewords, ep1, ep2)
    pin(wc, samewords) do
        fit!(wc, ep1)
    end
    fit!(wc, ep2, patient=-1) #patient=-1 means no teleport
end
pos = getpositions(wca, samewords, type=getcenter)
while wca.params[:epoch] < 2000
    global pos
    pinfit!(wca, samewords, 200, 50)
    pos = syncposition(samewords, pos, wca, wcb)
    pinfit!(wcb, samewords, 200, 50)
    pos = syncposition(samewords, pos, wcb, wca)
    if getstate(wca) == getstate(wcb) == :fit!
        break
    end
end
println("Takes $(wca.params[:epoch]) and $(wcb.params[:epoch]) epochs")
WordCloud.printcollisions(wca)
WordCloud.printcollisions(wcb)
#md# 
ma = paint(wca)
mb = paint(wcb)
h,w = size(ma)
space = fill(mb[1], (h, w÷20))
try mkdir("address_compare2") catch end
println("results are saved in address_compare2")
WordCloud.save("address_compare2/compare2.png", [ma space mb])
#eval# try rm("address_compare2", force=true, recursive=true) catch end 
gif = WordCloud.GIF("address_compare2")
record(wca, "Obama", gif)
record(wcb, "Trump", gif)
WordCloud.Render.generate(gif, framerate=1)
wca, wcb
#eval# runexample(:compare2)
#md# ![](address_compare2/compare2.png)  
#md# ![](address_compare2/result.gif)  
