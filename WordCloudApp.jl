### A Pluto.jl notebook ###
# v0.19.42

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
# ╠═╡ show_logs = false
begin 
    import Pkg
    Pkg.activate(homedir())
    # Pkg.activate()
    using PlutoUI
    using WordCloud
    using HTTP
    using ImageIO
    using PythonCall
	import TinySegmenter
	# Pkg.add(["PlutoUI", "WordCloud", "HTTP", "ImageIO", "PythonCall", "CondaPkg", "TinySegmenter"])
    # using CondaPkg; CondaPkg.add("jieba")
end

# ╔═╡ bda3fa85-04a3-4033-9890-a5b4f10e2a77
begin
    logo = html"""<a href="https://github.com/guo-yong-zhi/WordCloud.jl"><div align="right"><i>https://github.com/guo-yong-zhi/WordCloud.jl</i></div><img src="https://raw.githubusercontent.com/guo-yong-zhi/WordCloud.jl/master/docs/src/assets/logo.svg" alt="WordCloud" width=90></a>"""

    md"""$logo  **Data source:** $(@bind texttype Select(["Text", "File", "Web", "Table"]))　*You can directly input the text, or give a file, a table or even a website.*"""
end

# ╔═╡ 6b7b1da7-03dc-4815-9abf-b8eea410d2fd
md"**max word count:** $(@bind maxnum NumberField(1:5000, default=500))　　**shortest word:** $(@bind minlength NumberField(1:1000, default=1))"

# ╔═╡ 852810b2-1830-4100-ad74-18b8e96afafe
md"""
**language:** $(@bind language_ TextField(default="auto"))　　**word blacklist:** $(@bind wordblacklist_ TextField(default="")) $(@bind enablestopwords　　CheckBox(default=true)) built-in list"""

# ╔═╡ 0dddeaf5-08c3-46d0-8a79-30b5ce42ef2b
begin
    wordblacklist = [wordblacklist_[i] for i in findall(r"[^\s,;，；、]+", wordblacklist_)]
    isempty(wordblacklist) ? md"*Add the words you want to exclude.*" : wordblacklist
end

# ╔═╡ dfe608b0-077c-437a-adf2-b1382a0eb4eb
begin
    weightscale_funcs = [
        identity => "linear",
        (√) => "√x",
        log1p => "log x",
        (n -> n^2) => "x²",
        expm1 => "exp x",
    ]
    md"**scale:** $(@bind rescale_func Select(weightscale_funcs))　　**word length balance:** $(@bind word_length_balance Slider(-1:0.01:1, default=0, show_value=true))"
end

# ╔═╡ b199e23c-de37-4bcf-b563-70bccb59ba4e
md"""###### ✿ Overall Layout"""

# ╔═╡ 6e614caa-38dc-4028-b0a7-05f7030d5b43
md"**layout style:** $(@bind style Select([:auto, :uniform, :gathering]))"

# ╔═╡ 1e8947ee-5f2a-4bed-99d5-f24ebc6cfbf3
md"""**text density:** $(@bind density NumberField(0.1:0.01:10.0, default=0.5))　　**min word spacing:** $(@bind spacing NumberField(0:100, default=2))"""

# ╔═╡ 9bb3b69a-fd5b-469a-998f-23b6c9e23e5d
md"""###### ✿ Mask Style"""

# ╔═╡ f4844a5f-260b-4713-84bf-69cd8123c7fc
md"""**mask shape:** $(@bind mask_ Select([:auto, :customsvg, box, ellipse, squircle, ngon, star, bezingon, bezistar])) $(@bind configshape　　CheckBox(default=false))additional config

**mask size:** $(@bind masksize_ TextField(default="auto"))　*e.g. 400,300*"""

# ╔═╡ 1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
begin
    defaultsvgstr = """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
      <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z" />
    </svg>
    """
    if mask_ == :auto
        md"""**upload an image as a mask:** $(@bind uploadedmask FilePicker([MIME("image/*")]))"""
    elseif mask_ == :customsvg
        md"""**svg string:**　*For example, you can copy svg code from [here](https://heroicons.com/). You should choose a solid type icon.*

        $(@bind masksvgstr TextField((55, 2), default=defaultsvgstr))"""
    elseif configshape
        if mask_ in (ngon, star, bezingon, bezistar)
            md"**number of points:** $(@bind npoints NumberField(3:100, default=5))"
        elseif mask_ == squircle
            md"**shape parameter:** $(@bind rt NumberField(0.:0.5:3., default=0.))　*0: rectangle; 1: ellipse; 2: rhombus*; >2: four-armed star"
        else
            md"🛈 random $(mask_ isa Function ? nameof(mask_) : mask_) shape in use"
        end
    else
        md"🛈 random $(mask_ isa Function ? nameof(mask_) : mask_) shape in use"
    end
end

# ╔═╡ a90b83ca-384d-4157-99b3-df15764a242f
md"""**mask color:** $(@bind maskcolor_ Select([:auto, :default, :original, "custom color"], default=:default))　　**background color:** $(@bind backgroundcolor_ Select([:auto, :default, :original, :maskcolor, "custom color"], default=:default))　 $(@bind showbackground CheckBox(default=true))show background"""

# ╔═╡ 1842a3c8-4b47-4d36-a4e4-9a5ff4df452e
if maskcolor_ == "custom color"
    if backgroundcolor_ == "custom color"
        r = md"""**mask color:** $(@bind maskcolor ColorStringPicker())　　**background color:** $(@bind backgroundcolor ColorStringPicker())"""
    else
        backgroundcolor = backgroundcolor_
        r = md"""**mask color:** $(@bind maskcolor ColorStringPicker())"""
    end
else
    maskcolor = maskcolor_
    if backgroundcolor_ == "custom color"
        r = md"""**background color:** $(@bind backgroundcolor ColorStringPicker())"""
    else
        backgroundcolor = backgroundcolor_
        md"🛈 random mask color and background color in use"
    end
end


# ╔═╡ b38c3ad9-7885-4af6-8394-877fde8ed83b
md"**mask outline:** $(@bind outlinewidth NumberField(-1:100, default=-1))　*-1 means random*"

# ╔═╡ bd801e34-c012-4afc-8100-02b5e06d4e2b
md"""###### ✿ Text Style"""

# ╔═╡ 26d6b795-1cc3-4548-aa07-86c2f6ee0776
md"""**text fonts:** $(@bind fonts_ TextField(default="auto"))　*Use commas to separate multiple fonts.*　[*Browse available fonts*](https://fonts.google.com)"""

# ╔═╡ 7993fd44-2fcf-488e-9280-4b4d0bf0e22c
md"""
**text orientations:** $(@bind anglelength NumberField(0:1000, default=0)) orientations　*0 means random*
"""

# ╔═╡ 8153f1f1-9704-4b1e-bff9-009a54404448
if anglelength > 0
    md"""from $(@bind anglestart NumberField(-360:360, default=0)) degrees to $(@bind anglestop NumberField(-360:360, default=0)) degrees"""
else
    md"🛈 random text orientations in use"
end

# ╔═╡ 14666dc2-7ae4-4808-9db3-456eb26cd435
md"**text colors:** $(@bind colors_ Select([:auto; WordCloud.Schemes])) $(@bind colorstyle Select([:random, :gradient]))　[*Browse colorschemes in `ColorSchemes.jl`*](https://juliagraphics.github.io/ColorSchemes.jl/stable/catalogue)"

# ╔═╡ 2870a2ee-aa99-48ec-a26d-fed7b040e6de
@bind go Button("    🎲 Try again !    ")

# ╔═╡ 21ba4b81-07aa-4828-875d-090e0b918c76
begin
    defaulttext = """
    A word cloud (tag cloud or wordle) is a novelty visual representation of text data, 
    typically used to depict keyword metadata (tags) on websites, or to visualize free form text. 
    Tags are usually single words, and the importance of each tag is shown with font size or color. Bigger term means greater weight. 
    This format is useful for quickly perceiving the most prominent terms to determine its relative prominence.  
    """
    defaultttable = """
        বাংলা, 234
        भोजपुरी, 52.3
        مصري, 77.4
        English, 380
        Français, 80.8
        ગુજરાતી, 57.1
        هَوْسَ, 51.7
        हिन्दी, 345
        فارسی, 57.2
        Italiano, 64.6
        日本語, 123
        ꦧꦱꦗꦮ, 68.3
        한국어, 81.7
        普通话, 939
        मराठी, 83.2
        Português, 236
        Русский, 147
        Español, 485
        Deutsch, 75.3
        தமிழ், 78.6
        తెలుగు, 83
        Türkçe, 84
        اردو, 70.6
        Tiếng Việt, 85
        پنجابی, 66.7
        吴语, 83.4
        粤语, 86.1
        """
    nothing
end

# ╔═╡ 9191230b-b72a-4707-b7cf-1a51c9cdb217
if texttype == "Web"
    md"""🌐 $(@bind url TextField(70, default="http://en.wikipedia.org/wiki/Special:random")) 
    """
elseif texttype == "Text"
    @bind text_ TextField((55, 10), defaulttext)
elseif texttype == "File"
    @bind uploadedfile FilePicker()
else
    
	md"""
	*The first column contains words, the second column contains weights.*
	$(@bind text_ TextField((20, 15), defaultttable))
	"""
end

# ╔═╡ 66f4b71e-01e5-4279-858b-04d44aeeb574
begin
    function read_table(text)
        ps = [split(it, r"[,;\t]") for it in split(strip(text), "\n")]
        ps = sort([(first(it), parse(Float64, last(it))) for it in ps], by=last, rev=true)
        maxwidth = maximum(length ∘ first, ps[1:min(end, 9)])
        println(length(ps), " items table:\n")
        for (i, p) in enumerate(ps)
            if i == 10
                println("\t...")
                break
            end
            println("\t", p[1], " "^(maxwidth - length(p[1])) * "\t|\t", p[end])
        end
        println()
        ps
    end
    nothing
end

# ╔═╡ d8e73850-f0a6-4170-be45-5a7527f1ec39
begin
    function text_from_url(url)
        resp = HTTP.request("GET", url, redirect=true)
        println(resp.request)
        resp.body |> String |> html2text
    end
    go
    words_weights = ([], [])
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
        dict_process = rescaleweights(rescale_func, tan(word_length_balance * π / 2)) ∘ casemerge!
		lang = language_
		if lang == "auto"
        	lang = Symbol(lang)
		end
		if texttype == "Table"
			lang = WordCloud.TextProcessing.detect_language(first.(text), lang)
		else
			lang = WordCloud.TextProcessing.detect_language(text, lang)
		end
		_stopwords = enablestopwords ? get(WordCloud.STOPWORDS, lang, Set())∪ wordblacklist : wordblacklist
        global words_weights = processtext(
            text, 
			language=lang,
			maxnum=maxnum,
            minlength=minlength,
            stopwords=_stopwords,
            process=dict_process)
        global wordsnum = length(words_weights[1])
    catch e
        # rethrow(e)
    end
	md"""###### ✿ Text Processing
    """
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
            md"🛈 random color scheme in use"
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

# ╔═╡ 397fdd42-d2b2-46db-bf74-957909f47a58
begin
    function svgshapemask(svgstr, masksize; preservevolume=true, kargs...)
        ags = [string(masksize), "preservevolume=$preservevolume", ("$k=$(repr(v))" for (k, v) in kargs)...]
        println("svgshapemask(", join(ags, ", "), ")")
        masksvg = WordCloud.Render.loadsvg(masksvgstr)
        vf = preservevolume ? WordCloud.volume_factor(masksvg) : 1
        resizedsvg = WordCloud.Render.imresize(masksvg, masksize...; ratio=vf)
        loadmask(WordCloud.Render.tobitmap(resizedsvg); kargs...)
    end
    svgshapefunc(svgstr) = (a...; ka...) -> svgshapemask(svgstr, a...; ka...)
    if mask_ == :auto
        if uploadedmask === nothing
            mask = :auto
            nothing
        else
            mask = loadmask(IOBuffer(uploadedmask["data"]))
            nothing
        end
    elseif mask_ == :customsvg
        mask = svgshapefunc(masksvgstr)
        nothing
    else
        mask = mask_
        nothing
    end
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


# ╔═╡ b09620ef-4495-4c83-ad1c-2d8b0ed70710
begin
    google_fonts = ["Roboto", "Open Sans", "Lato", "Montserrat", "Noto Sans JP", "Roboto Condensed", "Oswald", "Source Sans Pro", "Slabo 27px", "Raleway", "PT Sans", "Poppins", "Roboto Slab", "Merriweather", "Noto Sans", "Ubuntu", "Roboto Mono", "Lora", "Playfair Display", "Nunito", "PT Serif", "Titillium Web", "PT Sans Narrow", "Arimo", "Noto Serif",
        "Rubik", "Fira Sans", "Work Sans", "Noto Sans KR", "Quicksand", "Dosis", "Inconsolata", "Oxygen", "Mukta", "Bitter", "Nanum Gothic", "Yanone Kaffeesatz", "Nunito Sans", "Lobster", "Cabin", "Fjalla One", "Indie Flower", "Anton", "Arvo", "Josefin Sans", "Karla", "Libre Baskerville", "Noto Sans TC", "Hind", "Crimson Text", "Hind Siliguri",
        "Inter", "Heebo", "Abel", "Libre Franklin", "Barlow", "Varela Round", "Pacifico", "Dancing Script", "Exo 2", "Source Code Pro", "Shadows Into Light", "Merriweather Sans", "Asap", "Bree Serif", "Archivo Narrow", "Play", "Ubuntu Condensed", "Questrial", "Abril Fatface", "Source Serif Pro", "Maven Pro", "Francois One", "Signika",
        "EB Garamond", "Comfortaa", "Exo", "Vollkorn", "Teko", "Catamaran", "Kanit", "Cairo", "Amatic SC", "IBM Plex Sans", "Cuprum", "Poiret One", "Rokkitt", "Bebas Neue", "Acme", "PT Sans Caption", "Righteous", "Noto Sans SC", "Alegreya Sans", "Alegreya", "Barlow Condensed", "Prompt", "Gloria Hallelujah", "Patua One", "Crete Round", "Permanent Marker"]
    empty!(WordCloud.AvailableFonts)
    append!(WordCloud.AvailableFonts, ["$f$w" for w in WordCloud.CandiWeights, f in google_fonts])
	function wordseg_cn(t)
        jieba = pyimport("jieba")
        pyconvert(Vector{String}, jieba.lcut(t))
    end
	WordCloud.settokenizer!("zho", wordseg_cn)
	WordCloud.settokenizer!("jpn", TinySegmenter.tokenize)
    nothing
end

# ╔═╡ fa6b3269-357e-4bf9-8514-70aff9df427f
begin
	google_fonts # used to adjust cell order
    function gen_cloud(words_weights)
        if outlinewidth isa Number && outlinewidth >= 0
            olw = outlinewidth
        else
            olw = rand((0, 0, 0, rand(2:10)))
        end
        masksize = :auto
        try
            masksize = Tuple(parse(Int, i) for i in split(masksize_, ","))
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
                maskcolor=maskcolor,
                backgroundcolor=backgroundcolor,
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
    @time wc = gen_cloud(words_weights)
    if wc !== nothing
        paintsvg(wc, background=showbackground)
    end
end


# ╔═╡ Cell order:
# ╟─bda3fa85-04a3-4033-9890-a5b4f10e2a77
# ╟─9191230b-b72a-4707-b7cf-1a51c9cdb217
# ╟─d8e73850-f0a6-4170-be45-5a7527f1ec39
# ╟─6b7b1da7-03dc-4815-9abf-b8eea410d2fd
# ╟─852810b2-1830-4100-ad74-18b8e96afafe
# ╟─0dddeaf5-08c3-46d0-8a79-30b5ce42ef2b
# ╟─dfe608b0-077c-437a-adf2-b1382a0eb4eb
# ╟─b199e23c-de37-4bcf-b563-70bccb59ba4e
# ╟─6e614caa-38dc-4028-b0a7-05f7030d5b43
# ╟─1e8947ee-5f2a-4bed-99d5-f24ebc6cfbf3
# ╟─9bb3b69a-fd5b-469a-998f-23b6c9e23e5d
# ╟─f4844a5f-260b-4713-84bf-69cd8123c7fc
# ╟─1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
# ╟─a90b83ca-384d-4157-99b3-df15764a242f
# ╟─1842a3c8-4b47-4d36-a4e4-9a5ff4df452e
# ╟─b38c3ad9-7885-4af6-8394-877fde8ed83b
# ╟─bd801e34-c012-4afc-8100-02b5e06d4e2b
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
# ╟─b09620ef-4495-4c83-ad1c-2d8b0ed70710
# ╟─daf38998-c448-498a-82e2-b48a6a2b9c27
