using WordCloud
using Test

@testset "WordCloud.jl" begin
    # Write your tests here.
    img, img_m = WordCloud.rendertext("test", 88.3, color="blue", angle = 20, border=1, returnmask=true)
    texts = "天地玄黄宇宙洪荒日月盈昃辰宿列张寒来暑往秋收冬藏闰余成岁律吕调阳云腾致雨露结为霜金生丽水玉出昆冈剑号巨阙珠称夜光果珍李柰菜重芥姜海咸河淡鳞潜羽翔龙师火帝鸟官人皇始制文字乃服衣裳推位让国有虞陶唐吊民伐罪周发殷汤坐朝问道垂拱平章"
    texts = [string(c) for c in texts];
    weights = rand(length(texts)) .^ 2 .* 100 .+ 30;
    wc = wordcloud(texts, weights, filling_rate=0.45)
    paint(wc)
    generate(wc)
    paint(wc::wordcloud, "test.jpg")
    @test isempty(WordCloud.outofbounds(wc.maskqtree, wc.qtrees))
end
