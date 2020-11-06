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

# ╔═╡ c3e52bf2-ca9a-11ea-13aa-03a4335f2906
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
			Pkg.PackageSpec(name="Plots", version="1.6-1"),
			Pkg.PackageSpec(name="PlutoUI", version="0.6.8-0.6"),
			Pkg.PackageSpec(name="ImageMagick"),
			Pkg.PackageSpec(name="Images", version="0.23"),
			])
	using Plots
	using PlutoUI
	using LinearAlgebra
	using Images
end

# ╔═╡ 1df32310-19c4-11eb-0824-6766cd21aaf4
md"_homework 8, version 1_"

# ╔═╡ 84d846d8-203a-11eb-3ab9-5ba145aa501c
md"""
# TODO:
1. Use scene instead of vector of Objects
2. Finish the step_ray function 
3. Transcripts for youtube lectures
"""

# ╔═╡ 1e01c912-19c4-11eb-269a-9796cccdf274
# WARNING FOR OLD PLUTO VERSIONS, DONT DELETE ME

html"""
<script>
const warning = html`
<h2 style="color: #800">Oopsie! You need to update Pluto to the latest version</h2>
<p>Close Pluto, go to the REPL, and type:
<pre><code>julia> import Pkg
julia> Pkg.update("Pluto")
</code></pre>
`

const super_old = window.version_info == null || window.version_info.pluto == null
if(super_old) {
	return warning
}
const version_str = window.version_info.pluto.substring(1)
const numbers = version_str.split(".").map(Number)
console.log(numbers)

if(numbers[0] > 0 || numbers[1] > 12 || numbers[2] > 1) {
	
} else {
	return warning
}

</script>

"""

# ╔═╡ 1e109620-19c4-11eb-013e-1bc95c14c2ba
md"""

# **Homework 8**: _Raytracing in 3D_
`18.S191`, fall 2020

This notebook contains _built-in, live answer checks_! In some exercises you will see a coloured box, which runs a test case on your code, and provides feedback based on the result. Simply edit the code, run it, and the check runs again.

_For MIT students:_ there will also be some additional (secret) test cases that will be run as part of the grading process, and we will look at your notebook and write comments.

This particular homework will continue from the previous week's homework, so we will define a number of functions at the start of this homework set.

Feel free to ask questions!
"""

# ╔═╡ 1e202680-19c4-11eb-29a7-99061b886b3c
# edit the code below to set your name and kerberos ID (i.e. email without @mit.edu)

student = (name = "Jazzy Doe", kerberos_id = "jazz")

# you might need to wait until all other cells in this notebook have completed running. 
# scroll around the page to see what's up

# ╔═╡ 1df82c20-19c4-11eb-0959-8543a0d5630d
md"""

Submission by: **_$(student.name)_** ($(student.kerberos_id)@mit.edu)
"""

# ╔═╡ 1e2cd0b0-19c4-11eb-3583-0b82092139aa
md"_Let's create a package environment:_"

# ╔═╡ 4e917968-1f87-11eb-371f-e3899b76dc24
md"""
### From the last homework

Below we have included some important functions from the last homework (_Raytracing in 2D_), which we will be able to re-use for the 3D case.

There are some small changes:
1. The concept of a `Photon` now carries **color information**.
2. The `Sphere` is no longer a pure lens, it contains a `Surface` property which describes the mixture between transmission, reflection and a pure color. More on this later!
3. The `refract` function is updated to handle two edge cases, but its behaviour is generally unchanged.

Outside of these changes, all functions from the previous homework can be taken "as-is" when converting to 3D, cool!
"""

# ╔═╡ 24b0d4ba-192c-11eb-0f66-e77b544b0510
struct Photon
	"Position vector"
	p::Vector{Float64}

	"Direction vector"
	l::Vector{Float64}

	"Color associated with the photon"
	c::RGB
	
	ior::Real
end

# ╔═╡ c6e8d30e-205c-11eb-271c-6165a164073d
md"""
#### Intersections:
"""

# ╔═╡ d851a202-1ca0-11eb-3da0-51fcb656783c
abstract type Object end

# ╔═╡ 8acef4b0-1a09-11eb-068d-79a259244ed1
struct Miss end

# ╔═╡ 8018fbf0-1a05-11eb-3032-95aae07ca78f
struct Intersection{T<:Object}
	object::T
	distance::Float64
	point::Vector{Float64}
end

# ╔═╡ fcde90ca-2048-11eb-3e96-f9f47b6154e8
begin
	Base.isless(a::Miss, b::Miss) = false
	Base.isless(a::Miss, b::Intersection) = false
	Base.isless(a::Intersection, b::Miss) = true
	Base.isless(a::Intersection, b::Intersection) = a.distance < b.distance
end

# ╔═╡ dc36ceaa-205c-11eb-169c-bb4c36aaec9f
md"""
#### Reflect and refract:
"""

# ╔═╡ 43306bd4-194d-11eb-2e30-07eabb8b29ef
reflect(ℓ₁::Vector, n̂::Vector)::Vector = normalize(ℓ₁ - 2 * dot(ℓ₁, n̂) * n̂)

# ╔═╡ 14dc73d2-1a0d-11eb-1a3c-0f793e74da9b
function refract(
		ℓ₁::Vector, n̂::Vector,
		old_ior, new_ior
	)
	
	r = old_ior / new_ior
	
	n̂_oriented = if -dot(ℓ₁, n̂) < 0
		-n̂
	else
		n̂
	end
	
	c = -dot(ℓ₁, n̂_oriented)
	
	if abs(c) > 0.999
		ℓ₁
	else
		f = 1 - r^2 * (1 - c^2)
		if f < 0
			ℓ₁
		else
			normalize(r * ℓ₁ + (r*c - sqrt(f)) * n̂_oriented)
		end
	end
end

# ╔═╡ 7f0bf286-2071-11eb-0cac-6d10c93bab6c
md"""
#### Surface (new)
"""

# ╔═╡ 8a4e888c-1ef7-11eb-2a52-17db130458a5
struct Surface
	# Reflectivity
	r::Float64

	# Transmission
	t::Float64

	# Color
	c::RGBA

	# index of refraction
	ior::Float64

end

# ╔═╡ 9c3bdb62-1ef7-11eb-2204-417510bf0d72
html"""
<h4 id="sphere-defs">Sphere</h4>
<p>Aasdf</p>
"""

# ╔═╡ cb7ed97e-1ef7-11eb-192c-abfd66238378
struct Sphere <: Object
	# Lens position
	p::Vector{Float64}

	# Lens radius
	r::Float64

	s::Surface
end

# ╔═╡ 6fdf613c-193f-11eb-0029-957541d2ed4d
function sphere_normal_at(p::Vector{Float64}, s::Sphere)
	normalize(p - s.p)
end

# ╔═╡ 452d6668-1ec7-11eb-3b0a-0b8f45b43fd5
md"""
## Exercise 6: Camera and Skyboxes

Now we can begin looking into the 3D nature of raytracing to create visualizations similar to those in lecture.
The first step is setting up the camera and another stuct known as a *sky box* to collect all the rays of light.

Luckily, the transition from 2D to 3D for raytracing is relatively straightforward and we can use all of the functions and concepts we have built in 2D moving forward.

Firstly, the camera:

"""

# ╔═╡ 791f0bd2-1ed1-11eb-0925-13c394b901ce
md"""
### Camera

For the purposes of this homework, we will constrain ourselves to a camera pointing exclusively downward.
This is simply because camera positioning can be a bit tricky and there is no reason to make the homework more complicated than it needs to be!

So, what is the purpose of the camera?

Well, in reality, a camera is a device that collects the color information from all the rays of light that are refracting and reflecting off of various objects in some sort of scene.
Because there are a nearly infinite number of rays bouncing around the scene at any time, we will actually constrain ourselves only to rays that are entering our camera.
In poarticular, we will create a 2D screen just in front of the camera and send a ray from the camera to each pixel in the screen, as shown in the following image:

$(RemoteResource("https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Ray_trace_diagram.svg/1920px-Ray_trace_diagram.svg.png", :width=>400, :style=>"display: block; margin: auto;"))
"""

# ╔═╡ 1a446de6-1ec9-11eb-1e2f-6f4376005d24
md"""
Because we are not considering camera motion for this exercise, we will assume that the image plane is constrained to the horizontal plane, but that the camera, itself, can be some distance behind it.
This distance from the image plane to the camera is called the *focal length* and is used to determine the field of view.

From here, it's clear we need to construct:
1. A camera struct
2. A function to initialize all the rays being generated by the camera

Let's start with the struct
"""

# ╔═╡ 88576c6e-1ecb-11eb-3e34-830aeb433df1
struct Camera <: Object
	"Set of all pixels, counts as scene resolution"
	resolution::Tuple{Int64,Int64}

	"Physical size of aperture"
	aperture_width::Float64

	"Camera's distance from screen"
	focal_length::Float64

	"Camera's position"
	p::Vector{Float64}
end

# ╔═╡ e774d6a8-2058-11eb-015a-83b4b6104e6e
test_cam = Camera((400,300), 9, -10, [0,00,100])

# ╔═╡ 8f73824e-1ecb-11eb-0b28-4d1bc0eefbc3
md"""
Now we need to construct some method to create each individual ray extending from the camera to a pixel in the image plane.
"""

# ╔═╡ 4006566e-1ecd-11eb-2ce1-9d1107186784
function init_rays(cam::Camera)
	
	# Physical size of the aperture/image/grid
	aspect_ratio = cam.resolution[1] / cam.resolution[2]
	dim = (
		cam.aperture_width, 
		cam.aperture_width / aspect_ratio
	)

	# The x, y coordinates of every pixel in our image grid
	# relative to the image center
	xs = LinRange(-0.5* dim[1], 0.5 * dim[1], cam.resolution[1])
	ys = LinRange(0.5* dim[2], -0.5 * dim[2], cam.resolution[2])
	
	pixel_positions = [[x, y, cam.focal_length] for y in ys, x in xs]
	directions = normalize.(pixel_positions)
	
	Photon.([cam.p], directions, [zero(RGB)], [1.0])
end

# ╔═╡ 156c0d7a-2071-11eb-1551-4f2d393df6c8
tiny_resolution_camera = Camera((4,3), 16, -5, [0, 20, 100])

# ╔═╡ 2838c1e4-2071-11eb-13d8-1da955fbf544
init_rays(tiny_resolution_camera)

# ╔═╡ 494687f6-1ecd-11eb-3ada-6f11f45aa74f
md"""
### Skybox

Now that we have the concept of a camera, we can technically do a fully 3D raytracing example; however, we want to ensure that each pixel will actually *hit* something -- preferrably something with some color gradient so we can make sure our simulation is working!

For this, we will introduce the concept of a sky box, which is standard for most gaming applications.
Here, the idea is that our entire scene is held within some additional object, just like the mirrors we used in the 2D example.
The only difference here is that we will be using some texture instead of a reflective surface.
In addition, even though we are calling it a box, we'll actually be treating it as a sphere.

Because we have already worked out how to make sure we have hit the interior of a spherical lens, we will be using a similar function here.
For this part of the exercise, we will need to construct 2 things:

1. A skybox struct
2. A function that returns some color gradient to be called whenever a ray of light interacts with a sky box

So let's start with the sky box struct
"""

# ╔═╡ 9e71183c-1ef4-11eb-1802-3fc60b51ceba
struct SkyBox <: Object
	# Skybox position
	p::Vector{Float64}

	# Skybox radius
	r::Float64
	
	# Color function
	c::Function
end

# ╔═╡ 093b9e4a-1f8a-11eb-1d32-ad1d85ddaf42
function intersection(photon::Photon, sphere::S; ϵ=1e-3) where {S <: Union{SkyBox, Sphere}}
	a = dot(photon.l, photon.l)
	b = 2 * dot(photon.l, photon.p - sphere.p)
	c = dot(photon.p - sphere.p, photon.p - sphere.p) - sphere.r^2
	
	d = b^2 - 4*a*c
	
	if d <= 0
		Miss()
	else
		t1 = (-b-sqrt(d))/2a
		t2 = (-b+sqrt(d))/2a
		
		t = if t1 > ϵ
			t1
		elseif t2 > ϵ
			t2
		else
			return Miss()
		end
		
		point = photon.p + t * photon.l
		
		Intersection(sphere, t, point)
	end
end

# ╔═╡ 89e98868-1fb2-11eb-078d-c9298d8a9970
function closest_hit(photon::Photon, objects::Vector{<:Object})
	hits = intersection.([photon], objects)
	
	minimum(hits)
end

# ╔═╡ aa9e61aa-1ef4-11eb-0b56-cd7ded52b640
md"""
Now we have the ability to create a skybox, the only thing left is to create some sort of texture function so that when the ray of light hits the sky box, we can return some form of color information.
So for this, we will basically create a function that returns back a smooth gradient in different directions depending on the position of the ray when it hits the skybox.

For the color information, we will be assigning a color to each cardinal axis.
That is to say that there will be a red gradient along $x$, a blue gradient along $y$, and a green gradient along $z$.
For this, we will need to define some extent over which the gradient will be active in 'real' units.
From there, we can say that the gradient is

$$\frac{r+D}{2D},$$

where $r$ is the ray's position when it hits the skybox, and $D$ is the extent over which the gradient is active.

So let's get to it and write the function!
"""

# ╔═╡ c947f546-1ef5-11eb-0f02-054f4e7ae871
function gradient_skybox_color(position, skybox)
	extents = skybox.r
	c = zero(RGB)
	
	if position[1] < extents && position[1] > -extents
		c += RGB((position[1]+extents)/(2.0*extents), 0, 0)
	end

	if position[2] < extents && position[2] > -extents
		c += RGB(0,0,(position[2]+extents)/(2.0*extents))
	end

	if position[3] < extents && position[3] > -extents
		c += RGB(0,(position[3]+extents)/(2.0*extents), 0)
	end

	return c
end

# ╔═╡ a919c880-206e-11eb-2796-55ccd9dbe619
gradient_skybox = SkyBox([0.0, 0.0, 0.0], 1000, gradient_skybox_color)

# ╔═╡ 49651bc6-2071-11eb-1aa0-ff829f7b4350
md"""
Let's set up a basic scene and trace an image! Since our skybox is _spherical_ we can use **the same `intersect`** method as we use for `Sphere`s. Have a look at [the `intersect` method](#sphere-defs), we already added `SkyBox` as a possible type.
"""

# ╔═╡ daf80644-2070-11eb-3363-c577ae5846b3
basic_camera = Camera((300,200), 16, -5, [0,20,100])

# ╔═╡ e453cf70-2070-11eb-0380-03a08a609023
sky = SkyBox([0.0, 0.0, 0.0], 1000, gradient_skybox_color)

# ╔═╡ 26a820d2-1ef6-11eb-1bb1-1fc4b1c22e25
md"""
### Putting it all together!

Now we have a camera and a skybox and we can put everything together in order to do our first raytracing visualization.
For this, we need to start with a function that will take in our set of rays and return back an image that represents the image plane in the above example image.
"""

# ╔═╡ 595acf48-1ef6-11eb-0b46-934d17186e7b
function extract_colors(rays)
	map(ray -> ray.c, rays)
end

# ╔═╡ 5c057466-1fb2-11eb-0451-45974dcc03c9
md"""
At this stage, we need a final function that steps all the rays forward
"""

# ╔═╡ df3f2178-1ef5-11eb-3098-b1c8c67cf136
md"""
So now all we need is a ray tracing function that simply takes in a camera and a set of objects / scene, and...
1. Initilializes all the rays
2. Propagates the rays forward
3. Converts everything into an image
"""

# ╔═╡ 78c85e38-1ef6-11eb-2fc7-f5677b0295b6
md"""
With this, we should have a simple image which is essentially a gradient of different colors by creating a sky box object, like so:
"""

# ╔═╡ a9754410-204d-11eb-123e-e5c5f87ae1c5
function interact(ray::Photon, hit::Intersection{SkyBox}, ::Any, ::Any)
	
	ray_color = hit.object.c(hit.point, hit.object)
	Photon(hit.point, ray.l, ray_color, ray.ior)
end

# ╔═╡ 086e1956-204e-11eb-2524-f719504fb95b
function interact(photon::Photon, ::Miss, ::Any, ::Any)
	photon
end

# ╔═╡ 16f4c8e6-2051-11eb-2f23-f7300abea642
main_scene = [
	SkyBox([0.0, 0.0, 0.0], 1000, gradient_skybox_color),
	Sphere([0,0,-25], 20, 
		Surface(1.0, 0.0, RGBA(1,1,1,0.0), 1.5)),
	
	Sphere([0,50,-100], 20, 
		Surface(0.0, 1.0, RGBA(0,0,0,0.0), 1.0)),
	
	Sphere([-50,0,-25], 20, 
		Surface(0.0, 0.0, RGBA(0, .3, .8, 1), 1.0)),
	
	Sphere([30, 25, -60], 20,
		Surface(0.0, 0.75, RGBA(1,0,0,0.25), 1.5)),
	
	Sphere([50, 0, -25], 20,
		Surface(0.5, 0.0, RGBA(.1,.9,.1,0.5), 1.5)),
	
	Sphere([-30, 25, -60], 20,
		Surface(0.5, 0.5, RGBA(1,1,1,0), 1.5)),
]

# ╔═╡ 95ca879a-204d-11eb-3473-959811aa8320
begin
	function interact(ray::Photon, hit::Intersection{Sphere}, num_intersections, objects)
		sphere = hit.object

		reflected_ray = ray
		refracted_ray = ray
		colored_ray = ray

		if !isapprox(sphere.s.t, 0)
			
			old_ior = ray.ior
			new_ior = if ray.ior == 1.0
				sphere.s.ior
			else
				1.0
			end

			normal = sphere_normal_at(hit.point, hit.object)

			refracted_ray = Photon(hit.point, refract(ray.l, normal, old_ior, new_ior), ray.c, new_ior)
			
			refracted_ray = step_ray(refracted_ray, objects,
									 num_intersections-1)
		end

		if !isapprox(sphere.s.r, 0)
			n = sphere_normal_at(hit.point, sphere)
			reflected_ray = Photon(hit.point, reflect(ray.l, n), ray.c, ray.ior)
			reflected_ray = step_ray(reflected_ray, objects,
									 num_intersections-1)
		end

		if !isapprox(sphere.s.c.alpha, 0)
			ray_color = RGB(sphere.s.c)
			colored_ray = Photon(ray.l, ray.p, ray_color, ray.ior)
		end

		ray_color = sphere.s.t * refracted_ray.c +
					sphere.s.r * reflected_ray.c +
					sphere.s.c.alpha*colored_ray.c

		Photon(hit.point, ray.l, ray_color, ray.ior)
	end
	
	
	function step_ray(ray::Photon, objects::Vector{O},
				   num_intersections) where {O <: Object}

		if num_intersections == 0
			ray
		else
			hit = closest_hit(ray, objects)
			interact(ray, hit, num_intersections, objects)
		end
	end
end

# ╔═╡ a4e81e2c-1fb2-11eb-0a19-27115387c133
function step_rays(rays::Array{Photon}, objects::Vector{O},
				   num_intersections) where {O <: Object}
	step_ray.(rays, [objects], [num_intersections])
end

# ╔═╡ 6b91a58a-1ef6-11eb-1c36-2f44713905e1
function ray_trace(objects::Vector{O}, cam::Camera;
				   num_intersections = 10) where {O <: Object}
	rays = init_rays(cam)

	new_rays = step_rays(rays, objects, num_intersections)

	extract_colors(new_rays)

end

# ╔═╡ a0b84f62-2047-11eb-348c-db83f4e6c39c
let
	scene = [sky]
	ray_trace(scene, basic_camera; num_intersections=4)
end

# ╔═╡ 1f66ba6e-1ef8-11eb-10ba-4594f7c5ff19
function main()
	cam = Camera((600,360), 16, -15, [0,10,100])

	return ray_trace(main_scene, cam; num_intersections=3)
end

# ╔═╡ ce8fabbc-1faf-11eb-240a-77373e5528f9
main()

# ╔═╡ 3f0cf012-2056-11eb-21d1-1f2b0eb80e12
@bind ior_experiment Slider(1.0:0.0000001:1.1)

# ╔═╡ 1552da14-2056-11eb-0beb-6d0a70bbbcaa
function variable_ior(ior)
	cam = Camera((300,300), 9, -8, [0,00,50])

	scene = [SkyBox([0.0, 0.0, 0.0], 1000),
			 Sphere([0,0,0], 20, Surface(0.0, 1.0, RGBA(1,1,1,0.0), ior)),
	]
	return ray_trace(scene, cam; num_intersections=20)
end

# ╔═╡ 383884fc-2056-11eb-2804-8930e1f1b0c0
variable_ior(ior_experiment)

# ╔═╡ eb157dd8-203c-11eb-1d05-b92969332928
md"""
The next step is to add objects, not too unlike what we did in the 2D example.
Similar to before, we will focus almost entirely onm sphere here, jsut because they are easy to work with.
"""

# ╔═╡ d175ff38-203c-11eb-38c6-a77e68196624
md"""

## Exercise 7: Dealing with Objects

In the 2D example, we dealt specifically with spheres that could either 100% reflect or refract.
In principle, it is possible for objects to either reflect or refract, something in-between.
That is to say, a ray of light can *split* when hitting an object surface, creating at least 2 more rays of light that will both return separate color values.
These color values will be combined at the end to create a final color for that ray.

As another note here, the objects that we create could, in principle, also have a color associated with them and just return the color value instead of reflecting or refracting.
In addition, the objects could cast a shadow on other objects or send diffuse light in all directions, but we will not deal with either of those cases in this homework.

For this homework, we will only deal with reflection, refraction, and color.

So, the first step is to create some form of surface *texture* that allows for a certain amount of reflectivity, transmittance, and coloring for each object.

After, we should be able to create a set of test orbs that all have different surfaces to make sure the code is working as intended.

So, first things first, let's make the surface struct!
"""

# ╔═╡ 64323080-1fb1-11eb-1d5c-9df3b29e38fa
md"""
At every interaction step, our ray will spawn 3 different children for
1. Reflection
2. Refraction
3. Coloring

So we need to modify out `step_ray(...)` function to take this into account.

For both reflection and refraction, a new ray will move in the corresponding direction, eventually returning color information back to their parent.
In the case that the object has a color already associated with it, then no sub ray will be spawned.
Instead, the ray will be colored according to the color of that object.

In the end, each ray will be colored based on the colors of it's child rays.
If the object's surface is 50% reflective and 50% transmittive, then 50% of the ray's final color will be determined by the reflective ray, and 50% will be determined by the refractive ray.

This means that we need to recursively call the `step_ray(...)` function for each ray child to determine the ray's final color.
"""

# ╔═╡ 98d811a2-1fb5-11eb-157b-5fed4e59f3f5
md"""
# This is what I need to modify!!!
"""

# ╔═╡ d1970a34-1ef7-11eb-3e1f-0fd3b8e9657f
md"""
The last thing to do is create a scene with a number of balls inside of it.
To make sure the code is working, please create at least the following balls:
1. one that returns a color value
2. one that only reflects
3. one that only refracts
4. one that colors and refracts
5. one that colors and reflects
6. one that reflects and refracts
"""

# ╔═╡ 67c0bd70-206a-11eb-3935-83d32c67f2eb
md"""
## **Bonus:** Escher

If you managed to get through the exercises, we have a treat for you! The goal of this bonus exercise is to recreate this self-portrait by M.C. Escher:

"""

# ╔═╡ 748cbaa2-206c-11eb-2cc9-7fa74308711b
Resource("https://www.researchgate.net/profile/Madhu_Gupta22/publication/3427377/figure/fig1/AS:663019482775553@1535087571714/A-self-portrait-of-MC-Escher-1898-1972-in-spherical-mirror-dating-from-1935-titled.png", :width=>300)

# ╔═╡ 981e6bd2-206c-11eb-116d-6fad4e04ce34
md"""
It looks like M.C. Escher is a skillful raytracer, but so are we! To recreate this image, we can simplify it by having just two objects in our scene:
- A purely reflective sphere
- A skybox, containing an image of us!

Let's start with our old skybox, and set up our scene:
"""

# ╔═╡ 7a12a99a-206d-11eb-2393-bf28b881087a
escher_sphere = Sphere([0,0,0], 20, 
			Surface(1.0, 0.0, RGBA(1,1,1,0.0), 1.5))

# ╔═╡ 373b6a26-206d-11eb-1e67-9debb032f69e
escher_cam = Camera((300,300), 30, -10, [0,00,30])

# ╔═╡ 5dfec31c-206d-11eb-23a2-259f2c205cb5
md"""
👆 You can modify `escher_cam` to increase or descrease the resolution!
"""

# ╔═╡ 6f1dbf48-206d-11eb-24d3-5154703e1753
let
	scene = [gradient_skybox, escher_sphere]
	ray_trace(scene, escher_cam; num_intersections=3)
end

# ╔═╡ dc786ccc-206e-11eb-29e2-99882e6613af
md"""
Awesome! To TODTODOTDOTD
"""

# ╔═╡ 8ebe4cd6-2061-11eb-396b-45745bd7ec55
earth = load(download("https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Whole_world_-_land_and_oceans_12000.jpg/1280px-Whole_world_-_land_and_oceans_12000.jpg"))

# ╔═╡ 12d3b806-2062-11eb-20a8-7d1a33e4b073
function get_index_rational(A, x, y)
	a, b = size(A)
	
	u = clamp(floor(Int, x * (a-1)) + 1, 1, a)
	v = clamp(floor(Int, y * (b-1)) + 1, 1, b)
	A[u,v]
end

# ╔═╡ cc492966-2061-11eb-1000-d90c279c4668
function image_skybox(img)
	f = function(position, skybox)
		lon = atan(-position[1], position[3])
		lat = -atan(position[2], norm(position[[1,3]]))

		get_index_rational(img, (lat/(pi)) + .5, (lon/2pi) + .5)
	end
	
	SkyBox([0.0, 0.0, 0.0], 1000, f)
end

# ╔═╡ 137834d4-206d-11eb-0082-7b87bf222808
earth_skybox = image_skybox(earth)

# ╔═╡ bff27890-206e-11eb-2e40-696424a0b8be
let
	scene = [earth_skybox, escher_sphere]
	ray_trace(scene, escher_cam; num_intersections=3)
end

# ╔═╡ b0bc76f8-206d-11eb-0cad-4bde96565fed


# ╔═╡ 48166866-2070-11eb-2722-556a6719c2a2
md"""
We need to pad it TODODODTOD
"""

# ╔═╡ 6480b85c-2067-11eb-0262-f752d306d8ae
function pad_dramatic(face)
	a,b = size(face)
	
	Abw = [((2a-y) / 2a) for y in 1:2a, x in 1:3b]
	Abw .-= .1 * rand(Gray, 2a, 3b)
	A = RGB.(Abw)
	
	c = a ÷ 2
	d = b ÷ 2
	
	A[
		c + 1:c + a,
		b + 1:2b] .= face
	A
end

# ╔═╡ dc6dcc58-2065-11eb-1f19-a9cac62d12a5
function escher(img)
	padded = pad_dramatic(img)
	
	scene = [
		image_skybox(padded),

		escher_sphere,
	]
	
	ray_trace(scene, escher_cam; num_intersections=3)
end

# ╔═╡ ebd05bf0-19c3-11eb-2559-7d0745a84025
if student.name == "Jazzy Doe" || student.kerberos_id == "jazz"
	md"""
	!!! danger "Before you submit"
	    Remember to fill in your **name** and **Kerberos ID** at the top of this notebook.
	"""
end

# ╔═╡ ec275590-19c3-11eb-23d0-cb3d9f62ba92
md"## Function library

Just some helper functions used in the notebook."

# ╔═╡ 2c36d3e8-2065-11eb-3a12-8382f8539ea6

function process_raw_camera_data(raw_camera_data)
	# the raw image data is a long byte array, we need to transform it into something
	# more "Julian" - something with more _structure_.
	
	# The encoding of the raw byte stream is:
	# every 4 bytes is a single pixel
	# every pixel has 4 values: Red, Green, Blue, Alpha
	# (we ignore alpha for this notebook)
	
	# So to get the red values for each pixel, we take every 4th value, starting at 
	# the 1st:
	reds_flat = UInt8.(raw_camera_data["data"][1:4:end])
	greens_flat = UInt8.(raw_camera_data["data"][2:4:end])
	blues_flat = UInt8.(raw_camera_data["data"][3:4:end])
	
	# but these are still 1-dimensional arrays, nicknamed 'flat' arrays
	# We will 'reshape' this into 2D arrays:
	
	width = raw_camera_data["width"]
	height = raw_camera_data["height"]
	
	# shuffle and flip to get it in the right shape
	reds = reshape(reds_flat, (width, height))' / 255.0
	greens = reshape(greens_flat, (width, height))' / 255.0
	blues = reshape(blues_flat, (width, height))' / 255.0
	
	# we have our 2D array for each color
	# Let's create a single 2D array, where each value contains the R, G and B value of 
	# that pixel
	
	RGB.(reds, greens, blues)
end

# ╔═╡ f7b5ff68-2064-11eb-3be3-554519ca4847
function camera_input(;max_size=200, default_url="https://i.imgur.com/SUmi94P.png")
"""
<span class="pl-image waiting-for-permission">
<style>
	
	.pl-image.popped-out {
		position: fixed;
		top: 0;
		right: 0;
		z-index: 5;
	}

	.pl-image #video-container {
		width: 250px;
	}

	.pl-image video {
		border-radius: 1rem 1rem 0 0;
	}
	.pl-image.waiting-for-permission #video-container {
		display: none;
	}
	.pl-image #prompt {
		display: none;
	}
	.pl-image.waiting-for-permission #prompt {
		width: 250px;
		height: 200px;
		display: grid;
		place-items: center;
		font-family: monospace;
		font-weight: bold;
		text-decoration: underline;
		cursor: pointer;
		border: 5px dashed rgba(0,0,0,.5);
	}

	.pl-image video {
		display: block;
	}
	.pl-image .bar {
		width: inherit;
		display: flex;
		z-index: 6;
	}
	.pl-image .bar#top {
		position: absolute;
		flex-direction: column;
	}
	
	.pl-image .bar#bottom {
		background: black;
		border-radius: 0 0 1rem 1rem;
	}
	.pl-image .bar button {
		flex: 0 0 auto;
		background: rgba(255,255,255,.8);
		border: none;
		width: 2rem;
		height: 2rem;
		border-radius: 100%;
		cursor: pointer;
		z-index: 7;
	}
	.pl-image .bar button#shutter {
		width: 3rem;
		height: 3rem;
		margin: -1.5rem auto .2rem auto;
	}

	.pl-image video.takepicture {
		animation: pictureflash 200ms linear;
	}

	@keyframes pictureflash {
		0% {
			filter: grayscale(1.0) contrast(2.0);
		}

		100% {
			filter: grayscale(0.0) contrast(1.0);
		}
	}
</style>

	<div id="video-container">
		<div id="top" class="bar">
			<button id="stop" title="Stop video">✖</button>
			<button id="pop-out" title="Pop out/pop in">⏏</button>
		</div>
		<video playsinline autoplay></video>
		<div id="bottom" class="bar">
		<button id="shutter" title="Click to take a picture">📷</button>
		</div>
	</div>
		
	<div id="prompt">
		<span>
		Enable webcam
		</span>
	</div>

<script>
	// based on https://github.com/fonsp/printi-static (by the same author)

	const span = currentScript.parentElement
	const video = span.querySelector("video")
	const popout = span.querySelector("button#pop-out")
	const stop = span.querySelector("button#stop")
	const shutter = span.querySelector("button#shutter")
	const prompt = span.querySelector(".pl-image #prompt")

	const maxsize = $(max_size)

	const send_source = (source, src_width, src_height) => {
		const scale = Math.min(1.0, maxsize / src_width, maxsize / src_height)

		const width = Math.floor(src_width * scale)
		const height = Math.floor(src_height * scale)

		const canvas = html`<canvas width=\${width} height=\${height}>`
		const ctx = canvas.getContext("2d")
		ctx.drawImage(source, 0, 0, width, height)

		span.value = {
			width: width,
			height: height,
			data: ctx.getImageData(0, 0, width, height).data,
		}
		span.dispatchEvent(new CustomEvent("input"))
	}
	
	const clear_camera = () => {
		window.stream.getTracks().forEach(s => s.stop());
		video.srcObject = null;

		span.classList.add("waiting-for-permission");
	}

	prompt.onclick = () => {
		navigator.mediaDevices.getUserMedia({
			audio: false,
			video: {
				facingMode: "environment",
			},
		}).then(function(stream) {

			stream.onend = console.log

			window.stream = stream
			video.srcObject = stream
			window.cameraConnected = true
			video.controls = false
			video.play()
			video.controls = false

			span.classList.remove("waiting-for-permission");

		}).catch(function(error) {
			console.log(error)
		});
	}
	stop.onclick = () => {
		clear_camera()
	}
	popout.onclick = () => {
		span.classList.toggle("popped-out")
	}

	shutter.onclick = () => {
		const cl = video.classList
		cl.remove("takepicture")
		void video.offsetHeight
		cl.add("takepicture")
		video.play()
		video.controls = false
		console.log(video)
		send_source(video, video.videoWidth, video.videoHeight)
	}
	
	
	document.addEventListener("visibilitychange", () => {
		if (document.visibilityState != "visible") {
			clear_camera()
		}
	})


	// Set a default image

	const img = html`<img crossOrigin="anonymous">`

	img.onload = () => {
	console.log("helloo")
		send_source(img, img.width, img.height)
	}
	img.src = "$(default_url)"
	console.log(img)
</script>
</span>
""" |> HTML
end

# ╔═╡ 27d64432-2065-11eb-3795-e99b1d6718d2
@bind wow camera_input()

# ╔═╡ 64ce8106-2065-11eb-226c-0bcaf7e3f871
face = process_raw_camera_data(wow)

# ╔═╡ 06ac2efc-206f-11eb-1a73-9306bf5f7a9c
let
	face_skybox = image_skybox(face)
	scene = [face_skybox, escher_sphere]
	ray_trace(scene, escher_cam; num_intersections=3)
end

# ╔═╡ 7d03b258-2067-11eb-3070-1168e282b2ea
pad_dramatic(face)

# ╔═╡ aa597a16-2066-11eb-35ae-3170468a90ed
@bind escher_face_data camera_input()

# ╔═╡ c68dbe1c-2066-11eb-048d-038df2c68a8b
escher(process_raw_camera_data(escher_face_data))

# ╔═╡ ec31dce0-19c3-11eb-1487-23cc20cd5277
hint(text) = Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))

# ╔═╡ 28e9c33c-1ef8-11eb-01f7-0b5176eb6c0f
md"""
Remember when placing these spheres that the camera is pointing in the z direction! Be sure that the sphere location can be seen by the camera!
""" |> hint

# ╔═╡ ec3ed530-19c3-11eb-10bb-a55e77550d1f
almost(text) = Markdown.MD(Markdown.Admonition("warning", "Almost there!", [text]))

# ╔═╡ ec4abc12-19c3-11eb-1ca4-b5e9d3cd100b
still_missing(text=md"Replace `missing` with your answer.") = Markdown.MD(Markdown.Admonition("warning", "Here we go!", [text]))

# ╔═╡ ec57b460-19c3-11eb-2142-07cf28dcf02b
keep_working(text=md"The answer is not quite right.") = Markdown.MD(Markdown.Admonition("danger", "Keep working on it!", [text]))

# ╔═╡ ec5d59b0-19c3-11eb-0206-cbd1a5415c28
yays = [md"Fantastic!", md"Splendid!", md"Great!", md"Yay ❤", md"Great! 🎉", md"Well done!", md"Keep it up!", md"Good job!", md"Awesome!", md"You got the right answer!", md"Let's move on to the next section."]

# ╔═╡ ec698eb0-19c3-11eb-340a-e319abb8ebb5
correct(text=rand(yays)) = Markdown.MD(Markdown.Admonition("correct", "Got it!", [text]))

# ╔═╡ ec7638e0-19c3-11eb-1ca1-0b3aa3b40240
not_defined(variable_name) = Markdown.MD(Markdown.Admonition("danger", "Oopsie!", [md"Make sure that you define a variable called **$(Markdown.Code(string(variable_name)))**"]))

# ╔═╡ ec85c940-19c3-11eb-3375-a90735beaec1
TODO = html"<span style='display: inline; font-size: 2em; color: purple; font-weight: 900;'>TODO</span>"

# ╔═╡ 8cfa4902-1ad3-11eb-03a1-736898ff9cef
TODO_note(text) = Markdown.MD(Markdown.Admonition("warning", "TODO note", [text]))

# ╔═╡ Cell order:
# ╟─1df32310-19c4-11eb-0824-6766cd21aaf4
# ╟─1df82c20-19c4-11eb-0959-8543a0d5630d
# ╠═84d846d8-203a-11eb-3ab9-5ba145aa501c
# ╟─1e01c912-19c4-11eb-269a-9796cccdf274
# ╟─1e109620-19c4-11eb-013e-1bc95c14c2ba
# ╠═1e202680-19c4-11eb-29a7-99061b886b3c
# ╟─1e2cd0b0-19c4-11eb-3583-0b82092139aa
# ╠═c3e52bf2-ca9a-11ea-13aa-03a4335f2906
# ╟─4e917968-1f87-11eb-371f-e3899b76dc24
# ╠═24b0d4ba-192c-11eb-0f66-e77b544b0510
# ╟─c6e8d30e-205c-11eb-271c-6165a164073d
# ╠═d851a202-1ca0-11eb-3da0-51fcb656783c
# ╠═8acef4b0-1a09-11eb-068d-79a259244ed1
# ╠═8018fbf0-1a05-11eb-3032-95aae07ca78f
# ╠═fcde90ca-2048-11eb-3e96-f9f47b6154e8
# ╠═89e98868-1fb2-11eb-078d-c9298d8a9970
# ╟─dc36ceaa-205c-11eb-169c-bb4c36aaec9f
# ╠═43306bd4-194d-11eb-2e30-07eabb8b29ef
# ╠═14dc73d2-1a0d-11eb-1a3c-0f793e74da9b
# ╟─7f0bf286-2071-11eb-0cac-6d10c93bab6c
# ╠═8a4e888c-1ef7-11eb-2a52-17db130458a5
# ╠═9c3bdb62-1ef7-11eb-2204-417510bf0d72
# ╠═cb7ed97e-1ef7-11eb-192c-abfd66238378
# ╠═093b9e4a-1f8a-11eb-1d32-ad1d85ddaf42
# ╠═6fdf613c-193f-11eb-0029-957541d2ed4d
# ╟─452d6668-1ec7-11eb-3b0a-0b8f45b43fd5
# ╟─791f0bd2-1ed1-11eb-0925-13c394b901ce
# ╟─1a446de6-1ec9-11eb-1e2f-6f4376005d24
# ╠═88576c6e-1ecb-11eb-3e34-830aeb433df1
# ╠═e774d6a8-2058-11eb-015a-83b4b6104e6e
# ╠═8f73824e-1ecb-11eb-0b28-4d1bc0eefbc3
# ╠═4006566e-1ecd-11eb-2ce1-9d1107186784
# ╠═156c0d7a-2071-11eb-1551-4f2d393df6c8
# ╠═2838c1e4-2071-11eb-13d8-1da955fbf544
# ╟─494687f6-1ecd-11eb-3ada-6f11f45aa74f
# ╠═9e71183c-1ef4-11eb-1802-3fc60b51ceba
# ╟─aa9e61aa-1ef4-11eb-0b56-cd7ded52b640
# ╠═c947f546-1ef5-11eb-0f02-054f4e7ae871
# ╠═a919c880-206e-11eb-2796-55ccd9dbe619
# ╟─49651bc6-2071-11eb-1aa0-ff829f7b4350
# ╠═daf80644-2070-11eb-3363-c577ae5846b3
# ╠═e453cf70-2070-11eb-0380-03a08a609023
# ╠═a0b84f62-2047-11eb-348c-db83f4e6c39c
# ╟─26a820d2-1ef6-11eb-1bb1-1fc4b1c22e25
# ╠═595acf48-1ef6-11eb-0b46-934d17186e7b
# ╟─5c057466-1fb2-11eb-0451-45974dcc03c9
# ╠═a4e81e2c-1fb2-11eb-0a19-27115387c133
# ╟─df3f2178-1ef5-11eb-3098-b1c8c67cf136
# ╠═6b91a58a-1ef6-11eb-1c36-2f44713905e1
# ╠═78c85e38-1ef6-11eb-2fc7-f5677b0295b6
# ╠═a9754410-204d-11eb-123e-e5c5f87ae1c5
# ╠═086e1956-204e-11eb-2524-f719504fb95b
# ╠═ce8fabbc-1faf-11eb-240a-77373e5528f9
# ╠═1f66ba6e-1ef8-11eb-10ba-4594f7c5ff19
# ╠═16f4c8e6-2051-11eb-2f23-f7300abea642
# ╠═95ca879a-204d-11eb-3473-959811aa8320
# ╠═3f0cf012-2056-11eb-21d1-1f2b0eb80e12
# ╠═383884fc-2056-11eb-2804-8930e1f1b0c0
# ╠═1552da14-2056-11eb-0beb-6d0a70bbbcaa
# ╟─eb157dd8-203c-11eb-1d05-b92969332928
# ╟─d175ff38-203c-11eb-38c6-a77e68196624
# ╟─64323080-1fb1-11eb-1d5c-9df3b29e38fa
# ╠═98d811a2-1fb5-11eb-157b-5fed4e59f3f5
# ╠═d1970a34-1ef7-11eb-3e1f-0fd3b8e9657f
# ╟─28e9c33c-1ef8-11eb-01f7-0b5176eb6c0f
# ╟─67c0bd70-206a-11eb-3935-83d32c67f2eb
# ╟─748cbaa2-206c-11eb-2cc9-7fa74308711b
# ╟─981e6bd2-206c-11eb-116d-6fad4e04ce34
# ╠═7a12a99a-206d-11eb-2393-bf28b881087a
# ╠═373b6a26-206d-11eb-1e67-9debb032f69e
# ╟─5dfec31c-206d-11eb-23a2-259f2c205cb5
# ╠═6f1dbf48-206d-11eb-24d3-5154703e1753
# ╠═dc786ccc-206e-11eb-29e2-99882e6613af
# ╟─8ebe4cd6-2061-11eb-396b-45745bd7ec55
# ╠═cc492966-2061-11eb-1000-d90c279c4668
# ╠═12d3b806-2062-11eb-20a8-7d1a33e4b073
# ╠═137834d4-206d-11eb-0082-7b87bf222808
# ╠═bff27890-206e-11eb-2e40-696424a0b8be
# ╠═b0bc76f8-206d-11eb-0cad-4bde96565fed
# ╠═27d64432-2065-11eb-3795-e99b1d6718d2
# ╟─64ce8106-2065-11eb-226c-0bcaf7e3f871
# ╠═06ac2efc-206f-11eb-1a73-9306bf5f7a9c
# ╠═48166866-2070-11eb-2722-556a6719c2a2
# ╟─7d03b258-2067-11eb-3070-1168e282b2ea
# ╠═6480b85c-2067-11eb-0262-f752d306d8ae
# ╟─aa597a16-2066-11eb-35ae-3170468a90ed
# ╠═c68dbe1c-2066-11eb-048d-038df2c68a8b
# ╟─dc6dcc58-2065-11eb-1f19-a9cac62d12a5
# ╟─ebd05bf0-19c3-11eb-2559-7d0745a84025
# ╟─ec275590-19c3-11eb-23d0-cb3d9f62ba92
# ╟─2c36d3e8-2065-11eb-3a12-8382f8539ea6
# ╟─f7b5ff68-2064-11eb-3be3-554519ca4847
# ╟─ec31dce0-19c3-11eb-1487-23cc20cd5277
# ╟─ec3ed530-19c3-11eb-10bb-a55e77550d1f
# ╟─ec4abc12-19c3-11eb-1ca4-b5e9d3cd100b
# ╟─ec57b460-19c3-11eb-2142-07cf28dcf02b
# ╟─ec5d59b0-19c3-11eb-0206-cbd1a5415c28
# ╠═ec698eb0-19c3-11eb-340a-e319abb8ebb5
# ╟─ec7638e0-19c3-11eb-1ca1-0b3aa3b40240
# ╟─ec85c940-19c3-11eb-3375-a90735beaec1
# ╠═8cfa4902-1ad3-11eb-03a1-736898ff9cef
