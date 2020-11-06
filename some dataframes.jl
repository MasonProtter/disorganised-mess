### A Pluto.jl notebook ###
# v0.12.7

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 71697846-1fb4-11eb-053e-b73ac96850cd
using DataFrames

# ╔═╡ 0f567b92-1fb7-11eb-1313-8dd2bd83d24c
using PlutoUI

# ╔═╡ 052e4444-1fc4-11eb-2bdc-6def590dfe5d


# ╔═╡ a050d25e-1fc7-11eb-0d78-9d401cc8ecc8
sl = @bind x html"<input type=range>"

# ╔═╡ 37fc1398-1fc8-11eb-28dd-87ffa3e555a8
DataFrame(:a => [html"<input type=range>"])

# ╔═╡ 0dc69172-1fc6-11eb-20dc-41f51dbb7198
md"""
# New ✨
"""

# ╔═╡ 143603bc-1fc6-11eb-2770-0fdf336cefbd
md"""
# DataFrames.jl default
"""

# ╔═╡ 98253b72-1fce-11eb-1216-97e38583501d
DataFrame(rand(200,20))

# ╔═╡ 8d91acd8-1fdb-11eb-326a-376d2c5bdd70
collect(1:100)

# ╔═╡ cf254188-1fd0-11eb-37d9-c1ead57db23a
123

# ╔═╡ 903a4310-1fb4-11eb-0a5b-5fca37c324c1
struct Wow
	x
end

# ╔═╡ 7bdf2f0c-1fb7-11eb-2b4f-539bb59a1782
rand(['a':'z'..., '\n'], 100000) |> String |> Text

# ╔═╡ 979aa9b0-1fbc-11eb-0c9a-fb7d75463c80
collect(1:50)

# ╔═╡ c415ab82-1fb9-11eb-2358-91e1ee287f77
img = md"![](https://fonsp.com/img/doggoSmall.jpg?raw=true)"

# ╔═╡ 9d41474c-1fc7-11eb-06ae-15831e77fafe
begin
	sleep(.2)
	@info "" x
	if !@isdefined(y)
		y = 20
	end
	DataFrame(
		"❤" => [sl, (@bind y Slider(1:100, default=y)), 3], 
		"🙊" => Wow.([6,x,y]), 
		"Hondjes enzo" => [md"**Wow** dit is echt heel erg veel tekst dit gaat _sowieso_ niet passen in een klein celletje", [img, img], rand(50)]
	)
end

# ╔═╡ 86d2be04-1fb4-11eb-0394-aff72c109f2d
d1 = DataFrame(
	# "❤" => [1, 2, 3], 
	"🙊" => Wow.(6:8), 
	"Hondjes enzo" => [md"**Wow** dit is echt heel erg veel tekst dit gaat _sowieso_ niet passen in een klein celletje", [img, img], rand(50)],
	"Cool plots" => plot.([sin, cos, tan]; size=(200,100))
)

# ╔═╡ 19d47f5a-1fc7-11eb-3829-2d9b512690da
d2 = DataFrame(
	"❤" => [rand('a':'z', 10) |> String for _ in 1:3], 
	"🙊" => Wow.(6:8), 
	"Hondjes enzo" => [md"**Wow** dit is echt heel erg veel tekst dit gaat _sowieso_ niet passen in een klein celletje", [img, img], rand(50)]
)

# ╔═╡ 880bf2e2-1fc1-11eb-0787-2fda069b81d0
dbig = let
	dwide = hcat(d2, d2, d2, d2, makeunique=true)
	vcat(dwide, dwide, dwide, dwide, dwide, dwide, dwide, dwide, dwide)
end

# ╔═╡ 016ffc0a-1fb8-11eb-2d6b-056c2da7d427
d3 = DataFrame(:a => 1:1000)

# ╔═╡ 4d267b74-1fb8-11eb-30a4-1dc7ad25f33f
default_iocontext = IOContext(devnull, :color => false, :limit => true, :displaysize => (18, 88))

# ╔═╡ 11e8a2ea-1fb7-11eb-2c30-bb886f8725d2
old(x) = HTML(repr(MIME"text/html"(), x; context=default_iocontext))

# ╔═╡ 11a61136-1fb8-11eb-1a02-0b9d7651e876
old(d1)

# ╔═╡ 1e165c64-1fb8-11eb-17cd-0f93602efc3c
old(d2)

# ╔═╡ 94fabb8c-1fb7-11eb-3b18-6b32f209810b
replace(repr(MIME"text/html"(), d1), "><"=>">\n<") |> Text

# ╔═╡ Cell order:
# ╟─052e4444-1fc4-11eb-2bdc-6def590dfe5d
# ╠═a050d25e-1fc7-11eb-0d78-9d401cc8ecc8
# ╠═37fc1398-1fc8-11eb-28dd-87ffa3e555a8
# ╠═9d41474c-1fc7-11eb-06ae-15831e77fafe
# ╟─0dc69172-1fc6-11eb-20dc-41f51dbb7198
# ╠═86d2be04-1fb4-11eb-0394-aff72c109f2d
# ╠═19d47f5a-1fc7-11eb-3829-2d9b512690da
# ╟─143603bc-1fc6-11eb-2770-0fdf336cefbd
# ╠═11a61136-1fb8-11eb-1a02-0b9d7651e876
# ╠═880bf2e2-1fc1-11eb-0787-2fda069b81d0
# ╠═98253b72-1fce-11eb-1216-97e38583501d
# ╠═8d91acd8-1fdb-11eb-326a-376d2c5bdd70
# ╠═71697846-1fb4-11eb-053e-b73ac96850cd
# ╠═cf254188-1fd0-11eb-37d9-c1ead57db23a
# ╠═903a4310-1fb4-11eb-0a5b-5fca37c324c1
# ╠═7bdf2f0c-1fb7-11eb-2b4f-539bb59a1782
# ╠═979aa9b0-1fbc-11eb-0c9a-fb7d75463c80
# ╠═c415ab82-1fb9-11eb-2358-91e1ee287f77
# ╠═0f567b92-1fb7-11eb-1313-8dd2bd83d24c
# ╠═016ffc0a-1fb8-11eb-2d6b-056c2da7d427
# ╠═1e165c64-1fb8-11eb-17cd-0f93602efc3c
# ╠═4d267b74-1fb8-11eb-30a4-1dc7ad25f33f
# ╠═11e8a2ea-1fb7-11eb-2c30-bb886f8725d2
# ╠═94fabb8c-1fb7-11eb-3b18-6b32f209810b
