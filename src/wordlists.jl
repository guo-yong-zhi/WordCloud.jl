# df = CSV.File("top5000-lemmas.txt")|> DataFrame;
# top5000 = df[!, :lemma];
# top5000nv = df[(df[!, :PoS] .== "v") .| (df[!, :PoS] .== "n"), :lemma];

#top5000[endswith.(top5000, "s").&(.!endswith.(top5000, "ss"))] + "has", "is", "was"
const s_ending_words = Set(["numerous", "serious", "towards", "clothes", "focus", "bonus", "sometimes", "suspicious", "his", 
        "species", "thanks", "hers", "as", "aids", "proceedings", "analysis", "bus", "us", "gas", "lots", "versus", 
        "emphasis", "nervous", "upstairs", "dangerous", "curious", "delicious", "anonymous", "various", "yours", 
        "lens", "physics", "dynamics", "indigenous", "besides", "anxious", "always", "works", "ours", "news", "bias", 
        "gorgeous", "vs", "diabetes", "virus", "genius", "consensus", "hypothesis", "ambitious", "whereas", "jealous",
        "crisis", "tremendous", "economics", "canvas", "odds", "obvious", "jeans", "stimulus", "chaos", "corps", 
        "mathematics", "statistics", "precious", "basis", "ridiculous", "perhaps", "headquarters", "lyrics", "yes", 
        "tennis", "continuous", "diagnosis", "plus", "its", "earnings", "previous", "mysterious", "christmas", 
        "politics", "ourselves", "themselves", "thus", "conscious", "sales", "religious", "generous", "enormous", 
        "this", "status", "series", "olympics", "famous", "campus", "census", "ethics", "terms", "has", "is", "was"]) 

#top5000nv[endswith.(top5000nv, r"xe|che|she|oe|ie")]
const xe_ending_words = Set(["tie", "lie", "rookie", "pie", "cookie", "toe", "movie", "calorie", "headache", "die", "shoe"])

#top5000nv[endswith.(top5000nv, r"fe|f")]
const f_ending_words = Set(["beef", "stuff", "wolf", "gulf", "sheriff", "grief", "chief", "life", "shelf", "relief", "roof",
        "proof", "wildlife", "playoff", "wife", "belief", "leaf", "knife", "self", "staff", "thief", "chef", "half", 
        "golf", "cliff", "cafe"])
