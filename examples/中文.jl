# 中文需要分词，须先配置python环境和安装结巴分词
# ENV["PYTHON"] = ""
# using Pkg
# Pkg.build("PyCall") #build PyCall

# using Conda
# Conda.pip_interop(true)
# Conda.pip("install","jieba") #安装python包：结巴分词

using WordCloud
using PyCall

@pyimport jieba

TheInternationale = "起来，饥寒交迫的奴隶！\n起来，全世界受苦的人！\n满腔的热血已经沸腾，\n要为真理而斗争！\n旧世界打个落花流水，\n奴隶们起来，起来！\n不要说我们一无所有，\n我们要做天下的主人！\n\n这是最后的斗争，\n团结起来到明天，\n英特纳雄耐尔\n就一定要实现！\n这是最后的斗争，\n团结起来到明天，\n英特纳雄耐尔\n就一定要实现！\n\n从来就没有什么救世主，\n也不靠神仙皇帝！\n要创造人类的幸福，\n全靠我们自己！\n我们要夺回劳动果实，\n让思想冲破牢笼！\n快把那炉火烧得通红，\n趁热打铁才能成功！\n\n是谁创造了人类世界？\n是我们劳动群众！\n一切归劳动者所有，\n哪能容得寄生虫？！\n最可恨那些毒蛇猛兽，\n吃尽了我们的血肉！\n一旦把它们消灭干净，\n鲜红的太阳照遍全球！\n"

wc = wordcloud(
    processtext(jieba.lcut(TheInternationale)), 
    colors = "#DE2910",
    mask = WordCloud.randommask("#FFDE00", 400),
    fillingrate=0.8)|>generate!
println("结果保存在 中文.svg")
paint(wc, "中文.svg")
wc