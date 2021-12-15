using EzXML

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
function xml_setattrs(ele, attr::AbstractString)
    an = TextNode(attr)
    link!(ele, an)
    ele
end
function xml_setattrs(ele, attr)
    isempty(attr) || link!(ele, AttributeNode(attr...))
    ele
end
xml_setattrs(ele, attrs::AbstractVector) = xml_setattrs.(Ref(ele), attrs)
function xml_addchildren(parent, children)
    children isa Pair && (children = (children,))
    for (e, attrs) in children
        ele = ElementNode(e)
        xml_setattrs(ele, attrs)
        link!(parent, ele)
    end
    parent
end
function xml_wrapper(wrappers)
    # @show wrappers
    parent = child = nothing
    wrappers isa Pair && (wrappers = (wrappers,))
    for (e, attrs) in wrappers
        ele = ElementNode(e)
        if child !== nothing
            ele = ElementNode(e)
            link!(child, ele)
        end
        if parent === nothing
            parent = ele
        end
        xml_setattrs(ele, attrs)
        child = ele
    end
    parent, child
end
function xml_wrapchildren(parent, wrappers)
    wrapper_parent, wrapper_child = xml_wrapper(wrappers)
    for c in collect(eachelement(parent))
        unlink!(c)
        link!(wrapper_child, c)
    end
    link!(parent, wrapper_parent)
    parent
end
function svg_add(svg::SVG, children)
    sz = size(svg)
    svg = xml_addchildren(root(svg|>string|>parsexml), children)
    SVG(string(svg), sz...)
end
function svg_wrap(svg::SVG, wrappers)
    sz = size(svg)
    svg = xml_wrapchildren(root(svg|>string|>parsexml), wrappers)
    SVG(string(svg), sz...)
end
function svg_stack(svgs)#::AbstractVector{SVG}
    @assert !isempty(svgs)
    bg, rest = Iterators.peel(svgs)
    sz = size(bg)
    rt = root(bg|>string|>parsexml)
    for svg in rest
        for c in collect(eachelement(root(svg|>string|>parsexml)))
            unlink!(c)
            link!(rt, c)
        end
    end
    SVG(string(rt), sz...)
end
