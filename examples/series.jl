#md# This example shows how to generate a dynamic word cloud on series data.
#md# ### Prepare some data
#md# We use the GDP of countries from 2000 to 2020 as an example.
using WorldBankData
using DataFrames
df0 = wdi("NY.GDP.MKTP.CD", "all", 2000, 2020) # GDP from 2000 to 2020
df0.year = round.(Int, df0[!, :year])
df = unstack(df0, :year, :NY_GDP_MKTP_CD)
country_groups = ["XC", "EU", "XE", "XD", "XF", "ZB", "ZT", "XH", "XI", "XG", "ZJ", "XJ", "XL", "XO", 
    "XM", "XN", "ZQ", "XQ", "XP", "XU", "XY", "OE", "ZG", "ZF", "XT"]|>Set # https://rpubs.com/federicoganz/749793
countrymask = .!occursin.(r"\d" , df.iso2c) .& .!in.(df.iso2c, Ref(country_groups))
df = df[countrymask, 2:end]
df[!, 2:end] .= sqrt.(df[!, 2:end] ./ length.(df.country))
df.country = replace.(df.country, " "=>"\n") # some names are too long
for i in 1:size(df, 1) # interpolation, fill missing
    for j in 3:size(df, 2)
        if ismissing(df[i, j])
            df[i, j] = df[i, j-1]
        end
    end
end
#md# ### Generate the wordcloud
using WordCloud
function gather!(wc, i=1:length(wc), r=1)
    O = reverse(size(getmask(wc))) .÷ 2
    order1 = sortperm(sortperm(getpositions(wc, i, mode=getcenter), by=p->sum((p .- O).^2)))
    order2 = sortperm(getweights(wc, i))
    radial = Int.(order2 .> order1)
    gatheritem!.(wc, WordCloud.index(wc, i), r.*radial);
end
function gatheritem!(wc, i, r=1)
    r == 0 && return
    C = getpositions(wc, i, mode=getcenter)
    Δ = sign.(reverse(size(getmask(wc))) .÷ 2 .- C)
    setpositions!(wc, i, C .+ r .* Δ, mode=setcenter!)
end
#md# These two functions are ussed to forcing large words to the center, but are not essential.
wc = wordcloud(df.country, 1, angles=0)
gif = WordCloud.GIF("series")
println("results are saved in series")
@assert length(unique(df[!, 1])) == length(df[!, 1])
initialized = false
for name in names(df)[2:end] # the first column is word list
    words = df[!, 1]
    weights = df[!, name]
    missingmask = ismissing.(weights)
    setweights!.(wc, words[.!missingmask], weights[.!missingmask])
    println("#"^9, name, "#"^9)
    ignore(wc, words[missingmask]) do
        global initialized
        words = getwords(wc)
        pos = getpositions(wc, mode=getcenter)
        initialize!(wc)
        if !initialized
            layout!(wc, style=:gathering)
            initialized = true
        else
            setpositions!(wc, words, pos, mode=setcenter!)
            setstate!(wc, :layout!)
        end
        generate!(wc, callback_pre=ep->(ep%5==0 && gather!(wc, 1:length(wc)÷5, 5)))
        WordCloud.frame(wc, name) |> gif
        # display(wc)
    end
end
WordCloud.Render.generate(gif, framerate=4)
wc
#eval# runexample(:series)
#md# ![](series/animation.gif)  
