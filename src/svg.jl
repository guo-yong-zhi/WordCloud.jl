using XML

struct SVG
    data::String
    height::Int
    width::Int
end
Base.string(svg::SVG) = svg.data
Base.size(s::SVG) = (s.height, s.width)
Base.broadcastable(s::SVG) = Ref(s)

function Base.show(f::IO, ::MIME"image/svg+xml", svg::SVG)
    write(f, string(svg))
end
function xml_addchildren!(svgdoc::Node, children)
    children isa Pair && (children = (children,))
    for (e, attrs) in children
        push!(svgdoc[end], Node(XML.Element, e, Dict(attrs)))
    end
    svgdoc
end
function xml_wrapchildren!(svgdoc::Node, wrappers)
    wrappers isa Pair && (wrappers = (wrappers,))
    for (e, attrs) in wrappers
        attrs isa Pair && (attrs = (attrs,))
        we = Node(XML.Element, e, Dict(attrs), nothing, children(svgdoc[end]))
        svgnode = Node(XML.nodetype(svgdoc[end]), tag(svgdoc[end]), XML.attributes(svgdoc[end]), value(svgdoc[end]), we)
        svgdoc[end] = svgnode
    end
    svgdoc
end
function xml_stack!(svgs::AbstractVector{Node})
    @assert !isempty(svgs)
    bg, rest = Iterators.peel(svgs)
    rt = bg[end]
    for svg in rest
        for c in children(svg[end])
            push!(rt, c)
        end
    end
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
