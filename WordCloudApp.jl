### A Pluto.jl notebook ###
# v0.19.23

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ daf38998-c448-498a-82e2-b48a6a2b9c27
begin
import Pkg; Pkg.activate(homedir())
using PlutoUI
using WordCloud 
using HTTP
using ImageIO
using PythonCall
# using CondaPkg; CondaPkg.add("jieba")
end

# ╔═╡ 6b7b1da7-03dc-4815-9abf-b8eea410d2fd
md"**max word count:** $(@bind maxnum NumberField(1:5000, default=500))　　**min word length:** $(@bind minlength NumberField(1:1000, default=1))"

# ╔═╡ 852810b2-1830-4100-ad74-18b8e96afafe
md"""
**word blacklist:** $(@bind wordblacklist_ TextField(default="")) $(@bind enablestopwords　　CheckBox(default=true))enable the built-in stop word list"""

# ╔═╡ 0dddeaf5-08c3-46d0-8a79-30b5ce42ef2b
begin
wordblacklist = [wordblacklist_[i] for i in findall(r"[^\s,;，；、]+", wordblacklist_)]
isempty(wordblacklist) ? nothing : wordblacklist 
end

# ╔═╡ f4844a5f-260b-4713-84bf-69cd8123c7fc
md"""**mask shape:** $(@bind mask_ Select([:auto, box, ellipse, squircle, ngon, star, bezingon, bezistar])) $(@bind configshape　　CheckBox(default=false))additional config　　**mask size:** $(@bind masksize_ TextField(default="auto"))　*e.g. 400,300*"""

# ╔═╡ 1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
begin
if mask_ == :auto
	md"""**upload an image as a mask:** $(@bind uploadedmask FilePicker([MIME("image/*")]))"""
elseif configshape
    if mask_ in (ngon, star, bezingon, bezistar)
        md"**number of points:** $(@bind npoints NumberField(3:100, default=5))"
	elseif mask_ == squircle
        md"**shape parameter:** $(@bind rt NumberField(0.:0.5:3., default=0.))　*0: rectangle; 1: ellipse; 2: rhombus*; >2: four-armed star"
    else
        md"use random $(mask_ isa Function ? nameof(mask_) : mask_) shape"
    end
else
    md"use random $(mask_ isa Function ? nameof(mask_) : mask_) shape"
end
end

# ╔═╡ b38c3ad9-7885-4af6-8394-877fde8ed83b
md"**mask outline:** $(@bind outlinewidth NumberField(-1:100, default=-1))　*-1 means random*"

# ╔═╡ 6e614caa-38dc-4028-b0a7-05f7030d5b43
md"**layout style:** $(@bind style Select([:auto, :uniform, :gathering]))"

# ╔═╡ 872f2653-303f-4b53-8e01-26bec86fc413
md"""**text density:** $(@bind density NumberField(0.1:0.01:10.0, default=0.5))　　**min word spacing:** $(@bind spacing NumberField(0:100, default=2))"""

# ╔═╡ 26d6b795-1cc3-4548-aa07-86c2f6ee0776
md"""**word fonts:** $(@bind fonts_ TextField(default="auto"))　*Use commas to separate multiple fonts.*　[*Browse available fonts*](https://fonts.google.com)"""

# ╔═╡ 7993fd44-2fcf-488e-9280-4b4d0bf0e22c
md"""
**word orientations:** $(@bind anglelength NumberField(-1:1000, default=-1)) orientations
"""

# ╔═╡ 8153f1f1-9704-4b1e-bff9-009a54404448
if anglelength > 0
	md"""from $(@bind anglestart NumberField(-360:360, default=0)) degrees to $(@bind anglestop NumberField(-360:360, default=0)) degrees"""
else
	md"use random word orientations"
end

# ╔═╡ 14666dc2-7ae4-4808-9db3-456eb26cd435
md"**word colors:** $(@bind colors_ Select([:auto; WordCloud.Schemes])) $(@bind colorstyle Select([:random, :gradient]))"

# ╔═╡ 2870a2ee-aa99-48ec-a26d-fed7b040e6de
@bind go Button("    Go!    ")

# ╔═╡ 21ba4b81-07aa-4828-875d-090e0b918c76
begin
    defaulttext = """
    A word cloud (tag cloud or wordle) is a novelty visual representation of text data, 
    typically used to depict keyword metadata (tags) on websites, or to visualize free form text. 
    Tags are usually single words, and the importance of each tag is shown with font size or color. Bigger term means greater weight. 
    This format is useful for quickly perceiving the most prominent terms to determine its relative prominence.  
    """
defaultttable = """
				饥寒交迫, 1
				落花流水, 1
				受苦, 1
				世界, 1
				不要, 1
				就, 2
				为, 1
				们, 1
				一定, 2
				团结起来, 2
				，, 10
				热血, 1
				沸腾, 1
				的, 6
				而, 1
				斗争, 3
				最后, 2
				真理, 1
				人, 1
				！, 7
				奴隶, 2
				旧, 1
				主人, 1
				这是, 2
				英特纳雄耐尔, 2
				说, 1
				一无所有, 1
				要, 4
				已经, 1
				我们, 2
				天下, 1
				实现, 2
				起来, 4
				全世界, 1
				满腔, 1
				打个, 1
				做, 1
				到, 2
				明天, 2
				"""
nothing
end

# ╔═╡ 66f4b71e-01e5-4279-858b-04d44aeeb574
begin
function read_table(text)
	ps = [split(it, r"[,;\t]") for it in split(strip(text), "\n")]
	ps = sort([(first(it), parse(Float64, last(it))) for it in ps], by=last, rev=true)
	maxlen = maximum(length∘first, ps)
	println(length(ps), " items table:\n")
	for (i,p) in enumerate(ps)
		println("\t", p[1], " "^(maxlen-length(p[1]))*"\t|\t", p[end])
		if i == 9
			println("\t。。。")
			break
		end
	end
	println()
	ps
end
nothing
end

# ╔═╡ 397fdd42-d2b2-46db-bf74-957909f47a58
if mask_ == :auto
	if uploadedmask === nothing
		mask = :auto
		nothing
	else
		mask = loadmask(IOBuffer(uploadedmask["data"]))
		nothing
	end
else
	mask = mask_
	nothing
end

# ╔═╡ 74bd4779-c13c-4d16-a90d-597db21eaa39
begin
    maskkwargs = (;)
    if configshape
        if mask in (ngon, star, bezingon, bezistar)
            maskkwargs = (npoints=npoints,)
        elseif mask == squircle
            maskkwargs = (rt=rt,)
        end
    end
    nothing
end

# ╔═╡ 9396cf96-d553-43db-a839-273fc9febd5a
begin
angles = :auto
try
    global angles = range(anglestart, anglestop, length=anglelength)
    isempty(angles) && (angles = :auto)
    nothing
catch
end
end

# ╔═╡ 1a4d1e62-6a41-4a75-a759-839445dacf4f
begin
if fonts_ == "auto"
    fonts = Symbol(fonts_)
elseif fonts_ === nothing
    fonts = ""
elseif occursin(",", fonts_)
    fonts = tuple(split(fonts_, ",")...)
else
    fonts = fonts_
end
nothing
end

# ╔═╡ 986cf1a6-8075-48ae-84d9-55ae11a27da1
begin
weightscale_funcs = [
    identity => "identity", 
    (√) => "√x", 
    log1p => "log x",
    (n->n^2) => "x²",
    expm1 => "exp x",
    ]
nothing
end

# ╔═╡ dfe608b0-077c-437a-adf2-b1382a0eb4eb
md"**rescale weights:** $(@bind rescale_func Select(weightscale_funcs))　　**word length balance:** $(@bind word_length_balance Slider(-1:0.01:1, default=0, show_value=true))"

# ╔═╡ e7ec8cd7-f60b-4eb0-88fc-76d694976f9d
begin
google_fonts = ["Roboto","Open Sans","Lato","Montserrat","Noto Sans JP","Roboto Condensed","Oswald","Source Sans Pro","Slabo 27px","Raleway","PT Sans","Poppins","Roboto Slab","Merriweather","Noto Sans","Ubuntu","Roboto Mono","Lora","Playfair Display","Nunito","PT Serif","Titillium Web","PT Sans Narrow","Arimo","Noto Serif",
"Rubik","Fira Sans","Work Sans","Noto Sans KR","Quicksand","Dosis","Inconsolata","Oxygen","Mukta","Bitter","Nanum Gothic","Yanone Kaffeesatz","Nunito Sans","Lobster","Cabin","Fjalla One","Indie Flower","Anton","Arvo","Josefin Sans","Karla","Libre Baskerville","Noto Sans TC","Hind","Crimson Text","Hind Siliguri",
"Inter","Heebo","Abel","Libre Franklin","Barlow","Varela Round","Pacifico","Dancing Script","Exo 2","Source Code Pro","Shadows Into Light","Merriweather Sans","Asap","Bree Serif","Archivo Narrow","Play","Ubuntu Condensed","Questrial","Abril Fatface","Source Serif Pro","Maven Pro","Francois One","Signika",
"EB Garamond","Comfortaa","Exo","Vollkorn","Teko","Catamaran","Kanit","Cairo","Amatic SC","IBM Plex Sans","Cuprum","Poiret One","Rokkitt","Bebas Neue","Acme","PT Sans Caption","Righteous","Noto Sans SC","Alegreya Sans","Alegreya","Barlow Condensed","Prompt","Gloria Hallelujah","Patua One","Crete Round","Permanent Marker"]
empty!(WordCloud.AvailableFonts)
append!(WordCloud.AvailableFonts, ["$f$w" for w in WordCloud.CandiWeights, f in google_fonts])
nothing
end

# ╔═╡ b09620ef-4495-4c83-ad1c-2d8b0ed70710
begin
function ischinese(text::AbstractString)
	ch = 0
	total = 0
	for c in text
		if match(r"\w", string(c)) !== nothing
			total += 1
			if '\u4e00' <= c <= '\u9fa5'
				ch += 1
			end
		end
	end
	if total > 0
		# println("total: $total; chinese: $ch; ratio: $(ch/total)")
		return ch / total > 0.05
	else
		return false
	end
end

function wordseg_cn(t)
	jieba = pyimport("jieba")
	pyconvert(Vector{String}, jieba.lcut(t))
end
nothing
end

# ╔═╡ 3dc10049-d257-4bcd-9119-2a1af5a0e233
begin
logo = html"""<a href="https://github.com/guo-yong-zhi/WordCloud.jl"><div align="right"><i>https://github.com/guo-yong-zhi/WordCloud.jl</i></div><img src="https://raw.githubusercontent.com/guo-yong-zhi/WordCloud.jl/master/docs/src/assets/logo.svg" alt="WordCloud" width=90></a>"""
nothing
end

# ╔═╡ bda3fa85-04a3-4033-9890-a5b4f10e2a77
md"""$logo  **From** $(@bind texttype Select(["Text", "File", "Web", "Table"])) """

# ╔═╡ 9191230b-b72a-4707-b7cf-1a51c9cdb217
if texttype == "Web"
    md"""**URL:** $(@bind url TextField(80, default="http://en.wikipedia.org/wiki/Special:random"))"""
elseif texttype == "Text"
    @bind text_ TextField((80, 10), defaulttext)
elseif texttype == "File"
	@bind uploadedfile FilePicker()
else
	@bind text_ TextField((30, 15), defaultttable)
end

# ╔═╡ d8e73850-f0a6-4170-be45-5a7527f1ec39
begin
function text_from_url(url)
    resp = HTTP.request("GET", url, redirect=true)
    println(resp.request)
    resp.body |> String |> html2text
end
go
words_weights = ([],[])
wordsnum = 0
try
	if texttype == "Web"
		if !isempty(url)
			text = text_from_url(url)
		end
	elseif texttype == "Text"
		text = text_
	elseif texttype == "File"
		if uploadedfile !== nothing
			text = read(IOBuffer(uploadedfile["data"]), String)
		end
	else
		text = read_table(text_)
	end
	dict_process = rescaleweights(rescale_func, tan(word_length_balance*π/2)) ∘ casemerge! ∘ lemmatize!
	if text isa AbstractString && ischinese(text)
		println("检测到中文")
		text = wordseg_cn(text)
	end
	global words_weights = processtext(
		text, maxnum=maxnum,
		minlength=minlength,
		stopwords=enablestopwords ? WordCloud.stopwords ∪ wordblacklist : wordblacklist,
		process = dict_process)
	global wordsnum = length(words_weights[1])
catch e
	# rethrow(e)
end
nothing
end

# ╔═╡ 77e13474-8987-4cc6-93a9-ea68ca53b217
begin
colors__ = colors_
if colorstyle == :gradient
    if colors__ == :auto
        colors__ = rand(WordCloud.Schemes)
    end
    md"""
    **gradient range:** $(@bind colorstart NumberField(0.:0.01:1., default=0.)) to $(@bind colorstop NumberField(0.:0.01:1., default=1.)). $wordsnum colors of $colors__   
    """
else
    if colors__ == :auto
        md"use random color scheme"
    else
        md"**sampling probability:** $(@bind colorprob NumberField(0.1:0.01:1., default=0.5))"
    end
end
end

# ╔═╡ a758178c-b6e6-491c-83a3-8b3fa594fc9e
begin
colors = colors__
if colors != :auto
    C = WordCloud.colorschemes[colors]
    if colorstyle == :random
        colors_vec = WordCloud.randsubseq(C.colors, colorprob)
        isempty(colors_vec) && (colors_vec = C.colors)
        colors = tuple(colors_vec...)
        colors_vec
    elseif colorstyle == :gradient
        colors = WordCloud.gradient(words_weights[end], scheme=colors, section=(colorstart, max(colorstart, colorstop)))
    else
        C
    end
else
    md""
end
end

# ╔═╡ 9a61bb59-5708-4fc0-81f3-3ca555b3bf5d
begin
function gen_cloud(words_weights)
    if outlinewidth isa Number && outlinewidth >= 0
		olw = outlinewidth
	else
		olw = rand((0, 0, 0, rand(2:10)))
	end
	masksize = :auto
	try
		masksize = Tuple(parse(Int, i ) for i in split(masksize_, ","))
		if length(masksize) == 1
			masksize = masksize[1]
		end
	catch
	end
try
	return wordcloud(
		words_weights;
		colors=colors,
		angles=angles,
		fonts=fonts,
		mask=mask,
		masksize=masksize,
		outline=olw,
		density=density,
		spacing=spacing,
		style=style,
		maskkwargs...
	) |> generate!
catch e
	# rethrow(e)
end
return nothing
end
nothing
end

# ╔═╡ fa6b3269-357e-4bf9-8514-70aff9df427f
begin
google_fonts #used to adjust cell order
@time wc = gen_cloud(words_weights)
wc
end


# ╔═╡ Cell order:
# ╟─bda3fa85-04a3-4033-9890-a5b4f10e2a77
# ╟─9191230b-b72a-4707-b7cf-1a51c9cdb217
# ╟─d8e73850-f0a6-4170-be45-5a7527f1ec39
# ╟─6b7b1da7-03dc-4815-9abf-b8eea410d2fd
# ╟─852810b2-1830-4100-ad74-18b8e96afafe
# ╟─0dddeaf5-08c3-46d0-8a79-30b5ce42ef2b
# ╟─f4844a5f-260b-4713-84bf-69cd8123c7fc
# ╟─1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
# ╟─b38c3ad9-7885-4af6-8394-877fde8ed83b
# ╟─6e614caa-38dc-4028-b0a7-05f7030d5b43
# ╟─dfe608b0-077c-437a-adf2-b1382a0eb4eb
# ╟─872f2653-303f-4b53-8e01-26bec86fc413
# ╟─26d6b795-1cc3-4548-aa07-86c2f6ee0776
# ╟─7993fd44-2fcf-488e-9280-4b4d0bf0e22c
# ╟─8153f1f1-9704-4b1e-bff9-009a54404448
# ╟─14666dc2-7ae4-4808-9db3-456eb26cd435
# ╟─77e13474-8987-4cc6-93a9-ea68ca53b217
# ╟─a758178c-b6e6-491c-83a3-8b3fa594fc9e
# ╟─2870a2ee-aa99-48ec-a26d-fed7b040e6de
# ╟─fa6b3269-357e-4bf9-8514-70aff9df427f
# ╟─21ba4b81-07aa-4828-875d-090e0b918c76
# ╟─66f4b71e-01e5-4279-858b-04d44aeeb574
# ╟─397fdd42-d2b2-46db-bf74-957909f47a58
# ╟─74bd4779-c13c-4d16-a90d-597db21eaa39
# ╟─9396cf96-d553-43db-a839-273fc9febd5a
# ╟─1a4d1e62-6a41-4a75-a759-839445dacf4f
# ╟─986cf1a6-8075-48ae-84d9-55ae11a27da1
# ╟─e7ec8cd7-f60b-4eb0-88fc-76d694976f9d
# ╟─b09620ef-4495-4c83-ad1c-2d8b0ed70710
# ╟─3dc10049-d257-4bcd-9119-2a1af5a0e233
# ╟─9a61bb59-5708-4fc0-81f3-3ca555b3bf5d
# ╟─daf38998-c448-498a-82e2-b48a6a2b9c27
