### A Pluto.jl notebook ###
# v0.19.17

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
import Pkg; Pkg.activate()
using PlutoUI
using WordCloud 
using HTTP
end

# ╔═╡ f83db0a7-9a83-4c41-8fb1-c2a75317deec
md"""$(Resource("https://raw.githubusercontent.com/guo-yong-zhi/WordCloud.jl/master/docs/src/assets/logo.svg", :width => 90)) **From** $(@bind texttype Select(["Text", "File", "Web"]))"""

# ╔═╡ f4844a5f-260b-4713-84bf-69cd8123c7fc
md"""**mask:** $(@bind mask_ Select([:auto, box, ellipse, squircle, ngon, star, bezingon, bezistar])) $(@bind configshape CheckBox(default=false))config"""

# ╔═╡ 1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
begin
if mask_ == :auto
	md"""**mask file:** $(@bind uploadedmask FilePicker([MIME("image/*")]))"""
elseif configshape
    if mask_ in (ngon, star, bezingon, bezistar)
        md"**npoints:** $(@bind npoints NumberField(3:100, default=5))"
	elseif mask_ == squircle
        md"**rt:** $(@bind rt NumberField(0.:0.5:3., default=0.))"
    else
        md"random $(mask_ isa Function ? nameof(mask_) : mask_) shape"
    end
else
    md"random $(mask_ isa Function ? nameof(mask_) : mask_) shape"
end
end

# ╔═╡ 6e614caa-38dc-4028-b0a7-05f7030d5b43
md"**style:** $(@bind style Select([:auto, :uniform, :gathering]))"

# ╔═╡ b4798663-d33d-4acc-94a2-c5175b3acb5a
md"**colors:** $(@bind colors_ Select([:auto; WordCloud.Schemes])) $(@bind colorstyle Select([:random, :gradient]))"

# ╔═╡ 7993fd44-2fcf-488e-9280-4b4d0bf0e22c
md"""
**angles:** $(@bind anglelength NumberField(0:1000, default=0)) orientations from $(@bind anglestart NumberField(-360:360, default=0))° to $(@bind anglestop NumberField(-360:360, default=0))°  
"""

# ╔═╡ 8f4d9caa-5f0d-405a-9e46-a6953e9fa67c
md"""**fonts:** $(@bind fonts_ TextField(default="auto"))　[*browse fonts*](https://fonts.google.com)"""

# ╔═╡ 23b925d3-b94f-487b-a213-f1e365ff9415
md"""**density:** $(@bind density NumberField(0.1:0.01:10.0, default=0.5))　　**spacing:** $(@bind spacing NumberField(0:100, default=1))"""

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
    nothing
end

# ╔═╡ 9191230b-b72a-4707-b7cf-1a51c9cdb217
if texttype == "Web"
    md"""**URL:** $(@bind url TextField(80, default="http://en.wikipedia.org/wiki/Special:random"))"""
elseif texttype == "Text"
    @bind text_ TextField((80, 10), defaulttext)
else
	@bind uploadedfile FilePicker()
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
if anglelength == 0
    angles = :auto
	nothing
else
    angles = range(anglestart, anglestop, length=anglelength)
    isempty(angles) && (angles = :auto)
    nothing
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

# ╔═╡ 4016ae0f-dcd6-4aea-b5e9-f06c69a692b1
begin
function text_from_url(url)
    resp = HTTP.request("GET", url, redirect=true)
    println(resp.request)
    resp.body |> String |> html2text
end
function scaleweights(dict, scale)
    Dict(k=>scale(v) for (k, v) in dict)
end
scaleweight(scale) = dict -> scaleweights(dict, scale)
nothing
end

# ╔═╡ 986cf1a6-8075-48ae-84d9-55ae11a27da1
begin
weightscalelist = [
    identity => "n", 
    (√) => "√n", 
    log1p => "log n",
    (n->n^2) => "n²",
    expm1 => "exp n",
    ]
nothing
end

# ╔═╡ 4d7cb093-f953-4fc0-bb5e-92e7c1716fd7
md"**word count:** $(@bind maxnum NumberField(1:5000, default=500))　　**scale:** $(@bind scale_ Select(weightscalelist))"

# ╔═╡ f9e0e9a1-2b44-4ef9-a846-92a6aa08fb40
begin
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
		else
			if uploadedfile !== nothing
				text = read(IOBuffer(uploadedfile["data"]), String)
			end
        end
        dict_process = scaleweight(scale_) ∘ casemerge! ∘ lemmatize!
        global words_weights = processtext(text, maxnum=maxnum, process = dict_process)
        global wordsnum = length(words_weights[1])
    catch
    end
    nothing
end

# ╔═╡ 68dced3e-1ec2-4a70-b2b9-043fb62967c5
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
        md""
    else
        md"**probability:** $(@bind colorprob NumberField(0.1:0.01:1., default=0.5))"
    end
end
end

# ╔═╡ 529ca925-422d-4c36-bc35-9e28a484aab0
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
    md"random colors"
end
end

# ╔═╡ 27fb4920-d120-43f6-8a03-0b09877c99c4
begin
function gen_cloud(words_weights)
try
	return wordcloud(
		words_weights;
		colors=colors,
		angles=angles,
		fonts=fonts,
		mask=mask,
		density=density,
		spacing=spacing,
		style=style,
		maskkwargs...
	) |> generate!
catch
end
return nothing
end
nothing
end

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

# ╔═╡ fa6b3269-357e-4bf9-8514-70aff9df427f
begin
google_fonts #used to adjust cell order
wc = gen_cloud(words_weights)
wc
end

# ╔═╡ 0ad31e2e-555e-45e9-a6c1-2fe218e77b5e
if wc!==nothing
    DownloadButton(svgstring(paintsvg(wc)), "wordcloud-$(getwords(wc, 1)).svg")
else
    nothing
end

# ╔═╡ Cell order:
# ╟─f83db0a7-9a83-4c41-8fb1-c2a75317deec
# ╟─9191230b-b72a-4707-b7cf-1a51c9cdb217
# ╟─f9e0e9a1-2b44-4ef9-a846-92a6aa08fb40
# ╟─f4844a5f-260b-4713-84bf-69cd8123c7fc
# ╟─1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
# ╟─6e614caa-38dc-4028-b0a7-05f7030d5b43
# ╟─b4798663-d33d-4acc-94a2-c5175b3acb5a
# ╟─68dced3e-1ec2-4a70-b2b9-043fb62967c5
# ╟─529ca925-422d-4c36-bc35-9e28a484aab0
# ╟─7993fd44-2fcf-488e-9280-4b4d0bf0e22c
# ╟─8f4d9caa-5f0d-405a-9e46-a6953e9fa67c
# ╟─4d7cb093-f953-4fc0-bb5e-92e7c1716fd7
# ╟─23b925d3-b94f-487b-a213-f1e365ff9415
# ╟─2870a2ee-aa99-48ec-a26d-fed7b040e6de
# ╟─0ad31e2e-555e-45e9-a6c1-2fe218e77b5e
# ╟─fa6b3269-357e-4bf9-8514-70aff9df427f
# ╟─21ba4b81-07aa-4828-875d-090e0b918c76
# ╟─397fdd42-d2b2-46db-bf74-957909f47a58
# ╟─74bd4779-c13c-4d16-a90d-597db21eaa39
# ╟─9396cf96-d553-43db-a839-273fc9febd5a
# ╟─1a4d1e62-6a41-4a75-a759-839445dacf4f
# ╟─4016ae0f-dcd6-4aea-b5e9-f06c69a692b1
# ╟─27fb4920-d120-43f6-8a03-0b09877c99c4
# ╟─986cf1a6-8075-48ae-84d9-55ae11a27da1
# ╟─e7ec8cd7-f60b-4eb0-88fc-76d694976f9d
# ╟─daf38998-c448-498a-82e2-b48a6a2b9c27
