module Render
export renderstring

using Makie
using GLMakie


function removeborder(p::AbstractMatrix, v)
    a = c = 1
    b = d = 0
    while all(p[a,:] .== v) && a < size(p, 1)
        a += 1
    end
    while all(p[end-b,:] .== v) && b < size(p, 2)
        b += 1
    end
    p = p[a:end-b, :]
    while all(p[:,c] .== v) && c < size(p, 1)
        c += 1
    end
    while all(p[:, end-d] .== v) && d < size(p, 2)
        d += 1
    end
    return p[:, c:end-d]
end

function renderstring(str::AbstractString, size::Real=256, color=:black)
    scene = Scene(resolution = (size, size))
    st = Stepper(scene, "output")
    t=text!(
        scene,
        str,
#       position = (100, 200),
#         align = (:left, :center),
#         textsize = 1,
        color = color,
#         font = "Lisu",
        show_axis = false,
        scale_plot = false,
    )
    step!(st)
    img = GLMakie.scene2image(scene)
    removeborder(img, img[1,1])
end
end