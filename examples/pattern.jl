using WordCloud

sc = WordCloud.randomscheme()
l = 200
#`words` & `weights` just as placeholders
# style arguments like `colors`, `angles` and `fillingrate` have no effect
wc = wordcloud(
    repeat(["placeholder"], l), repeat([1], l), 
    mask = shape(box, 400, 300, color=WordCloud.chooseabgcolor(sc)),
    transparentcolor = (0,0,0,0),
    run=x->x)

# manually initialize images for the placeholders, instead of calling `initimages!`
## svg version
#shapes = [shape(ellipse, repeat([floor(20expm1(rand())+5)],2)..., color=rand(sc)) for i in 1:l]
#setsvgimages!(wc, :, shapes)
## bitmap version
shapes = WordCloud.svg2bitmap.([shape(ellipse, repeat([floor(15expm1(rand())+5)],2)..., color=rand(sc)) for i in 1:l])
setimages!(wc, :, shapes)

setstate!(wc, :initimages!) #set the state flag after manual initialization
# generate_animation!(wc, retry=1, outputdir="pattern_animation")
generate!(wc, retry=1) #turn off rescale attempts. manually set images can't be rescaled
println("results are saved to pattern.png")
paint(wc, "pattern.png")
wc
#eval# runexample(:pattern)
#md# ![](pattern.png)  