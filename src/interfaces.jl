not_implemented_for(x) = error("Not implemented for $(x). You might want to put:  `using Makie` into your code!")

#TODO only have one?
const Theme = Attributes

Theme(x::AbstractPlot) = x.attributes

default_theme(scene, T) = Attributes()

function default_theme(scene)
    light = Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]
    Theme(
        color = theme(scene, :color),
        visible = theme(scene, :visible),
        linewidth = 1,
        light = light,
        transformation = automatic,
        model = automatic,
        alpha = 1.0,
        transparency = false,
        overdraw = false,
    )
end


#this defines which attributes in a theme should be removed if another attribute is defined by the user,
#to avoid conflicts later through the pipeline

mutual_exclusive_attributes(::Type{<:AbstractPlot}) = Dict()
"""
    image(x, y, image)
    image(image)

Plots an image on range `x, y` (defaults to dimensions).

## Theme
$(ATTRIBUTES)
"""
@recipe(Image, x, y, image) do scene
    Theme(;
        default_theme(scene)...,
        colormap = [RGBAf0(0,0,0,1), RGBAf0(1,1,1,1)],
        colorrange = automatic,
        fxaa = false,
    )
end


# could be implemented via image, but might be optimized specifically by the backend
"""
    heatmap(x, y, values)
    heatmap(values)

Plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).

## Theme
$(ATTRIBUTES)
"""
@recipe(Heatmap, x, y, values) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        linewidth = 0.0,
        levels = 1,
        fxaa = true,
        interpolate = false
    )
end

"""
    volume(volume_data)

Plots a volume. Available algorithms are:
* `:iso` => IsoValue
* `:absorption` => Absorption
* `:mip` => MaximumIntensityProjection
* `:absorptionrgba` => AbsorptionRGBA
* `:indexedabsorption` => IndexedAbsorptionRGBA

## Theme
$(ATTRIBUTES)
"""
@recipe(Volume, x, y, z, volume) do scene
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        algorithm = :iso,
        absorption = 1f0,
        isovalue = 0.5f0,
        isorange = 0.05f0,
        color = nothing,
        colormap = theme(scene, :colormap),
        colorrange = (0, 1),
    )
end

function mutual_exclusive_attributes(::Type{<:Volume})
    Dict(
        :colorrange => :color,
        :colormap   => :color,
    )
end

"""
    surface(x, y, z)

Plots a surface, where `(x, y)`  define a grid whose heights are the entries in `z`.

## Theme
$(ATTRIBUTES)
"""
@recipe(Surface, x, y, z) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        shading = true,
        fxaa = true,
    )
end

"""
    lines(positions)
    lines(x, y)
    lines(x, y, z)

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.

## Theme
$(ATTRIBUTES)
"""
@recipe(Lines, positions) do scene
    Theme(;
        default_theme(scene)...,
        linewidth = 1.0,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        linestyle = theme(scene, :linestyle),
        fxaa = false
    )
end

"""
    linesegments(positions)
    linesegments(x, y)
    linesegments(x, y, z)

Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

## Theme
$(ATTRIBUTES)
"""
@recipe(LineSegments, positions) do scene
    default_theme(scene, Lines)
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    mesh(x, y, z)
    mesh(mesh_object)
    mesh(x, y, z, faces)
    mesh(xyz, faces)

Plots a 3D mesh.

## Theme
$(ATTRIBUTES)
"""
@recipe(Mesh, mesh) do scene
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        interpolate = false,
        shading = true,
        colormap = theme(scene, :colormap),
        colorrange = automatic,
    )
end

"""
    scatter(positions)
    scatter(x, y)
    scatter(x, y, z)

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.

## Theme
$(ATTRIBUTES)
"""
@recipe(Scatter, positions) do scene
    Theme(;
        default_theme(scene)...,
        marker = theme(scene, :marker),
        markersize = theme(scene, :markersize),
        strokecolor = RGBA(0, 0, 0, 0),
        strokewidth = 0.0,
        glowcolor = RGBA(0, 0, 0, 0),
        glowwidth = 0.0,
        rotations = Billboard(),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        marker_offset = automatic,
        fxaa = false,
        transform_marker = false, # Applies the plots transformation to marker
        uv_offset_width = Vec4f0(0),
        distancefield = nothing,
    )
end

"""
    meshscatter(positions)
    meshscatter(x, y)
    meshscatter(x, y, z)

Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`).
`markersize` is a scaling applied to the primitive passed as `marker`.

## Theme
$(ATTRIBUTES)
"""
@recipe(MeshScatter, positions) do scene
    Theme(;
        default_theme(scene)...,
        marker = Sphere(Point3f0(0), 1f0),
        markersize = theme(scene, :markersize),
        rotations = Quaternionf0(0, 0, 0, 1),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        fxaa = true,
        shading = true
    )
end

"""
    text(string)

Plots a text.

## Theme
$(ATTRIBUTES)
"""
@recipe(Text, text) do scene
    Theme(;
        default_theme(scene)...,
        font = theme(scene, :font),
        strokecolor = (:black, 0.0),
        strokewidth = 0,
        align = (:left, :bottom),
        rotation = 0.0,
        textsize = 20,
        position = Point2f0(0),
    )
end

const atomic_function_symbols = (
    :text, :meshscatter, :scatter, :mesh, :linesegments,
    :lines, :surface, :volume, :heatmap, :image
)


const atomic_functions = getfield.(Ref(AbstractPlotting), atomic_function_symbols)
const Atomic{Arg} = Union{map(x-> Combined{x, Arg}, atomic_functions)...}

function color_and_colormap!(plot, intensity = plot[:color])
    if isa(intensity[], AbstractArray{<: Number})
        haskey(plot, :colormap) || error("Plot $T needs to have a colormap to allow the attribute color to be an array of numbers")
        replace_automatic!(plot, :colorrange) do
            lift(extrema_nan, intensity)
        end
        true
    else
        delete!(plot, :colorrange)
        false
    end
end


"""
    `calculated_attributes!(plot::AbstractPlot)`

Fill in values that can only be calculated when we have all other attributes filled
"""
calculated_attributes!(plot::T) where T = calculated_attributes!(T, plot)

"""
    `calculated_attributes!(trait::Type{<: AbstractPlot}, plot)`
trait version of calculated_attributes
"""
calculated_attributes!(trait, plot) = nothing

function calculated_attributes!(::Type{<: Mesh}, plot)
    need_cmap = color_and_colormap!(plot)
    need_cmap || delete!(plot, :colormap)
    return
end

function calculated_attributes!(::Type{<: Union{Heatmap, Image}}, plot)
    plot[:color] = plot[3]
    color_and_colormap!(plot)
end
function calculated_attributes!(::Type{<: Surface}, plot)
    colors = plot[3]
    if haskey(plot, :color)
        color = plot[:color][]
        if isa(color, AbstractMatrix{<: Number}) && !(color === to_value(colors))
            colors = plot[:color]
        end
    end
    color_and_colormap!(plot, colors)
end
function calculated_attributes!(::Type{<: MeshScatter}, plot)
    color_and_colormap!(plot)
end


function calculated_attributes!(::Type{<: Scatter}, plot)
    # calculate base case
    color_and_colormap!(plot)
    replace_automatic!(plot, :marker_offset) do
        # default to middle
        lift(x-> to_2d_scale(x .* (-0.5f0)), plot[:markersize])
    end
end

function calculated_attributes!(::Type{<: Union{Lines, LineSegments}}, plot)
    color_and_colormap!(plot)
    pos = plot[1][]
    # extend one color per linesegment to be one (the same) color per vertex
    # taken from @edljk  in PR #77
    if haskey(plot, :color) && isa(plot[:color][], AbstractVector) && iseven(length(pos)) && (length(pos) ÷ 2) == length(plot[:color][])
        plot[:color] = lift(plot[:color]) do cols
            map(i-> cols[(i + 1) ÷ 2], 1:(length(cols) * 2))
        end
    end
end


# # to allow one color per edge
# function calculated_attributes!(plot::LineSegments)
#     plot[:color] = lift(plot[:color], plot[1]) do c, p
#         if (length(p) ÷ 2) == length(c)
#             [c[k] for k in 1:length(c), l in 1:2]
#         else
#             c
#         end
#     end
# end

function (PT::Type{<: Combined})(parent, transformation, attributes, input_args, converted)
    PT(parent, transformation, attributes, input_args, converted, AbstractPlot[])
end
plotsym(::Type{<:AbstractPlot{F}}) where F = Symbol(typeof(F).name.mt.name)

"""
    used_attributes(args...) = ()

function used to indicate what keyword args one wants to get passed in `convert_arguments`.
Usage:
```example
    struct MyType end
    used_attributes(::MyType) = (:attribute,)
    function convert_arguments(x::MyType; attribute = 1)
        ...
    end
    # attribute will get passed to convert_arguments
    # without keyword_verload, this wouldn't happen
    plot(MyType, attribute = 2)
    #You can also use the convenience macro, to overload convert_arguments in one step:
    @keywords convert_arguments(x::MyType; attribute = 1)
        ...
    end
```
"""
used_attributes(PlotType, args...) = ()


"""
apply for return type
    (args...,)
"""
function apply_convert!(P, attributes::Attributes, x::Tuple)
    return (plottype(P, x...), x)
end


"""
apply for return type PlotSpec
"""
function apply_convert!(P, attributes::Attributes, x::PlotSpec{S}) where S
    args, kwargs = x.args, x.kwargs
    # Note that kw_args in the plot spec that are not part of the target plot type
    # will end in the "global plot" kw_args (rest)
    for (k, v) in pairs(kwargs)
        attributes[k] = v
    end
    return (plottype(P, S), args)
end


function seperate_tuple(args::Node{<: NTuple{N, Any}}) where N
    ntuple(N) do i
        lift(args) do x
            if i <= length(x)
                x[i]
            else
                error("You changed the number of arguments. This isn't allowed!")
            end
        end
    end
end

function (PlotType::Type{<: AbstractPlot{Typ}})(scene::SceneLike, attributes::Attributes, args) where Typ
    input = to_node.(args)
    argnodes = lift(input...) do args...
        convert_arguments(PlotType, args...)
    end
    PlotType(scene, attributes, input, argnodes)
end

function (PlotType::Type{<: AbstractPlot{Typ}})(scene::SceneLike, attributes::Attributes, input, args) where Typ
    # The argument type of the final plot object is the assumened to stay constant after
    # argument conversion. This might not always hold, but it simplifies
    # things quite a bit
    ArgTyp = typeof(to_value(args))
    # construct the fully qualified plot type, from the possible incomplete (abstract)
    # PlotType
    FinalType = Combined{Typ, ArgTyp}
    plot_attributes = merged_get!(
        ()-> default_theme(scene, FinalType),
        plotsym(FinalType), scene, attributes
    )

    # Transformation is a field of the plot type, but can be given as an attribute
    trans = get(plot_attributes, :transformation, automatic)
    transformation = if to_value(trans) == automatic
        Transformation(scene)
    elseif isa(to_value(trans), Transformation)
        to_value(trans)
    else
        t = Transformation(scene)
        transform!(t, to_value(trans))
        t
    end
    replace_automatic!(plot_attributes, :model) do
        transformation.model
    end
    # create the plot, with the full attributes, the input signals, and the final signal nodes.
    plot_obj = FinalType(scene, transformation, plot_attributes, input, seperate_tuple(args))
    transformation.parent[] = plot_obj
    calculated_attributes!(plot_obj)
    plot_obj
end



"""
    `plottype(plot_args...)`

The default plot type for any argument is `lines`.
Any custom argument combination that has only one meaningful way to be plotted should overload this.
e.g.:
```example
    # make plot(rand(5, 5, 5)) plot as a volume
    plottype(x::Array{<: AbstractFloat, 3}) = Volume
```
"""
plottype(plot_args...) = Combined{Any, Tuple{typeof.(to_value.(plot_args))...}} # default to dispatch to type recipes!

## generic definitions
# If the Combined has no plot func, calculate them
plottype(::Type{<: Combined{Any}}, argvalues...) = plottype(argvalues...)
plottype(::Type{Any}, argvalues...) = plottype(argvalues...)
# If it has something more concrete than Any, use it directly
plottype(P::Type{<: Combined{T}}, argvalues...) where T = P

## specialized definitions for types
plottype(::RealVector, ::RealVector) = Lines
plottype(::RealVector) = Lines
plottype(::AbstractMatrix{<: Real}) = Heatmap
plottype(::Array{<: AbstractFloat, 3}) = Volume
plottype(::AbstractString) = Text

"""
    plottype(P1::Type{<: Combined{T1}}, P2::Type{<: Combined{T2}})

Chooses the more concrete plot type
```example
function convert_arguments(P::PlotFunc, args...)
    ptype = plottype(P, Lines)
    ...
end
"""
plottype(P1::Type{<: Combined{Any}}, P2::Type{<: Combined{T}}) where T = P2
plottype(P1::Type{<: Combined{T}}, P2::Type{<: Combined}) where T = P1


"""
Returns the Combined type that represents the signature of `args`.
"""
function Plot(args::Vararg{Any, N}) where N
    Combined{Any, <: Tuple{args...}}
end
Base.@pure function Plot(::Type{T}) where T
    Combined{Any, <: Tuple{T}}
end
Base.@pure function Plot(::Type{T1}, ::Type{T2}) where {T1, T2}
    Combined{Any, <: Tuple{T1, T2}}
end

# all the plotting functions that get a plot type
const PlotFunc = Union{Type{Any}, Type{<: AbstractPlot}}

plot(P::PlotFunc, args...; kw_attributes...) = plot!(Scene(), P, Attributes(kw_attributes), args...)
plot!(P::PlotFunc, args...; kw_attributes...) = plot!(current_scene(), P, Attributes(kw_attributes), args...)
plot(scene::SceneLike, P::PlotFunc, args...; kw_attributes...) = plot!(Scene(scene), P, Attributes(kw_attributes), args...)
plot!(scene::SceneLike, P::PlotFunc, args...; kw_attributes...) = plot!(scene, P, Attributes(kw_attributes), args...)

plot(scene::SceneLike, P::PlotFunc, attributes::Attributes, args...; kw_attributes...) = plot!(Scene(scene), P, merge!(Attributes(kw_attributes), attributes), args...)
plot!(P::PlotFunc, attributes::Attributes, args...; kw_attributes...) = plot!(current_scene(), P, merge!(Attributes(kw_attributes), attributes), args...)
plot(P::PlotFunc, attributes::Attributes, args...; kw_attributes...) = plot!(Scene(), P, merge!(Attributes(kw_attributes), attributes), args...)

# Overload remaining functions
eval(default_plot_signatures(:plot, :plot!, :Any))

# plots to scene

plotfunc(::Combined{F}) where F = F


"""
Main plotting signatures that plot/plot! route to if no Plot Type is given
"""
function plot!(scene::SceneLike, P::PlotFunc, attributes::Attributes, args...; kw_attributes...)
    attributes = merge!(Attributes(kw_attributes), attributes)
    argvalues = to_value.(args)
    PreType = plottype(P, argvalues...)
    # plottype will lose the argument types, so we just extract the plot func
    # type and recreate the type with the argument type
    PreType = Combined{plotfunc(PreType), typeof(argvalues)}
    convert_keys = intersect(used_attributes(PreType, argvalues...), keys(attributes))
    kw_signal = if isempty(convert_keys) # lift(f) isn't supported so we need to catch the empty case
        Node(())
    else
        lift((args...)-> Pair.(convert_keys, args), getindex.(attributes, convert_keys)...) # make them one tuple to easier pass through
    end
    # call convert_arguments for a first time to get things started
    converted = convert_arguments(PreType, argvalues...; kw_signal[]...)
    # convert_arguments can return different things depending on the recipe type
    # apply_conversion deals with that!

    FinalType, argsconverted = apply_convert!(PreType, attributes, converted)
    converted_node = Node(argsconverted)
    input_nodes =  to_node.(args)
    onany(kw_signal, lift(tuple, input_nodes...)) do kwargs, args
        # do the argument conversion inside a lift
        result = convert_arguments(FinalType, args...; kwargs...)
        finaltype, argsconverted = apply_convert!(FinalType, attributes, result)
        if finaltype != FinalType
            error("Plot type changed from $FinalType to $finaltype after conversion.
                Changing the plot type based on values in convert_arguments is not allowed"
            )
        end
        converted_node[] = argsconverted
    end
    plot!(scene, FinalType, attributes, input_nodes, converted_node)
end

plot!(p::Combined) = _plot!(p)

_plot!(p::Atomic{T}) where T = p

function _plot!(p::Combined{Any, T}) where T
    args = (T.parameters...,)
    typed_args = join(string.("::", args), ", ")
    error("Plotting for the arguments ($typed_args) not defined. If you want to support those arguments, overload plot!(plot::Plot$((args...,)))")
end
function _plot!(p::Combined{X, T}) where {X, T}
    args = (T.parameters...,)
    typed_args = join(string.("::", args), ", ")
    error("Plotting for the arguments ($typed_args) not defined for $X. If you want to support those arguments, overload plot!(plot::$X{ <: $T})")
end

function show_attributes(attributes)
    for (k, v) in attributes
        println("    ", k, ": ", v[] == nothing ? "nothing" : v[])
    end
end

"""
    extract_scene_attributes!(attributes)

removes all scene attributes from `attributes` and returns them in a new
Attribute dict.
"""
function extract_scene_attributes!(attributes)
    scene_attributes = (
        :backgroundcolor,
        :resolution,
        :show_axis,
        :show_legend,
        :scale_plot,
        :center,
        :axis,
        :axis2d,
        :axis3d,
        :legend,
        :camera,
        :limits,
        :padding,
        :raw
    )
    result = Attributes()
    for k in scene_attributes
        haskey(attributes, k) && (result[k] = pop!(attributes, k))
    end
    return result
end

function plot!(scene::SceneLike, ::Type{PlotType}, attributes::Attributes, input::NTuple{N, Node}, args::Node) where {N, PlotType <: AbstractPlot}
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    scene_attributes = extract_scene_attributes!(attributes)
    plot_object = PlotType(scene, copy(attributes), input, args)
    # transfer the merged attributes from theme and user defined to the scene
    for (k, v) in scene_attributes
        scene.attributes[k] = v
    end
    # We allow certain scene attributes to be part of the plot theme
    for k in (:camera, :raw)
        if haskey(plot_object, k)
            scene.attributes[k] = plot_object[k]
        end
    end
    for (at1, at2) in mutual_exclusive_attributes(PlotType)
        #nothing here to get around defaults in GLVisualize
        haskey(attributes, at1) && haskey(attributes, at2) && error("$at1 conflicts with $at2, please specify only one.")
        if haskey(attributes, at1) && haskey(plot_object.attributes, at2)
            plot_object.attributes[at2] = nothing
        elseif haskey(attributes, at2) && haskey(plot_object.attributes, at1)
            plot_object.attributes[at1] = nothing
        end
    end
    # call user defined recipe overload to fill the plot type
    plot!(plot_object)

    push!(scene, plot_object)

    if !scene.raw[] || scene[:camera][] !== automatic
        # if no camera controls yet, setup camera
        setup_camera!(scene)
    end
    if !scene.raw[]
        add_axis!(scene, scene.attributes)
    end
    # ! ∘ isaxis --> (x)-> !isaxis(x)
    # move axis to front, so that scene[end] gives back the last plot and not the axis!
    if !isempty(scene.plots) && isaxis(last(scene.plots))
        axis = pop!(scene.plots)
        pushfirst!(scene.plots, axis)
    end
    scene
end

function plot!(scene::Combined, ::Type{PlotType}, attributes::Attributes, args...) where PlotType <: AbstractPlot
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object = PlotType(scene, attributes, args)
    # call user defined recipe overload to fill the plot type
    plot!(plot_object)
    push!(scene.plots, plot_object)
    scene
end
function plot!(scene::Combined, ::Type{PlotType}, attributes::Attributes, input::NTuple{N,Node}, args::Node) where {N, PlotType <: AbstractPlot}
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    plot_object = PlotType(scene, attributes, input, args)
    # call user defined recipe overload to fill the plot type
    plot!(plot_object)
    push!(scene.plots, plot_object)
    scene
end

function apply_camera!(scene::Scene, cam_func)
    if cam_func in (cam2d!, cam3d!, campixel!, cam3d_cad!)
        cam_func(scene)
    else
        error("Unrecognized `camera` attribute type: $(typeof(cam_func)). Use automatic, cam2d! or cam3d!, campixel!, cam3d_cad!")
    end
end




function setup_camera!(scene::Scene)
    theme_cam = scene[:camera][]
    if theme_cam == automatic
        cam = cameracontrols(scene)
        # only automatically add camera when cameracontrols are empty (not set)
        if cam == EmptyCamera()
            if is2d(scene)
                cam2d!(scene)
            else
                cam3d!(scene)
            end
        end
    else
        apply_camera!(scene, theme_cam)
    end
    scene
end

function find_in_plots(scene::Scene, key::Symbol)
    # TODO findfirst is a bit flaky... maybe merge multiple ranges + tick labels?!
    idx = findfirst(scene.plots) do plot
        !isaxis(plot) && haskey(plot, key) && plot[key][] !== automatic
    end
    if idx !== nothing
        scene.plots[idx][key]
    else
        automatic
    end
end

function add_axis!(scene::Scene, attributes = Attributes())
    show_axis = scene.show_axis[]
    show_axis isa Bool || error("show_axis needs to be a bool")
    axistype = if scene.axis_type[] == automatic
        is2d(scene) ? axis2d! : axis3d!
    elseif scene.axis_type[] in (axis2d!, axis3d!)
        scene.axis_type[]
    else
        error("Unrecogniced `axis_type` attribute type: $(typeof(scene[:axis_type][])). Use automatic, axis2d! or axis3d!")
    end

    if show_axis && scene[Axis] === nothing
        axis_attributes = Attributes()
        for key in (:axis, :axis2d, :axis3d)
            if haskey(scene, key) && !isempty(scene[key])
                axis_attributes = scene[key]
                break
            end
        end
        ranges = get(attributes, :tickranges) do
            find_in_plots(scene, :tickranges)
        end
        labels = get(attributes, :ticklabels) do
            find_in_plots(scene, :ticklabels)
        end
        lims = lift(scene.limits, scene.data_limits) do sl, dl
            sl === automatic && return dl
            return sl
        end
        axistype(
            scene, axis_attributes, lims,
            ticks = (ranges = ranges, labels = labels)
        )
    end
    scene
end

function add_labels!(scene::Scene)
    if plot_attributes.show_legend[] && haskey(p.attributes, :colormap)
        legend_attributes = plot_attributes[:legend][]
        colorlegend(scene, p.attributes[:colormap], p.attributes[:colorrange], legend_attributes)
    end
    scene
end
