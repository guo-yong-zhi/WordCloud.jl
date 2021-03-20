import .QTree.decode
import Colors.Gray
function imageof(layer::AbstractMatrix{UInt8})
    Gray.(decode(layer))
end

