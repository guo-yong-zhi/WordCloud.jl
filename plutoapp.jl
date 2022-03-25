### A Pluto.jl notebook ###
# v0.18.4

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
using PlutoUI
using WordCloud 
using HTTP
end

# ╔═╡ f4844a5f-260b-4713-84bf-69cd8123c7fc
md"**mask:** $(@bind mask Select([:auto, box, ellipse, squircle, ngon, star])) $(@bind configshape CheckBox(default=false))config"

# ╔═╡ 1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
if configshape
	if mask in (ngon, star)
		md"**npoints:** $(@bind npoints NumberField(3:100, default=5))"
	elseif mask == squircle
		md"**rt:** $(@bind rt NumberField(0.:0.5:3., default=0.))"
	else
		md"random $(mask isa Function ? nameof(mask) : mask) shape"
	end
else
	md"random $(mask isa Function ? nameof(mask) : mask) shape"
end

# ╔═╡ b4798663-d33d-4acc-94a2-c5175b3acb5a
md"**colors:** $(@bind colors_ Select([:auto; WordCloud.Schemes])) $(@bind samplecolor CheckBox(default=true))random sampling"

# ╔═╡ 529ca925-422d-4c36-bc35-9e28a484aab0
if colors_ != :auto
	C = WordCloud.colorschemes[colors_]
	if samplecolor
		colors2 = WordCloud.randsubseq(C.colors, rand())
		isempty(colors2) && (colors2 = C.colors)
		colors = tuple(colors2...)
		colors2
	else
		colors = colors_
		C
	end
else
	colors = colors_
	md"random colors"
end

# ╔═╡ 7993fd44-2fcf-488e-9280-4b4d0bf0e22c
md"""
**angles:** $(@bind anglelength NumberField(0:1000, default=0)) orientations from $(@bind anglestart NumberField(-360:360, default=0))° to $(@bind anglestop NumberField(-360:360, default=0))°  
"""

# ╔═╡ 23b925d3-b94f-487b-a213-f1e365ff9415
md"""**density:** $(@bind density NumberField(0.1:0.01:10.0, default=0.5))　　**spacing:** $(@bind spacing NumberField(0:100, default=1))"""

# ╔═╡ 2870a2ee-aa99-48ec-a26d-fed7b040e6de
@bind go Button("   Go!   ")

# ╔═╡ 456d1448-a17f-4e5f-8998-f1306c621ac4
md"""**URL:** $(@bind url TextField(80, default="http://en.wikipedia.org/wiki/Special:random"))"""

# ╔═╡ 71b59dfe-8a87-4c7a-81c0-ac68c5c0f0ec
@bind web_go CounterButton("   Go!   ")

# ╔═╡ 7f67b50c-8800-45d6-a39c-c3b70307efa5


# ╔═╡ 52e65934-f9a5-4ad3-971f-076070080e8c


# ╔═╡ 3968aaa2-aa49-40b1-a81f-6e8f2fc9a71b


# ╔═╡ 72dec223-fa62-4771-9d7d-c7c4eeec9e87
md"---"

# ╔═╡ 74bd4779-c13c-4d16-a90d-597db21eaa39
begin
	maskkwargs = (;)
	if configshape
		if mask in (ngon, star)
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
else
	angles = range(anglestart, anglestop, length=anglelength)
	isempty(angles) && (angles = :auto)
	angles
end

# ╔═╡ 21ba4b81-07aa-4828-875d-090e0b918c76
defaulttext = """
A word cloud (tag cloud or wordle) is a novelty visual representation of text data, 
typically used to depict keyword metadata (tags) on websites, or to visualize free form text. 
Tags are usually single words, and the importance of each tag is shown with font size or color. Bigger term means greater weight. 
This format is useful for quickly perceiving the most prominent terms to determine its relative prominence.  
"""

# ╔═╡ 9191230b-b72a-4707-b7cf-1a51c9cdb217
@bind text TextField((80, 10), defaulttext)

# ╔═╡ 0bf2ba32-321a-470d-8224-700cbc29cd7a
function scaleweights(dict, scale)
	Dict(k=>scale(v) for (k, v) in dict)
end

# ╔═╡ 6a8d7068-2975-43ab-a387-7f0e7c2e4262
scaleweight(scale) = dict -> scaleweights(dict, scale)

# ╔═╡ 986cf1a6-8075-48ae-84d9-55ae11a27da1
weightscalelist = [
	identity => "n", 
	(√) => "√n", 
	log1p => "log n",
	(n->n^2) => "n²",
	expm1 => "exp n",
	]

# ╔═╡ 8f4d9caa-5f0d-405a-9e46-a6953e9fa67c
md"""**fonts:** $(@bind fonts_ TextField(default="serif bold"))　　**word count:** $(@bind maxnum NumberField(1:5000, default=500))　　**scale:** $(@bind scale_ Select(weightscalelist))"""

# ╔═╡ 1a4d1e62-6a41-4a75-a759-839445dacf4f
if fonts_ == "auto"
	fonts = Symbol(fonts_)
elseif fonts_ === nothing
	fonts = ""
elseif occursin(",", fonts_)
	fonts = tuple(split(fonts_, ",")...)
else
	fonts = fonts_
end

# ╔═╡ 11ce5ff1-d594-4636-91dd-4bed3b463658
dict_process = scaleweight(scale_) ∘ casemerge! ∘ lemmatize!

# ╔═╡ 4016ae0f-dcd6-4aea-b5e9-f06c69a692b1
function fromURL(url)
	resp = nothing
	try
		resp = HTTP.request("GET", url, redirect=true)
	catch e
		return e
	end
	println(resp.request)
	content = resp.body |> String
	words_weights = processtext(html2text(content), maxnum=maxnum, process=dict_process);
	wc = wordcloud(
		words_weights;
		colors=colors,
		angles=angles,
		fonts=fonts,
        mask=mask,
		density=density,
		spacing=spacing,
		maskkwargs...
	) |> generate!
	wc
end

# ╔═╡ 091212c9-828f-4568-89cb-595d29631755
begin
	(web_go > 0 && url isa String && !isempty(url)) ? (wc2=fromURL(url)) : md""
end

# ╔═╡ 94d53b64-508c-49a5-a6c2-ad02dc481952
web_go > 0 && wc2 isa WordCloud.WC && (wordcloudname2 = getwords(wc2, 1))

# ╔═╡ bad0f581-dfe2-4c8c-b821-dd73bcc2f4a5
 web_go > 0 && wc2 isa WordCloud.WC ? DownloadButton(svgstring(paintsvg(wc2)), "wordcloud-$(wordcloudname2).svg") : md"Fill in a web url and click the button."

# ╔═╡ 27fb4920-d120-43f6-8a03-0b09877c99c4
function fromtext(text)
	try
		go
		words_weights = processtext(text, maxnum=maxnum, process = dict_process)
		wordcloud(
			words_weights;
			colors=colors,
			angles=angles,
			fonts=fonts,
	        mask=mask,
			density=density,
			spacing=spacing,
			maskkwargs...
		) |>  generate!
	catch e
		if !(e isa AssertionError)
			throw(e)
		end
	end
end

# ╔═╡ fa6b3269-357e-4bf9-8514-70aff9df427f
begin
	wc1 = fromtext(text)
	wc1
end

# ╔═╡ bcb2b087-ba7c-4f5d-aa6b-44c3545f6409
wordcloudname1 = getwords(wc1, 1)

# ╔═╡ 0ad31e2e-555e-45e9-a6c1-2fe218e77b5e
 wc1!==nothing ? DownloadButton(svgstring(paintsvg(wc1)), "wordcloud-$(wordcloudname1).svg") : md"Please enter some text..."

# ╔═╡ Cell order:
# ╟─9191230b-b72a-4707-b7cf-1a51c9cdb217
# ╟─f4844a5f-260b-4713-84bf-69cd8123c7fc
# ╟─1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
# ╟─b4798663-d33d-4acc-94a2-c5175b3acb5a
# ╟─529ca925-422d-4c36-bc35-9e28a484aab0
# ╟─7993fd44-2fcf-488e-9280-4b4d0bf0e22c
# ╟─8f4d9caa-5f0d-405a-9e46-a6953e9fa67c
# ╟─23b925d3-b94f-487b-a213-f1e365ff9415
# ╟─2870a2ee-aa99-48ec-a26d-fed7b040e6de
# ╟─0ad31e2e-555e-45e9-a6c1-2fe218e77b5e
# ╟─fa6b3269-357e-4bf9-8514-70aff9df427f
# ╟─456d1448-a17f-4e5f-8998-f1306c621ac4
# ╟─71b59dfe-8a87-4c7a-81c0-ac68c5c0f0ec
# ╟─bad0f581-dfe2-4c8c-b821-dd73bcc2f4a5
# ╟─091212c9-828f-4568-89cb-595d29631755
# ╟─7f67b50c-8800-45d6-a39c-c3b70307efa5
# ╟─52e65934-f9a5-4ad3-971f-076070080e8c
# ╟─3968aaa2-aa49-40b1-a81f-6e8f2fc9a71b
# ╟─72dec223-fa62-4771-9d7d-c7c4eeec9e87
# ╟─4016ae0f-dcd6-4aea-b5e9-f06c69a692b1
# ╟─94d53b64-508c-49a5-a6c2-ad02dc481952
# ╟─daf38998-c448-498a-82e2-b48a6a2b9c27
# ╟─74bd4779-c13c-4d16-a90d-597db21eaa39
# ╟─9396cf96-d553-43db-a839-273fc9febd5a
# ╟─1a4d1e62-6a41-4a75-a759-839445dacf4f
# ╟─21ba4b81-07aa-4828-875d-090e0b918c76
# ╟─27fb4920-d120-43f6-8a03-0b09877c99c4
# ╟─0bf2ba32-321a-470d-8224-700cbc29cd7a
# ╟─6a8d7068-2975-43ab-a387-7f0e7c2e4262
# ╟─986cf1a6-8075-48ae-84d9-55ae11a27da1
# ╟─11ce5ff1-d594-4636-91dd-4bed3b463658
# ╟─bcb2b087-ba7c-4f5d-aa6b-44c3545f6409
