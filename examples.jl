### A Pluto.jl notebook ###
# v0.16.0

using Markdown
using InteractiveUtils

# ╔═╡ 6a2b140a-1828-11ec-1321-4dd0d0ce401c
using WordCloud

# ╔═╡ d6f8b7bc-b773-4626-b42e-48dc7b7f7f68
using HTTP

# ╔═╡ 8fe03fb6-d024-4869-8ee5-57c7cb770ee4
md"# Basic Usage"

# ╔═╡ d7ce106a-6dbb-4a09-aa56-b21b9fdd4f74
text = """
A word cloud (tag cloud or wordle) is a novelty visual representation of text data, 
typically used to depict keyword metadata (tags) on websites, or to visualize free form text. 
Tags are usually single words, and the importance of each tag is shown with font size or color. 
This format is useful for quickly perceiving the most prominent terms to determine its relative prominence. 
Bigger term means greater weight.
"""

# ╔═╡ f22485b9-cbbe-4d19-8354-8e6b22ccd398
wordcloud(text) |> generate!

# ╔═╡ 73b92429-097d-4665-9f3c-53aa67caa022
md"# Examples"

# ╔═╡ 2ffdece8-427d-4144-9472-b47d48763b7f
WordCloud.examples

# ╔═╡ cf09af76-ca19-4977-b997-d28a6ade4279
begin
function capturestdout(func)
	fname = tempname()
	open(fname, "w") do f
        redirect_stdout(f) do
            func()
        end
    end
	read(fname, String)
end
function juliacode(str)
	Markdown.parse("""```julia
		$str
		```""")
end
end

# ╔═╡ 5d29cbff-8a57-4fc0-97ce-577a43784eee
capturestdout() do
	showexample("alice")
end |> juliacode

# ╔═╡ eca33a61-96c2-495c-87ea-b019c3672f2a
runexample("alice")

# ╔═╡ 75c6dc12-f78f-4bd6-b480-1507e03f74e1
runexample(:fromweb)

# ╔═╡ Cell order:
# ╠═6a2b140a-1828-11ec-1321-4dd0d0ce401c
# ╟─8fe03fb6-d024-4869-8ee5-57c7cb770ee4
# ╠═d7ce106a-6dbb-4a09-aa56-b21b9fdd4f74
# ╠═f22485b9-cbbe-4d19-8354-8e6b22ccd398
# ╟─73b92429-097d-4665-9f3c-53aa67caa022
# ╠═2ffdece8-427d-4144-9472-b47d48763b7f
# ╟─cf09af76-ca19-4977-b997-d28a6ade4279
# ╠═5d29cbff-8a57-4fc0-97ce-577a43784eee
# ╠═eca33a61-96c2-495c-87ea-b019c3672f2a
# ╠═d6f8b7bc-b773-4626-b42e-48dc7b7f7f68
# ╠═75c6dc12-f78f-4bd6-b480-1507e03f74e1
