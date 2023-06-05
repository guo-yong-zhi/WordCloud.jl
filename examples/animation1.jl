#md# This animation shows how the initial layout is generated.
using WordCloud
stopwords = WordCloud.stopwords_en ∪ ["said"]
textfile = pkgdir(WordCloud)*"/res/alice.txt"
wc = wordcloud(
    processtext(open(textfile), stopwords=stopwords, maxnum=300), 
    masksize = (300, 200),
    outline = 3,
    angles = 0:90,
    state = initialize!)
#md# ### uniform style
gifdirectory = "animation1/uniform"
setpositions!(wc, :, (-1000,-1000))
@record gifdirectory overwrite=true filter=i->i%(2^(i÷100))==0 layout!(wc, style=:uniform)
#md# ![](animation1/uniform/animation.gif)  
#md# ### gathering style
gifdirectory = "animation1/gathering"
setpositions!(wc, :, (-1000,-1000))
@record gifdirectory overwrite=true filter=i->i%(2^(i÷100))==0 layout!(wc, style=:gathering)
#md# ![](animation1/gathering/animation.gif)  
#md# 
println("results are saved in animation1")
wc
#eval# runexample(:animation1)