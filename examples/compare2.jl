#md# This is a more symmetrical and accurate way to generate comparison wordclouds, but it may be more time consuming.  
#md# ### Prepare two wordcloud objects
using WordCloud

dens = 0.45 # not too high
wca = wordcloud(
    open(pkgdir(WordCloud) * "/res/Barack Obama's First Inaugural Address.txt"), 
    density=dens,
    backgroundcolor=:maskcolor,
    state=identity, # turn off the initialize! and layout! in advance
)
wcb = wordcloud(
    open(pkgdir(WordCloud) * "/res/Donald Trump's Inaugural Address.txt");
    density=dens,
    getscheme(wca)...,
    state=identity, 
)
#md# ### Make the same words the same style
samewords = getwords(wca) ∩ getwords(wcb)
println(length(samewords), " same words")
@assert !hasparameter(wca, :uniquewords)
@assert !hasparameter(wcb, :uniquewords)
setparameter!(wca, setdiff(getwords(wca), samewords), :uniquewords)
setparameter!(wcb, setdiff(getwords(wcb), samewords), :uniquewords)
for w in samewords
    setcolors!(wcb, w, getcolors(wca, w))
    setangles!(wcb, w, getangles(wca, w))
    setfonts!(wcb, w, getfonts(wca, w))
end
#md# ### Put the same words at same position
initialize!(wca)
initialize!(wcb)
keep(wca, samewords) do
    layout!(wca, style=:uniform)
    fit!(wca, 1000)
end
pin(wca, samewords) do
    layout!(wca, style=:uniform) # place other words
end
centers = getpositions(wca, samewords, mode=getcenter)
setpositions!(wcb, samewords, centers, mode=setcenter!) # manually initialize the position,
pin(wcb, samewords) do
    layout!(wcb, style=:uniform) # place other words
end
#md# ### Fit them all
function syncposition(samewords, pos, wca, wcb)
    pos2 = getpositions(wca, samewords, mode=getcenter)
    if pos != pos2
        setpositions!(wcb, samewords, pos2, mode=setcenter!)
        setstate!(wcb, :layout!)
    end
    pos2
end
function pinfit!(wc, samewords, ep1, ep2)
    pin(wc, samewords) do
        fit!(wc, ep1)
    end
    fit!(wc, ep2, reposition=getparameter(wc, :uniquewords)) # only reposition the unique words
end
pos = getpositions(wca, samewords, mode=getcenter)
while getparameter(wca, :epoch) < 2000 && getparameter(wcb, :epoch) < 2000
    global pos
    pinfit!(wca, samewords, 200, 50)
    pos = syncposition(samewords, pos, wca, wcb)
    pinfit!(wcb, samewords, 200, 50)
    pos = syncposition(samewords, pos, wcb, wca)
    if getstate(wca) == getstate(wcb) == :fit!
        break
    end
end
println("Takes $(getparameter(wca, :epoch)) and $(getparameter(wcb, :epoch)) epochs")
WordCloud.printcollisions(wca)
WordCloud.printcollisions(wcb)
#md# 
ma = paint(wca)
mb = paint(wcb)
h, w = size(ma)
println("results are saved in address_compare2")
WordCloud.save("address_compare2/compare2.png", [ma mb])
#eval# try rm("address_compare2", force=true, recursive=true) catch end 
gif = WordCloud.GIF("address_compare2")
WordCloud.frame(wca, "Obama") |> gif
WordCloud.frame(wcb, "Trump") |> gif
WordCloud.Render.generate(gif, framerate=1)
wca, wcb
#eval# runexample(:compare2)
#md# ![](address_compare2/compare2.png)  
#md# ![](address_compare2/animation.gif)  
