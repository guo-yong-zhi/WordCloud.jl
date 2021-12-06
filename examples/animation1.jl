#md# This animation shows how the initial layout is generated.
using WordCloud
stopwords = WordCloud.stopwords_en ∪ ["said"]
textfile = pkgdir(WordCloud)*"/res/alice.txt"
wc = wordcloud(
    processtext(open(textfile), stopwords=stopwords, maxnum=300), 
    masksize = (300, 200),
    outline = 3,
    angles = 0:90,
    state = initwords!)
#md# ### uniform style
gifdirectory = "animation1/uniform"
setpositions!(wc, :, (-1000,-1000))
record(placewords!, wc, style=:uniform, outputdir=gifdirectory, filter=i->i%(2^(i÷100))==0)
#md# ![](animation1/uniform/result.gif)  
#md# ### gathering style
gifdirectory = "animation1/gathering"
setpositions!(wc, :, (-1000,-1000))
record(placewords!, wc, style=:gathering, outputdir=gifdirectory, filter=i->i%(2^(i÷100))==0)
#md# ![](animation1/gathering/result.gif)  
#md# 
println("results are saved in animation1")
wc
#eval# runexample(:animation1)