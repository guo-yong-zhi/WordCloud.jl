using Images

function imageof(layer::AbstractMatrix{UInt8})
    Gray.(QTree.decode(layer))
end

bitor(l) = reduce((a,b)->a.|b, l)