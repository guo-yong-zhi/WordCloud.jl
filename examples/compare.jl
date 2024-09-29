#md# ### First generate the wordcloud on the left  
using WordCloud

println("==Obama's==")
dens = 0.45 # not too high
wca = wordcloud(
    open(pkgdir(WordCloud) * "/res/Barack Obama's First Inaugural Address.txt"), 
    density=dens,
    backgroundcolor=:maskcolor,
    style=:uniform,
    ) |> generate!
#md# ### Then generate the wordcloud on the right      
println("==Trump's==")
wcb = wordcloud(
    open(pkgdir(WordCloud) * "/res/Donald Trump's Inaugural Address.txt");
    density=dens,
    getscheme(wca)...,
    state=identity, # disables the useless initialize! and layout! in advance
)
#md# Follow these steps to generate a wordcloud: initialize! -> layout! -> generate!
samewords = getwords(wca) ∩ getwords(wcb)
println(length(samewords), " same words")

for w in samewords
    setcolors!(wcb, w, getcolors(wca, w))
    setangles!(wcb, w, getangles(wca, w))
    setfonts!(wcb, w, getfonts(wca, w))
end
initialize!(wcb)

println("=ignore defferent words=")
keep(wcb, samewords) do
    @assert Set(wcb.words) == Set(samewords)
    centers = getpositions(wca, samewords, mode=getcenter)
    setpositions!(wcb, samewords, centers, mode=setcenter!) # manually initialize the position,
    setstate!(wcb, :layout!) # and set the state flag
    generate!(wcb, 1000, reposition=false, retry=1) # disables repositioning; retry=1 means no rescale
end

println("=pin same words=")
pin(wcb, samewords) do
    layout!(wcb, style=:uniform)
    generate!(wcb, 1000, retry=1) # enables repositioning while disabling rescaling
end

if getstate(wcb) != :generate!
    println("=overall tuning=")
    generate!(wcb, 1000, reposition=setdiff(getwords(wcb), samewords), retry=2) # only reposition the unique words
end

ma = paint(wca)
mb = paint(wcb)
h, w = size(ma)
println("results are saved in address_compare")
WordCloud.save("address_compare/compare.png", [ma mb])
#eval# try rm("address_compare", force=true, recursive=true) catch end 
gif = WordCloud.GIF("address_compare")
WordCloud.frame(wca, "Obama") |> gif
WordCloud.frame(wcb, "Trump") |> gif
WordCloud.Render.generate(gif, framerate=1)
wca, wcb
#eval# runexample(:compare)
#md# ![](address_compare/compare.png)  
#md# ![](address_compare/animation.gif)  
