import .QTree.decode
import Colors.Gray
function imageof(layer::AbstractMatrix{UInt8})
    Gray.(decode.(layer))
end
function showmask!(img, mask; highlight=ARGB(1, 0, 0, 0.3))
    mask = .!mask
    hl = convert(eltype(img), parsecolor(highlight))
    img[mask] .= Render.overlay.(img[mask], hl)
    img
end
showmask(img, args...; kargs...) = showmask!(deepcopy(img), args...; kargs...) 
