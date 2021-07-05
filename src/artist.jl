SansSerifFonts= ["Trebuchet MS", "Heiti TC", "微軟正黑體", "Arial Unicode MS", "Droid Fallback Sans", "sans-serif", "Helvetica", "Verdana", "Hei",
"Arial", "Tahoma", "Trebuchet MS", "Microsoft Yahei", "Comic Sans MS", "Impact", "Segoe Script", "STHeiti", "Apple LiGothic", "MingLiU", "Ubuntu", "Segoe UI",
"DejaVu Sans", "DejaVu Sans Mono"]
SerifFonts =["Baskerville", "Times New Roman", "華康儷金黑 Std", "華康儷宋 Std",  "DFLiKingHeiStd-W8", "DFLiSongStd-W5", "DejaVu Serif", "SimSun",
    "Hiragino Mincho Pro", "LiSong Pro Light", "新細明體", "serif", "Georgia", "STSong", "FangSong", "KaiTi", "STKaiti", "Courier New"]
macfonts = ["Trebuchet MS", "Helvetica", "Verdana", "Arial", "Comic Sans MS", "STHeiti", "Apple LiGothic", "Baskerville", "Times New Roman", "Hiragino Mincho Pro", "Georgia", "STSong", "STKaiti", "Courier New"]
windowsfonts = ["Trebuchet MS", "sans-serif", "Verdana", "Arial", "Tahoma", "Microsoft Yahei", "Comic Sans MS", "Impact", "Segoe Script", "Segoe UI", "serif", "Georgia", "STSong", "FangSong", "KaiTi", "STKaiti", "Courier New"]
CandiFonts = union(SansSerifFonts, SerifFonts)
CandiWeights = ["", " regular", " normal", " medium", " bold", " light"]
function checkfonts(fonts::AbstractVector)
    fname = tempname()
    r = Bool[]
    open(fname, "w") do f
        redirect_stderr(f) do
            p = position(f)
            for font in fonts
                rendertext("a", 1+rand(), font=font) #相同字体相同字号仅warning一次，故首次执行最准
                #flush(f) #https://en.cppreference.com/w/cpp/io/c/fseek The standard C++ file streams guarantee both flushing and unshifting 
                seekend(f)
                p2 = position(f)
                push!(r, p2 == p)
                p = p2
            end
        end
    end
    return r
end
checkfonts(f) = checkfonts([f]) |> only
function filterfonts(;fonts=CandiFonts, weights=CandiWeights)
    candi = ["$f$w" for w in weights, f in fonts] |> vec
    candi[checkfonts(candi)]
end
AvailableFonts = filterfonts()
push!(AvailableFonts, "")