using XML

struct SVG
    data::String
    height::Float64
    width::Float64
end
Base.string(svg::SVG) = svg.data
Base.size(s::SVG) = (s.height, s.width)
Base.broadcastable(s::SVG) = Ref(s)

function Base.show(f::IO, ::MIME"image/svg+xml", svg::SVG)
    write(f, string(svg))
end

function xmlnode(tag, attrs, children=nothing)
    if !(attrs isa Tuple || attrs isa Vector)
        attrs = (attrs,)
    end
    if (!isempty(attrs)) && first(attrs) isa AbstractString
        c, attrs = Iterators.peel(attrs)
        ch = isnothing(children) ? XML.Text(c) : [XML.Text(c), children...]
        n = Node(XML.Element, tag, Dict(attrs), nothing, ch)
    else
        n = Node(XML.Element, tag, Dict(attrs), nothing, children)
    end
    n
end
function xml_addchildren!(svgdoc::Node, children)
    children isa Pair && (children = (children,))
    for (e, attrs) in children
        pushfirst!(svgdoc[end].children, xmlnode(e, attrs))
    end
    svgdoc
end

function xml_wrapchildren!(svgdoc::Node, wrappers)
    wrappers isa Pair && (wrappers = (wrappers,))
    for (e, attrs) in wrappers
        we = xmlnode(e, attrs, copy(children(svgdoc[end])))
        empty!(svgdoc[end].children)
        push!(svgdoc[end].children, we)
    end
    svgdoc
end
function xml_stack!(svgs::AbstractVector{Node})
    @assert !isempty(svgs)
    bg, rest = Iterators.peel(svgs)
    rt = bg[end]
    for svg in rest
        for c in children(svg[end])
            if isempty(children(rt))
                rt = Node(XML.nodetype(rt), tag(rt), XML.attributes(rt), value(rt), c)
            else
                push!(rt, c)
            end
        end
    end
    bg[end] = rt
    bg
end
function svg_add(svg::SVG, children)
    sz = size(svg)
    svg = xml_addchildren!(parse(string(svg), Node), children)
    SVG(XML.write(svg), sz...)
end
function svg_wrap(svg::SVG, wrappers)
    sz = size(svg)
    svg = xml_wrapchildren!(parse(string(svg), Node), wrappers)
    SVG(XML.write(svg), sz...)
end
function svg_stack(svgs)#::AbstractVector{SVG})
    sz = size(first(svgs))
    svgs = [parse(string(s), Node) for s in svgs]
    bg = xml_stack!(svgs)
    SVG(XML.write(bg), sz...)
end
