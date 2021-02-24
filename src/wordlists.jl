#top5000[endswith.(top5000, "s").&(.!endswith.(top5000, "ss"))] + "has"
const s_ending_words = Set(["numerous", "serious", "towards", "clothes", "focus", "bonus", "sometimes", "suspicious", "his", 
        "species", "thanks", "hers", "as", "aids", "proceedings", "analysis", "bus", "us", "gas", "lots", "versus", 
        "emphasis", "nervous", "upstairs", "dangerous", "curious", "delicious", "anonymous", "various", "yours", 
        "lens", "physics", "dynamics", "indigenous", "besides", "anxious", "always", "works", "ours", "news", "bias", 
        "gorgeous", "vs", "diabetes", "virus", "genius", "consensus", "hypothesis", "ambitious", "whereas", "jealous",
        "crisis", "tremendous", "economics", "canvas", "odds", "obvious", "jeans", "stimulus", "chaos", "corps", 
        "mathematics", "statistics", "precious", "basis", "ridiculous", "perhaps", "headquarters", "lyrics", "yes", 
        "tennis", "continuous", "diagnosis", "plus", "its", "earnings", "previous", "mysterious", "christmas", 
        "politics", "ourselves", "themselves", "thus", "conscious", "sales", "religious", "generous", "enormous", 
        "this", "status", "series", "olympics", "famous", "campus", "census", "ethics", "terms", "has"]) 
#endswith.(top5000nv, r"se|xe|che|she|oe|ie")])
const xe_ending_words = Set(["tie", "compromise", "raise", "rookie", "praise", "confuse", "purpose", "pause", "headache", 
        "abuse", "phase", "promise", "impose", "cease", "reverse", "spouse", "rise", "cookie", "disease", "release", 
        "expose", "mouse", "response", "disclose", "premise", "license", "lose", "purchase", "pie", "horse", 
        "increase", "case", "universe", "base", "surprise", "die", "expense", "verse", "cause", "exercise", "toe", 
        "purse", "rose", "house", "defense", "endorse", "suppose", "course", "pulse", "expertise", "chase", "choose", 
        "sense", "use", "dose", "arise", "franchise", "cheese", "excuse", "close", "discourse", "noise", "oppose", 
        "clause", "lie", "please", "compose", "ease", "decrease", "movie", "diagnose", "phrase", "nonsense", "refuse",
        "cruise", "calorie", "advise", "comprise", "shoe", "propose", "database", "enterprise", "nose", "accuse", 
        "nurse", "pose", "japanese", "offense", "collapse"]) 
#top5000nv[endswith.(top5000nv, r"fe|f")]
const f_ending_words = Set(["beef", "stuff", "wolf", "gulf", "sheriff", "grief", "chief", "life", "shelf", "relief", "roof",
        "proof", "wildlife", "playoff", "wife", "belief", "leaf", "knife", "self", "staff", "thief", "chef", "half", 
        "golf", "cliff", "cafe"])