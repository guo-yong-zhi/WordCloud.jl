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

function xml_wraper(wrapers)
    parent = child = nothing
    for (e, attrs) in wrapers
        ele = ElementNode(e)
        if child !== nothing
            ele = ElementNode(e)
            link!(child, ele)
        end
        if parent === nothing
            parent = ele
        end
        for attr in attrs
            an = AttributeNode(attr...)
            link!(ele, an)
        end
        child = ele
    end
    parent, child
end
function xml_wrapchildren(parent, wrapers)
    wraper_parent, wraper_child = xml_wraper(wrapers)
    for c in collect(eachelement(parent))
        unlink!(c)
        link!(wraper_child, c)
    end
    link!(parent, wraper_parent)
    parent
end
function svg_wrap(svg::SVG, wrapers)
    sz = size(svg)
    svg = xml_wrapchildren(root(svg|>string|>parsexml), wrapers)
    SVG(string(svg), sz...)
end
function svg_stack!(svgs)#::AbstractVector{SVG}
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
