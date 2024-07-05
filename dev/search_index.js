var documenterSearchIndex = {"docs":
[{"location":"#WordCloud.jl-Documentation","page":"Index","title":"WordCloud.jl Documentation","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"","category":"page"},{"location":"","page":"Index","title":"Index","text":"CurrentModule = WordCloud\nDocTestSetup = quote\n    using WordCloud\nend","category":"page"},{"location":"#Adding-WordCloud.jl","page":"Index","title":"Adding WordCloud.jl","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"using Pkg\nPkg.add(\"WordCloud\")","category":"page"},{"location":"#Documentation","page":"Index","title":"Documentation","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"Modules = [WordCloud, WordCloud.TextProcessing, WordCloud.Render]","category":"page"},{"location":"#WordCloud.WordCloud","page":"Index","title":"WordCloud.WordCloud","text":"The WordCloud.jl package is a flexible, faithful and efficient word cloud generator in Julia.\n\nusing WordCloud\nwc = wordcloud(\"It's easy to generate a beautiful word cloud.\") |> generate!\npaint(wc, \"wordcloud.svg\")\n\nPlease visit the repository at: https://github.com/guo-yong-zhi/WordCloud.jl\n\n\n\n\n\n","category":"module"},{"location":"#WordCloud.fit!-Tuple{Any, Vararg{Any}}","page":"Index","title":"WordCloud.fit!","text":"Positional Arguments\n\nwc: the word cloud object generated by the wordcloud function, which needs to be fitted.\nepochs: the number of training epochs\n\nKeyword Arguments\n\npatience: the number of epochs before repositioning\nreposition: a boolean value that determines whether repositioning is enabled or disabled. Additionally, it can accept a float value p (0 ≤ p ≤ 1) to indicate the repositioning ratio, an integer value n to specify the minimum index for repositioning, a function index::Int -> repositionable::Bool to customize the repositioning behavior, or a whitelist for specific indexes.\ntrainer: specify a training engine\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.generate!-Tuple{WordCloud.WC, Vararg{Any}}","page":"Index","title":"WordCloud.generate!","text":"Positional Arguments\n\nwc: the word cloud object generated by the wordcloud function, which needs to be fitted.\nepochs: the number of training epochs\n\nKeyword Arguments\n\nretry: the number of attempts for shrinking and retraining, default is 3; set to 1 to disable shrinking\npatience: the number of epochs before repositioning\nreposition: a boolean value that determines whether repositioning is enabled or disabled. Additionally, it can accept a float value p (0 ≤ p ≤ 1) to indicate the repositioning ratio, an integer value n to specify the minimum index for repositioning, a function index::Int -> repositionable::Bool to customize the repositioning behavior, or a whitelist for specific indexes.\ntrainer: specify a training engine\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.getangles","page":"Index","title":"WordCloud.getangles","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.getcolors","page":"Index","title":"WordCloud.getcolors","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.getfonts","page":"Index","title":"WordCloud.getfonts","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.getfontsizes","page":"Index","title":"WordCloud.getfontsizes","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.getimages","page":"Index","title":"WordCloud.getimages","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.getpositions","page":"Index","title":"WordCloud.getpositions","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values. The keyword argument mode can be either getshift or getcenter.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.getsvgimages","page":"Index","title":"WordCloud.getsvgimages","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.getweights","page":"Index","title":"WordCloud.getweights","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.getwords","page":"Index","title":"WordCloud.getwords","text":"This function accepts two positional arguments: a wordcloud object and an index. The index can be a string, number, list, or any other supported type of index. The index argument is optional, and omitting it will retrieve all the values.\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.ignore-Tuple{Any, WordCloud.WC, AbstractArray{Bool}}","page":"Index","title":"WordCloud.ignore","text":"Exclude specific words as if they do not exist, and then execute the function. It functions as the opposite of keep.\n\nignore(fun, wc, ws::String) # ignore a word\nignore(fun, wc, ws::Set{String}) # ignore all words in ws\nignore(fun, wc, ws::Vector{String}) # ignore all words in ws\nignore(fun, wc, inds::Union{Integer, Vector{Integer}})\nignore(fun, wc::WC, mask::AbstractArray{Bool}) # ignore words. The mask must have the same length as wc\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.initialize!-Tuple{Any, Integer}","page":"Index","title":"WordCloud.initialize!","text":"Initialize the images and other resources associated with words using the specified style.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.keep-Tuple{Any, WordCloud.WC, AbstractArray{Bool}}","page":"Index","title":"WordCloud.keep","text":"Retain specific words and ignore the rest, and then execute the function. It functions as the opposite of ignore.\n\nkeep(fun, wc, ws::String) # keep a word\nkeep(fun, wc, ws::Set{String}) # keep all words in ws\nkeep(fun, wc, ws::Vector{String}) # keep all words in ws\nkeep(fun, wc, inds::Union{Integer, Vector{Integer}})\nkeep(fun, wc::WC, mask::AbstractArray{Bool}) # keep words. The mask must have the same length as wc\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.layout!-Tuple{WordCloud.WC}","page":"Index","title":"WordCloud.layout!","text":"The layout! function is employed to establish an initial layout for the word cloud.\n\nlayout!(wc)\nlayout!(wc, style=:uniform)\nlayout!(wc, style=:gathering)\nlayout!(wc, style=:gathering, level=5) # The level parameter controls the intensity of gathering, typically ranging from 4 to 6. The default value is 5.\nlayout!(wc, style=:gathering, level=6, rt=0) # rt=0 for rectangle, rt=1 for ellipse, rt=2 for rhombus. The default value is 1.  \n\nThere is also a keyword argument centralword available. For example, centralword=1, centralword=\"Alice\" or centralword=false. When you have set style=:gathering, you should also disable repositioning in generate!, especially for big words. For example, generate!(wc, reposition=0.7). The keyword argument reorder is a function used to reorder the words, which affects the order of placement. For example, you can use reverse or WordCloud.shuffle.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.loadmask-Tuple{AbstractMatrix{<:ColorTypes.TransparentColor{C, T, 4} where {C<:ColorTypes.AbstractRGB, T}}, Vararg{Any}}","page":"Index","title":"WordCloud.loadmask","text":"Load an image as a mask, recolor it, or resize it, among other options.\n\nExamples\n\nloadmask(open(\"res/heart.jpg\"), 256, 256) # resize to 256*256  \nloadmask(\"res/heart.jpg\", ratio=0.3) # scaled by 0.3  \nloadmask(\"res/heart.jpg\", color=\"red\", ratio=2) # set forecolor  \nloadmask(\"res/heart.jpg\", transparent=rgba->maximum(rgba[1:3])*(rgba[4]/255)>128) # set transparent using a Function \nloadmask(\"res/heart.jpg\", color=\"red\", transparent=(1,1,1)) # set forecolor and transparent  \nloadmask(\"res/heart.svg\") # only a subset of arguments is supported\n\npadding: an Integer or a tuple of two Integers.   For other keyword arguments like outline, linecolor, and smoothness, refer to the function outline.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.paint-Tuple{WordCloud.WC, Vararg{Any}}","page":"Index","title":"WordCloud.paint","text":"Examples\n\npaint(wc::WC)\npaint(wc::WC, background=false) # without background\npaint(wc::WC, background=outline(wc.mask)) # use a different background\npaint(wc::WC, ratio=0.5) # resize the output\npaint(wc::WC, \"result.png\", ratio=0.5) # save as png file\npaint(wc::WC, \"result.svg\") # save as svg file\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.paintsvg-Tuple{WordCloud.WC}","page":"Index","title":"WordCloud.paintsvg","text":"Similar to paint, but exports SVG\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.pin-Tuple{Any, WordCloud.WC, AbstractArray{Bool}}","page":"Index","title":"WordCloud.pin","text":"Fix specific words as if they were part of the background, and then execute the function.\n\npin(fun, wc, ws::String) # pin an single  word\npin(fun, wc, ws::Set{String}) # pin all words in ws\npin(fun, wc, ws::Vector{String}) # pin all words in ws\npin(fun, wc, inds::Union{Integer, Vector{Integer}})\npin(fun, wc::WC, mask::AbstractArray{Bool}) # pin words. # pin words. The mask must have the same length as wc.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.recolor!-Tuple{Any, Vararg{Any}}","page":"Index","title":"WordCloud.recolor!","text":"Recolor the words according to the pixel color in the background image. The styles supported are :average, :main, :clipping, :blending, and :reset (to undo all effects of the other styles).\n\nExamples\n\nrecolor!(wc, style=:average)\nrecolor!(wc, style=:main)\nrecolor!(wc, style=:clipping, background=blur(getmask(wc))) # The background parameter is optional\nrecolor!(wc, style=:blending, alpha=0.3) # The alpha parameter is optional\nrecolor!(wc, style=:reset)\n\nThe effects of :average, :main, and :clipping are determined solely by the background.  However, the effect of :blending is also influenced by the previous color of the word.  Therefore, :blending can also be used in combination with other styles.  The results of clipping and blending cannot be exported as SVG files; PNG should be used instead.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.rescale!-Tuple{WordCloud.WC, Real}","page":"Index","title":"WordCloud.rescale!","text":"rescale!(wc::WC, ratio::Real)\n\nResize all words proportionally. Use a ratio < 1 to shrink the size, and a ratio > 1 to expand the size.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.runexample","page":"Index","title":"WordCloud.runexample","text":"Available values: [:alice, :animation1, :animation2, :benchmark, :compare, :compare2, :custom, :fromweb, :gathering, :highdensity, :japanese, :juliadoc, :languages, :lettermask, :logo, :nomask, :outline, :pattern, :qianziwen, :random, :recolor, :semantic, :series, :中文]\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.setangles!-Tuple{WordCloud.WC, Any, Union{Number, AbstractVector{<:Number}}}","page":"Index","title":"WordCloud.setangles!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setcolors!-Tuple{WordCloud.WC, Any, Any}","page":"Index","title":"WordCloud.setcolors!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setfontcandidates!-Tuple{AbstractString, Any}","page":"Index","title":"WordCloud.setfontcandidates!","text":"setfontcandidates!(lang::AbstractString, str_set)\n\nCustomize font candidates for language lang\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setfonts!-Tuple{WordCloud.WC, Any, Union{AbstractString, AbstractVector{<:AbstractString}}}","page":"Index","title":"WordCloud.setfonts!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setfontsizes!-Tuple{WordCloud.WC, Any, Union{Number, AbstractVector{<:Number}}}","page":"Index","title":"WordCloud.setfontsizes!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setimages!-Tuple{WordCloud.WC, Any, AbstractMatrix}","page":"Index","title":"WordCloud.setimages!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setpositions!-Tuple{WordCloud.WC, Any, Any}","page":"Index","title":"WordCloud.setpositions!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index. The keyword argument mode can be either setshift! or setcenter!.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setsvgimages!-Tuple{WordCloud.WC, Any, Any}","page":"Index","title":"WordCloud.setsvgimages!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setweights!-Tuple{WordCloud.WC, Any, Union{Number, AbstractVector{<:Number}}}","page":"Index","title":"WordCloud.setweights!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.setwords!-Tuple{WordCloud.WC, Any, Union{AbstractString, AbstractVector{<:AbstractString}}}","page":"Index","title":"WordCloud.setwords!","text":"This function accepts three positional arguments: a wordcloud object, an index, and a value. The index can be a string, number, list, or any other supported type of index.\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.showexample","page":"Index","title":"WordCloud.showexample","text":"Available values: [:alice, :animation1, :animation2, :benchmark, :compare, :compare2, :custom, :fromweb, :gathering, :highdensity, :japanese, :juliadoc, :languages, :lettermask, :logo, :nomask, :outline, :pattern, :qianziwen, :random, :recolor, :semantic, :series, :中文]\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.wordcloud-Tuple{Tuple}","page":"Index","title":"WordCloud.wordcloud","text":"Positional Arguments\n\nThe positional arguments are used to specify words and weights in various forms, such as Tuple or Dict.\n\nwords::AbstractVector{<:AbstractString}, weights::AbstractVector{<:Real}\nwords_weights::Tuple\ncounter::AbstractDict\ncounter::AbstractVector{<:Pair}\n\nOptional Keyword Arguments\n\ntext-related keyword arguments\n\nFor more sophisticated text processing, please utilize the function processtext.\n\nlanguage: language of the text, default is :auto. \nstopwords: a set of words, default is :auto which means decided by language.  \nstopwords_extra: an additional set of stopwords. By setting this while keeping the stopwords argument as :auto, the built-in stopword list will be preserved.\nmaxnum: maximum number of words, default is 500\n\nstyle-related keyword arguments\n\ncolors = \"black\" # same color for all words  \ncolors = (\"black\", (0.5,0.5,0.7), \"yellow\", \"#ff0000\", 0.2) # entries are randomly chosen  \ncolors = [\"black\", (0.5,0.5,0.7), \"yellow\", \"red\", (0.5,0.5,0.7), 0.2, ......] # elements are used in a cyclic manner  \ncolors = :seaborn_dark # Using a preset scheme. See WordCloud.colorschemes for all supported Symbols. WordCloud.displayschemes() may be helpful.\nangles = 0 # same angle for all words  \nangles = (0, 90, 45) # randomly select entries  \nangles = 0:180 # randomly select entries  \nangles = [0, 22, 4, 1, 100, 10, ......] # use elements in a cyclic manner  \nfonts = \"Serif Bold\" # same font for all words  \nfonts = (\"Arial\", \"Times New Roman\", \"Tahoma\") # randomly select entries  \nfonts = [\"Arial\", \"Times New Roman\", \"Tahoma\", ......] # use elements in a cyclic manner  \ndensity = 0.55 # default is 0.5  \nspacing = 1  # minimum spacing between words, default is 2\n\nmask-related keyword arguments\n\nmask = loadmask(\"res/heart.jpg\", 256, 256) # refer to the documentation of loadmask  \nmask = loadmask(\"res/heart.jpg\", color=\"red\", ratio=2) # refer to the documentation of loadmask\nmask = \"res/heart.jpg\" # shortcut for loadmask(\"res/heart.jpg\")\nmask = shape(ellipse, 800, 600, color=\"white\", backgroundcolor=(0,0,0,0)) # refer to the documentation of shape.\nmask = box # mask can also be one of box, ellipse, squircle, ngon, star, bezingon or bezistar. Refer to the documentation of shape. \nmasksize: It can be a tuple (width, height), a single number indicating the side length, or one of the symbols :original, :default, or :auto. \nbackgroundsize: Refer to shape. It is used with masksize to specify the padding size.\nmaskcolor: It can take various values that represent colors, such as \"black\", \"#f000f0\", (0.5, 0.5, 0.7), or 0.2. Alternatively, it can be set to one of the following options: :default, :original (to maintain its original color), or :auto (to automatically recolor the mask).\nbackgroundcolor: It can take various values that represent colors. Alternatively, it can be set to one of the following options: :default, :original, :maskcolor, or :auto (which randomly selects between :original and :maskcolor).\noutline, linecolor, smoothness: Refer to the shape and outline functions.\ntransparent = (1,0,0) # interpret the color (1,0,0) as transparent  \ntransparent = nothing # no transparent color  \ntransparent = c->(c[1]+c[2]+c[3])/3*(c[4]/255)>128) # set transparency using a function. c is an (r,g,b,a) Tuple.\n\n\n\nNotes\nSome arguments depend on whether the mask is provided or on the type of the provided mask.\n\nother keyword arguments\n\nstyle, centralword, reorder, rt, level: Configure the layout style of word cloud. Refer to the documentation of layout!.\nThe keyword argument state is a function. It will be called after the wordcloud object is constructed, which sets the object to a specific state.\nstate = initialize! # only initializes resources, such as word images\nstate = layout! # It is the default setting that initializes the position of words\nstate = generate! # get the result directly\nstate = identity # do nothing\n\n\n\nNotes\nAfter obtaining the wordcloud object, the following steps are required to obtain the resulting picture: initialize! -> layout! -> generate! -> paint\nYou can skip initialize! and/or layout!, and these operations will be automatically performed with default parameters\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.TextProcessing.countwords-Tuple{Any, Any}","page":"Index","title":"WordCloud.TextProcessing.countwords","text":"countwords(text_or_counter; counter=Dict{String,Int}(), language=:auto, regexp=r\"(?:\\S[\\s\\S]*)?[^0-9_\\W](?:[\\s\\S]*\\S)?\")\n\nCount words in text. And save results into counter.   text_or_counter can be a String, a Vector of Strings, an opend file (IO) or a Dict.   regexp is a regular expression to partially match and filter words. For example, regexp=r\"\\S(?:[\\s\\S]*\\S)?\" will trim whitespaces then eliminate empty words.  \n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.TextProcessing.lemmatizer_eng-Tuple{Any}","page":"Index","title":"WordCloud.TextProcessing.lemmatizer_eng","text":"only handles the simple cases of plural nouns and third person singular verbs\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.TextProcessing.processtext-Tuple{AbstractDict{<:AbstractString, <:Real}}","page":"Index","title":"WordCloud.TextProcessing.processtext","text":"Process the text, filter the words, and adjust the weights. Return a vector of words and a vector of weights.\n\nPositional Arguments\n\ntextorcounter: a string, a vector of words, an opened file (IO), a Dict{<:String, <:Real}, a Vector{Pair}, a Vector{Tuple}, or two Vectors.\n\nOptional Keyword Arguments\n\nlanguage: language of the text, default is :auto. \nstopwords: a set of words, default is :auto which means decided by language.  \nstopwords_extra: an additional set of stopwords. By setting this while keeping the stopwords argument as :auto, the built-in stopword list will be preserved.\nminlength, maxlength: minimum and maximum length of a word to be included\nminfrequency: minimum frequency of a word to be included\nmaxnum: maximum number of words, default is 500\nminweight, maxweight: within 0 ~ 1, set to adjust extreme weight\nregexp: a regular expression to partially match and filter words. For example, regexp=r\"\\S(?:[\\s\\S]*\\S)?\" will trim whitespaces then eliminate empty words. This argument is not available when text_or_counter is a counter.\nprocess: a function to process word count dict, default is rescaleweights(identity, 0) ∘ casemerge!\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.TextProcessing.rescaleweights","page":"Index","title":"WordCloud.TextProcessing.rescaleweights","text":"rescaleweights(func=identity, p=0)\n\nThis function takes word length into account. Therefore, the rescaled weights can be used as font size coefficients.   The function func(w::Real)->Real is used to remap the weight, expressed as weight = func(weight); p represents the exponent of the power mean. We set weight = powermean(1*fontsize, wordlength*fontsize) = ((fontsize^p + (wordlength*fontsize)^p)/2) ^ (1/p).   That is, weight = fontsize * powermean(1, wordlength).   Overall, this gives us fontsize = func(weight) / powermean(1, wordlength).   When p is -Inf, the power mean is the minimum value, resulting in fontsize=weight.  When p is Inf, the power mean is the maximum value, resulting in fontsize=weight/wordlength. When p is -1, the power mean is the harmonic mean. When p is 0, the power mean is the geometric mean, preserving the word area.  When p is 1, the power mean is the arithmetic mean. When p is 2, the power mean is the root mean square, preserving the diagonal length.  \n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.TextProcessing.setlemmatizer!-Tuple{AbstractString, Any}","page":"Index","title":"WordCloud.TextProcessing.setlemmatizer!","text":"setlemmatizer!(lang::AbstractString, str_to_str_func)\n\nCustomize lemmatizer for language lang\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.TextProcessing.setstopwords!-Tuple{AbstractString, Any}","page":"Index","title":"WordCloud.TextProcessing.setstopwords!","text":"setstopwords!(lang::AbstractString, str_set)\n\nCustomize stopwords for language lang\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.TextProcessing.settokenizer!-Tuple{AbstractString, Any}","page":"Index","title":"WordCloud.TextProcessing.settokenizer!","text":"settokenizer!(lang::AbstractString, str_to_list_func)\n\nCustomize tokenizer for language lang\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.Render.crop-Tuple{AbstractMatrix, Vararg{Any, 4}}","page":"Index","title":"WordCloud.Render.crop","text":"a, b, c, d are all inclusive\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.Render.crop-Tuple{Luxor.Drawing, Vararg{Any, 4}}","page":"Index","title":"WordCloud.Render.crop","text":"a, b, c, d are all inclusive\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.Render.intersection_region","page":"Index","title":"WordCloud.Render.intersection_region","text":"Return the intersecting region views of img1 and img2, where img2 is positioned in img1 with its top left corner located at coordinates (x, y).\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.Render.outline-Tuple{Any}","page":"Index","title":"WordCloud.Render.outline","text":"Positional Arguments\n\nimg: a bitmap image\n\nKeyword Arguments\n\nlinewidth: 0 <= linewidth \ncolor: line color\ntransparent: the color of the transparent area, default is :auto\nsmoothness: 0 <= smoothness <= 1, smoothness of the line, default is 0.5\n\n\n\n\n\n","category":"method"},{"location":"#WordCloud.Render.overlay!","page":"Index","title":"WordCloud.Render.overlay!","text":"Place img2 onto img1 at coordinates (x, y).\n\n\n\n\n\n","category":"function"},{"location":"#WordCloud.Render.shape-Tuple{Any, Any, Any, Vararg{Any}}","page":"Index","title":"WordCloud.Render.shape","text":"Generate an SVG image of a box, ellipse, squircle, ngon, star, bezingon, or bezistar.\n\nPositional Arguments\n\nshape: one of box, ellipse, squircle, ngon, star, bezingon, or bezistar\nwidth: width of the shape\nheight: height of the shape\n\nKeyword Arguments\n\noutline: an integer indicating the width of the outline\npadding: an integer or a tuple of two integers indicating the padding size\nbackgroundsize: a tuple of two integers indicating the size of the background\ncolor, linecolor, backgroundcolor: any value that can be parsed as a color. \nnpoints, starratio, orientation, cornerradius, rt: see the Examples section below\n\nExamples\n\nshape(box, 80, 50) # box with dimensions 80*50\nshape(box, 80, 50, cornerradius=4) # box with corner radius 4\nshape(squircle, 80, 50, rt=0.7) # squircle or superellipse. rt=0 for rectangle, rt=1 for ellipse, rt=2 for rhombus.\nshape(ngon, 120, 100, npoints=12, orientation=π/6) # regular dodecagon (12 corners) oriented by π/6 \nshape(star, 120, 100, npoints=5) # pentagram (5 tips)\nshape(star, 120, 100, npoints=5, starratio=0.7, orientation=π/2) # 0.7 specifies the ratio of the smaller and larger radii; oriented by π/2\nshape(ellipse, 80, 50, color=\"red\") # red ellipse with dimensions 80*50\nshape(box, 80, 50, backgroundcolor=(0,1,0), backgroundsize=(100, 100)) # 8050 box on a 100100 green background\nshape(squircle, 80, 50, outline=3, linecolor=\"red\", backgroundcolor=\"gray\") # add a red outline to the squircle\n\n\n\n\n\n","category":"method"},{"location":"#Gallery","page":"Index","title":"Gallery","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"WordCloud-Gallery","category":"page"},{"location":"#Index","page":"Index","title":"Index","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"","category":"page"}]
}
