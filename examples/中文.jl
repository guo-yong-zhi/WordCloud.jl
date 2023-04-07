#md# 中文需要分词，可以通过PythonCall调用python版的结巴分词  

using CondaPkg; CondaPkg.add("jieba")
using WordCloud
using PythonCall

jieba = pyimport("jieba")

TheInternationale = "起来，饥寒交迫的奴隶！\n起来，全世界受苦的人！\n满腔的热血已经沸腾，\n要为真理而斗争！\n旧世界打个落花流水，\n奴隶们起来，起来！\n不要说我们一无所有，\n我们要做天下的主人！\n\n这是最后的斗争，\n团结起来到明天，\n英特纳雄耐尔\n就一定要实现！\n这是最后的斗争，\n团结起来到明天，\n英特纳雄耐尔\n就一定要实现！\n\n从来就没有什么救世主，\n也不靠神仙皇帝！\n要创造人类的幸福，\n全靠我们自己！\n我们要夺回劳动果实，\n让思想冲破牢笼！\n快把那炉火烧得通红，\n趁热打铁才能成功！\n\n是谁创造了人类世界？\n是我们劳动群众！\n一切归劳动者所有，\n哪能容得寄生虫？！\n最可恨那些毒蛇猛兽，\n吃尽了我们的血肉！\n一旦把它们消灭干净，\n鲜红的太阳照遍全球！\n"

jieba.add_word("英特纳雄耐尔")

wc = wordcloud(
    processtext(pyconvert(Vector{String}, jieba.lcut(TheInternationale))), 
    colors="#DE2910",
#     mask = WordCloud.randommask(400, color="#FFDE00"),
    mask=pkgdir(WordCloud) * "/res/heart_mask.png",
    maskcolor="#FFDE00",
    density=0.65) |> generate!

println("结果保存在 中文.png")
paint(wc, "中文.png")
wc
#eval# runexample(:中文)
#md# ![](中文.png)  
