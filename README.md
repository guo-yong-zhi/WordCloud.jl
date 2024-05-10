# <div><img src="docs/src/assets/logo.svg" height="25px"><span> [WordCloud.jl](https://github.com/guo-yong-zhi/WordCloud.jl)</span></div>  
![juliadoc](res/juliadoc.png)  
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://guo-yong-zhi.github.io/WordCloud.jl/dev) [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/guo-yong-zhi/WordCloud.jl/master?filepath=examples.ipynb) [![CI](https://github.com/guo-yong-zhi/WordCloud.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/guo-yong-zhi/WordCloud.jl/actions/workflows/ci.yml) [![CI-nightly](https://github.com/guo-yong-zhi/WordCloud.jl/actions/workflows/ci-nightly.yml/badge.svg)](https://github.com/guo-yong-zhi/WordCloud.jl/actions/workflows/ci-nightly.yml) [![codecov](https://codecov.io/gh/guo-yong-zhi/WordCloud.jl/branch/master/graph/badge.svg?token=2U0X769Z51)](https://codecov.io/gh/guo-yong-zhi/WordCloud.jl) [![DOI](https://zenodo.org/badge/211266031.svg)](https://zenodo.org/badge/latestdoi/211266031)  
Word cloud (tag cloud or wordle) is a novelty visual representation of text data. The importance of each word is shown with its font size, position, or color. WordCloud.jl is the perfect tool for generating word clouds, offering several advantages:
* ***Flexible*** - You have control over every aspect of generating a word cloud. You can customize the shape, color, angle, position, distribution, density, and spacing to align with your preferences and artistic style.
* ***Faithful*** - This visualization solution guarantees precise results. Each word appears only once, and its font size is determined solely by the provided weight. Words are never repeated or shrunk artificially to fill empty spaces.
* ***Efficient*** - It utilizes intelligent strategies and efficient nesting algorithms, implemented entirely in Julia (see [Stuffing.jl](https://github.com/guo-yong-zhi/Stuffing.jl)). As a result, it can easily generate high-resolution word clouds.

<br>

[🌐 Try the online generator 🌐](https://mybinder.org/v2/gh/guo-yong-zhi/pluto-on-binder/master?urlpath=pluto/open?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguo-yong-zhi%2FWordCloud.jl%2Fmaster%2FWordCloudApp.jl)  

[✨ Go to the gallery ✨](https://github.com/guo-yong-zhi/WordCloud-Gallery) 

<br>

# Installation
```julia
import Pkg; Pkg.add("WordCloud")
```
# Basic Usage 
```julia
using WordCloud
using Random
words = [randstring(rand(1:8)) for i in 1:300]
weights = randexp(length(words))
wc = wordcloud(words, weights)
generate!(wc)
paint(wc, "random.svg")
```
Alternatively, it could be
```julia
wc = wordcloud("It's easy to generate word clouds") |> generate! # from a string
```
```julia
wc = wordcloud(open(pkgdir(WordCloud)*"/res/alice.txt")) |> generate! # from a file
```
```julia
wc = wordcloud(["中文", "需要", "提前", "分词"], fonts="") |> generate! # from a list
```
```julia
wc = wordcloud(["the"=>1.0, "to"=>0.51, "and"=>0.50,
                  "of"=>0.47, "a"=>0.44, "in"=>0.33]) |> generate! # from pairs or a dict
```
# Advanced Usage
```julia
using WordCloud
textfile = pkgdir(WordCloud)*"/res/alice.txt"
maskfile = pkgdir(WordCloud)*"/res/alice_mask.png"
wc = wordcloud(
    open(textfile),
    stopwords_extra = ["said"],
    maxnum = 500, 
    mask = maskfile,
    maskcolor = "#faeef8",
    outline = 4,
    linecolor = "purple",
    colors = :Set1_5,
    angles = (0, 90),
    fonts = "Tahoma",
    density = 0.55,
    spacing = 3,) |> generate!
paint(wc, "alice.png", ratio=0.5)
```
*try `runexample(:alice)` or `showexample(:alice)`*  
[![alice](res/alice.png)](./examples/alice.jl)
# More Examples
## Gathering style
[![gathering](res/gathering.png)](./examples/gathering.jl)  
*try `runexample(:gathering)` or `showexample(:gathering)`* 
## Recolor
[![recolor](res/recolor.png)](./examples/recolor.jl)  
*try `runexample(:recolor)` or `showexample(:recolor)`* 
## Semantic
[![semantic](res/semantic.png)](./examples/semantic.jl)  
*try `runexample(:semantic)` or `showexample(:semantic)`*  
The variable `WordCloud.examples` holds all available examples.   

# About Implementation
WordCloud.jl stands out from other tools due to its unique approach based on image local gradient optimization. Unlike conventional algorithms, WordCloud.jl utilizes a non-greedy algorithm that enables words to be [repositioned](res/animation2.gif) even after their initial placement. This dynamic adjustment process provides unparalleled freedom in assigning words to any desired position, irrespective of potential overlaps. Furthermore, it eliminates the necessity of scaling words during the adjustment phase. This ingenious design choice maximizes the generator's flexibility, opening up boundless possibilities for customization. For a more detailed understanding of the algorithm, you can refer to the [Stuffing.jl - Algorithm Description](https://github.com/guo-yong-zhi/Stuffing.jl#algorithm-description). 
* [x] 权重计算和单词位置初始化
* [x] 基于四叉树（层次包围盒）的碰撞检测
* [x] 根据局部灰度梯度平移单词（训练迭代）
* [x] 引入动量加速训练
* [x] 分代检测优化性能（for pairwise trainer)
* [x] 区域四叉树批量碰撞检测
* [x] LRU优化性能（for element-wise trainer)
* [x] 控制字体大小和填充密度的策略
* [x] 使用重新放置策略跳出局部最优
* [x] 使用缩放策略降低训练难度
* [x] 训练失败检测和提前中断
* [x] 主题配色等
* [x] 并行计算

# Other word cloud generators
* [word_cloud (Python)](https://github.com/amueller/word_cloud)  
* [d3-cloud](https://github.com/jasondavies/d3-cloud)  
* [wordcloud (HTML5)](https://github.com/timdream/wordcloud)  
* [swcv](https://github.com/spupyrev/swcv)  
* [Wordle](http://static.mrfeinberg.com/bv_ch03.pdf)  
* [Semantic Word Clouds with Background Corpus Normalization and t-distributed Stochastic Neighbor Embedding](https://arxiv.org/pdf/1708.03569.pdf)  
* [An Evaluation of Semantically Grouped Word Cloud Designs](https://www.semanticscholar.org/paper/An-Evaluation-of-Semantically-Grouped-Word-Cloud-Hearst-Pedersen/ddae6a380123988f578433ae103393e255c0b4d1)  
