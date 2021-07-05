SansSerifFonts= ["Trebuchet MS", "Heiti TC", "微軟正黑體", "Arial Unicode MS", "Droid Fallback Sans", "sans-serif", "Helvetica", "Verdana", "Hei",
"Arial", "Tahoma", "Trebuchet MS", "Microsoft Yahei", "Comic Sans MS", "Impact", "Segoe Script", "STHeiti", "Apple LiGothic", "MingLiU", "Ubuntu", "Segoe UI",
"DejaVu Sans", "DejaVu Sans Mono"]
SerifFonts =["Baskerville", "Times New Roman", "華康儷金黑 Std", "華康儷宋 Std",  "DFLiKingHeiStd-W8", "DFLiSongStd-W5", "DejaVu Serif", "SimSun",
    "Hiragino Mincho Pro", "LiSong Pro Light", "新細明體", "serif", "Georgia", "STSong", "FangSong", "KaiTi", "STKaiti", "Courier New"]
macfonts = ["Trebuchet MS", "Helvetica", "Verdana", "Arial", "Comic Sans MS", "STHeiti", "Apple LiGothic", "Baskerville", "Times New Roman", "Hiragino Mincho Pro", "Georgia", "STSong", "STKaiti", "Courier New"]
windowsfonts = ["Trebuchet MS", "sans-serif", "Verdana", "Arial", "Tahoma", "Microsoft Yahei", "Comic Sans MS", "Impact", "Segoe Script", "Segoe UI", "serif", "Georgia", "STSong", "FangSong", "KaiTi", "STKaiti", "Courier New"]
CandiFonts = union(SansSerifFonts, SerifFonts)
CandiWeights = ["", " bold", " light"]
function checkfont(font)
    fname = tempname()
    try
        open(fname, "w") do f
            redirect_stderr(f) do
                rendertext("a", 4+rand(), font=font)
            end
        end
    finally
        ret = isempty(read(fname, String))
        rm(fname, force=true)
        return ret
    end
end
checkfonts(;fonts=CandiFonts, weights=CandiWeights) = ["$f$w" for w in weights, f in fonts if checkfont("$f$w")]
AvailableFonts = checkfonts()
push!(AvailableFonts, "")