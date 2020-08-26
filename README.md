# WordCloud
wordcloud in Julia
---

* [x] 排序 & 预放置
* [x] 基于四叉树碰撞检测
* [x] 根据局部灰度梯度位置调整（训练迭代）
* [x] 引入动量加速训练
* [x] 分代调整以优化性能
* [x] 控制字体大小和填充密度的策略
* [x] 重新放置和缩放的策略
* [x] 文字颜色和方向
* [ ] 并行计算

# Basic Usage 
```julia
]add WordCloud
using WordCloud
texts = "天地玄黄宇宙洪荒日月盈昃辰宿列张寒来暑往秋收冬藏闰余成岁律吕调阳云腾致雨露结为霜金生丽水玉出昆冈剑号巨阙珠称夜光果珍李柰菜重芥姜海咸河淡鳞潜羽翔龙师火帝鸟官人皇始制文字乃服衣裳推位让国有虞陶唐吊民伐罪周发殷汤坐朝问道垂拱平章"
texts = [string(c) for c in texts]
weights = rand(length(texts)) .^ 2 .* 100 .+ 30
wc = wordcloud(texts, weights)
generate(wc)
paint(wc, "qianziwen.png")
```
# More Complex Usage
```julia
wc = wordcloud(
    process(open("res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask = loadmask("res/alice_mask.png", color="#faeef8"),
    colors = (WordCloud.colorschemes[:Set1_5].colors..., ),
    angles = (0, 90),
    filling_rate = 0.6) |> generate
paint(wc, "alice.png")
```
![wordcloud](res/alice.png)

# Visualization of Training
![training](res/training.gif)
***
linux添加中文字体  
> mv wqy-microhei.ttc ~/.fonts  
> fc-cache -vf  

配置ffmpeg环境
> add /mnt/lustre/share/ffmpeg-4.2.1/lib to ENV["LD_LIBRARY_PATH"]  
> add /mnt/lustre/share/ffmpeg-4.2.1/bin to ENV["PATH"]  
***
# other wordcloud 
> [word_cloud](https://github.com/amueller/word_cloud)  
> [d3-cloud](https://github.com/jasondavies/d3-cloud)  
> [wordcloud](https://github.com/timdream/wordcloud)  