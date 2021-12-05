#md# This animation shows how the initial layout is generated.
using WordCloud
stopwords = WordCloud.stopwords_en ∪ ["said"]
textfile = pkgdir(WordCloud)*"/res/alice.txt"
wc = wordcloud(
    processtext(open(textfile), stopwords=stopwords, maxnum=120), 
    masksize = (300, 200),
    outline = 3,
    angles = 0:90,
    density = 0.55,
    state = initwords!)
#md# ### uniform style
gifdirectory = "animation1_placewords/uniform"
#eval# try rm("animation1_placewords/uniform", force=true, recursive=true) catch end 
setpositions!(wc, :, (-1000,-1000))
WordCloud.placewords_animation!(wc, outputdir=gifdirectory, style=:uniform)
#md# ![](animation1_placewords/uniform/result.gif)  
#md# ### gathering style
gifdirectory = "animation1_placewords/gathering"
#eval# try rm("animation1_placewords/gathering", force=true, recursive=true) catch end 
setpositions!(wc, :, (-1000,-1000))
WordCloud.placewords_animation!(wc, outputdir=gifdirectory, style=:gathering)
#md# ![](animation1_placewords/gathering/result.gif)  
#md# 
println("results are saved in animation1_placewords")
wc
#eval# runexample(:animation1_placewords)