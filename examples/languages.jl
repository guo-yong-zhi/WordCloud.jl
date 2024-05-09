#md# For languages that are not processed perfectly, you can refer to [the example for Chinese](#中文) or you can input the data in the form of a "word => weight" list, as illustrated in the following example.
using WordCloud
words_weights = [
    "普通话" => 939.0,
    "Español" => 485.0,
    "English" => 380.0,
    "हिन्दी" => 345.0,
    "Português" => 236.0,
    "বাংলা" => 234.0,
    "Русский" => 147.0,
    "日本語" => 123.0,
    "粤语" => 86.1,
    "Tiếng Việt" => 85.0,
    "Türkçe" => 84.0,
    "吴语" => 83.4,
    "मराठी" => 83.2,
    "తెలుగు" => 83.0,
    "한국어" => 81.7,
    "Français" => 80.8,
    "தமிழ்" => 78.6,
    "مصري" => 77.4,
    "Deutsch" => 75.3,
    "اردو" => 70.6,
    "ꦧꦱꦗꦮ" => 68.3,
    "پنجابی" => 66.7,
    "Italiano" => 64.6,
    "فارسی" => 57.2,
    "ગુજરાતી" => 57.1,
    "भोजपुरी" => 52.3,
    "هَوْسَ" => 51.7
]
wc = wordcloud(words_weights) |> generate!

println("results are saved to languages.svg")
paint(wc, "languages.svg")
wc
#eval# runexample(:languages)
#md# ![](languages.svg)  