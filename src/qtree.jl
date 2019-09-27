module QTree
export　StackedQtree, ShiftedQtree, buildqtree!
export shift!, setrshift!,　setcshift!, collision,  collision_bfs, collision_bfs_rand, decode, levelnum

using Random
function child(ind::Tuple{Int,Int,Int}, n::Int)
    s = 4-n
    (ind[1]-1, 2ind[2]-s&0x01, 2ind[3]-(s&0x02)>>1)
end
parent(ind::Tuple{Int,Int,Int}) = (ind[1]+1, (ind[2]+1)÷2, (ind[3]+1)÷2)

function qcode(Q, i)
    c1 = Q[child(i, 1)]|>first
    c2 = Q[child(i, 2)]|>first
    c3 = Q[child(i, 3)]|>first
    c4 = Q[child(i, 4)]|>first
    c1 | c2 | c3 | c4
end
qcode!(Q, i) = Q[i] = qcode(Q, i)
decode(c) = [0., 1., 0.5][c.&0x03]

const FULL = 0xaa; EMPTY = 0x55; HALF = 0xff


abstract type AbstractStackedQtree end
function Base.getindex(t::AbstractStackedQtree, l::Integer) end
Base.getindex(t::AbstractStackedQtree, l, r, c) = t[l][r, c]
Base.getindex(t::AbstractStackedQtree, inds::Tuple{Int, Int, Int}) = t[inds...]
Base.setindex!(t::AbstractStackedQtree, v, l, r, c) =  t[l][r, c] = v
Base.setindex!(t::AbstractStackedQtree, v, inds::Tuple{Int, Int, Int}) = t[inds...]=v
function levelnum(t::AbstractStackedQtree) end
Base.size(t::AbstractStackedQtree) = levelnum(t)>0 ? size(t[1]) : (0,)

################ StackedQtree
struct StackedQtree{T<:AbstractVector} <: AbstractStackedQtree
    layers::T
    function StackedQtree{T}(l::T) where T<:AbstractVector
        if eltype(l) <: AbstractMatrix{UInt8}
            return new(l)
        else
            error("Roung Type $(eltype(l)). should be AbstractMatrix{UInt8}")
        end
    end
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
        push!(l, similar(pic, (m+1)÷2, (n+1)÷2))
    end
    StackedQtree(l)
end

function StackedQtree(pic::AbstractMatrix)
    pic = map(x -> x==0 ? EMPTY : FULL, pic)
    StackedQtree(pic)
end

Base.getindex(t::StackedQtree, l::Integer) = t.layers[l]
levelnum(t::StackedQtree) = length(t.layers)

function buildqtree!(t::AbstractStackedQtree, layer=2)
    for l in layer:levelnum(t)
        for r in 1:size(t[l], 1)
            for c in 1:size(t[l], 2)
                qcode!(t, (l,r,c))
            end
        end
    end
end


################ ShiftedQtree
mutable struct PaddedMat{T<:AbstractMatrix{UInt8}} <: AbstractMatrix{UInt8}
    kernel::T
    size::Tuple{Int, Int}
    rshift::Int
    cshift::Int
    default::UInt8
end
PaddedMat(l::AbstractMatrix{UInt8}, sz::Tuple{Int, Int}=size(l), 
    rshift=0, cshift=0; default=0x00) = PaddedMat(l, sz, rshift, cshift, default)

rshift!(l::PaddedMat, v) = l.rshift += v
cshift!(l::PaddedMat, v) = l.cshift += v
rshift(l::PaddedMat) = l.rshift
cshift(l::PaddedMat) = l.cshift
setrshift!(l::PaddedMat, v) = l.rshift = v
setcshift!(l::PaddedMat, v) = l.cshift = v
inkernelbound(l::PaddedMat, r, c) = 0<r-l.rshift<=size(l.kernel,1)&&0<c-l.cshift<=size(l.kernel,2)
kernelszie(l::PaddedMat) = size(l.kernel)
kernel(l::PaddedMat) = l.kernel
function Base.getindex(l::PaddedMat, r, c)
    if inkernelbound(l, r, c)
        return l.kernel[r-l.rshift, c-l.cshift]
    end
    return l.default
#     if 0<r<=l.size[1] && 0<c<=l.size[2]
#         return l.default
#     end
# #     throw(BoundsError(l,(r,c)))
end
function Base.setindex!(l::PaddedMat, v, r, c)
    l.kernel[r-l.rshift, c-l.cshift] = v
end
Base.size(l::PaddedMat) = l.size

struct ShiftedQtree{T<:AbstractVector} <: AbstractStackedQtree
    layers::T
    function ShiftedQtree{T}(l::T) where T<:AbstractVector
        if eltype(l) <: PaddedMat
            return new(l)
        else
            error("Roung Type $(eltype(l)). should be PaddedMat")
        end
    end
end

ShiftedQtree(l::T) where T = ShiftedQtree{T}(l)
function ShiftedQtree(pic::AbstractMatrix{UInt8}, sz::Integer; default=EMPTY)
    @assert isinteger(log2(sz))
    l = [PaddedMat(pic, (sz,sz), default=default)]
    m, n = kernelszie(l[end])
    while sz != 1
        sz ÷= 2
        m, n = m÷2+1, n÷2+1
#         @show m,n
        push!(l, PaddedMat(similar(pic, m, n), (sz,sz), default=default))
    end
    ShiftedQtree(l)
end
function ShiftedQtree(pic::AbstractMatrix{UInt8}; default=EMPTY)
    m = max(size(pic)...)
    ShiftedQtree(pic, 2^ceil(Int, log2(m)), default=default)
end
function ShiftedQtree(pic::AbstractMatrix, args...; kargs...)
    pic = map(x -> x==0 ? EMPTY : FULL, pic)
    ShiftedQtree(pic, args...; kargs...)
end
Base.getindex(t::ShiftedQtree, l::Integer) = t.layers[l]
levelnum(t::ShiftedQtree) = length(t.layers)
function buildqtree!(t::ShiftedQtree, layer=2)
    for l in layer:levelnum(t)
        m = rshift(t[l-1])
        n = cshift(t[l-1])
        m2 = m÷2
        n2 = n÷2
        setrshift!(t[l], m2)
        setcshift!(t[l], n2)
        for r in 1:kernelszie(t[l])[1]
            for c in 1:kernelszie(t[l])[2]
#                 @show (l,m2+r,n2+c)
                qcode!(t, (l,m2+r,n2+c))
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
    buildqtree!(t, l+1)
end
function cshift!(t::ShiftedQtree, l::Integer, st::Integer)
    for i in l:-1:1
        cshift!(t[i], st)
        st *= 2
    end
    buildqtree!(t, l+1)
end

function shift!(t::ShiftedQtree, l::Integer, st1::Integer, st2::Integer)
    for i in l:-1:1
        rshift!(t[i], st1)
        cshift!(t[i], st2)
        st1 *= 2
        st2 *= 2
    end
    buildqtree!(t, l+1)
end
shift!(t::ShiftedQtree, l::Integer, st::Tuple{Integer,Integer}) = shift!(t, l, st...)


################ collision
function collision(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, i=(levelnum(Q1),1,1))
    #     @show i
        @assert size(Q1)==size(Q2)
        n1 = Q1[i]
        n2 = Q2[i]
        if n1 == EMPTY || n2 == EMPTY
            return false, i
        end
        if n1 == FULL || n2 == FULL
            return true, i
        end
        
        r = false, i
        for cn in 1:4 #half
            ci = child(i, cn)
    #         @show cn,ci
    #         @show Q1[ci],Q2[ci]
            r = collision(Q1, Q2, ci)
            if r[1] return r end 
        end
        return r #no collision
    end

function collision_bfs(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, q=[(levelnum(Q1),1,1)])
    @assert size(Q1)==size(Q2)
    @assert !isempty(q)
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
        #Q1[i],Q2[i]都是HALF
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
    return false, i #no collision
end

function collision_bfs_rand(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, q=[(levelnum(Q1),1,1)])
    @assert size(Q1)==size(Q2)
    @assert !isempty(q)
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
        #Q1[i],Q2[i]都是HALF
        i = popfirst!(q)
        for cn in shuffle(1:4)
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
    return false, i #no collision
end

end