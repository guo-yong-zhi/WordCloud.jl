module QTree
export AbstractStackedQtree, StackedQtree, ShiftedQtree, buildqtree!,
    shift!, setrshift!,　setcshift!, setshift!, getshift,
    collision,  collision_bfs, collision_bfs_rand, listcollision,
    findroom, levelnum, outofbounds, kernelsize, placement!, decode, placement!

using Random
using Combinatorics

const PERM4 = permutations(1:4)|>collect
@assert length(PERM4) == 24
shuffle4() = @inbounds PERM4[rand(1:24)]
function child(ind::Tuple{Int,Int,Int}, n::Int)
    s = 4 - n
    @inbounds (ind[1] - 1, 2ind[2] - s & 0x01, 2ind[3] - (s & 0x02) >> 1)
end
parent(ind::Tuple{Int,Int,Int}) = (ind[1] + 1, (ind[2] + 1) ÷ 2, (ind[3] + 1) ÷ 2)

function qcode(Q, i)
    @inbounds c1 = Q[child(i, 1)] |> first
    @inbounds c2 = Q[child(i, 2)] |> first
    @inbounds c3 = Q[child(i, 3)] |> first
    @inbounds c4 = Q[child(i, 4)] |> first
    c1 | c2 | c3 | c4
end
qcode!(Q, i) = @inbounds Q[i] = qcode(Q, i)
decode(c) = [0., 1., 0.5][c .& 0x03]

const FULL = 0xaa; EMPTY = 0x55; HALF = 0xff

abstract type AbstractStackedQtree end
function Base.getindex(t::AbstractStackedQtree, l::Integer) end
Base.getindex(t::AbstractStackedQtree, l, r, c) = t[l][r, c]
Base.getindex(t::AbstractStackedQtree, inds::Tuple{Int,Int,Int}) = t[inds...]
Base.setindex!(t::AbstractStackedQtree, v, l, r, c) =  t[l][r, c] = v
Base.setindex!(t::AbstractStackedQtree, v, inds::Tuple{Int,Int,Int}) = t[inds...] = v
function levelnum(t::AbstractStackedQtree) end
Base.lastindex(t::AbstractStackedQtree) = levelnum(t)
Base.size(t::AbstractStackedQtree) = levelnum(t) > 0 ? size(t[1]) : (0,)

################ StackedQtree
struct StackedQtree{T <: AbstractVector{<:AbstractMatrix{UInt8}}} <: AbstractStackedQtree
    layers::T
end

StackedQtree(l::T) where T = StackedQtree{T}(l)
function StackedQtree(pic::AbstractMatrix{UInt8})
    m, n = size(pic)
    @assert m == n
    @assert isinteger(log2(m))
        
    l = Vector{typeof(pic)}()
    push!(l, pic)
    while size(l[end]) != (1, 1)
        m, n = size(l[end])
        push!(l, similar(pic, (m + 1) ÷ 2, (n + 1) ÷ 2))
    end
    StackedQtree(l)
end

function StackedQtree(pic::AbstractMatrix)
    pic = map(x -> x == 0 ? EMPTY : FULL, pic)
    StackedQtree(pic)
end

Base.getindex(t::StackedQtree, l::Integer) = t.layers[l]
levelnum(t::StackedQtree) = length(t.layers)

function buildqtree!(t::AbstractStackedQtree, layer=2)
    for l in layer:levelnum(t)
        for r in 1:size(t[l], 1)
            for c in 1:size(t[l], 2)
                qcode!(t, (l, r, c))
            end
        end
    end
end


################ ShiftedQtree
mutable struct PaddedMat{T <: AbstractMatrix{UInt8}} <: AbstractMatrix{UInt8}
    kernel::T
    size::Tuple{Int,Int}
    rshift::Int
    cshift::Int
    default::UInt8
end

PaddedMat(l::AbstractMatrix{UInt8}, sz::Tuple{Int,Int}=size(l), rshift=0, cshift=0; default=0x00) = PaddedMat(l, sz, rshift, cshift, default)
PaddedMat{T}(l::T, sz::Tuple{Int,Int}=size(l), rshift=0, 
cshift=0; default=0x00) where {T <: AbstractMatrix{UInt8}} = PaddedMat(l, sz, rshift, cshift, default)

rshift!(l::PaddedMat, v) = l.rshift += v
cshift!(l::PaddedMat, v) = l.cshift += v
rshift(l::PaddedMat) = l.rshift
cshift(l::PaddedMat) = l.cshift
setrshift!(l::PaddedMat, v) = l.rshift = v
setcshift!(l::PaddedMat, v) = l.cshift = v
getrshift(l::PaddedMat) = l.rshift
getcshift(l::PaddedMat) = l.cshift
getshift(l::PaddedMat) = l.rshift, l.cshift
getdefault(l::PaddedMat) = l.default
inkernelbounds(l::PaddedMat, r, c) = 0 < r - l.rshift <= size(l.kernel, 1) && 0 < c - l.cshift <= size(l.kernel, 2)
inbounds(l::PaddedMat, r, c) = 0 < r <= size(l, 1) && 0 < c  <= size(l, 2)
kernelsize(l::PaddedMat) = size(l.kernel)
kernel(l::PaddedMat) = l.kernel
function Base.checkbounds(l::PaddedMat, I...) end #关闭边界检查，允许负索引、超界索引
function Base.getindex(l::PaddedMat, r, c)
    if inkernelbounds(l, r, c)
        return @inbounds l.kernel[r - l.rshift, c - l.cshift]
    end
    return l.default #负索引、超界索引返回default
end
function Base.setindex!(l::PaddedMat, v, r, c)
    l.kernel[r - l.rshift, c - l.cshift] = v #kernel自身有边界检查
end

Base.size(l::PaddedMat) = l.size

struct ShiftedQtree{T <: AbstractVector{<:PaddedMat}} <: AbstractStackedQtree
    layers::T
end

ShiftedQtree(l::T) where T = ShiftedQtree{T}(l)
function ShiftedQtree(pic::PaddedMat{Array{UInt8,2}})
    sz = size(pic, 1)
    @assert size(pic, 1) == size(pic, 2)
    @assert isinteger(log2(sz))
    l = [pic]
    m, n = kernelsize(l[end])
    while sz != 1
        sz ÷= 2
        m, n = m ÷ 2 + 1, n ÷ 2 + 1
#         @show m,n
        push!(l, PaddedMat(similar(pic, m, n), (sz, sz), default=getdefault(pic)))
    end
    ShiftedQtree(l)
end
function ShiftedQtree(pic::AbstractMatrix{UInt8}, sz::Integer; default=EMPTY)
    @assert isinteger(log2(sz))
    ShiftedQtree(PaddedMat(pic, (sz, sz), default=default))
end
function ShiftedQtree(pic::AbstractMatrix{UInt8}; default=EMPTY)
    m = max(size(pic)...)
    ShiftedQtree(pic, 2^ceil(Int, log2(m)), default=default)
end
function ShiftedQtree(pic::AbstractMatrix, args...; kargs...)
    @assert !isempty(pic)
    pic = map(x -> x == 0 ? EMPTY : FULL, pic)
    ShiftedQtree(pic, args...; kargs...)
end
Base.getindex(t::ShiftedQtree, l::Integer) = t.layers[l]
levelnum(t::ShiftedQtree) = length(t.layers)
function buildqtree!(t::ShiftedQtree, layer=2)
    for l in layer:levelnum(t)
        m = rshift(t[l - 1])
        n = cshift(t[l - 1])
        m2 = m ÷ 2
        n2 = n ÷ 2
        setrshift!(t[l], m2)
        setcshift!(t[l], n2)
        for r in 1:kernelsize(t[l])[1]
            for c in 1:kernelsize(t[l])[2]
#                 @show (l,m2+r,n2+c)
                qcode!(t, (l, m2 + r, n2 + c))
            end
        end
    end
    t
end
function rshift!(t::ShiftedQtree, l::Integer, st::Integer)
    for i in l:-1:1
        rshift!(t[i], st)
        st *= 2
    end
    buildqtree!(t, l + 1)
end
function cshift!(t::ShiftedQtree, l::Integer, st::Integer)
    for i in l:-1:1
        cshift!(t[i], st)
        st *= 2
    end
    buildqtree!(t, l + 1)
end
function setrshift!(t::ShiftedQtree, l::Integer, st::Integer)
    for i in l:-1:1
        setrshift!(t[i], st)
        st *= 2
    end
    buildqtree!(t, l + 1)
end
function setcshift!(t::ShiftedQtree, l::Integer, st::Integer)
    for i in l:-1:1
        setcshift!(t[i], st)
        st *= 2
    end
    buildqtree!(t, l + 1)
end

function shift!(t::ShiftedQtree, l::Integer, st1::Integer, st2::Integer)
    for i in l:-1:1
        rshift!(t[i], st1)
        cshift!(t[i], st2)
        st1 *= 2
        st2 *= 2
    end
    buildqtree!(t, l + 1)
end
shift!(t::ShiftedQtree, l::Integer, st::Tuple{Integer,Integer}) = shift!(t, l, st...)
function setshift!(t::ShiftedQtree, l::Integer, st1::Integer, st2::Integer)
    for i in l:-1:1
        setrshift!(t[i], st1)
        setcshift!(t[i], st2)
        st1 *= 2
        st2 *= 2
    end
    buildqtree!(t, l + 1)
end
setshift!(t::ShiftedQtree, l::Integer, st::Tuple{Integer,Integer}) = setshift!(t, l, st...)
getshift(t::ShiftedQtree, l::Integer=1) = getshift(t[l])
kernelsize(t::ShiftedQtree, l::Integer=1) = kernelsize(t[l])
function inbounds(bgqt::ShiftedQtree, qt::ShiftedQtree)
    inbounds(bgqt[1], (getshift(qt[1]) .+ kernelsize(qt[1]) .÷ 2)...)
end
function outofbounds(bgqt::ShiftedQtree, qts)
    [i for (i,t) in enumerate(qts) if !inbounds(bgqt, t)]
end


function collision(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, i=(levelnum(Q1), 1, 1))
    #     @show i
#     @assert size(Q1) == size(Q2)
    n1 = Q1[i]
    n2 = Q2[i]
    if n1 == EMPTY || n2 == EMPTY
        return false, i
    end
    if n1 == FULL || n2 == FULL
        return true, i
    end
        
    r = false, i
    for cn in 1:4 # half
        ci = child(i, cn)
    #         @show cn,ci
    #         @show Q1[ci],Q2[ci]
        r = collision(Q1, Q2, ci)
        if r[1] return r end 
    end
    return r # no collision
end

function collision_bfs(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, q=[(levelnum(Q1), 1, 1)])
#     @assert size(Q1) == size(Q2)
    if isempty(q)
        push!(q, (levelnum(Q1), 1, 1))
    end
    i = q[1]
    n1 = Q1[i]
    n2 = Q2[i]
    if n1 == EMPTY || n2 == EMPTY
        return false, i
    end
    if n1 == FULL || n2 == FULL
        return true, i
    end
    while !isempty(q)
#         @show q
        # Q1[i],Q2[i]都是HALF
        i = popfirst!(q)
        for cn in 1:4
            ci = child(i, cn)
#             @show cn,ci
#             @show Q1[ci],Q2[ci]
            if !(Q1[ci] == EMPTY || Q2[ci] == EMPTY)
                if Q1[ci] == FULL || Q2[ci] == FULL
                    return true, ci
                else
                    push!(q, ci)
                end
            end
        end
    end
    return false, i # no collision
end

function collision_bfs_rand(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, q=[(levelnum(Q1), 1, 1)])
#     @assert size(Q1) == size(Q2)
    if isempty(q)
        push!(q, (levelnum(Q1), 1, 1))
    end
    i = q[1]
    n1 = Q1[i]
    n2 = Q2[i]
    if n1 == EMPTY || n2 == EMPTY
        return .-i
    end
    if n1 == FULL || n2 == FULL
        return i
    end
    while !isempty(q)
#         @show q
        # Q1[i],Q2[i]都是HALF
        i = popfirst!(q)
        for cn in shuffle4()
            ci = child(i, cn)
#             @show cn,ci
#             @show Q1[ci],Q2[ci]
            if !(Q1[ci] == EMPTY || Q2[ci] == EMPTY)
                if Q1[ci] == FULL || Q2[ci] == FULL
                    return ci
                else
                    push!(q, ci)
                end
            end
        end
    end
    return .- i # no collision
end

function listcollision(qtrees::AbstractVector, mask::AbstractStackedQtree)
    collist = []
    indpairs = combinations(0:length(qtrees), 2) |> collect
    getqtree(i) = i==0 ? mask : qtrees[i]
    for (i1, i2) in indpairs
        cp = collision_bfs_rand(getqtree(i1), getqtree(i2))
        if cp[1] >= 0
            push!(collist, (i1, i2))
        end
    end
    collist
end

function findroom(ground, q=[(levelnum(ground), 1, 1)])
    if isempty(q)
        push!(q, (levelnum(ground), 1, 1))
    end
    i = q[1]
    if ground[i] == EMPTY
        return i
    elseif ground[i] == FULL
        return nothing
    end
    while !isempty(q)
        i = popfirst!(q)
        for cn in shuffle4()
            ci = child(i, cn)
            if ground[ci] == EMPTY
                return ci
            elseif ground[ci] == HALF
                push!(q, ci)
            end
        end
    end
    return nothing
end

function overlap(p1::UInt8, p2::UInt8)
    if p1 == FULL || p2 == FULL
        return FULL
    elseif p1 == EMPTY && p2 == EMPTY
        return EMPTY
    else
        error("roung code")
    end
end

overlap(p1::AbstractMatrix, p2::AbstractMatrix) = overlap.(p1, p2)

"将p2叠加到p1上"
function overlap!(p1::PaddedMat, p2::PaddedMat)
    @assert size(p1) == size(p2)
    rs, cs = getshift(p2)
    for i in 1:kernelsize(p2)[1]
        for j in 1:kernelsize(p2)[2]
            p1[rs + i, cs + j] = overlap(p1[rs + i, cs + j], p2[rs + i, cs + j])
        end
    end
    return p1
end

function overlap2!(tree1::ShiftedQtree, tree2::ShiftedQtree)
    overlap!(tree1[1], tree2[1])
    tree1 |> buildqtree!
end

function overlap!(tree1::ShiftedQtree, tree2::ShiftedQtree, ind::Tuple{Int,Int,Int})
    if !(tree1[ind] == FULL || tree2[ind] == EMPTY)
        if ind[1] == 1
            tree1[ind] = FULL
        else
            for ci in 1:4
                overlap!(tree1, tree2, child(ind, ci))
            end
            qcode!(tree1, ind)
        end
    end
    tree1
end

function overlap!(tree1::ShiftedQtree, tree2::ShiftedQtree)
    @assert lastindex(tree1) == lastindex(tree2)
    @assert size(tree1[end]) == size(tree2[end]) == (1, 1)
    overlap!(tree1, tree2, (lastindex(tree1), 1, 1))
end

"将sortedtrees依次叠加到ground上，同时修改sortedtrees的shift"
function placement!(ground, sortedtrees)
    pos = Vector{Tuple{Int, Int, Int}}()
    for t in sortedtrees
        ind = placement!(ground, t)
        overlap!(ground, t)
        if ind === nothing
            return pos
        end
        push!(pos, ind)
    end
    return pos
end

function placement!(ground, qtree::ShiftedQtree)
    ind = findroom(ground)
    # @show ind
    if ind === nothing
        return nothing
    end
    l, r, c = ind
    x = floor(2^(l - 1) * (r - 1) + 2^(l - 2))
    y = floor(2^(l - 1) * (c - 1) + 2^(l - 2))
    m, n = kernelsize(qtree[1])
    setshift!(qtree, 1, x - m ÷ 2, y - n ÷ 2) # 居中
    return ind
end

function placement!(ground, sortedtrees, index::Number)
    for i in 1:length(sortedtrees)
        if i == index
            continue
        end
        overlap!(ground, sortedtrees[i])
    end
    ind = placement!(ground, sortedtrees[index])
    return ind
end
function placement!(ground, sortedtrees, indexes)
    for i in 1:length(sortedtrees)
        if i in indexes
            continue
        end
        overlap!(ground, sortedtrees[i])
    end
    for i in indexes
        placement!(ground, sortedtrees[i])
    end
    nothing
end

end