# [WordCloud.jl](https://github.com/guo-yong-zhi/WordCloud.jl)
![juliadoc](res/juliadoc.png)  
[![CI](https://github.com/guo-yong-zhi/WordCloud.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/guo-yong-zhi/WordCloud.jl/actions/workflows/ci.yml) [![CI-nightly](https://github.com/guo-yong-zhi/WordCloud.jl/actions/workflows/ci-nightly.yml/badge.svg)](https://github.com/guo-yong-zhi/WordCloud.jl/actions/workflows/ci-nightly.yml) [![codecov](https://codecov.io/gh/guo-yong-zhi/WordCloud.jl/branch/master/graph/badge.svg?token=2U0X769Z51)](https://codecov.io/gh/guo-yong-zhi/WordCloud.jl) [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/guo-yong-zhi/WordCloud.jl/master?filepath=examples.ipynb)  
 Word cloud (tag cloud or wordle) is a novelty visual representation of text data. The importance of each word is shown with font size or color. Our generator has the following highlights:
* **Flexible** Any mask, any color, any angle, adjustable density. You can specify the initial position of some words. Or you can pin some words and adjust others, etc.
* **Fast**  100% in Julia and efficient implementation based on Quadtree & gradient optimization (see [Stuffing.jl](https://github.com/guo-yong-zhi/Stuffing.jl)). The advantage is more obvious when generating large images.
* **Exact**  Words with the same weight have the exact same size. The algorithm will never scale the word to fit the blank.  

 *run `showexample(:juliadoc)` to see how to generate the banner*
***
# Installation
```julia
import Pkg; Pkg.add("WordCloud")
```
# Basic Usage 
```julia
using WordCloud
words = "天地玄黄宇宙洪荒日月盈昃辰宿列张寒来暑往秋收冬藏闰余成岁律吕调阳云腾致雨露结为霜金生丽水玉出昆冈剑号巨阙珠称夜光果珍李柰菜重芥姜海咸河淡鳞潜羽翔龙师火帝鸟官人皇始制文字乃服衣裳推位让国有虞陶唐吊民伐罪周发殷汤坐朝问道垂拱平章"
words = [string(c) for c in words]
weights = rand(length(words)) .^ 2 .* 100 .+ 30
wc = wordcloud(words, weights)
generate!(wc)
paint(wc, "qianziwen.svg")
```
*Run the command `runexample(:qianziwen)` or `showexample(:qianziwen)` to get the result.*  
# More Complex Usage
```julia
using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask = loadmask(pkgdir(WordCloud)*"/res/alice_mask.png", color="#faeef8"),
    colors = :Set1_5,
    angles = (0, 90),
    density = 0.55) |> generate!
paint(wc, "alice.png", ratio=0.5, background=outline(wc.mask, color="purple", linewidth=1))
```
*Run the command `runexample(:alice)` or `showexample(:alice)` to get the result.*  
[![alice](res/alice.png)](./examples/alice.jl)

# More Examples
## Training animation
[![animation](res/animation.gif)](./examples/animation.jl)  
*Run the command `runexample(:animation)` or `showexample(:animation)` to get the result.* 
## Gathering style
[![gathering](res/gathering.png)](./examples/gathering.jl)  
*Run the command `runexample(:gathering)` or `showexample(:gathering)` to get the result.* 
## Recolor
[![recolor](res/recolor.png)](./examples/recolor.jl)![recolor](res/butterfly.png)  
*Run the command `runexample(:recolor)` or `showexample(:recolor)` to get the result.* 
## Comparison
[![compare](res/compare.png)](./examples/compare.jl)  
*Run the command `runexample(:compare)` or `showexample(:compare)` to get the result.* 

*The variable `WordCloud.examples` holds all available examples.* 
You can also [**see more examples**](https://github.com/guo-yong-zhi/WordCloud-Gallery) or [**try it online**](https://mybinder.org/v2/gh/guo-yong-zhi/WordCloud.jl/master?filepath=examples.ipynb).  
***
* [x] 排序 & 预放置
* [x] 基于四叉树碰撞检测
* [x] 根据局部灰度梯度位置调整（训练迭代）
* [x] 引入动量加速训练
* [x] 分代调整以优化性能
* [x] 定位树批量碰撞检测（≈O(n)）
* [x] LRU优化性能
* [x] 控制字体大小和填充密度的策略
* [x] 重新放置和缩放的策略
* [x] 文字颜色和方向
* [x] 并行计算
***
linux添加中文字体  
> mv wqy-microhei.ttc ~/.fonts  
> fc-cache -vf  

配置ffmpeg环境
> add /path/to/ffmpeg-4.2.1/lib to ENV["LD_LIBRARY_PATH"]  
> add /path/to/ffmpeg-4.2.1/bin to ENV["PATH"]  
***
# other wordclouds
> [word_cloud](https://github.com/amueller/word_cloud)  
> [d3-cloud](https://github.com/jasondavies/d3-cloud)  
> [wordcloud](https://github.com/timdream/wordcloud)  
